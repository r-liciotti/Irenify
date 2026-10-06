import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../app/theme_mode.dart';
import '../../../app/widgets/mirtilla_logo.dart';
import '../../../l10n/app_localizations.dart';
import '../../import_pipeline/presentation/imports_screen.dart';
import 'erase_data_tile.dart';
import 'gemini_settings_tile.dart';
import 'settings_providers.dart';
import 'speech_model_tile.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        children: [
          const _ImportsTile(),
          const Divider(height: 1),
          _SectionHeader(l10n.geminiSection),
          const GeminiKeyTile(),
          const GeminiModelTile(),
          _SectionHeader(l10n.settingsTranscription),
          const SpeechModelTile(),
          _SectionHeader(l10n.settingsAppearance),
          const _ThemeModeChoice(),
          _SectionHeader(l10n.settingsData),
          const EraseDataTile(),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: Text(l10n.settingsGuide),
            subtitle: Text(l10n.settingsGuideSubtitle),
            onTap: () => context.push(Routes.welcome),
          ),
          _SectionHeader(l10n.settingsDiagnostics),
          ListTile(
            leading: const Icon(Icons.copy_all),
            title: Text(l10n.settingsCopyLog),
            subtitle: Text(l10n.settingsCopyLogSubtitle),
            onTap: () => _copyLog(context, ref),
          ),
          _SectionHeader(l10n.settingsAbout),
          const _AboutTiles(),
        ],
      ),
    );
  }

  Future<void> _copyLog(BuildContext context, WidgetRef ref) async {
    final log = ref.read(appLogProvider);
    final count = log.lines.length;
    await Clipboard.setData(ClipboardData(text: log.export()));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context).settingsLogCopied(count)),
      ),
    );
  }
}

/// Voce delle importazioni in cima (D-52), con lo stesso numero del badge
/// sulla scheda. `go` e non `push`: l'elenco è una sotto-rotta del ramo, la
/// freccia indietro torna qui e la barra resta visibile.
class _ImportsTile extends ConsumerWidget {
  const _ImportsTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pending = ref.watch(importsNeedingAttentionCountProvider).value ?? 0;
    return ListTile(
      leading: const Icon(Icons.downloading),
      title: Text(l10n.settingsImports),
      subtitle: Text(l10n.settingsImportsSubtitle(pending)),
      trailing: pending > 0
          ? Badge.count(count: pending)
          : const Icon(Icons.chevron_right),
      onTap: () => context.go(Routes.imports),
    );
  }
}

/// Tema: come il telefono, chiaro o scuro (D-45). Tre righe e non un
/// `SegmentedButton`: "Come il telefono" non ci sta a 360 dp con il testo
/// ingrandito.
class _ThemeModeChoice extends ConsumerWidget {
  const _ThemeModeChoice();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final mode = ref.watch(themeModeProvider);
    return RadioGroup<ThemeMode>(
      groupValue: mode,
      onChanged: (value) {
        if (value != null) ref.read(themeModeProvider.notifier).set(value);
      },
      child: Column(
        children: [
          for (final (value, label, icon) in [
            (
              ThemeMode.system,
              l10n.settingsThemeSystem,
              Icons.brightness_auto_outlined,
            ),
            (
              ThemeMode.light,
              l10n.settingsThemeLight,
              Icons.light_mode_outlined,
            ),
            (ThemeMode.dark, l10n.settingsThemeDark, Icons.dark_mode_outlined),
          ])
            RadioListTile<ThemeMode>(
              value: value,
              title: Text(label),
              secondary: Icon(icon),
              controlAffinity: ListTileControlAffinity.trailing,
            ),
        ],
      ),
    );
  }
}

/// Versione e licenze (D-50).
class _AboutTiles extends ConsumerWidget {
  const _AboutTiles();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final version = ref.watch(appVersionProvider).value;
    return Column(
      children: [
        ListTile(
          leading: const MirtillaLogo(size: 40),
          title: Text(l10n.appTitle),
          subtitle: version == null
              ? null
              : Text(l10n.settingsVersion(version)),
        ),
        ListTile(
          leading: const Icon(Icons.gavel_outlined),
          title: Text(l10n.settingsLicenses),
          subtitle: Text(l10n.settingsLicensesSubtitle),
          onTap: () => showLicensePage(
            context: context,
            applicationName: l10n.appTitle,
            applicationVersion: version,
            applicationIcon: const Padding(
              padding: EdgeInsets.all(8),
              child: MirtillaLogo(size: 64),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => ListTile(
    title: Text(
      title,
      style: TextStyle(color: Theme.of(context).colorScheme.primary),
    ),
  );
}
