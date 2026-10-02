import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/failure_presentation.dart';
import '../../../l10n/app_localizations.dart';
import '../../import_pipeline/domain/llm_provider.dart';
import 'gemini_key_controller.dart';

/// Nome e spiegazione dei modelli Gemini proposti (D-35).
extension GeminiModelText on GeminiModel {
  String label(AppLocalizations l10n) => switch (this) {
    GeminiModel.flashLite35 => l10n.geminiModelFlashLite35,
    GeminiModel.flashLite31 => l10n.geminiModelFlashLite31,
    GeminiModel.flash38 => l10n.geminiModelFlash38,
  };

  String hint(AppLocalizations l10n) => switch (this) {
    GeminiModel.flashLite35 => l10n.geminiModelFlashLite35Hint,
    GeminiModel.flashLite31 => l10n.geminiModelFlashLite31Hint,
    GeminiModel.flash38 => l10n.geminiModelFlash38Hint,
  };
}

/// Riga delle impostazioni con la chiave Gemini (mascherata), l'esito
/// dell'ultima verifica e le azioni: inserisci/cambia, prova, elimina.
class GeminiKeyTile extends ConsumerWidget {
  const GeminiKeyTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(geminiKeyControllerProvider);
    final controller = ref.read(geminiKeyControllerProvider.notifier);

    if (state is! GeminiKeyReady) {
      return ListTile(
        leading: const Icon(Icons.key_outlined),
        title: Text(l10n.geminiKeyTitle),
        subtitle: Text(l10n.geminiKeyLoading),
      );
    }

