import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../app/theme.dart';
import '../../../app/widgets/share_steps.dart';
import '../../../l10n/app_localizations.dart';
import '../../settings/presentation/gemini_settings_tile.dart';
import '../../settings/presentation/speech_model_tile.dart';
import 'onboarding_controller.dart';

/// Primo avvio (D-50): come condividere, chiave Gemini, modello di
/// trascrizione. Tre passi saltabili; si rivede dalle Impostazioni.
class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  static const stepCount = 3;

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final _pages = PageController();
  var _page = 0;

  bool get _isLast => _page == WelcomeScreen.stepCount - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _goTo(int page) => unawaited(
    _pages.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    ),
  );

  /// "Inizia" o "Salta": il benvenuto non si mostra più all'avvio. Aperto
  /// dalle Impostazioni torna lì, al primo avvio va alle Ricette.
  void _finish() {
    unawaited(ref.read(onboardingProvider.notifier).markDone());
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.recipes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    // Il tasto Indietro di sistema torna al passo precedente; dal primo passo
    // chiude come sempre (l'app al primo avvio, il benvenuto se aperto dalle
    // Impostazioni).
    return PopScope(
      canPop: _page == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _page > 0) _goTo(_page - 1);
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 8, 0),
                child: Row(
                  children: [
                    _StepDots(current: _page, total: WelcomeScreen.stepCount),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.welcomeStep(_page + 1, WelcomeScreen.stepCount),
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _finish,
                      child: Text(l10n.welcomeSkip),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pages,
                  onPageChanged: (page) => setState(() => _page = page),
                  children: const [_SharePage(), _KeyPage(), _ModelPage()],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Row(
                  children: [
                    if (_page > 0)
                      TextButton(
                        onPressed: () => _goTo(_page - 1),
                        child: Text(l10n.welcomeBack),
                      ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _isLast ? _finish : () => _goTo(_page + 1),
                      child: Text(
                        _isLast ? l10n.welcomeDone : l10n.welcomeNext,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Pallini del passo: quello attuale è più lungo e colorato.
class _StepDots extends StatelessWidget {
  const _StepDots({required this.current, required this.total});

  final int current;
  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsetsDirectional.only(end: 6),
            width: i == current ? 20 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == current ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

/// Contenuto di un passo: scorre se il testo è grande.
class _StepPage extends StatelessWidget {
  const _StepPage({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
    children: children,
  );
}

class _SharePage extends StatelessWidget {
  const _SharePage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return _StepPage(
      children: [
        Text(l10n.welcomeTitle, style: theme.textTheme.displaySmall),
        const SizedBox(height: 12),
        Text(
          l10n.welcomeIntro,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 32),
        Text(
          l10n.welcomeShareTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            color: IrenefyColors.of(context).accentDecoration,
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.welcomeShareBody, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 24),
        const ShareSteps(),
      ],
    );
  }
}

/// Passo con titolo, spiegazione e la riga delle Impostazioni da usare.
class _SettingPage extends StatelessWidget {
  const _SettingPage({
    required this.title,
    required this.body,
    required this.tile,
  });

  final String title;
  final String body;
  final Widget tile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _StepPage(
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        const SizedBox(height: 12),
        Text(body, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 24),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: tile,
          ),
        ),
      ],
    );
  }
}

class _KeyPage extends StatelessWidget {
  const _KeyPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SettingPage(
      title: l10n.welcomeKeyTitle,
      body: l10n.welcomeKeyBody,
      tile: const GeminiKeyTile(),
    );
  }
}

class _ModelPage extends StatelessWidget {
  const _ModelPage();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return _SettingPage(
      title: l10n.welcomeModelTitle,
      body: l10n.welcomeModelBody,
      tile: const SpeechModelTile(),
    );
  }
}
