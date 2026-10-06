import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/failure_presentation.dart';
import '../../../app/providers.dart';
import '../../../core/errors/failure.dart';
import '../../../l10n/app_localizations.dart';
import '../data/data_eraser.dart';
import 'settings_providers.dart';

/// Voce "Elimina dati" (D-50): disattivata finché c'è un'importazione non
/// conclusa; altrimenti chiede conferma, con due caselle per chiave e
/// modello (spente di default).
class EraseDataTile extends ConsumerStatefulWidget {
  const EraseDataTile({super.key});

  @override
  ConsumerState<EraseDataTile> createState() => _EraseDataTileState();
}

class _EraseDataTileState extends ConsumerState<EraseDataTile> {
  bool _erasing = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final unfinished = ref.watch(unfinishedImportsCountProvider).value;
    // Finché il conteggio non è noto la voce resta disattivata.
    final busy = unfinished != 0;
    final enabled = !busy && !_erasing;
    return ListTile(
      leading: const Icon(Icons.delete_forever_outlined),
      title: Text(l10n.settingsEraseData),
      subtitle: Text(
        unfinished != null && unfinished > 0
            ? l10n.settingsEraseBusy
            : l10n.settingsEraseDataSubtitle,
      ),
      enabled: enabled,
      onTap: enabled ? _confirmAndErase : null,
    );
  }

  Future<void> _confirmAndErase() async {
    final choice = await showDialog<_EraseChoice>(
      context: context,
      builder: (_) => const _EraseDialog(),
    );
    if (choice == null || !mounted) return;
    setState(() => _erasing = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    String message;
    try {
      await ref
          .read(dataEraserProvider)
          .eraseAll(apiKey: choice.apiKey, speechModel: choice.speechModel);
      message = l10n.settingsErased;
    } on Object catch (e, st) {
      ref.read(appLogProvider).error('Elimina dati non riuscito', e, st);
      message = Failure.from(e, st).message(l10n);
    } finally {
      if (mounted) setState(() => _erasing = false);
    }
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }
}

typedef _EraseChoice = ({bool apiKey, bool speechModel});

class _EraseDialog extends StatefulWidget {
  const _EraseDialog();

  @override
  State<_EraseDialog> createState() => _EraseDialogState();
}

class _EraseDialogState extends State<_EraseDialog> {
  bool _apiKey = false;
  bool _speechModel = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l10n.settingsEraseTitle),
      scrollable: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.settingsEraseBody),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _apiKey,
            title: Text(l10n.settingsEraseApiKey),
            onChanged: (v) => setState(() => _apiKey = v ?? false),
          ),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            value: _speechModel,
            title: Text(l10n.settingsEraseSpeechModel),
            onChanged: (v) => setState(() => _speechModel = v ?? false),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          onPressed: () => Navigator.of(
            context,
          ).pop<_EraseChoice>((apiKey: _apiKey, speechModel: _speechModel)),
          child: Text(l10n.settingsEraseConfirm),
        ),
      ],
    );
  }
}
