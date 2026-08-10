import 'dart:collection';
import 'dart:typed_data';

import '../model/canonical_json.dart';
import '../model/content_format.dart';
import '../model/note_draft.dart';
import '../model/revision.dart';
import '../model/sync_event.dart';
import '../model/vault_identity.dart';
import 'id_factory.dart';
import 'protocol_paths.dart';
import 'sync_exception.dart';

typedef UtcClock = DateTime Function();

enum PendingObjectKind { revision, event }

final class PendingObject {
  PendingObject({
    required this.key,
    required this.kind,
    required List<int> bytes,
    required this.payloadHash,
    required this.createdAtUtc,
    this.dependencyKey,
  }) : bytes = Uint8List.fromList(bytes);

  final String key;
  final PendingObjectKind kind;
  final Uint8List bytes;
  final String payloadHash;
  final DateTime createdAtUtc;
  final String? dependencyKey;
  int attemptCount = 0;
  String? lastError;
}

/// In-memory protocol replica used by the simulator.
///
/// Its maps correspond directly to Schema v1 tables. A production repository
/// will persist each mutation transactionally with Drift.
final class SyncReplica {
  SyncReplica({
    required this.vault,
    required this.deviceId,
    IdFactory? idFactory,
    UtcClock? clock,
  }) : idFactory = idFactory ?? UuidV7IdFactory(),
       clock = clock ?? (() => DateTime.now().toUtc());

  final VaultIdentity vault;
  final String deviceId;
  final IdFactory idFactory;
  final UtcClock clock;

  final Map<String, NoteDraft> _drafts = <String, NoteDraft>{};
  final Map<String, Revision> _revisions = <String, Revision>{};
  final Map<String, Set<String>> _heads = <String, Set<String>>{};
  final LinkedHashMap<String, PendingObject> _outbox = LinkedHashMap();
  final Map<String, int> _cursors = <String, int>{};
  int _nextEventSequence = 1;

  int get draftCount => _drafts.length;
  int get revisionCount => _revisions.length;
  int get outboxCount => _outbox.length;
  Map<String, int> get cursors => Map.unmodifiable(_cursors);
  List<PendingObject> get outboxEntries => List.unmodifiable(_outbox.values);

  String createMarkdownNote({
    String title = '',
    String body = '',
    Iterable<String> tags = const <String>[],
  }) {
    final now = clock().toUtc();
    final noteId = idFactory.next(now);
    saveDraft(
      noteId: noteId,
      format: ContentFormat.markdown,
      title: title,
      body: body,
      tags: tags,
    );
    return noteId;
  }

  void editMarkdownNote(
    String noteId, {
    String? title,
    String? body,
    Iterable<String>? tags,
  }) {
    final currentDraft = _drafts[noteId];
    final base = currentDraft ?? _singleHeadAsDraft(noteId);
    saveDraft(
      noteId: noteId,
      format: ContentFormat.markdown,
      title: title ?? base.title,
      body: body ?? base.body,
      tags: tags ?? base.tags,
    );
  }

  void deleteNote(String noteId) {
    final currentDraft = _drafts[noteId];
    final base = currentDraft ?? _singleHeadAsDraft(noteId);
    saveDraft(
      noteId: noteId,
      format: base.format,
      title: base.title,
      body: base.body,
      tags: base.tags,
      deleted: true,
    );
  }

  void saveDraft({
    required String noteId,
    required ContentFormat format,
    required String title,
    required Object body,
    Iterable<String> tags = const <String>[],
    bool deleted = false,
  }) {
    if (format == ContentFormat.markdown && body is! String) {
      throw ArgumentError.value(body, 'body', 'Markdown body must be a string');
    }
    if (format == ContentFormat.miaoDoc && body is! Map<String, Object?>) {
      throw ArgumentError.value(
        body,
        'body',
        'MiaoDoc body must be a JSON map',
      );
    }
    final existingDraft = _drafts[noteId];
    final bases = existingDraft?.baseRevisionIds ?? noteHeads(noteId);
    _drafts[noteId] = NoteDraft(
      noteId: noteId,
      format: format,
      title: title,
      body: body,
      tags: tags,
      baseRevisionIds: bases,
      updatedAtUtc: clock().toUtc(),
      deleted: deleted,
    );
  }

  Revision? commitDraft(String noteId) {
    final draft = _drafts[noteId];
    if (draft == null) {
      return null;
    }

    if (draft.baseRevisionIds.length == 1) {
      final base = _revisions[draft.baseRevisionIds.single];
      if (base != null &&
          base.contentHash == sha256HexJson(draft.contentPayload)) {
        _drafts.remove(noteId);
        return null;
      }
    } else if (draft.baseRevisionIds.isEmpty && draft.deleted) {
      _drafts.remove(noteId);
      return null;
    }

    final now = clock().toUtc();
    final revision = Revision.create(
      vaultId: vault.vaultId,
      vaultGeneration: vault.generation,
      revisionId: idFactory.next(now),
      deviceId: deviceId,
      createdAtUtc: now,
      draft: draft,
    );
    applyRevision(revision);

    final revisionKey = ProtocolPaths.revision(noteId, revision.revisionId);
    final revisionBytes = revision.toBytes();
    _outbox[revisionKey] = PendingObject(
      key: revisionKey,
      kind: PendingObjectKind.revision,
      bytes: revisionBytes,
      payloadHash: sha256HexBytes(revisionBytes),
      createdAtUtc: now,
    );

    final event = SyncEvent.revisionCommitted(
      vaultId: vault.vaultId,
      vaultGeneration: vault.generation,
      eventId: idFactory.next(now),
      deviceId: deviceId,
      sequence: _nextEventSequence,
      objectKey: revisionKey,
      objectHash: sha256HexBytes(revisionBytes),
      occurredAtUtc: now,
    );
    _nextEventSequence += 1;
    final eventKey = ProtocolPaths.event(
      deviceId,
      event.sequence,
      event.eventId,
    );
    final eventBytes = event.toBytes();
    _outbox[eventKey] = PendingObject(
      key: eventKey,
      kind: PendingObjectKind.event,
      bytes: eventBytes,
      payloadHash: sha256HexBytes(eventBytes),
      createdAtUtc: now,
      dependencyKey: revisionKey,
    );
    _drafts.remove(noteId);
    return revision;
  }

