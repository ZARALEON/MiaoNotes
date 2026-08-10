import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';

import '../export/export_snapshot.dart';
import '../import/portable_import.dart';
import '../model/canonical_json.dart';
import '../model/content_format.dart';
import '../model/note_draft.dart';
import '../model/revision.dart';
import '../model/sync_event.dart';
import '../model/vault_identity.dart';
import '../sync/id_factory.dart';
import '../sync/protocol_paths.dart';
import '../sync/sync_exception.dart';
import 'database.dart' hide Revision, SyncEvent;

typedef CommitFaultHook = FutureOr<void> Function();

final class CommittedRevisionBundle {
  const CommittedRevisionBundle({required this.revision, required this.event});

  final Revision revision;
  final SyncEvent event;
}

final class DurableOutboxEntry {
  const DurableOutboxEntry({
    required this.outboxId,
    required this.objectKey,
    required this.kind,
    required this.payload,
    required this.payloadHash,
    required this.attemptCount,
    required this.nextAttemptAtUtc,
    required this.createdAtUtc,
    this.dependencyKey,
    this.lastError,
  });

  final int outboxId;
  final String objectKey;
  final String kind;
  final Uint8List payload;
  final String payloadHash;
  final String? dependencyKey;
  final int attemptCount;
  final DateTime nextAttemptAtUtc;
  final String? lastError;
  final DateTime createdAtUtc;
}

final class StoredNoteSummary {
  const StoredNoteSummary({
    required this.noteId,
    required this.title,
    required this.bodyPreview,
    required this.format,
    required this.updatedAtUtc,
    required this.deleted,
  });

  final String noteId;
  final String title;
  final String bodyPreview;
  final ContentFormat format;
  final DateTime updatedAtUtc;
  final bool deleted;
}

final class StoredConflict {
  const StoredConflict({
    required this.conflictId,
    required this.noteId,
    required this.headRevisionIds,
    required this.createdAtUtc,
  });

  final String conflictId;
  final String noteId;
  final List<String> headRevisionIds;
  final DateTime createdAtUtc;
}

final class ConflictDetails {
  const ConflictDetails({required this.conflict, required this.versions});

  final StoredConflict conflict;
  final List<Revision> versions;
}

final class ConflictResolutionException implements Exception {
  const ConflictResolutionException(this.message);

  final String message;

  @override
  String toString() => 'ConflictResolutionException: $message';
}

final class PersistentRecoveryState {
  const PersistentRecoveryState({
    required this.dirtyDrafts,
    required this.revisions,
    required this.pendingObjects,
    required this.openConflicts,
    required this.nextEventSequence,
  });

  final int dirtyDrafts;
  final int revisions;
  final int pendingObjects;
  final int openConflicts;
  final int nextEventSequence;
}

/// Durable local-first repository backed by SQLite through Drift.
///
/// Draft saves are single local statements. Revision, event, outbox, head, and
/// sequence changes are committed in one transaction and never require network
/// access.
final class PersistentNoteStore {
  PersistentNoteStore({
    required this.database,
    IdFactory? idFactory,
    DateTime Function()? clock,
  }) : idFactory = idFactory ?? UuidV7IdFactory(),
       clock = clock ?? (() => DateTime.now().toUtc());

  final MiaoNotesDatabase database;
  final IdFactory idFactory;
  final DateTime Function() clock;

  Future<void> initializeVault({
    required VaultIdentity vault,
    required String deviceId,
    required String deviceName,
  }) async {
    final now = clock().toUtc().millisecondsSinceEpoch;
    await database.transaction(() async {
      final existing = await database
          .customSelect(
            'SELECT vault_id, vault_generation, protocol_version, '
            'local_device_id FROM vault_state WHERE singleton_id = 1',
          )
          .getSingleOrNull();
      if (existing == null) {
        await database.customInsert(
          'INSERT INTO vault_state ('
          'singleton_id, vault_id, vault_generation, protocol_version, '
          'schema_version, local_device_id, next_event_sequence, '
          'created_at_ms, updated_at_ms'
          ') VALUES (1, ?, ?, ?, 1, ?, 1, ?, ?)',
          variables: <Variable>[
            Variable.withString(vault.vaultId),
            Variable.withInt(vault.generation),
            Variable.withInt(vault.protocolVersion),
            Variable.withString(deviceId),
            Variable.withInt(vault.createdAtUtc.millisecondsSinceEpoch),
            Variable.withInt(now),
          ],
        );
      } else {
        _verifyVaultRow(existing, vault, deviceId);
      }

      await database.customInsert(
        'INSERT INTO devices ('
        'device_id, display_name, created_at_ms, last_seen_at_ms'
        ') VALUES (?, ?, ?, ?) '
        'ON CONFLICT(device_id) DO UPDATE SET '
        'display_name = excluded.display_name, '
        'last_seen_at_ms = excluded.last_seen_at_ms',
        variables: <Variable>[
          Variable.withString(deviceId),
          Variable.withString(deviceName),
          Variable.withInt(now),
          Variable.withInt(now),
        ],
      );
    });
  }

  /// Rebinds a completely empty local database to an existing remote Vault.
  ///
  /// The local device identity is retained. Any user data, revision history,
  /// event cursor, conflict, or outbox entry permanently closes this path.
  Future<void> adoptRemoteVault(VaultIdentity remote) async {
    await database.transaction(() async {
      final local = await vaultIdentity();
      if (remote.protocolVersion != local.protocolVersion) {
        throw SyncException(
          'Remote protocol ${remote.protocolVersion} does not match '
          '${local.protocolVersion}',
        );
      }
      final state = await database
          .customSelect(
            'SELECT '
            '(SELECT COUNT(*) FROM notes) + '
            '(SELECT COUNT(*) FROM revisions) + '
            '(SELECT COUNT(*) FROM sync_events) + '
            '(SELECT COUNT(*) FROM sync_outbox) + '
            '(SELECT COUNT(*) FROM sync_cursors) + '
            '(SELECT COUNT(*) FROM conflicts) AS protected_rows, '
            '(SELECT next_event_sequence FROM vault_state '
            'WHERE singleton_id = 1) AS next_event_sequence',
          )
          .getSingle();
      if (state.read<int>('protected_rows') != 0 ||
          state.read<int>('next_event_sequence') != 1) {
        throw const VaultAdoptionNotAllowedException(
          'A remote Vault can only be imported into an empty local database',
        );
      }
      final now = clock().toUtc().millisecondsSinceEpoch;
      await database.customUpdate(
        'UPDATE vault_state SET vault_id = ?, vault_generation = ?, '
        'protocol_version = ?, created_at_ms = ?, updated_at_ms = ? '
        'WHERE singleton_id = 1',
        variables: <Variable>[
          Variable.withString(remote.vaultId),
          Variable.withInt(remote.generation),
          Variable.withInt(remote.protocolVersion),
          Variable.withInt(remote.createdAtUtc.millisecondsSinceEpoch),
          Variable.withInt(now),
        ],
        updates: <TableInfo<Table, Object?>>{database.vaultState},
      );
    });
  }