    final checking = state.check is GeminiKeyChecking;
    final status = _status(context, l10n, state.check);
    final keyText = Text(state.maskedKey ?? l10n.geminiKeyMissing);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          leading: const Icon(Icons.key_outlined),
          title: Text(l10n.geminiKeyTitle),
          subtitle: status == null
              ? keyText
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [keyText, const SizedBox(height: 4), status],
                ),
          trailing: state.hasKey
              ? null
              : TextButton(
                  onPressed: checking
                      ? null
                      : () => showGeminiKeyDialog(context, controller),
                  child: Text(l10n.geminiKeyInsert),
                ),
        ),
        if (state.hasKey)
          Padding(
            // Allineati al titolo, dopo l'icona.
            padding: const EdgeInsetsDirectional.only(start: 56, end: 8),
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Wrap(
                children: [
                  TextButton(
                    onPressed: checking
                        ? null
                        : () => showGeminiKeyDialog(context, controller),
                    child: Text(l10n.geminiKeyChange),
                  ),
                  TextButton(
                    onPressed: checking ? null : controller.checkSavedKey,
                    child: Text(l10n.geminiKeyTry),
                  ),
                  TextButton(
                    onPressed: checking
                        ? null
                        : () => _confirmDelete(context, controller),
                    child: Text(l10n.geminiKeyDelete),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// Esito della verifica sotto la chiave; `null` se non c'è nulla da dire.
  Widget? _status(
    BuildContext context,
    AppLocalizations l10n,
    GeminiKeyCheck check,
  ) {
    final colors = Theme.of(context).colorScheme;
    return switch (check) {
      GeminiKeyChecking() => Row(
        children: [
          const SizedBox.square(
            dimension: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Flexible(child: Text(l10n.geminiKeyChecking)),
        ],
      ),
      GeminiKeyValid() => Text(
        l10n.geminiKeyValid,
        style: TextStyle(color: colors.primary),
      ),
      GeminiKeyRejected() => Text(
        l10n.geminiKeyRejected,
        style: TextStyle(color: colors.error),
      ),
      GeminiKeyUnverified(:final failure) => Text(
        l10n.geminiKeyUnverified(failure.message(l10n)),
        style: TextStyle(color: colors.error),
      ),
      GeminiKeyUnchecked() || GeminiKeyEmpty() => null,
    };
  }

  Future<void> _confirmDelete(
    BuildContext context,
    GeminiKeyController controller,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.geminiKeyDeleteTitle),
        content: Text(l10n.geminiKeyDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.geminiCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.geminiKeyDelete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await controller.deleteKey();
  }
}

/// Dialog di inserimento: verifica la chiave prima di chiudersi e resta
/// aperto se è vuota o rifiutata.
Future<void> showGeminiKeyDialog(
  BuildContext context,
  GeminiKeyController controller,
) => showDialog<void>(
  context: context,
  builder: (_) => _GeminiKeyDialog(controller),
);

class _GeminiKeyDialog extends StatefulWidget {
  const _GeminiKeyDialog(this.controller);

  final GeminiKeyController controller;

  @override
  State<_GeminiKeyDialog> createState() => _GeminiKeyDialogState();
}

class _GeminiKeyDialogState extends State<_GeminiKeyDialog> {
  final _field = TextEditingController();
  var _obscure = true;
  var _saving = false;
  String? _error;

  @override
  void dispose() {
    _field.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    final check = await widget.controller.saveKey(_field.text);
    if (!mounted) return;
    switch (check) {
      case GeminiKeyValid() || GeminiKeyUnverified():
        Navigator.of(context).pop();
      case GeminiKeyEmpty():
        setState(() {
          _saving = false;
          _error = l10n.geminiKeyEmpty;
        });
      case GeminiKeyRejected():
        setState(() {
          _saving = false;
          _error = l10n.geminiKeyRejected;
        });
      case GeminiKeyUnchecked() || GeminiKeyChecking():
        // Un'altra verifica era già in corso: si può riprovare.
        setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n.geminiKeyTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.geminiKeyHelp),
          const SizedBox(height: 16),
          TextField(
            controller: _field,
            autofocus: true,
            enabled: !_saving,
            obscureText: _obscure,
            autocorrect: false,
            enableSuggestions: false,
            keyboardType: TextInputType.visiblePassword,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              labelText: l10n.geminiKeyFieldLabel,
              errorText: _error,
              errorMaxLines: 3,
              suffixIcon: IconButton(
                tooltip: _obscure ? l10n.geminiKeyShow : l10n.geminiKeyHide,
                icon: Icon(
                  _obscure
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          if (_saving) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(l10n.geminiKeyChecking),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.geminiCancel),
        ),
        TextButton(
          onPressed: _saving ? null : _save,
          child: Text(l10n.geminiKeySave),
        ),
      ],
    );
  }
}

/// Riga delle impostazioni con il modello Gemini scelto; il tocco apre la
/// scelta tra i modelli proposti.
class GeminiModelTile extends ConsumerWidget {
  const GeminiModelTile({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(geminiKeyControllerProvider);
    final model = state is GeminiKeyReady ? state.model : null;

    return ListTile(
      leading: const Icon(Icons.auto_awesome_outlined),
      title: Text(l10n.geminiModelTitle),
      subtitle: Text(
        model == null
            ? l10n.geminiKeyLoading
            : '${model.label(l10n)} — ${model.hint(l10n)}',
      ),
      enabled: model != null,
      onTap: model == null ? null : () => _choose(context, ref, model),
    );
  }

  Future<void> _choose(
    BuildContext context,
    WidgetRef ref,
    GeminiModel current,
  ) async {
    final l10n = AppLocalizations.of(context);
    final controller = ref.read(geminiKeyControllerProvider.notifier);
    final chosen = await showDialog<GeminiModel>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.geminiModelTitle),
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        content: RadioGroup<GeminiModel>(
          groupValue: current,
          onChanged: (model) => Navigator.of(context).pop(model),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final model in GeminiModel.values)
                RadioListTile<GeminiModel>(
                  value: model,
                  title: Text(model.label(l10n)),
                  subtitle: Text(model.hint(l10n)),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.geminiCancel),
          ),
        ],
      ),
    );
    if (chosen != null) await controller.selectModel(chosen);
  }
}
