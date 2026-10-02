import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/failure_presentation.dart';
import '../../../l10n/app_localizations.dart';
import '../data/whisper_model_manager.dart';
import 'speech_model_controller.dart';

/// Riga delle impostazioni con lo stato del modello Whisper e le azioni
/// (scarica, annulla, riprova, elimina).
class SpeechModelTile extends ConsumerWidget {
  const SpeechModelTile({super.key});

  /// MB decimali, come li mostra Android.
  static int megabytes(int bytes) => (bytes / 1000000).round();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(speechModelControllerProvider);
    final controller = ref.read(speechModelControllerProvider.notifier);
    final expectedMb = megabytes(WhisperModelManager.modelBytes);

    final Widget subtitle = switch (state) {
      SpeechModelChecking() => Text(l10n.speechModelChecking),
      SpeechModelMissing() => Text(l10n.speechModelMissing(expectedMb)),
      SpeechModelDownloading(:final progress) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.speechModelDownloading((progress * 100).floor())),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: progress),
        ],
      ),
      SpeechModelVerifying() => Text(l10n.speechModelVerifying),
      SpeechModelReady(:final bytes) => Text(
        l10n.speechModelReady(megabytes(bytes)),
      ),
      SpeechModelFailed(:final failure) => Text(
        l10n.speechModelFailed(failure.message(l10n)),
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
    };

    final Widget? action = switch (state) {
      SpeechModelMissing() => TextButton(
        onPressed: controller.download,
        child: Text(l10n.speechModelDownload),
      ),
      SpeechModelDownloading() => TextButton(
        onPressed: controller.cancel,
        child: Text(l10n.speechModelCancel),
      ),
      SpeechModelReady(:final bytes) => TextButton(
        onPressed: () => _confirmDelete(context, controller, bytes),
        child: Text(l10n.speechModelDelete),
      ),
      SpeechModelFailed(:final failure) => TextButton(
        onPressed: controller.download,
        child: Text(failure.action.label(l10n) ?? l10n.actionRetry),
      ),
      SpeechModelChecking() || SpeechModelVerifying() => null,
    };

    return ListTile(
      leading: const Icon(Icons.record_voice_over_outlined),
      title: Text(l10n.speechModelTitle),
      subtitle: subtitle,
      isThreeLine: state is SpeechModelMissing || state is SpeechModelFailed,
      trailing: action,
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    SpeechModelController controller,
    int bytes,
  ) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.speechModelDeleteTitle),
        content: Text(l10n.speechModelDeleteBody(megabytes(bytes))),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.speechModelCancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.speechModelDelete),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await controller.delete();
  }
}