  Future<void> saveDraft(NoteDraft draft) async {
    final updatedAt = draft.updatedAtUtc.toUtc().millisecondsSinceEpoch;
    final bodyText = _searchableBody(draft.format, draft.body);
    await database.customInsert(
      'INSERT INTO notes ('
      'note_id, format, title, draft_json, body_text, tags_json, tags_text, '
      'base_revision_ids_json, dirty, is_deleted, created_at_ms, updated_at_ms'
      ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?) '
      'ON CONFLICT(note_id) DO UPDATE SET '
      'format = excluded.format, title = excluded.title, '
      'draft_json = excluded.draft_json, body_text = excluded.body_text, '
      'tags_json = excluded.tags_json, tags_text = excluded.tags_text, '
      'base_revision_ids_json = excluded.base_revision_ids_json, '
      'dirty = 1, is_deleted = excluded.is_deleted, '
      'updated_at_ms = excluded.updated_at_ms',
      variables: <Variable>[
        Variable.withString(draft.noteId),
        Variable.withString(draft.format.wireName),
        Variable.withString(draft.title),
        Variable.withString(_draftJson(draft)),
        Variable.withString(bodyText),
        Variable.withString(canonicalJson(draft.tags)),
        Variable.withString(draft.tags.join(' ')),
        Variable.withString(canonicalJson(draft.baseRevisionIds)),
        Variable.withInt(draft.deleted ? 1 : 0),
        Variable.withInt(updatedAt),
        Variable.withInt(updatedAt),
      ],
    );
  }

  Future<NoteDraft?> loadDraft(String noteId) async {
    final row = await database
        .customSelect(
          'SELECT note_id, format, title, draft_json, tags_json, '
          'base_revision_ids_json, is_deleted, updated_at_ms '
          'FROM notes WHERE note_id = ?',
          variables: <Variable>[Variable.withString(noteId)],
        )
        .getSingleOrNull();
    return row == null ? null : _draftFromRow(row);
  }

  Future<List<NoteDraft>> loadDirtyDrafts() async {
    final rows = await database
        .customSelect(
          'SELECT note_id, format, title, draft_json, tags_json, '
          'base_revision_ids_json, is_deleted, updated_at_ms '
          'FROM notes WHERE dirty = 1 ORDER BY updated_at_ms, note_id',
        )
        .get();
    return List.unmodifiable(rows.map(_draftFromRow));
  }

  Future<CommittedRevisionBundle?> commitDraft(
    String noteId, {
    CommitFaultHook? faultHook,
  }) => database.transaction(() async {
    final noteRow = await database
        .customSelect(
          'SELECT note_id, format, title, draft_json, tags_json, '
          'base_revision_ids_json, is_deleted, updated_at_ms '
          'FROM notes WHERE note_id = ? AND dirty = 1',
          variables: <Variable>[Variable.withString(noteId)],
        )
        .getSingleOrNull();
    if (noteRow == null) {
      return null;
    }

    final draft = _draftFromRow(noteRow);
    if (await _isNoOpDraft(draft)) {
      await database.customUpdate(
        'UPDATE notes SET dirty = 0 WHERE note_id = ?',
        variables: <Variable>[Variable.withString(noteId)],
        updates: <TableInfo<Table, Object?>>{database.notes},
      );
      return null;
    }

    return _commitPreparedDraft(draft, faultHook: faultHook);
  });

  Future<CommittedRevisionBundle> _commitPreparedDraft(
    NoteDraft draft, {
    CommitFaultHook? faultHook,
  }) async {
    final vaultRow = await _requireVaultRow();
    final vaultId = vaultRow.read<String>('vault_id');
    final generation = vaultRow.read<int>('vault_generation');
    final deviceId = vaultRow.read<String>('local_device_id');
    final sequence = vaultRow.read<int>('next_event_sequence');
    final now = clock().toUtc();
    final revision = Revision.create(
      vaultId: vaultId,
      vaultGeneration: generation,
      revisionId: idFactory.next(now),
      deviceId: deviceId,
      createdAtUtc: now,
      draft: draft,
    );
    final revisionKey = ProtocolPaths.revision(
      draft.noteId,
      revision.revisionId,
    );
    final revisionBytes = revision.toBytes();
    final event = SyncEvent.revisionCommitted(
      vaultId: vaultId,
      vaultGeneration: generation,
      eventId: idFactory.next(now),
      deviceId: deviceId,
      sequence: sequence,
      objectKey: revisionKey,
      objectHash: sha256HexBytes(revisionBytes),
      occurredAtUtc: now,
    );

    await _insertRevision(revision);
    await _updateHeads(revision);
    if (faultHook != null) {
      await faultHook();
    }
    await _insertEvent(event);
    await _insertOutbox(
      key: revisionKey,
      kind: 'revision',
      bytes: revisionBytes,
      createdAtUtc: now,
    );
    final eventBytes = event.toBytes();
    await _insertOutbox(
      key: ProtocolPaths.event(deviceId, sequence, event.eventId),
      kind: 'event',
      bytes: eventBytes,
      dependencyKey: revisionKey,
      createdAtUtc: now,
    );
    await database.customUpdate(
      'UPDATE vault_state SET next_event_sequence = ?, updated_at_ms = ? '
      'WHERE singleton_id = 1',
      variables: <Variable>[
        Variable.withInt(sequence + 1),
        Variable.withInt(now.millisecondsSinceEpoch),
      ],
      updates: <TableInfo<Table, Object?>>{database.vaultState},
    );
    await _materializeCommittedNote(draft, revision);
    await _refreshConflict(draft.noteId, now);
    return CommittedRevisionBundle(revision: revision, event: event);
  }

  Future<int> commitAllDirtyDrafts() async {
    final drafts = await loadDirtyDrafts();
    var committed = 0;
    for (final draft in drafts) {
      if (await commitDraft(draft.noteId) != null) {
        committed += 1;
      }
    }
    return committed;
  }

  Future<VaultIdentity?> loadVaultIdentity() async {
    final row = await database
        .customSelect(
          'SELECT vault_id, vault_generation, protocol_version, created_at_ms '
          'FROM vault_state WHERE singleton_id = 1',
        )
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    return VaultIdentity(
      vaultId: row.read<String>('vault_id'),
      generation: row.read<int>('vault_generation'),
      protocolVersion: row.read<int>('protocol_version'),
      createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
        row.read<int>('created_at_ms'),
        isUtc: true,
      ),
    );
  }

  Future<VaultIdentity> vaultIdentity() async =>
      await loadVaultIdentity() ??
      (throw StateError('Vault has not been initialized'));

  /// Captures notes, immutable revisions and conflict history in one SQLite
  /// read transaction. Dirty Drafts are included so an export never omits the
  /// user's latest locally saved keystrokes.
  Future<ExportSnapshot> createExportSnapshot() => database.transaction(
    () async {
      final vault = await vaultIdentity();
      final noteRows = await database
          .customSelect(
            'SELECT note_id, format, title, draft_json, tags_json, '
            'base_revision_ids_json, dirty, is_deleted, created_at_ms, '
            'updated_at_ms, last_committed_revision_id FROM notes '
            'ORDER BY note_id',
          )
          .get();
      final revisionRows = await database
          .customSelect(
            'SELECT canonical_payload_json, payload_hash FROM revisions '
            'ORDER BY note_id, created_at_ms, revision_id',
          )
          .get();
      final conflictRows = await database
          .customSelect(
            'SELECT conflict_id, note_id, head_revision_ids_json, status, '
            'created_at_ms, resolved_at_ms FROM conflicts '
            'ORDER BY created_at_ms, conflict_id',
          )
          .get();

      return ExportSnapshot(
        vault: vault,
        exportedAtUtc: clock().toUtc(),
        notes: List.unmodifiable(
          noteRows.map(
            (row) => ExportNoteState(
              draft: _draftFromRow(row),
              createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
                row.read<int>('created_at_ms'),
                isUtc: true,
              ),
              dirty: row.read<int>('dirty') == 1,
              lastCommittedRevisionId: row.readNullable<String>(
                'last_committed_revision_id',
              ),
            ),
          ),
        ),
        revisions: List.unmodifiable(revisionRows.map(_revisionFromRow)),
        conflicts: List.unmodifiable(
          conflictRows.map((row) {
            final status = row.read<String>('status');
            return ExportConflictRecord(
              conflictId: row.read<String>('conflict_id'),
              noteId: row.read<String>('note_id'),
              headRevisionIds: List.unmodifiable(
                (jsonDecode(row.read<String>('head_revision_ids_json')) as List)
                    .cast<String>(),
              ),
              status: switch (status) {
                'open' => ExportConflictStatus.open,
                'resolved' => ExportConflictStatus.resolved,
                _ => throw StateError('Unsupported conflict status: $status'),
              },
              createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
                row.read<int>('created_at_ms'),
                isUtc: true,
              ),
              resolvedAtUtc: switch (row.readNullable<int>('resolved_at_ms')) {
                final value? => DateTime.fromMillisecondsSinceEpoch(
                  value,
                  isUtc: true,
                ),
                null => null,
              },
            );
          }),
        ),
      );
    },
  );

  /// Restores a verified portable snapshot into a completely empty local
  /// Vault. The local device identity is retained and imported revisions are
  /// re-announced through a new durable outbox so history can synchronize.
  Future<PortableImportResult> importPortableSnapshot(
    ExportSnapshot snapshot, {
    ImportApplyHook? applyHook,
  }) async {
    final validated = _validatePortableImport(snapshot);
    return database.transaction(() async {
      final state = await database
          .customSelect(
            'SELECT '
            '(SELECT COUNT(*) FROM notes) + '
            '(SELECT COUNT(*) FROM revisions) + '
            '(SELECT COUNT(*) FROM sync_events) + '
            '(SELECT COUNT(*) FROM sync_outbox) + '
            '(SELECT COUNT(*) FROM sync_cursors) + '
            '(SELECT COUNT(*) FROM conflicts) + '
            '(SELECT COUNT(*) FROM attachments) + '
            '(SELECT COUNT(*) FROM note_attachments) AS protected_rows, '
            '(SELECT next_event_sequence FROM vault_state '
            'WHERE singleton_id = 1) AS next_event_sequence',
          )
          .getSingle();
      if (state.read<int>('protected_rows') != 0 ||
          state.read<int>('next_event_sequence') != 1) {
        throw const PortableImportException(
          'Portable import requires an empty local Vault',
        );
      }

      final importingDeviceId = await localDeviceId();
      final now = clock().toUtc();
      await database.customUpdate(
        'UPDATE vault_state SET vault_id = ?, vault_generation = ?, '
        'protocol_version = ?, created_at_ms = ?, updated_at_ms = ? '
        'WHERE singleton_id = 1',
        variables: <Variable>[
          Variable.withString(snapshot.vault.vaultId),
          Variable.withInt(snapshot.vault.generation),
          Variable.withInt(snapshot.vault.protocolVersion),
          Variable.withInt(snapshot.vault.createdAtUtc.millisecondsSinceEpoch),
          Variable.withInt(now.millisecondsSinceEpoch),
        ],
        updates: <TableInfo<Table, Object?>>{database.vaultState},
      );

      var sequence = 1;
      for (final revision in validated.revisions) {
        await _insertRevision(revision);
        await _updateHeads(revision);
        final revisionKey = ProtocolPaths.revision(
          revision.noteId,
          revision.revisionId,
        );
        final revisionBytes = revision.toBytes();
        final event = SyncEvent.revisionCommitted(
          vaultId: snapshot.vault.vaultId,
          vaultGeneration: snapshot.vault.generation,
          eventId: idFactory.next(now),
          deviceId: importingDeviceId,
          sequence: sequence,
          objectKey: revisionKey,
          objectHash: sha256HexBytes(revisionBytes),
          occurredAtUtc: now,
        );
        await _insertEvent(event);
        await _insertOutbox(
          key: revisionKey,
          kind: 'revision',
          bytes: revisionBytes,
          createdAtUtc: now,
        );
        await _insertOutbox(
          key: ProtocolPaths.event(importingDeviceId, sequence, event.eventId),
          kind: 'event',
          bytes: event.toBytes(),
          dependencyKey: revisionKey,
          createdAtUtc: now,
        );
        sequence += 1;
        await applyHook?.call(sequence - 1);
      }

      for (final note in snapshot.notes) {
        final draft = note.draft;
        await database.customInsert(
          'INSERT INTO notes ('
          'note_id, format, title, draft_json, body_text, tags_json, tags_text, '
          'base_revision_ids_json, dirty, is_deleted, '
          'last_committed_revision_id, created_at_ms, updated_at_ms'
          ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
          variables: <Variable>[
            Variable.withString(draft.noteId),
            Variable.withString(draft.format.wireName),
            Variable.withString(draft.title),
            Variable.withString(_draftJson(draft)),
            Variable.withString(_searchableBody(draft.format, draft.body)),
            Variable.withString(canonicalJson(draft.tags)),
            Variable.withString(draft.tags.join(' ')),
            Variable.withString(canonicalJson(draft.baseRevisionIds)),
            Variable.withInt(note.dirty ? 1 : 0),
            Variable.withInt(draft.deleted ? 1 : 0),
            Variable<String>(note.lastCommittedRevisionId),
            Variable.withInt(note.createdAtUtc.millisecondsSinceEpoch),
            Variable.withInt(draft.updatedAtUtc.millisecondsSinceEpoch),
          ],
        );
      }

      for (final conflict in snapshot.conflicts) {
        await database.customInsert(
          'INSERT INTO conflicts ('
          'conflict_id, note_id, head_revision_ids_json, status, '
          'created_at_ms, resolved_at_ms'
          ') VALUES (?, ?, ?, ?, ?, ?)',
          variables: <Variable>[
            Variable.withString(conflict.conflictId),
            Variable.withString(conflict.noteId),
            Variable.withString(canonicalJson(conflict.headRevisionIds)),
            Variable.withString(conflict.status.name),
            Variable.withInt(conflict.createdAtUtc.millisecondsSinceEpoch),
            Variable<int>(conflict.resolvedAtUtc?.millisecondsSinceEpoch),
          ],
        );
      }

      await database.customUpdate(
        'UPDATE vault_state SET next_event_sequence = ?, updated_at_ms = ? '
        'WHERE singleton_id = 1',
        variables: <Variable>[
          Variable.withInt(sequence),
          Variable.withInt(now.millisecondsSinceEpoch),
        ],
        updates: <TableInfo<Table, Object?>>{database.vaultState},
      );
      return PortableImportResult(
        noteCount: snapshot.notes.length,
        revisionCount: validated.revisions.length,
        conflictCount: snapshot.conflicts.length,
        queuedObjectCount: validated.revisions.length * 2,
      );
    });
  }

  Future<String> localDeviceId() async {
    final row = await _requireVaultRow();
    return row.read<String>('local_device_id');
  }

  Future<bool> hasRevision(String revisionId) async =>
      await loadRevision(revisionId) != null;

  Future<Revision?> loadRevision(String revisionId) async {
    final row = await database
        .customSelect(
          'SELECT canonical_payload_json, payload_hash FROM revisions '
          'WHERE revision_id = ?',
          variables: <Variable>[Variable.withString(revisionId)],
        )
        .getSingleOrNull();
    return row == null ? null : _revisionFromRow(row);
  }

  Future<List<StoredConflict>> openConflicts({int limit = 100}) async {
    if (limit < 1) {
      throw ArgumentError.value(limit, 'limit', 'Must be positive');
    }
    final rows = await database
        .customSelect(
          'SELECT conflict_id, note_id, head_revision_ids_json, '
          'created_at_ms FROM conflicts WHERE status = \'open\' '
          'ORDER BY created_at_ms DESC, conflict_id LIMIT ?',
          variables: <Variable>[Variable.withInt(limit)],
        )
        .get();
    return List.unmodifiable(rows.map(_conflictFromRow));
  }

  Future<ConflictDetails?> loadConflictDetails(String conflictId) async {
    final row = await database
        .customSelect(
          'SELECT conflict_id, note_id, head_revision_ids_json, '
          'created_at_ms FROM conflicts '
          'WHERE conflict_id = ? AND status = \'open\'',
          variables: <Variable>[Variable.withString(conflictId)],
        )
        .getSingleOrNull();
    if (row == null) {
      return null;
    }
    final conflict = _conflictFromRow(row);
    final versions = <Revision>[];
    for (final revisionId in conflict.headRevisionIds) {
      final revision = await loadRevision(revisionId);
      if (revision == null || revision.noteId != conflict.noteId) {
        throw StateError('Conflict references a missing revision: $revisionId');
      }
      versions.add(revision);
    }
    return ConflictDetails(
      conflict: conflict,
      versions: List.unmodifiable(versions),
    );
  }

  /// Atomically creates a merge Revision whose parents are every current head.
  /// Existing heads and conflict rows are never deleted; they become ancestors
  /// of the new immutable Revision.
  Future<CommittedRevisionBundle> resolveConflict({
    required String conflictId,
    required ContentFormat format,
    required String title,
    required Object body,
    required List<String> tags,
    bool deleted = false,
  }) => database.transaction(() async {
    final details = await loadConflictDetails(conflictId);
    if (details == null) {
      throw const ConflictResolutionException('The conflict is no longer open');
    }
    final conflict = details.conflict;
    final currentHeads = await noteHeads(conflict.noteId);
    if (!_sameStringList(currentHeads, conflict.headRevisionIds)) {
      throw const ConflictResolutionException(
        'The conflict changed while it was being reviewed',
      );
    }
    final note = await database
        .customSelect(
          'SELECT dirty FROM notes WHERE note_id = ?',
          variables: <Variable>[Variable.withString(conflict.noteId)],
        )
        .getSingleOrNull();
    if (note == null) {
      throw const ConflictResolutionException('The note no longer exists');
    }
    if (note.read<int>('dirty') == 1) {
      throw const ConflictResolutionException(
        'The note has an uncommitted local edit',
      );
    }
    final now = clock().toUtc();
    final mergedDraft = NoteDraft(
      noteId: conflict.noteId,
      format: format,
      title: title,
      body: body,
      tags: tags,
      baseRevisionIds: currentHeads,
      updatedAtUtc: now,
      deleted: deleted,
    );
    return _commitPreparedDraft(mergedDraft);
  });

  Future<int> cursorFor(String remoteDeviceId) async {
    final row = await database
        .customSelect(
          'SELECT last_sequence FROM sync_cursors WHERE remote_device_id = ?',
          variables: <Variable>[Variable.withString(remoteDeviceId)],
        )
        .getSingleOrNull();
    return row?.read<int>('last_sequence') ?? 0;
  }

  Future<bool> isOutboxPending(String objectKey) async {
    final row = await database
        .customSelect(
          'SELECT 1 AS found FROM sync_outbox WHERE object_key = ? LIMIT 1',
          variables: <Variable>[Variable.withString(objectKey)],
        )
        .getSingleOrNull();
    return row != null;
  }

  /// Atomically applies a validated remote event and its parent-first revision
  /// chain. The caller must verify remote object hashes before this method.
  Future<void> applyRemoteEvent({
    required SyncEvent event,
    required List<Revision> revisions,
  }) => database.transaction(() async {
    final vault = await vaultIdentity();
    _verifyIdentity(
      expected: vault,
      vaultId: event.vaultId,
      generation: event.vaultGeneration,
    );
    final cursor = await cursorFor(event.deviceId);
    if (event.sequence <= cursor) {
      return;
    }
    if (event.sequence != cursor + 1) {
      throw EventGapException(
        'Cursor for ${event.deviceId} expected ${cursor + 1}, '
        'got ${event.sequence}',
      );
    }

    final affectedNotes = <String>{};
    for (final revision in revisions) {
      _verifyIdentity(
        expected: vault,
        vaultId: revision.vaultId,
        generation: revision.vaultGeneration,
      );
      final existing = await loadRevision(revision.revisionId);
      if (existing == null) {
        await _insertRevision(revision);
      } else if (existing.payloadHash != revision.payloadHash) {
        throw RemoteObjectCorruptedException(
          'Revision ${revision.revisionId} has multiple payloads',
        );
      }
      await _updateHeads(revision);
      affectedNotes.add(revision.noteId);
    }

    final targetRevisionId = _revisionIdFromObjectKey(event.objectKey);
    final target = await loadRevision(targetRevisionId);
    if (target == null ||
        ProtocolPaths.revision(target.noteId, target.revisionId) !=
            event.objectKey ||
        sha256HexBytes(target.toBytes()) != event.objectHash) {
      throw RemoteObjectCorruptedException(
        'Event ${event.eventId} does not match its revision object',
      );
    }
    affectedNotes.add(target.noteId);

    await _insertEventIdempotently(event);
    await database.customInsert(
      'INSERT INTO sync_cursors ('
      'remote_device_id, last_sequence, updated_at_ms'
      ') VALUES (?, ?, ?) '
      'ON CONFLICT(remote_device_id) DO UPDATE SET '
      'last_sequence = excluded.last_sequence, '
      'updated_at_ms = excluded.updated_at_ms',
      variables: <Variable>[
        Variable.withString(event.deviceId),
        Variable.withInt(event.sequence),
        Variable.withInt(clock().toUtc().millisecondsSinceEpoch),
      ],
    );
    final now = clock().toUtc();
    for (final noteId in affectedNotes) {
      await _materializeRemoteNote(noteId);
      await _refreshConflict(noteId, now);
    }
  });

  Future<List<DurableOutboxEntry>> loadReadyOutbox({
    int limit = 100,
    DateTime? nowUtc,
  }) async {
    final now = (nowUtc ?? clock()).toUtc().millisecondsSinceEpoch;
    final rows = await database
        .customSelect(
          'SELECT outbox_id, object_key, object_kind, payload, payload_hash, '
          'dependency_key, attempt_count, next_attempt_at_ms, last_error, '
          'created_at_ms FROM sync_outbox '
          'WHERE next_attempt_at_ms <= ? ORDER BY outbox_id LIMIT ?',
          variables: <Variable>[Variable.withInt(now), Variable.withInt(limit)],
        )
        .get();
    return List.unmodifiable(rows.map(_outboxFromRow));
  }

  Future<void> acknowledgeOutbox(int outboxId) async {
    await database.customUpdate(
      'DELETE FROM sync_outbox WHERE outbox_id = ?',
      variables: <Variable>[Variable.withInt(outboxId)],
      updates: <TableInfo<Table, Object?>>{database.syncOutbox},
    );
  }

  Future<void> recordOutboxFailure(
    int outboxId,
    Object error, {
    Duration retryAfter = const Duration(seconds: 5),
  }) async {
    final retryAt = clock().toUtc().add(retryAfter).millisecondsSinceEpoch;
    await database.customUpdate(
      'UPDATE sync_outbox SET attempt_count = attempt_count + 1, '
      'next_attempt_at_ms = ?, last_error = ? WHERE outbox_id = ?',
      variables: <Variable>[
        Variable.withInt(retryAt),
        Variable.withString(error.toString()),
        Variable.withInt(outboxId),
      ],
      updates: <TableInfo<Table, Object?>>{database.syncOutbox},
    );
  }

  Future<List<StoredNoteSummary>> recentNotes({int limit = 50}) async {
    final rows = await database
        .customSelect(
          'SELECT note_id, title, body_text, format, is_deleted, updated_at_ms '
          'FROM notes WHERE is_deleted = 0 '
          'ORDER BY updated_at_ms DESC, note_id LIMIT ?',
          variables: <Variable>[Variable.withInt(limit)],
        )
        .get();
    return List.unmodifiable(rows.map(_summaryFromRow));
  }

  Future<List<StoredNoteSummary>> searchNotes(
    String query, {
    int limit = 50,
  }) async {
    if (query.trim().isEmpty) {
      return recentNotes(limit: limit);
    }
    final rows = await database
        .customSelect(
          'SELECT n.note_id, n.title, n.body_text, n.format, '
          'n.is_deleted, n.updated_at_ms FROM notes_fts f '
          'JOIN notes n ON n.note_id = f.note_id '
          'WHERE notes_fts MATCH ? AND n.is_deleted = 0 '
          'ORDER BY bm25(notes_fts), n.updated_at_ms DESC LIMIT ?',
          variables: <Variable>[
            Variable.withString(query),
            Variable.withInt(limit),
          ],
          readsFrom: <ResultSetImplementation<Table, Object?>>{
            database.notes,
            database.notesFts,
          },
        )
        .get();
    return List.unmodifiable(rows.map(_summaryFromRow));
  }

  Future<List<String>> noteHeads(String noteId) async {
    final rows = await database
        .customSelect(
          'SELECT revision_id FROM note_heads WHERE note_id = ? '
          'ORDER BY revision_id',
          variables: <Variable>[Variable.withString(noteId)],
        )
        .get();
    return List.unmodifiable(
      rows.map((row) => row.read<String>('revision_id')),
    );
  }

  Future<PersistentRecoveryState> recoveryState() async {
    final counts = await database
        .customSelect(
          'SELECT '
          '(SELECT COUNT(*) FROM notes WHERE dirty = 1) AS dirty_drafts, '
          '(SELECT COUNT(*) FROM revisions) AS revisions, '
          '(SELECT COUNT(*) FROM sync_outbox) AS pending_objects, '
          '(SELECT COUNT(*) FROM conflicts WHERE status = \'open\') '
          'AS open_conflicts, '
          '(SELECT next_event_sequence FROM vault_state WHERE singleton_id = 1) '
          'AS next_event_sequence',
        )
        .getSingle();
    return PersistentRecoveryState(
      dirtyDrafts: counts.read<int>('dirty_drafts'),
      revisions: counts.read<int>('revisions'),
      pendingObjects: counts.read<int>('pending_objects'),
      openConflicts: counts.read<int>('open_conflicts'),
      nextEventSequence: counts.read<int>('next_event_sequence'),
    );
  }

  Future<bool> integrityCheck() async {
    final row = await database
        .customSelect('PRAGMA integrity_check')
        .getSingle();
    return row.data.values.single == 'ok';
  }

  Future<QueryRow> _requireVaultRow() async {
    final row = await database
        .customSelect(
          'SELECT vault_id, vault_generation, local_device_id, '
          'next_event_sequence FROM vault_state WHERE singleton_id = 1',
        )
        .getSingleOrNull();
    if (row == null) {
      throw StateError('Vault must be initialized before committing drafts');
    }
    return row;
  }

  Future<bool> _isNoOpDraft(NoteDraft draft) async {
    if (draft.baseRevisionIds.isEmpty) {
      return draft.deleted;
    }
    if (draft.baseRevisionIds.length != 1) {
      return false;
    }
    final row = await database
        .customSelect(
          'SELECT canonical_payload_json, payload_hash FROM revisions '
          'WHERE revision_id = ?',
          variables: <Variable>[
            Variable.withString(draft.baseRevisionIds.single),
          ],
        )
        .getSingleOrNull();
    if (row == null) {
      throw StateError('Draft base revision is missing locally');
    }
    final revision = _revisionFromRow(row);
    return revision.contentHash == sha256HexJson(draft.contentPayload);
  }

  Future<void> _insertRevision(Revision revision) async {
    await database.customInsert(
      'INSERT INTO revisions ('
      'revision_id, vault_id, vault_generation, note_id, device_id, '
      'operation, format, title, body_json, body_text, tags_json, '
      'canonical_payload_json, payload_hash, created_at_ms'
      ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: <Variable>[
        Variable.withString(revision.revisionId),
        Variable.withString(revision.vaultId),
        Variable.withInt(revision.vaultGeneration),
        Variable.withString(revision.noteId),
        Variable.withString(revision.deviceId),
        Variable.withString(revision.operation.wireName),
        Variable.withString(revision.format.wireName),
        Variable.withString(revision.title),
        Variable.withString(canonicalJson(revision.body)),
        Variable.withString(_searchableBody(revision.format, revision.body)),
        Variable.withString(canonicalJson(revision.tags)),
        Variable.withString(canonicalJson(revision.payloadFields)),
        Variable.withString(revision.payloadHash),
        Variable.withInt(revision.createdAtUtc.millisecondsSinceEpoch),
      ],
    );
    for (var index = 0; index < revision.parentRevisionIds.length; index += 1) {
      await database.customInsert(
        'INSERT INTO revision_parents ('
        'revision_id, parent_revision_id, parent_order'
        ') VALUES (?, ?, ?)',
        variables: <Variable>[
          Variable.withString(revision.revisionId),
          Variable.withString(revision.parentRevisionIds[index]),
          Variable.withInt(index),
        ],
      );
    }
  }

  Future<void> _insertEvent(SyncEvent event) async {
    await database.customInsert(
      'INSERT INTO sync_events ('
      'event_id, vault_id, vault_generation, device_id, sequence, event_type, '
      'object_key, object_hash, occurred_at_ms'
      ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)',
      variables: <Variable>[
        Variable.withString(event.eventId),
        Variable.withString(event.vaultId),
        Variable.withInt(event.vaultGeneration),
        Variable.withString(event.deviceId),
        Variable.withInt(event.sequence),
        Variable.withString(event.eventType),
        Variable.withString(event.objectKey),
        Variable.withString(event.objectHash),
        Variable.withInt(event.occurredAtUtc.millisecondsSinceEpoch),
      ],
    );
  }

  Future<void> _insertEventIdempotently(SyncEvent event) async {
    final existing = await database
        .customSelect(
          'SELECT event_id, object_key, object_hash FROM sync_events '
          'WHERE event_id = ? OR (device_id = ? AND sequence = ?) LIMIT 1',
          variables: <Variable>[
            Variable.withString(event.eventId),
            Variable.withString(event.deviceId),
            Variable.withInt(event.sequence),
          ],
        )
        .getSingleOrNull();
    if (existing == null) {
      await _insertEvent(event);
      return;
    }
    if (existing.read<String>('event_id') != event.eventId ||
        existing.read<String>('object_key') != event.objectKey ||
        existing.read<String>('object_hash') != event.objectHash) {
      throw RemoteObjectCorruptedException(
        'Event sequence ${event.deviceId}/${event.sequence} is not immutable',
      );
    }
  }

  Future<void> _insertOutbox({
    required String key,
    required String kind,
    required Uint8List bytes,
    required DateTime createdAtUtc,
    String? dependencyKey,
  }) async {
    await database.customInsert(
      'INSERT INTO sync_outbox ('
      'object_key, object_kind, payload, payload_hash, dependency_key, '
      'created_at_ms'
      ') VALUES (?, ?, ?, ?, ?, ?)',
      variables: <Variable>[
        Variable.withString(key),
        Variable.withString(kind),
        Variable.withBlob(bytes),
        Variable.withString(sha256HexBytes(bytes)),
        Variable<String>(dependencyKey),
        Variable.withInt(createdAtUtc.millisecondsSinceEpoch),
      ],
    );
  }

  Future<void> _updateHeads(Revision revision) async {
    await database.customUpdate(
      'WITH RECURSIVE ancestors(revision_id) AS ('
      'SELECT parent_revision_id FROM revision_parents WHERE revision_id = ? '
      'UNION '
      'SELECT rp.parent_revision_id FROM revision_parents rp '
      'JOIN ancestors a ON rp.revision_id = a.revision_id'
      ') DELETE FROM note_heads WHERE note_id = ? '
      'AND revision_id IN (SELECT revision_id FROM ancestors)',
      variables: <Variable>[
        Variable.withString(revision.revisionId),
        Variable.withString(revision.noteId),
      ],
      updates: <TableInfo<Table, Object?>>{database.noteHeads},
    );
    final isAlreadySuperseded = await database
        .customSelect(
          'WITH RECURSIVE ancestors(revision_id) AS ('
          'SELECT rp.parent_revision_id FROM revision_parents rp '
          'JOIN note_heads h ON h.revision_id = rp.revision_id '
          'WHERE h.note_id = ? '
          'UNION '
          'SELECT rp.parent_revision_id FROM revision_parents rp '
          'JOIN ancestors a ON rp.revision_id = a.revision_id'
          ') SELECT 1 AS found FROM ancestors WHERE revision_id = ? LIMIT 1',
          variables: <Variable>[
            Variable.withString(revision.noteId),
            Variable.withString(revision.revisionId),
          ],
        )
        .getSingleOrNull();
    if (isAlreadySuperseded == null) {
      await database.customInsert(
        'INSERT OR IGNORE INTO note_heads (note_id, revision_id) VALUES (?, ?)',
        variables: <Variable>[
          Variable.withString(revision.noteId),
          Variable.withString(revision.revisionId),
        ],
      );
    }
  }

  Future<void> _materializeCommittedNote(
    NoteDraft draft,
    Revision revision,
  ) async {
    final cleanDraft = NoteDraft(
      noteId: draft.noteId,
      format: draft.format,
      title: draft.title,
      body: draft.body,
      tags: draft.tags,
      baseRevisionIds: <String>[revision.revisionId],
      updatedAtUtc: revision.createdAtUtc,
      deleted: revision.operation == RevisionOperation.tombstone,
    );
    await database.customUpdate(
      'UPDATE notes SET format = ?, title = ?, draft_json = ?, '
      'body_text = ?, tags_json = ?, '
      'tags_text = ?, base_revision_ids_json = ?, dirty = 0, '
      'is_deleted = ?, last_committed_revision_id = ?, updated_at_ms = ? '
      'WHERE note_id = ?',
      variables: <Variable>[
        Variable.withString(draft.format.wireName),
        Variable.withString(draft.title),
        Variable.withString(_draftJson(cleanDraft)),
        Variable.withString(_searchableBody(draft.format, draft.body)),
        Variable.withString(canonicalJson(draft.tags)),
        Variable.withString(draft.tags.join(' ')),
        Variable.withString(canonicalJson(<String>[revision.revisionId])),
        Variable.withInt(cleanDraft.deleted ? 1 : 0),
        Variable.withString(revision.revisionId),
        Variable.withInt(revision.createdAtUtc.millisecondsSinceEpoch),
        Variable.withString(draft.noteId),
      ],
      updates: <TableInfo<Table, Object?>>{database.notes},
    );
  }

  Future<void> _materializeRemoteNote(String noteId) async {
    final existing = await database
        .customSelect(
          'SELECT dirty FROM notes WHERE note_id = ?',
          variables: <Variable>[Variable.withString(noteId)],
        )
        .getSingleOrNull();
    if (existing?.read<int>('dirty') == 1) {
      return;
    }
    final heads = await noteHeads(noteId);
    if (heads.isEmpty) {
      return;
    }

    Revision? selected;
    for (final head in heads) {
      final candidate = await loadRevision(head);
      if (candidate == null) {
        throw RemoteObjectCorruptedException('Missing local head $head');
      }
      if (selected == null ||
          candidate.createdAtUtc.isAfter(selected.createdAtUtc) ||
          (candidate.createdAtUtc == selected.createdAtUtc &&
              candidate.revisionId.compareTo(selected.revisionId) > 0)) {
        selected = candidate;
      }
    }
    if (heads.length > 1 && existing != null) {
      return;
    }

    final revision = selected!;
    final materialized = NoteDraft(
      noteId: revision.noteId,
      format: revision.format,
      title: revision.title,
      body: revision.body,
      tags: revision.tags,
      baseRevisionIds: heads,
      updatedAtUtc: revision.createdAtUtc,
      deleted: revision.operation == RevisionOperation.tombstone,
    );
    final createdAt = revision.createdAtUtc.millisecondsSinceEpoch;
    await database.customInsert(
      'INSERT INTO notes ('
      'note_id, format, title, draft_json, body_text, tags_json, tags_text, '
      'base_revision_ids_json, dirty, is_deleted, '
      'last_committed_revision_id, created_at_ms, updated_at_ms'
      ') VALUES (?, ?, ?, ?, ?, ?, ?, ?, 0, ?, ?, ?, ?) '
      'ON CONFLICT(note_id) DO UPDATE SET '
      'format = excluded.format, title = excluded.title, '
      'draft_json = excluded.draft_json, body_text = excluded.body_text, '
      'tags_json = excluded.tags_json, tags_text = excluded.tags_text, '
      'base_revision_ids_json = excluded.base_revision_ids_json, '
      'is_deleted = excluded.is_deleted, '
      'last_committed_revision_id = excluded.last_committed_revision_id, '
      'updated_at_ms = excluded.updated_at_ms '
      'WHERE notes.dirty = 0',
      variables: <Variable>[
        Variable.withString(revision.noteId),
        Variable.withString(revision.format.wireName),
        Variable.withString(revision.title),
        Variable.withString(_draftJson(materialized)),
        Variable.withString(_searchableBody(revision.format, revision.body)),
        Variable.withString(canonicalJson(revision.tags)),
        Variable.withString(revision.tags.join(' ')),
        Variable.withString(canonicalJson(heads)),
        Variable.withInt(materialized.deleted ? 1 : 0),
        Variable.withString(revision.revisionId),
        Variable.withInt(createdAt),
        Variable.withInt(createdAt),
      ],
    );
  }

  Future<void> _refreshConflict(String noteId, DateTime nowUtc) async {
    final headRows = await database
        .customSelect(
          'SELECT revision_id FROM note_heads WHERE note_id = ? '
          'ORDER BY revision_id',
          variables: <Variable>[Variable.withString(noteId)],
        )
        .get();
    final heads = headRows
        .map((row) => row.read<String>('revision_id'))
        .toList(growable: false);
    await database.customUpdate(
      'UPDATE conflicts SET status = \'resolved\', resolved_at_ms = ? '
      'WHERE note_id = ? AND status = \'open\'',
      variables: <Variable>[
        Variable.withInt(nowUtc.millisecondsSinceEpoch),
        Variable.withString(noteId),
      ],
      updates: <TableInfo<Table, Object?>>{database.conflicts},
    );
    if (heads.length > 1) {
      final conflictHash = sha256HexJson(<String, Object?>{
        'heads': heads,
        'noteId': noteId,
      });
      await database.customInsert(
        'INSERT INTO conflicts ('
        'conflict_id, note_id, head_revision_ids_json, status, created_at_ms'
        ') VALUES (?, ?, ?, \'open\', ?) '
        'ON CONFLICT(conflict_id) DO UPDATE SET status = \'open\', '
        'resolved_at_ms = NULL',
        variables: <Variable>[
          Variable.withString('conflict-${conflictHash.substring(0, 32)}'),
          Variable.withString(noteId),
          Variable.withString(canonicalJson(heads)),
          Variable.withInt(nowUtc.millisecondsSinceEpoch),
        ],
      );
    }
  }
}

