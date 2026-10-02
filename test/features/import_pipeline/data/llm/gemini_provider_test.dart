import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:irenefy/core/errors/failure.dart';
import 'package:irenefy/core/logging/app_log.dart';
import 'package:irenefy/features/import_pipeline/data/llm/gemini_prompt.dart';
import 'package:irenefy/features/import_pipeline/data/llm/gemini_provider.dart';
import 'package:irenefy/features/import_pipeline/domain/llm_provider.dart';
import 'package:irenefy/features/import_pipeline/domain/recipe_schema.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';

import '../../../settings/fake_llm_settings.dart';
import '../fake_http.dart';

// Chiavi finte nei due formati di Google: mai chiavi reali nei test.
const authKey = 'AQ.Ab8RN6-prova_FINTA_1234567890';
const classicKey = 'AIzaSyFINTA_prova-0123456789abcdefghijk';

const generateUrl =
    '${geminiBaseUrl}models/gemini-3.5-flash-lite:generateContent';
const modelUrl = '${geminiBaseUrl}models/gemini-3.5-flash-lite';

String fixture(String name) =>
    File('test/fixtures/gemini/$name').readAsStringSync();

const input = ExtractionInput(
  platform: SourcePlatform.instagram,
  caption: 'Pasta al pomodoro 🍅\n200 g di spaghetti\n300 g di passata\n#pasta',
  transcript: 'oggi facciamo una pasta velocissima',
  authorName: '@cuoca_prova',
);

/// Risposta di `generateContent` con un solo candidato.
String generation({
  List<Map<String, Object?>> parts = const [
    {'text': '{"isRecipe": true}'},
  ],
  String? finishReason = 'STOP',
  String? modelVersion = 'gemini-3.5-flash-lite',
}) => jsonEncode({
  'candidates': [
    {
      'content': {'role': 'model', 'parts': parts},
      'finishReason': ?finishReason,
    },
  ],
  'modelVersion': ?modelVersion,
});

