import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/errors/failure.dart';
import '../../../../core/logging/app_log.dart';
import '../../../settings/data/llm_settings_store.dart';
import '../../domain/llm_provider.dart';
import '../../domain/recipe_schema.dart';
import 'gemini_prompt.dart';

/// Indirizzo dell'API REST di Gemini.
const geminiBaseUrl = 'https://generativelanguage.googleapis.com/v1beta/';

/// Client dio solo per Gemini: senza lo user agent di Safari del client
/// generale (serve a TikTok, non qui) e con un'attesa lunga per la risposta,
/// perché la generazione può richiedere decine di secondi. Gli stati HTTP li
/// interpreta [GeminiProvider]: nessuno fa lanciare un'eccezione.
Dio createGeminiHttpClient() => Dio(
  BaseOptions(
    baseUrl: geminiBaseUrl,
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 120),
    responseType: ResponseType.plain,
    validateStatus: (_) => true,
  ),
);

final geminiHttpClientProvider = Provider<Dio>((ref) {
  final dio = createGeminiHttpClient();
  ref.onDispose(dio.close);
  return dio;
});

/// LLM usato per estrarre le ricette (D-03: dietro un'interfaccia).
final llmProviderProvider = Provider<LlmProvider>(
  (ref) => GeminiProvider(
    settings: ref.watch(llmSettingsProvider),
    dio: ref.watch(geminiHttpClientProvider),
    log: ref.watch(appLogProvider),
  ),
);

/// Estrazione della ricetta con l'API REST di Gemini (D-35, D-36, D-38).
///
/// La chiave viaggia solo nell'intestazione `x-goog-api-key` e non finisce
/// mai nelle cause dei [Failure] né nel registro: le cause sono stringhe
/// costruite dallo stato HTTP e dal messaggio di Google, passate comunque da
/// [AppLog.redact].
class GeminiProvider implements LlmProvider {
  GeminiProvider({
    required LlmSettings settings,
    required Dio dio,
    AppLog? log,
    Future<void> Function(Duration delay)? wait,
  }) : _settings = settings,
       _dio = dio,
       _log = log,
       _wait = wait ?? Future<void>.delayed;

  final LlmSettings _settings;
  final Dio _dio;
  final AppLog? _log;

  /// Attesa tra un tentativo e l'altro; nei test non aspetta davvero.
  final Future<void> Function(Duration delay) _wait;

  /// Nuovi tentativi dopo un 429 al minuto o un errore temporaneo del server.
  static const maxRetries = 2;

  /// Attesa dopo un 429 senza `RetryInfo`, e tetto a quella indicata.
  static const defaultQuotaDelay = Duration(seconds: 10);
  static const maxQuotaDelay = Duration(seconds: 60);

  /// Attese prima del 1° e del 2° nuovo tentativo dopo un errore del server.
  static const serverDelays = [Duration(seconds: 2), Duration(seconds: 5)];

  static const maxOutputTokens = 8192;

  static const _temporaryStatuses = {408, 500, 502, 503, 504};

  // Motivi di fine generazione dovuti ai filtri di Google: ripetere non
  // cambierebbe nulla. Gli altri (MAX_TOKENS, MALFORMED_RESPONSE, OTHER,
  // LANGUAGE…) sono una risposta non valida, da ritentare nella tappa.
  static const _blockedFinishReasons = {
    'SAFETY',
    'RECITATION',
    'BLOCKLIST',
    'PROHIBITED_CONTENT',
    'SPII',
    'IMAGE_SAFETY',
    'IMAGE_PROHIBITED_CONTENT',
    'IMAGE_RECITATION',
  };

  @override
  Future<LlmExtraction> extractRecipe(
    ExtractionInput input, {
    String? previousError,
  }) async {
    final apiKey = await _settings.readApiKey();
    if (apiKey == null || apiKey.trim().isEmpty) {
      throw const MissingApiKeyFailure();
    }
    final model = await _settings.readModel();
    final body = requestBody(input, model, previousError: previousError);

    var quotaRetries = 0;
    var serverRetries = 0;
    while (true) {
      _log?.info(
        'Gemini: estrazione con ${model.id}'
        '${previousError == null ? '' : ' (correzione)'}',
      );
      final response = await _send(
        () => _dio.post<String>(
          'models/${model.id}:generateContent',
          data: body,
          options: _options(apiKey),
        ),
      );
      final status = response.statusCode ?? 0;
      if (status == 200) return _parseGeneration(response.data, model);

      final error = _GoogleError.parse(status, response.data);
      if (status == 429) {
        if (error.isDailyQuota) {
          throw QuotaExceededFailure(daily: true, cause: error.describe());
        }
        if (quotaRetries >= maxRetries) {
          throw QuotaExceededFailure(cause: error.describe());
        }
        final delay = error.retryDelay ?? defaultQuotaDelay;
        final capped = delay > maxQuotaDelay ? maxQuotaDelay : delay;
        _log?.warning(
          'Gemini: quota al minuto esaurita, nuovo tentativo tra '
          '${capped.inSeconds} s',
        );
        quotaRetries++;
        await _wait(capped);
        continue;
      }
      if (_temporaryStatuses.contains(status)) {
        if (serverRetries >= maxRetries) {
          throw LlmUnavailableFailure(cause: error.describe());
        }
        final delay = serverDelays[serverRetries];
        _log?.warning(
          'Gemini: ${error.describe()}; nuovo tentativo tra '
          '${delay.inSeconds} s',
        );
        serverRetries++;
        await _wait(delay);
        continue;
      }
      throw _failureFor(error, model);
    }
  }