final class _ValidatedPortableImport {
  const _ValidatedPortableImport({required this.revisions});

  final List<Revision> revisions;
}

_ValidatedPortableImport _validatePortableImport(ExportSnapshot snapshot) {
  final vault = snapshot.vault;
  if (vault.vaultId.isEmpty ||
      vault.generation < 1 ||
      vault.protocolVersion != 1) {
    throw const PortableImportException('Invalid exported Vault identity');
  }

  final notes = <String, ExportNoteState>{};
  for (final note in snapshot.notes) {
    final noteId = note.draft.noteId;
    if (noteId.isEmpty || notes.containsKey(noteId)) {
      throw PortableImportException('Duplicate or empty note ID: $noteId');
    }
    notes[noteId] = note;
    if (note.createdAtUtc.isAfter(note.draft.updatedAtUtc)) {
      throw PortableImportException('Note timestamps are invalid: $noteId');
    }
    if (note.draft.format == ContentFormat.markdown &&
        note.draft.body is! String) {
      throw PortableImportException('Markdown note body is invalid: $noteId');
    }
  }

  final revisions = <String, Revision>{};
  for (final revision in snapshot.revisions) {
    if (revision.revisionId.isEmpty ||
        revisions.containsKey(revision.revisionId)) {
      throw PortableImportException(
        'Duplicate or empty revision ID: ${revision.revisionId}',
      );
    }
    revisions[revision.revisionId] = revision;
    if (!notes.containsKey(revision.noteId)) {
      throw PortableImportException(
        'Revision references a missing note: ${revision.revisionId}',
      );
    }
    if (revision.vaultId != vault.vaultId ||
        revision.vaultGeneration != vault.generation) {
      throw PortableImportException(
        'Revision belongs to another Vault: ${revision.revisionId}',
      );
    }
  }

  final children = <String, List<String>>{
    for (final revisionId in revisions.keys) revisionId: <String>[],
  };
  final indegree = <String, int>{
    for (final revisionId in revisions.keys) revisionId: 0,
  };
  for (final revision in revisions.values) {
    for (final parentId in revision.parentRevisionIds) {
      final parent = revisions[parentId];
      if (parent == null || parent.noteId != revision.noteId) {
        throw PortableImportException(
          'Revision parent is missing or belongs to another note: '
          '${revision.revisionId} -> $parentId',
        );
      }
      children[parentId]!.add(revision.revisionId);
      indegree[revision.revisionId] = indegree[revision.revisionId]! + 1;
    }
  }

  int compareRevisionIds(String left, String right) {
    final time = revisions[left]!.createdAtUtc.compareTo(
      revisions[right]!.createdAtUtc,
    );
    return time != 0 ? time : left.compareTo(right);
  }

  final ready =
      indegree.entries
          .where((entry) => entry.value == 0)
          .map((entry) => entry.key)
          .toList()
        ..sort(compareRevisionIds);
  final ordered = <Revision>[];
  while (ready.isNotEmpty) {
    final revisionId = ready.removeAt(0);
    ordered.add(revisions[revisionId]!);
    for (final childId in children[revisionId]!) {
      final remaining = indegree[childId]! - 1;
      indegree[childId] = remaining;
      if (remaining == 0) {
        ready.add(childId);
        ready.sort(compareRevisionIds);
      }
    }
  }
  if (ordered.length != revisions.length) {
    throw const PortableImportException('Revision history contains a cycle');
  }

  final headsByNote = <String, Set<String>>{
    for (final noteId in notes.keys) noteId: <String>{},
  };
  for (final revision in revisions.values) {
    if (children[revision.revisionId]!.isEmpty) {
      headsByNote[revision.noteId]!.add(revision.revisionId);
    }
  }
  for (final entry in notes.entries) {
    final noteId = entry.key;
    final note = entry.value;
    for (final baseId in note.draft.baseRevisionIds) {
      if (revisions[baseId]?.noteId != noteId) {
        throw PortableImportException(
          'Note references a missing base revision: $noteId -> $baseId',
        );
      }
    }
    final lastCommittedId = note.lastCommittedRevisionId;
    if (lastCommittedId != null &&
        revisions[lastCommittedId]?.noteId != noteId) {
      throw PortableImportException(
        'Note references a missing committed revision: $noteId',
      );
    }
    if (!note.dirty) {
      if (lastCommittedId == null) {
        throw PortableImportException(
          'Clean note has no committed revision: $noteId',
        );
      }
      if (revisions[lastCommittedId]!.contentHash !=
          sha256HexJson(note.draft.contentPayload)) {
        throw PortableImportException(
          'Clean note does not match its committed revision: $noteId',
        );
      }
    }
  }

  final conflictIds = <String>{};
  final openConflictNotes = <String>{};
  for (final conflict in snapshot.conflicts) {
    if (conflict.conflictId.isEmpty || !conflictIds.add(conflict.conflictId)) {
      throw PortableImportException(
        'Duplicate or empty conflict ID: ${conflict.conflictId}',
      );
    }
    if (!notes.containsKey(conflict.noteId) ||
        conflict.headRevisionIds.length < 2) {
      throw PortableImportException(
        'Conflict is missing its note or heads: ${conflict.conflictId}',
      );
    }
    for (final headId in conflict.headRevisionIds) {
      if (revisions[headId]?.noteId != conflict.noteId) {
        throw PortableImportException(
          'Conflict references a missing revision: ${conflict.conflictId}',
        );
      }
    }
    if (conflict.status == ExportConflictStatus.open) {
      if (!openConflictNotes.add(conflict.noteId) ||
          !_sameStringSet(
            conflict.headRevisionIds,
            headsByNote[conflict.noteId]!,
          )) {
        throw PortableImportException(
          'Open conflict does not match current DAG heads: '
          '${conflict.conflictId}',
        );
      }
      if (conflict.resolvedAtUtc != null) {
        throw PortableImportException(
          'Open conflict has a resolution timestamp: ${conflict.conflictId}',
        );
      }
    } else if (conflict.resolvedAtUtc == null) {
      throw PortableImportException(
        'Resolved conflict has no resolution timestamp: ${conflict.conflictId}',
      );
    }
  }
  return _ValidatedPortableImport(revisions: List.unmodifiable(ordered));
}