void main() {
  late List<Duration> waits;
  late AppLog log;

  setUp(() {
    waits = [];
    log = AppLog();
  });

  GeminiProvider provider(
    FakeHttp http, {
    String? apiKey = authKey,
    GeminiModel model = GeminiModel.defaultModel,
  }) => GeminiProvider(
    settings: FakeLlmSettings(apiKey: apiKey, model: model),
    dio: createGeminiHttpClient()..httpClientAdapter = http,
    log: log,
    wait: (delay) async => waits.add(delay),
  );

  Map<String, Object?> sentBody(FakeHttp http, [int index = 0]) =>
      http.requests[index].data as Map<String, Object?>;

  String userText(Map<String, Object?> body) {
    final contents = body['contents']! as List<Object?>;
    final message = contents.single! as Map<String, Object?>;
    final parts = message['parts']! as List<Object?>;
    return (parts.single! as Map<String, Object?>)['text']! as String;
  }

  group('richiesta', () {
    test(
      'POST al modello scelto, chiave solo nell\'intestazione, corpo completo',
      () async {
        final http = FakeHttp({
          generateUrl: jsonResponse(fixture('risposta_valida.json')),
        });

        await provider(http).extractRecipe(input);

        final request = http.requests.single;
        expect(request.method, 'POST');
        expect(request.uri.toString(), generateUrl);
        expect(request.uri.query, isEmpty);
        expect(request.uri.toString(), isNot(contains(authKey)));
        expect(request.headers['x-goog-api-key'], authKey);

        final body = sentBody(http);
        // Il corpo deve essere serializzabile così com'è.
        expect(() => jsonEncode(body), returnsNormally);
        final system = body['systemInstruction']! as Map<String, Object?>;
        expect(jsonEncode(system), contains('ricette'));

        final message =
            (body['contents']! as List<Object?>).single!
                as Map<String, Object?>;
        expect(message['role'], 'user');

        final config = body['generationConfig']! as Map<String, Object?>;
        expect(config['responseMimeType'], 'application/json');
        expect(config['responseJsonSchema'], same(recipeResponseSchema));
        expect(config['thinkingConfig'], {'thinkingLevel': 'MINIMAL'});
        expect(config['maxOutputTokens'], 8192);
        // D-36: si lascia la temperatura predefinita dei modelli Gemini 3.
        expect(jsonEncode(body), isNot(contains('"temperature":')));
        expect(config.containsKey('temperature'), isFalse);
      },
    );

    test('il thinkingLevel segue il modello scelto', () async {
      final http = FakeHttp({
        '${geminiBaseUrl}models/gemini-3.8-flash:generateContent': jsonResponse(
          generation(),
        ),
      });

      await provider(http, model: GeminiModel.flash38).extractRecipe(input);

      final config =
          sentBody(http)['generationConfig']! as Map<String, Object?>;
      expect(config['thinkingConfig'], {'thinkingLevel': 'LOW'});
    });

    test('il messaggio contiene didascalia, trascrizione e fonte', () async {
      final http = FakeHttp({generateUrl: jsonResponse(generation())});

      await provider(http).extractRecipe(input);

      final text = userText(sentBody(http));
      expect(text, contains('$captionLabel\nPasta al pomodoro'));
      expect(text, contains('$transcriptLabel\noggi facciamo'));
      expect(text, contains('Instagram'));
      expect(text, contains('@cuoca_prova'));
      expect(text, contains('Whisper'));
      expect(text, isNot(contains(correctionLabel)));
    });

    test(
      'al secondo tentativo il messaggio riporta l\'errore precedente',
      () async {
        final http = FakeHttp({generateUrl: jsonResponse(generation())});

        await provider(http).extractRecipe(
          input,
          previousError: 'ingredients[0].unit: valore "grammi" non ammesso',
        );

        final text = userText(sentBody(http));
        expect(text, contains(correctionLabel));
        expect(text, contains('non era valida'));
        expect(text, contains('valore "grammi" non ammesso'));
        // La correzione sta in fondo, dopo la trascrizione.
        expect(
          text.indexOf(correctionLabel),
          greaterThan(text.indexOf(transcriptLabel)),
        );
      },
    );
  });

  group('risposta', () {
    test(
      'risposta valida: JSON della ricetta e versione del modello',
      () async {
        final http = FakeHttp({
          generateUrl: jsonResponse(fixture('risposta_valida.json')),
        });

        final result = await provider(http).extractRecipe(input);

        expect(result.model, 'gemini-3.5-flash-lite');
        expect(result.json[RecipeJson.isRecipe], isTrue);
        expect(result.json[RecipeJson.title], 'Pasta al pomodoro');
        expect(result.json[RecipeJson.ingredients], hasLength(3));
        expect(log.export(), contains('token prompt 1342'));
      },
    );

    test('senza modelVersion si usa l\'ID del modello scelto', () async {
      final http = FakeHttp({
        generateUrl: jsonResponse(generation(modelVersion: null)),
      });

      final result = await provider(http).extractRecipe(input);

      expect(result.model, GeminiModel.defaultModel.id);
    });

    test('le parti di ragionamento sono escluse e il testo è unito', () async {
      final http = FakeHttp({
        generateUrl: jsonResponse(
          generation(
            parts: [
              {'text': 'Ragiono sugli ingredienti…', 'thought': true},
              {'text': '{"isRecipe": '},
              {'text': 'false, "notRecipeReason": "È un vlog"}'},
            ],
          ),
        ),
      });

      final result = await provider(http).extractRecipe(input);

      expect(result.json, {'isRecipe': false, 'notRecipeReason': 'È un vlog'});
    });

    test('promptFeedback.blockReason → contenuto bloccato', () {
      final http = FakeHttp({
        generateUrl: jsonResponse(
          jsonEncode({
            'promptFeedback': {'blockReason': 'PROHIBITED_CONTENT'},
            'modelVersion': 'gemini-3.5-flash-lite',
          }),
        ),
      });

      expect(
        provider(http).extractRecipe(input),
        throwsA(isA<ContentBlockedFailure>()),
      );
    });

    for (final reason in ['SAFETY', 'RECITATION', 'PROHIBITED_CONTENT']) {
      test('finishReason $reason → contenuto bloccato', () {
        final http = FakeHttp({
          generateUrl: jsonResponse(
            generation(parts: const [], finishReason: reason),
          ),
        });

        expect(
          provider(http).extractRecipe(input),
          throwsA(isA<ContentBlockedFailure>()),
        );
      });
    }

    for (final reason in ['MAX_TOKENS', 'MALFORMED_RESPONSE', 'OTHER']) {
      test('finishReason $reason → risposta non valida', () {
        final http = FakeHttp({
          generateUrl: jsonResponse(
            generation(
              parts: const [
                {'text': '{"isRecipe": true, "title": "Pasta'},
              ],
              finishReason: reason,
            ),
          ),
        });

        expect(
          provider(http).extractRecipe(input),
          throwsA(isA<LlmResponseException>()),
        );
      });
    }

    test('nessun candidato e nessun blocco → risposta non valida', () {
      final http = FakeHttp({
        generateUrl: jsonResponse('{"candidates": [], "modelVersion": "x"}'),
      });

      expect(
        provider(http).extractRecipe(input),
        throwsA(isA<LlmResponseException>()),
      );
    });

    test('JSON rotto → risposta non valida', () {
      final http = FakeHttp({
        generateUrl: jsonResponse(
          generation(
            parts: const [
              {'text': '{"isRecipe": true,,}'},
            ],
          ),
        ),
      });

      expect(
        provider(http).extractRecipe(input),
        throwsA(isA<LlmResponseException>()),
      );
    });

    test('JSON che non è un oggetto → risposta non valida', () {
      final http = FakeHttp({
        generateUrl: jsonResponse(
          generation(
            parts: const [
              {'text': '[1, 2, 3]'},
            ],
          ),
        ),
      });

      expect(
        provider(http).extractRecipe(input),
        throwsA(isA<LlmResponseException>()),
      );
    });

    test('testo vuoto → risposta non valida', () {
      final http = FakeHttp({
        generateUrl: jsonResponse(generation(parts: const [])),
      });

      expect(
        provider(http).extractRecipe(input),
        throwsA(isA<LlmResponseException>()),
      );
    });
  });

  group('errori', () {
    test('chiave mancante: nessuna richiesta', () async {
      final http = FakeHttp({generateUrl: jsonResponse(generation())});

      await expectLater(
        provider(http, apiKey: null).extractRecipe(input),
        throwsA(isA<MissingApiKeyFailure>()),
      );
      expect(http.requests, isEmpty);
    });

    test('400 API_KEY_INVALID → chiave non valida', () {
      final http = FakeHttp({
        generateUrl: jsonResponse(
          fixture('errore_400_api_key_invalid.json'),
          400,
        ),
      });

      expect(
        provider(http).extractRecipe(input),
        throwsA(isA<InvalidApiKeyFailure>()),
      );
    });

    test('401 ACCESS_TOKEN_TYPE_UNSUPPORTED → chiave non valida', () {
      final http = FakeHttp({
        generateUrl: jsonResponse(
          fixture('errore_401_access_token_type_unsupported.json'),
          401,
        ),
      });

      expect(
        provider(http).extractRecipe(input),
        throwsA(isA<InvalidApiKeyFailure>()),
      );
    });

    test('403 → chiave non valida', () {
      final http = FakeHttp({
        generateUrl: jsonResponse(
          fixture('errore_403_permission_denied.json'),
          403,
        ),
      });

      expect(
        provider(http).extractRecipe(input),
        throwsA(isA<InvalidApiKeyFailure>()),
      );
    });

    test('altro 400 → errore imprevisto con il messaggio di Google', () async {
      final http = FakeHttp({
        generateUrl: jsonResponse(fixture('errore_400_schema.json'), 400),
      });

      final failure = await _failureOf(provider(http).extractRecipe(input));

      expect(failure, isA<UnexpectedFailure>());
      expect('${failure.cause}', contains('400'));
      expect('${failure.cause}', contains('INVALID_ARGUMENT'));
      expect('${failure.cause}', contains('propertyOrdering'));
      expect(waits, isEmpty);
    });

    test('404 → Gemini non disponibile, con il nome del modello', () async {
      final http = FakeHttp({
        generateUrl: jsonResponse(fixture('errore_404_modello.json'), 404),
      });

      final failure = await _failureOf(provider(http).extractRecipe(input));

      expect(failure, isA<LlmUnavailableFailure>());
      expect('${failure.cause}', contains('gemini-3.5-flash-lite'));
      expect(http.requests, hasLength(1));
    });

    test('429 al minuto, poi successo: attende il retryDelay', () async {
      final http = FakeHttp({
        generateUrl: sequence([
          jsonResponse(fixture('errore_429_al_minuto.json'), 429),
          jsonResponse(fixture('risposta_valida.json')),
        ]),
      });

      final result = await provider(http).extractRecipe(input);

      expect(result.json[RecipeJson.isRecipe], isTrue);
      expect(waits, [const Duration(seconds: 21)]);
      expect(http.requests, hasLength(2));
    });

    test(
      '429 al minuto ripetuto → quota esaurita dopo 2 nuovi tentativi',
      () async {
        final http = FakeHttp({
          generateUrl: jsonResponse(fixture('errore_429_al_minuto.json'), 429),
        });

        final failure = await _failureOf(provider(http).extractRecipe(input));

        expect(failure, isA<QuotaExceededFailure>());
        expect((failure as QuotaExceededFailure).daily, isFalse);
        expect(http.requests, hasLength(3));
        expect(waits, hasLength(2));
      },
    );

    test(
      '429 senza RetryInfo attende 10 s; retryDelay oltre 60 s è limitato',
      () async {
        final http = FakeHttp({
          generateUrl: sequence([
            jsonResponse(
              '{"error":{"code":429,"status":"RESOURCE_EXHAUSTED",'
              '"message":"Resource exhausted"}}',
              429,
            ),
            jsonResponse(
              '{"error":{"code":429,"status":"RESOURCE_EXHAUSTED","details":['
              '{"@type":"type.googleapis.com/google.rpc.RetryInfo",'
              '"retryDelay":"300s"}]}}',
              429,
            ),
            jsonResponse(generation()),
          ]),
        });

        await provider(http).extractRecipe(input);

        expect(waits, [
          const Duration(seconds: 10),
          const Duration(seconds: 60),
        ]);
      },
    );

    test('429 giornaliero → quota esaurita subito, senza attese', () async {
      final http = FakeHttp({
        generateUrl: jsonResponse(fixture('errore_429_giornaliero.json'), 429),
      });

      final failure = await _failureOf(provider(http).extractRecipe(input));

      expect(failure, isA<QuotaExceededFailure>());
      expect((failure as QuotaExceededFailure).daily, isTrue);
      expect(http.requests, hasLength(1));
      expect(waits, isEmpty);
    });

    test(
      '503, poi successo: un nuovo tentativo dopo una breve attesa',
      () async {
        final http = FakeHttp({
          generateUrl: sequence([
            jsonResponse(fixture('errore_503.json'), 503),
            jsonResponse(generation()),
          ]),
        });

        await provider(http).extractRecipe(input);

        expect(waits, [const Duration(seconds: 2)]);
        expect(http.requests, hasLength(2));
      },
    );

    test(
      '503 ripetuto → Gemini non disponibile dopo 2 nuovi tentativi',
      () async {
        final http = FakeHttp({
          generateUrl: jsonResponse(fixture('errore_503.json'), 503),
        });

        final failure = await _failureOf(provider(http).extractRecipe(input));

        expect(failure, isA<LlmUnavailableFailure>());
        expect(waits, [const Duration(seconds: 2), const Duration(seconds: 5)]);
        expect(http.requests, hasLength(3));
      },
    );

    test('rete assente → errore di rete, senza nuovi tentativi', () async {
      final http = FakeHttp({});

      final failure = await _failureOf(provider(http).extractRecipe(input));

      expect(failure, isA<NetworkFailure>());
      expect(failure.cause, isA<String>());
      expect(http.requests, hasLength(1));
      expect(waits, isEmpty);
    });
  });

  group('checkKey', () {
    Future<void> check(FakeHttp http, [String key = authKey]) =>
        provider(http, apiKey: null).checkKey(key, GeminiModel.defaultModel);

    test('200 → chiave valida, GET con la chiave nell\'intestazione', () async {
      final http = FakeHttp({modelUrl: jsonResponse(fixture('modello.json'))});

      await check(http);

      final request = http.requests.single;
      expect(request.method, 'GET');
      expect(request.uri.toString(), modelUrl);
      expect(request.headers['x-goog-api-key'], authKey);
    });

    test('429 → chiave valida (è finita la quota)', () async {
      final http = FakeHttp({
        modelUrl: jsonResponse(fixture('errore_429_giornaliero.json'), 429),
      });

      await check(http);
      expect(http.requests, hasLength(1));
    });

    for (final (status, name) in [
      (400, 'errore_400_api_key_invalid.json'),
      (401, 'errore_401_access_token_type_unsupported.json'),
      (403, 'errore_403_permission_denied.json'),
    ]) {
      test('$status → chiave non valida', () {
        final http = FakeHttp({modelUrl: jsonResponse(fixture(name), status)});

        expect(check(http), throwsA(isA<InvalidApiKeyFailure>()));
      });
    }

    test('404 → modello non disponibile per la chiave', () {
      final http = FakeHttp({
        modelUrl: jsonResponse(fixture('errore_404_modello.json'), 404),
      });

      expect(check(http), throwsA(isA<LlmUnavailableFailure>()));
    });

    test('503 → Gemini non disponibile, senza nuovi tentativi', () async {
      final http = FakeHttp({
        modelUrl: jsonResponse(fixture('errore_503.json'), 503),
      });

      await expectLater(check(http), throwsA(isA<LlmUnavailableFailure>()));
      expect(http.requests, hasLength(1));
      expect(waits, isEmpty);
    });

    test('rete assente → errore di rete', () {
      expect(check(FakeHttp({})), throwsA(isA<NetworkFailure>()));
    });
  });

  group('sicurezza della chiave', () {
    test('le chiavi finte hanno il formato di quelle vere', () {
      expect(classicKey, hasLength(39));
      expect(AppLog.redact(classicKey), isNot(contains(classicKey)));
      expect(AppLog.redact(authKey), isNot(contains(authKey)));
    });

    for (final key in [authKey, classicKey]) {
      test('la chiave ${key.substring(0, 3)}… non finisce mai nelle cause '
          'né nel registro', () async {
        // Google a volte ripete la chiave nel messaggio d'errore.
        String echo(int code, String status) => jsonEncode({
          'error': {
            'code': code,
            'status': status,
            'message': 'Chiave $key rifiutata',
          },
        });
        final scenarios = <String, ResponseBody Function()>{
          '400': jsonResponse(echo(400, 'INVALID_ARGUMENT'), 400),
          '401': jsonResponse(echo(401, 'UNAUTHENTICATED'), 401),
          '404': jsonResponse(echo(404, 'NOT_FOUND'), 404),
          '429': jsonResponse(echo(429, 'RESOURCE_EXHAUSTED'), 429),
          '503': jsonResponse(echo(503, 'UNAVAILABLE'), 503),
        };

        final failures = <Failure>[];
        for (final MapEntry(key: status, value: response)
            in scenarios.entries) {
          final http = FakeHttp({generateUrl: response, modelUrl: response});
          failures.add(
            await _failureOf(provider(http, apiKey: key).extractRecipe(input)),
          );
          // Con 429 la verifica riesce: la chiave è stata accettata.
          if (status != '429') {
            failures.add(
              await _failureOf(
                provider(http).checkKey(key, GeminiModel.defaultModel),
              ),
            );
          }
        }
        // Rete assente.
        failures.add(
          await _failureOf(
            provider(FakeHttp({}), apiKey: key).extractRecipe(input),
          ),
        );

        for (final failure in failures) {
          expect(failure.cause, anyOf(isNull, isA<String>()));
          expect('$failure', isNot(contains(key)));
          expect('${failure.cause}', isNot(contains(key)));
          log.error('Gemini', failure, failure.stackTrace);
        }
        expect(log.export(), isNot(contains(key)));
      });
    }
  });

  group('parseRetryDelay', () {
    test('secondi interi e decimali', () {
      expect(parseRetryDelay('34s'), const Duration(seconds: 34));
      expect(parseRetryDelay('1.5s'), const Duration(milliseconds: 1500));
    });

    test('formato sconosciuto → null', () {
      expect(parseRetryDelay(null), isNull);
      expect(parseRetryDelay('34'), isNull);
      expect(parseRetryDelay(34), isNull);
    });
  });
}

/// Errore lanciato da [future], che deve fallire.
Future<Failure> _failureOf(Future<Object?> future) async {
  try {
    await future;
  } on Failure catch (e) {
    return e;
  }
  fail('Doveva fallire');
}
