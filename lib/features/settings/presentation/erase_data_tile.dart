import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/failure_presentation.dart';
import '../../../app/providers.dart';
import '../../../core/errors/failure.dart';
import '../../../l10n/app_localizations.dart';
import '../data/data_eraser.dart';
import 'settings_providers.dart';

/// Voce "Elimina dati" (D-50): disattivata finché c'è un'importazione non
/// conclusa; altrimenti chiede conferma. Chiave Gemini e modello di
/// trascrizione non si eliminano mai da qui (D-64).
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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const _EraseDialog(),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _erasing = true);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    String message;
    try {
      await ref.read(dataEraserProvider).eraseAll();
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

class _EraseDialog extends StatelessWidget {
  const _EraseDialog();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return AlertDialog(
      title: Text(l10n.settingsEraseTitle),
      content: Text(l10n.settingsEraseBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.actionCancel),
        ),
        TextButton(
          style: TextButton.styleFrom(foregroundColor: scheme.error),
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.settingsEraseConfirm),
        ),
      ],
    );
  }
}