bool _sameStringSet(Iterable<String> left, Set<String> right) {
  final leftSet = left.toSet();
  return leftSet.length == right.length && leftSet.containsAll(right);
}

void _verifyVaultRow(QueryRow row, VaultIdentity vault, String deviceId) {
  final remoteVaultId = row.read<String>('vault_id');
  final remoteGeneration = row.read<int>('vault_generation');
  final remoteProtocol = row.read<int>('protocol_version');
  final localDeviceId = row.read<String>('local_device_id');
  if (remoteVaultId != vault.vaultId) {
    throw VaultMismatchException(
      'Database vault $remoteVaultId does not match ${vault.vaultId}',
    );
  }
  if (remoteGeneration != vault.generation) {
    throw VaultGenerationChangedException(
      'Database generation $remoteGeneration does not match ${vault.generation}',
    );
  }
  if (remoteProtocol != vault.protocolVersion) {
    throw SyncException('Unsupported local protocol version $remoteProtocol');
  }
  if (localDeviceId != deviceId) {
    throw StateError(
      'Database belongs to device $localDeviceId, not requested device $deviceId',
    );
  }
}

void _verifyIdentity({
  required VaultIdentity expected,
  required String vaultId,
  required int generation,
}) {
  if (vaultId != expected.vaultId) {
    throw VaultMismatchException(
      'Expected vault ${expected.vaultId}, received $vaultId',
    );
  }
  if (generation != expected.generation) {
    throw VaultGenerationChangedException(
      'Expected generation ${expected.generation}, received $generation',
    );
  }
}

