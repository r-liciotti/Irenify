import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/failure_presentation.dart';
import '../../../app/widgets/empty_state.dart';
import '../../../l10n/app_localizations.dart';
import '../data/import_job_repository.dart';
import '../domain/import_job.dart';
import 'import_job_tile.dart';

final recentImportJobsProvider = StreamProvider<List<ImportJob>>(
  (ref) => ref.watch(importJobRepositoryProvider).watchRecent(),
);

/// Importazioni in corso e recenti, con le azioni possibili su ognuna
/// (D-43). L'elenco si aggiorna da solo a ogni salvataggio del motore.
class ImportsScreen extends ConsumerWidget {
  const ImportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final jobs = ref.watch(recentImportJobsProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.navImports)),
      body: switch (jobs) {
        AsyncData(value: []) => EmptyState(
          icon: Icons.downloading_outlined,
          title: l10n.importsEmptyTitle,
          body: l10n.importsEmptyBody,
        ),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.only(bottom: 16),
          children: [
            for (final (i, job) in value.indexed) ...[
              if (i > 0) const Divider(height: 1, indent: 56),
              ImportJobTile(job, key: ValueKey(job.id)),
            ],
          ],
        ),
        AsyncError(:final error, :final stackTrace) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.navImports,
          body: failureFromProviderError(error, stackTrace).message(l10n),
        ),
        _ => const Center(child: CircularProgressIndicator()),
      },
    );
  }
}