  @override
  Future<void> checkKey(String apiKey, GeminiModel model) async {
    final response = await _send(
      () => _dio.get<String>('models/${model.id}', options: _options(apiKey)),
    );
    final status = response.statusCode ?? 0;
    // 429: la chiave è stata accettata, è finita la quota.
    if (status == 200 || status == 429) return;
    final error = _GoogleError.parse(status, response.data);
    if (status >= 500) throw LlmUnavailableFailure(cause: error.describe());
    throw _failureFor(error, model);
  }

  /// Corpo di `generateContent` (D-36: niente `temperature`, il valore
  /// predefinito è quello consigliato per i modelli Gemini 3).
  static Map<String, Object?> requestBody(
    ExtractionInput input,
    GeminiModel model, {
    String? previousError,
  }) => {
    'systemInstruction': {
      'parts': [
        {'text': geminiSystemPrompt},
      ],
    },
    'contents': [
      {
        'role': 'user',
        'parts': [
          {'text': buildUserPrompt(input, previousError: previousError)},
        ],
      },
    ],
    'generationConfig': {
      'responseMimeType': 'application/json',
      'responseJsonSchema': recipeResponseSchema,
      'thinkingConfig': {'thinkingLevel': model.thinkingLevel},
      'maxOutputTokens': maxOutputTokens,
    },
  };

  Options _options(String apiKey) =>
      Options(headers: {'x-goog-api-key': apiKey.trim()});

  /// Esegue la richiesta; un errore di dio diventa un [Failure] con una
  /// causa testuale (l'eccezione di dio contiene le intestazioni, quindi la
  /// chiave, e non va conservata).
  Future<Response<String>> _send(
    Future<Response<String>> Function() request,
  ) async {
    try {
      return await request();
    } on DioException catch (e, st) {
      final cause = AppLog.redact(
        'Gemini: ${e.type.name}: ${e.message ?? e.error ?? ''}',
      );
      throw switch (Failure.from(e)) {
        NetworkFailure() => NetworkFailure(cause: cause, stackTrace: st),
        _ => UnexpectedFailure(cause: cause, stackTrace: st),
      };
    }
  }

  /// Errori HTTP definitivi (né quota né temporanei).
  Failure _failureFor(_GoogleError error, GeminiModel model) =>
      switch (error.status) {
        400 when error.reasons.contains('API_KEY_INVALID') =>
          InvalidApiKeyFailure(cause: error.describe()),
        401 || 403 => InvalidApiKeyFailure(cause: error.describe()),
        404 => LlmUnavailableFailure(
          cause: error.describe(
            'modello ${model.id} non disponibile per questa chiave',
          ),
        ),
        _ => UnexpectedFailure(cause: error.describe()),
      };

  LlmExtraction _parseGeneration(String? data, GeminiModel model) {
    final body = _decodeObject(data);
    if (body == null) {
      throw const LlmResponseException('Risposta di Gemini non in JSON');
    }

    final feedback = body['promptFeedback'];
    if (feedback is Map<String, Object?> && feedback['blockReason'] != null) {
      throw ContentBlockedFailure(
        cause: 'Gemini: richiesta bloccata (${feedback['blockReason']})',
      );
    }

    final candidates = body['candidates'];
    if (candidates is! List<Object?> ||
        candidates.isEmpty ||
        candidates.first is! Map<String, Object?>) {
      throw const LlmResponseException('Gemini non ha restituito risposte');
    }
    final candidate = candidates.first! as Map<String, Object?>;
    final finishReason = candidate['finishReason'];
    if (_blockedFinishReasons.contains(finishReason)) {
      throw ContentBlockedFailure(
        cause: 'Gemini: risposta bloccata ($finishReason)',
      );
    }
    // Senza motivo si prova comunque a leggere il testo: il JSON decide.
    if (finishReason != null && finishReason != 'STOP') {
      throw LlmResponseException(
        'Risposta interrotta da Gemini ($finishReason)',
      );
    }

    final text = _answerText(candidate);
    if (text.isEmpty) {
      throw const LlmResponseException('Risposta di Gemini vuota');
    }
    final Object? json;
    try {
      json = jsonDecode(_stripCodeFence(text));
    } on FormatException catch (e) {
      throw LlmResponseException('JSON non valido: ${e.message}');
    }
    if (json is! Map<String, Object?>) {
      throw const LlmResponseException('La risposta non è un oggetto JSON');
    }

    final modelVersion = body['modelVersion'];
    _logUsage(body['usageMetadata']);
    return LlmExtraction(
      json: json,
      model: modelVersion is String && modelVersion.isNotEmpty
          ? modelVersion
          : model.id,
    );
  }

