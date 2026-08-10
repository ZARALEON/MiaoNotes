import '../model/canonical_json.dart';
import '../model/revision.dart';
import '../model/sync_event.dart';
import '../model/vault_identity.dart';
import '../storage/object_store.dart';
import 'protocol_paths.dart';
import 'sync_exception.dart';
import 'sync_replica.dart';

final class SyncRunStats {
  const SyncRunStats({
    required this.committedDrafts,
    required this.pulledEvents,
    required this.pushedObjects,
  });

  final int committedDrafts;
  final int pulledEvents;
  final int pushedObjects;
}

/// Minimal protocol-v1 coordinator. It performs no startup-time work on its own.
final class SyncEngine {
  const SyncEngine({required this.replica, required this.store});

  final SyncReplica replica;
  final ObjectStore store;

  Future<SyncRunStats> syncOnce() async {
    final committed = replica.commitAllDrafts();
    return syncCommitted(committedDrafts: committed);
  }

  /// Synchronizes only already-committed immutable objects.
  ///
  /// UI clients use this after their local commit coordinator has serialized
  /// mutable editor state. It therefore never reaches into live Drafts.
  Future<SyncRunStats> syncCommitted({int committedDrafts = 0}) async {
    await _verifyOrCreateVault();
    final pulled = await pull();
    final pushed = await push();
    return SyncRunStats(
      committedDrafts: committedDrafts,
      pulledEvents: pulled,
      pushedObjects: pushed,
    );
  }

  Future<int> pull() async {
    final keys = await store.listKeys(ProtocolPaths.eventsPrefix);
    final events = <SyncEvent>[];
    for (final key in keys) {
      final object = await store.get(key);
      if (object == null) {
        throw RemoteObjectCorruptedException('Listed event is missing: $key');
      }
      final event = SyncEvent.fromBytes(object.bytes);
      final expectedKey = ProtocolPaths.event(
        event.deviceId,
        event.sequence,
        event.eventId,
      );
      if (expectedKey != key) {
        throw RemoteObjectCorruptedException(
          'Event identity does not match object key: $key',
        );
      }
      events.add(event);
    }
    events.sort((left, right) {
      final deviceOrder = left.deviceId.compareTo(right.deviceId);
      return deviceOrder != 0
          ? deviceOrder
          : left.sequence.compareTo(right.sequence);
    });

    var pulled = 0;
    for (final event in events) {
      _checkIdentity(event.vaultId, event.vaultGeneration);
      final cursor = replica.cursorFor(event.deviceId);
      if (event.sequence <= cursor) {
        continue;
      }
      if (event.sequence != cursor + 1) {
        throw EventGapException(
          'Event gap for ${event.deviceId}: expected ${cursor + 1}, '
          'found ${event.sequence}',
        );
      }
      await _loadRevisionTree(event.objectKey, event.objectHash);
      replica.advanceCursor(event.deviceId, event.sequence);
      pulled += 1;
    }
    return pulled;
  }

  Future<int> push() async {
    var pushed = 0;
    final pending = List<PendingObject>.of(replica.outboxEntries);
    for (final object in pending) {
      final dependency = object.dependencyKey;
      if (dependency != null &&
          replica.outboxEntries.any((entry) => entry.key == dependency)) {
        throw SyncException('Outbox dependency was not uploaded: $dependency');
      }
      try {
        await store.putImmutable(object.key, object.bytes);
      } on Object catch (error) {
        replica.markOutboxAttempt(object.key, error);
        rethrow;
      }
      replica.removeOutboxObject(object.key);
      pushed += 1;
    }
    return pushed;
  }

  Future<void> _verifyOrCreateVault() async {
    final localBytes = replica.vault.toBytes();
    final existing = await store.get(ProtocolPaths.vaultConfig);
    if (existing == null) {
      try {
        await store.putImmutable(ProtocolPaths.vaultConfig, localBytes);
      } on ObjectStoreException {
        final afterFailure = await store.get(ProtocolPaths.vaultConfig);
        if (afterFailure == null) {
          rethrow;
        }
        _verifyVault(VaultIdentity.fromBytes(afterFailure.bytes));
      }
      return;
    }
    _verifyVault(VaultIdentity.fromBytes(existing.bytes));
  }

  Future<void> _loadRevisionTree(
    String objectKey,
    String? expectedObjectHash,
  ) async {
    final object = await store.get(objectKey);
    if (object == null) {
      throw RemoteObjectCorruptedException(
        'Referenced revision is missing: $objectKey',
      );
    }
    if (expectedObjectHash != null &&
        sha256HexBytes(object.bytes) != expectedObjectHash) {
      throw RemoteObjectCorruptedException(
        'Revision object hash mismatch: $objectKey',
      );
    }
    final revision = Revision.fromBytes(object.bytes);
    _checkIdentity(revision.vaultId, revision.vaultGeneration);
    final expectedKey = ProtocolPaths.revision(
      revision.noteId,
      revision.revisionId,
    );
    if (expectedKey != objectKey) {
      throw RemoteObjectCorruptedException(
        'Revision identity does not match object key: $objectKey',
      );
    }
    if (replica.hasRevision(revision.revisionId)) {
      return;
    }
    for (final parentId in revision.parentRevisionIds) {
      if (!replica.hasRevision(parentId)) {
        await _loadRevisionTree(
          ProtocolPaths.revision(revision.noteId, parentId),
          null,
        );
      }
    }
    replica.applyRevision(revision);
  }

  void _verifyVault(VaultIdentity remote) {
    _checkIdentity(remote.vaultId, remote.generation);
    if (remote.protocolVersion != replica.vault.protocolVersion) {
      throw SyncException(
        'Unsupported remote protocol version ${remote.protocolVersion}',
      );
    }
  }

  void _checkIdentity(String vaultId, int generation) {
    if (vaultId != replica.vault.vaultId) {
      throw VaultMismatchException(
        'Remote vault $vaultId does not match ${replica.vault.vaultId}',
      );
    }
    if (generation != replica.vault.generation) {
      throw VaultGenerationChangedException(
        'Remote generation $generation does not match '
        '${replica.vault.generation}',
      );
    }
  }
}
