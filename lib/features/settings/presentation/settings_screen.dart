import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/providers.dart';
import '../../../app/router.dart';
import '../../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navSettings)),
      body: ListView(
        children: [
          ListTile(
            title: Text(
              l10n.settingsDiagnostics,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.copy_all),
            title: Text(l10n.settingsCopyLog),
            subtitle: Text(l10n.settingsCopyLogSubtitle),
            onTap: () => _copyLog(context, ref),
          ),
          ListTile(
            leading: const Icon(Icons.science_outlined),
            title: Text(l10n.settingsSpikeTools),
            subtitle: Text(l10n.settingsSpikeToolsSubtitle),
            onTap: () => context.push(Routes.spikeTools),
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