  /// Testo della risposta senza le parti di ragionamento (`thought: true`).
  static String _answerText(Map<String, Object?> candidate) {
    final content = candidate['content'];
    final parts = content is Map<String, Object?> ? content['parts'] : null;
    if (parts is! List<Object?>) return '';
    return [
      for (final part in parts)
        if (part is Map<String, Object?> &&
            part['thought'] != true &&
            part['text'] is String)
          part['text']! as String,
    ].join().trim();
  }

  /// Con `responseMimeType` JSON non dovrebbe succedere, ma un blocco
  /// ```json … ``` attorno all'oggetto non rende la risposta inutilizzabile.
  static String _stripCodeFence(String text) {
    final match = RegExp(r'^```(?:json)?\s*([\s\S]*?)\s*```$').firstMatch(text);
    return match == null ? text : match.group(1)!;
  }

  void _logUsage(Object? usage) {
    if (_log == null || usage is! Map<String, Object?>) return;
    _log.info(
      'Gemini: token prompt ${usage['promptTokenCount'] ?? '?'}, '
      'risposta ${usage['candidatesTokenCount'] ?? '?'}, '
      'ragionamento ${usage['thoughtsTokenCount'] ?? 0}',
    );
  }
}

/// Decodifica [data] se è un oggetto JSON; altrimenti `null`.
Map<String, Object?>? _decodeObject(String? data) {
  if (data == null || data.isEmpty) return null;
  try {
    final decoded = jsonDecode(data);
    return decoded is Map<String, Object?> ? decoded : null;
  } on FormatException {
    return null;
  }
}

/// Corpo d'errore di Google: `{error: {code, message, status, details[]}}`.
class _GoogleError {
  const _GoogleError({
    required this.status,
    this.googleStatus,
    this.message,
    this.reasons = const {},
    this.quotaIds = const [],
    this.retryDelay,
  });

  factory _GoogleError.parse(int status, String? data) {
    final error = _decodeObject(data)?['error'];
    if (error is! Map<String, Object?>) return _GoogleError(status: status);

    final reasons = <String>{};
    final quotaIds = <String>[];
    Duration? retryDelay;
    final details = error['details'];
    if (details is List<Object?>) {
      for (final detail in details.whereType<Map<String, Object?>>()) {
        final type = detail['@type'];
        if (type is! String) continue;
        if (type.endsWith('google.rpc.ErrorInfo') &&
            detail['reason'] is String) {
          reasons.add(detail['reason']! as String);
        } else if (type.endsWith('google.rpc.QuotaFailure')) {
          final violations = detail['violations'];
          if (violations is List<Object?>) {
            for (final v in violations.whereType<Map<String, Object?>>()) {
              if (v['quotaId'] is String) quotaIds.add(v['quotaId']! as String);
            }
          }
        } else if (type.endsWith('google.rpc.RetryInfo')) {
          retryDelay = parseRetryDelay(detail['retryDelay']);
        }
      }
    }
    final googleStatus = error['status'];
    final message = error['message'];
    return _GoogleError(
      status: status,
      googleStatus: googleStatus is String ? googleStatus : null,
      message: message is String ? message : null,
      reasons: reasons,
      quotaIds: quotaIds,
      retryDelay: retryDelay,
    );
  }

  final int status;
  final String? googleStatus;
  final String? message;
  final Set<String> reasons;
  final List<String> quotaIds;
  final Duration? retryDelay;

  /// Limite giornaliero (es. `GenerateRequestsPerDayPerProjectPerModel-FreeTier`):
  /// aspettare qualche secondo non serve.
  bool get isDailyQuota => quotaIds.any((id) => id.contains('PerDay'));

  /// Causa per il registro e il database: stato HTTP, stato e messaggio di
  /// Google, motivi; mai le intestazioni della richiesta.
  String describe([String? context]) => AppLog.redact(
    [
      'Gemini HTTP $status',
      ?googleStatus,
      ?context,
      ?message,
      if (reasons.isNotEmpty) reasons.join(', '),
      if (quotaIds.isNotEmpty) quotaIds.join(', '),
    ].join(' · '),
  );
}

/// `"34s"`, `"1.5s"` → [Duration]; formato diverso → `null`.
Duration? parseRetryDelay(Object? value) {
  if (value is! String) return null;
  final match = RegExp(r'^(\d+(?:\.\d+)?)s$').firstMatch(value.trim());
  if (match == null) return null;
  final seconds = double.parse(match.group(1)!);
  return Duration(milliseconds: (seconds * 1000).round());
}
