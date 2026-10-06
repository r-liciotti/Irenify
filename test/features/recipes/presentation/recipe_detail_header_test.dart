import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:irenefy/app/theme.dart';
import 'package:irenefy/features/recipes/domain/recipe.dart';
import 'package:irenefy/features/recipes/domain/recipe_enums.dart';
import 'package:irenefy/features/recipes/presentation/detail/recipe_detail_header.dart';
import 'package:irenefy/l10n/app_localizations.dart';

import '../data/recipe_repository_test.dart' show sampleRecipe;

const _button = ValueKey('recipe-detail-open-post');

/// Solo l'intestazione, con il tema dell'app; [opened] raccoglie i link
/// aperti.
Future<void> pumpHeader(
  WidgetTester tester,
  Recipe recipe, {
  List<String>? opened,
}) => tester.pumpWidget(
  MaterialApp(
    theme: lightTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: RecipeDetailHeader(
        recipe: recipe,
        onTagSelected: (_) {},
        onOpenPost: (url) => opened?.add(url),
      ),
    ),
  ),
);

Recipe withSource(RecipeSourceInfo source) =>
    sampleRecipe().copyWith(source: source);

void main() {
  group('pulsante del post originale (D-60)', () {
    testWidgets('Instagram: logo, tooltip e tocco che apre il link', (
      tester,
    ) async {
      final opened = <String>[];
      await pumpHeader(tester, sampleRecipe(), opened: opened);
      expect(find.byKey(_button), findsOneWidget);
      expect(
        tester.widget<FaIcon>(find.byType(FaIcon)).icon,
        FontAwesomeIcons.instagram.data,
      );
      expect(find.byTooltip('Apri il post su Instagram'), findsOneWidget);
      // Solo l'icona: nessun testo.
      expect(find.text('Apri il post su Instagram'), findsNothing);
      expect(
        tester.getSize(find.byKey(_button)).height,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSize(find.byKey(_button)).width,
        greaterThanOrEqualTo(48),
      );
      expect(
        tester.getSemantics(find.byKey(_button)),
        matchesSemantics(
          tooltip: 'Apri il post su Instagram',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          isFocusable: true,
          hasTapAction: true,
          hasFocusAction: true,
        ),
      );

      await tester.tap(find.byKey(_button));
      expect(opened, ['https://www.instagram.com/p/DDle01fMxoA/']);
    });

    testWidgets('TikTok: logo e tooltip di TikTok', (tester) async {
      await pumpHeader(
        tester,
        withSource(
          const RecipeSourceInfo(
            platform: SourcePlatform.tiktok,
            url: 'https://www.tiktok.com/@cuoca/video/1',
          ),
        ),
      );
      expect(
        tester.widget<FaIcon>(find.byType(FaIcon)).icon,
        FontAwesomeIcons.tiktok.data,
      );
      expect(find.byTooltip('Apri il post su TikTok'), findsOneWidget);
    });

    testWidgets('altra fonte con link: freccia e tooltip generico', (
      tester,
    ) async {
      await pumpHeader(
        tester,
        withSource(
          const RecipeSourceInfo(
            platform: SourcePlatform.manual,
            url: 'https://example.com/ricetta',
          ),
        ),
      );
      expect(find.byType(FaIcon), findsNothing);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
      expect(find.byTooltip('Apri il post originale'), findsOneWidget);
    });

    testWidgets(
      'video condiviso dalla galleria (senza link): niente pulsante',
      (tester) async {
        await pumpHeader(
          tester,
          withSource(const RecipeSourceInfo(platform: SourcePlatform.file)),
        );
        expect(find.byKey(_button), findsNothing);
        expect(find.byType(FaIcon), findsNothing);
        // I tempi restano.
        expect(find.byIcon(Icons.timer_outlined), findsOneWidget);
      },
    );

    testWidgets('senza tempi né difficoltà il pulsante resta', (tester) async {
      await pumpHeader(
        tester,
        sampleRecipe().copyWith(
          prepMinutes: null,
          cookMinutes: null,
          restMinutes: null,
          difficulty: null,
        ),
      );
      expect(find.byKey(_button), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
