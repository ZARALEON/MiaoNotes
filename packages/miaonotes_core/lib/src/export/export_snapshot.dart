import '../model/note_draft.dart';
import '../model/revision.dart';
import '../model/vault_identity.dart';

/// A consistent, read-only view of the portable data required by Export v1.
///
/// Sync cursors, credentials and encryption keys are intentionally excluded.
final class ExportSnapshot {
  const ExportSnapshot({
    required this.vault,
    required this.exportedAtUtc,
    required this.notes,
    required this.revisions,
    required this.conflicts,
  });

  final VaultIdentity vault;
  final DateTime exportedAtUtc;
  final List<ExportNoteState> notes;
  final List<Revision> revisions;
  final List<ExportConflictRecord> conflicts;
}

final class ExportNoteState {
  const ExportNoteState({
    required this.draft,
    required this.createdAtUtc,
    required this.dirty,
    this.lastCommittedRevisionId,
  });

  final NoteDraft draft;
  final DateTime createdAtUtc;
  final bool dirty;
  final String? lastCommittedRevisionId;
}

enum ExportConflictStatus { open, resolved }

final class ExportConflictRecord {
  const ExportConflictRecord({
    required this.conflictId,
    required this.noteId,
    required this.headRevisionIds,
    required this.status,
    required this.createdAtUtc,
    this.resolvedAtUtc,
  });

  final String conflictId;
  final String noteId;
  final List<String> headRevisionIds;
  final ExportConflictStatus status;
  final DateTime createdAtUtc;
  final DateTime? resolvedAtUtc;
}