String _revisionIdFromObjectKey(String objectKey) {
  if (!objectKey.startsWith('${ProtocolPaths.root}revisions/') ||
      !objectKey.endsWith('.json')) {
    throw RemoteObjectCorruptedException(
      'Invalid revision object key: $objectKey',
    );
  }
  final filename = objectKey.substring(objectKey.lastIndexOf('/') + 1);
  final revisionId = filename.substring(0, filename.length - '.json'.length);
  if (revisionId.isEmpty) {
    throw RemoteObjectCorruptedException(
      'Invalid revision object key: $objectKey',
    );
  }
  return revisionId;
}

Revision _revisionFromRow(QueryRow row) {
  final payload =
      jsonDecode(row.read<String>('canonical_payload_json'))
          as Map<String, Object?>;
  return Revision.fromJson(<String, Object?>{
    ...payload,
    'payloadHash': row.read<String>('payload_hash'),
  });
}

String _draftJson(NoteDraft draft) => canonicalJson(<String, Object?>{
  ...draft.contentPayload,
  'baseRevisionIds': draft.baseRevisionIds,
  'updatedAt': draft.updatedAtUtc.toUtc().toIso8601String(),
});

NoteDraft _draftFromRow(QueryRow row) {
  final payload =
      jsonDecode(row.read<String>('draft_json')) as Map<String, Object?>;
  return NoteDraft(
    noteId: row.read<String>('note_id'),
    format: ContentFormat.fromWireName(row.read<String>('format')),
    title: row.read<String>('title'),
    body: payload['body']!,
    tags: (jsonDecode(row.read<String>('tags_json')) as List).cast<String>(),
    baseRevisionIds:
        (jsonDecode(row.read<String>('base_revision_ids_json')) as List)
            .cast<String>(),
    updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(
      row.read<int>('updated_at_ms'),
      isUtc: true,
    ),
    deleted: row.read<int>('is_deleted') == 1,
  );
}

