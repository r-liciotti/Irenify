import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../l10n/app_localizations.dart';
import 'gemini_settings_tile.dart';
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
          _SectionHeader(l10n.geminiSection),
          const GeminiKeyTile(),
          const GeminiModelTile(),
          _SectionHeader(l10n.settingsTranscription),
          const SpeechModelTile(),
          _SectionHeader(l10n.settingsDiagnostics),
          ListTile(
            leading: const Icon(Icons.copy_all),
            title: Text(l10n.settingsCopyLog),
            subtitle: Text(l10n.settingsCopyLogSubtitle),
            onTap: () => _copyLog(context, ref),
          ),
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