  int commitAllDrafts() {
    final noteIds = _drafts.keys.toList(growable: false);
    var committed = 0;
    for (final noteId in noteIds) {
      if (commitDraft(noteId) != null) {
        committed += 1;
      }
    }
    return committed;
  }

  bool hasRevision(String revisionId) => _revisions.containsKey(revisionId);

  Revision? revisionById(String revisionId) => _revisions[revisionId];

  void applyRevision(Revision revision) {
    _checkIdentity(revision.vaultId, revision.vaultGeneration);
    final existing = _revisions[revision.revisionId];
    if (existing != null) {
      if (existing.payloadHash != revision.payloadHash) {
        throw RemoteObjectCorruptedException(
          'Revision ID ${revision.revisionId} has multiple payloads',
        );
      }
      return;
    }
    for (final parent in revision.parentRevisionIds) {
      if (!_revisions.containsKey(parent)) {
        throw RemoteObjectCorruptedException(
          'Revision ${revision.revisionId} is missing parent $parent',
        );
      }
    }

    _revisions[revision.revisionId] = revision;
    final heads = _heads.putIfAbsent(revision.noteId, () => <String>{});
    final alreadySuperseded = heads.any(
      (head) => _isAncestor(revision.revisionId, head),
    );
    if (!alreadySuperseded) {
      heads.removeWhere((head) => _isAncestor(head, revision.revisionId));
      heads.add(revision.revisionId);
    }
  }

  List<String> noteHeads(String noteId) {
    final values = _heads[noteId]?.toList() ?? <String>[];
    values.sort();
    return List.unmodifiable(values);
  }

  bool hasConflict(String noteId) => noteHeads(noteId).length > 1;

  bool isDeleted(String noteId) {
    final heads = noteHeads(noteId);
    if (heads.length != 1) {
      return false;
    }
    return _revisions[heads.single]!.operation == RevisionOperation.tombstone;
  }

  String? markdownBody(String noteId) {
    final heads = noteHeads(noteId);
    if (heads.length != 1) {
      return null;
    }
    final revision = _revisions[heads.single]!;
    if (revision.operation == RevisionOperation.tombstone ||
        revision.format != ContentFormat.markdown) {
      return null;
    }
    return revision.body as String;
  }

  int cursorFor(String remoteDeviceId) => _cursors[remoteDeviceId] ?? 0;

  void advanceCursor(String remoteDeviceId, int sequence) {
    final current = cursorFor(remoteDeviceId);
    if (sequence != current + 1) {
      throw EventGapException(
        'Cursor for $remoteDeviceId expected ${current + 1}, got $sequence',
      );
    }
    _cursors[remoteDeviceId] = sequence;
  }

  void markOutboxAttempt(String key, Object error) {
    final pending = _outbox[key];
    if (pending == null) {
      return;
    }
    pending.attemptCount += 1;
    pending.lastError = error.toString();
  }

  void removeOutboxObject(String key) => _outbox.remove(key);

  NoteDraft _singleHeadAsDraft(String noteId) {
    final heads = noteHeads(noteId);
    if (heads.length != 1) {
      throw StateError(
        heads.isEmpty
            ? 'Unknown note: $noteId'
            : 'Note $noteId has unresolved concurrent heads',
      );
    }
    final revision = _revisions[heads.single]!;
    return NoteDraft(
      noteId: noteId,
      format: revision.format,
      title: revision.title,
      body: revision.body,
      tags: revision.tags,
      baseRevisionIds: heads,
      updatedAtUtc: clock().toUtc(),
      deleted: revision.operation == RevisionOperation.tombstone,
    );
  }

  bool _isAncestor(String candidate, String descendant) {
    if (candidate == descendant) {
      return true;
    }
    final pending = <String>[descendant];
    final visited = <String>{};
    while (pending.isNotEmpty) {
      final current = pending.removeLast();
      if (!visited.add(current)) {
        continue;
      }
      final revision = _revisions[current];
      if (revision == null) {
        continue;
      }
      if (revision.parentRevisionIds.contains(candidate)) {
        return true;
      }
      pending.addAll(revision.parentRevisionIds);
    }
    return false;
  }

  void _checkIdentity(String vaultId, int generation) {
    if (vaultId != vault.vaultId) {
      throw VaultMismatchException(
        'Expected vault ${vault.vaultId}, received $vaultId',
      );
    }
    if (generation != vault.generation) {
      throw VaultGenerationChangedException(
        'Expected generation ${vault.generation}, received $generation',
      );
    }
  }
}