DurableOutboxEntry _outboxFromRow(QueryRow row) => DurableOutboxEntry(
  outboxId: row.read<int>('outbox_id'),
  objectKey: row.read<String>('object_key'),
  kind: row.read<String>('object_kind'),
  payload: row.read<Uint8List>('payload'),
  payloadHash: row.read<String>('payload_hash'),
  dependencyKey: row.readNullable<String>('dependency_key'),
  attemptCount: row.read<int>('attempt_count'),
  nextAttemptAtUtc: DateTime.fromMillisecondsSinceEpoch(
    row.read<int>('next_attempt_at_ms'),
    isUtc: true,
  ),
  lastError: row.readNullable<String>('last_error'),
  createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
    row.read<int>('created_at_ms'),
    isUtc: true,
  ),
);

StoredNoteSummary _summaryFromRow(QueryRow row) => StoredNoteSummary(
  noteId: row.read<String>('note_id'),
  title: row.read<String>('title'),
  bodyPreview: row.read<String>('body_text'),
  format: ContentFormat.fromWireName(row.read<String>('format')),
  updatedAtUtc: DateTime.fromMillisecondsSinceEpoch(
    row.read<int>('updated_at_ms'),
    isUtc: true,
  ),
  deleted: row.read<int>('is_deleted') == 1,
);

StoredConflict _conflictFromRow(QueryRow row) => StoredConflict(
  conflictId: row.read<String>('conflict_id'),
  noteId: row.read<String>('note_id'),
  headRevisionIds: List.unmodifiable(
    (jsonDecode(row.read<String>('head_revision_ids_json')) as List)
        .cast<String>(),
  ),
  createdAtUtc: DateTime.fromMillisecondsSinceEpoch(
    row.read<int>('created_at_ms'),
    isUtc: true,
  ),
);

bool _sameStringList(List<String> left, List<String> right) {
  if (left.length != right.length) {
    return false;
  }
  for (var index = 0; index < left.length; index += 1) {
    if (left[index] != right[index]) {
      return false;
    }
  }
  return true;
}

String _searchableBody(ContentFormat format, Object body) {
  if (format == ContentFormat.markdown) {
    return body as String;
  }
  final text = <String>[];
  void collect(Object? node) {
    if (node is Map) {
      final ownText = node['text'];
      if (ownText is String && ownText.isNotEmpty) {
        text.add(ownText);
      }
      for (final entry in node.entries) {
        if (entry.key != 'text') {
          collect(entry.value);
        }
      }
    } else if (node is Iterable) {
      for (final child in node) {
        collect(child);
      }
    }
  }

  collect(body);
  return text.join('\n');
}
