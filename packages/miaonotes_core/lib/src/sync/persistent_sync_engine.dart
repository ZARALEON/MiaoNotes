import '../database/persistent_store.dart';
import '../model/canonical_json.dart';
import '../model/revision.dart';
import '../model/sync_event.dart';
import '../model/vault_identity.dart';
import '../storage/object_store.dart';
import 'protocol_paths.dart';
import 'sync_engine.dart';
import 'sync_exception.dart';

/// Protocol-v1 coordinator whose local state survives process restarts.
final class PersistentSyncEngine {
  const PersistentSyncEngine({
    required this.localStore,
    required this.remoteStore,
    this.retryDelay = const Duration(seconds: 5),
  });

  final PersistentNoteStore localStore;
  final ObjectStore remoteStore;
  final Duration retryDelay;

  Future<SyncRunStats> syncOnce() async {
    final committed = await localStore.commitAllDirtyDrafts();
    return syncCommitted(committedDrafts: committed);
  }

  /// Synchronizes only immutable local state and never commits live Drafts.
  ///
  /// Interactive clients should prefer this entry point and let their local
  /// editor coordinator decide when mutable Drafts become Revisions.
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
    final vault = await localStore.vaultIdentity();
    final keys = await remoteStore.listKeys(ProtocolPaths.eventsPrefix);
    final events = <({String key, SyncEvent event})>[];
    for (final key in keys) {
      final object = await remoteStore.get(key);
      if (object == null) {
        throw RemoteObjectCorruptedException('Listed event is missing: $key');
      }
      final event = _parseEvent(object.bytes, key);
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
      _verifyIdentity(vault, event.vaultId, event.vaultGeneration);
      events.add((key: key, event: event));
    }
    events.sort((left, right) {
      final deviceOrder = left.event.deviceId.compareTo(right.event.deviceId);
      return deviceOrder != 0
          ? deviceOrder
          : left.event.sequence.compareTo(right.event.sequence);
    });

    var pulled = 0;
    for (final remoteEvent in events) {
      final event = remoteEvent.event;
      final cursor = await localStore.cursorFor(event.deviceId);
      if (event.sequence <= cursor) {
        continue;
      }
      if (event.sequence != cursor + 1) {
        throw EventGapException(
          'Event gap for ${event.deviceId}: expected ${cursor + 1}, '
          'found ${event.sequence}',
        );
      }
      final revisions = <Revision>[];
      await _collectRevisionTree(
        event.objectKey,
        event.objectHash,
        vault,
        revisions,
        <String>{},
      );
      await localStore.applyRemoteEvent(event: event, revisions: revisions);
      pulled += 1;
    }
    return pulled;
  }

  Future<int> push() async {
    var pushed = 0;
    while (true) {
      final pending = await localStore.loadReadyOutbox();
      if (pending.isEmpty) {
        return pushed;
      }
      var madeProgress = false;
      for (final object in pending) {
        final dependency = object.dependencyKey;
        if (dependency != null &&
            await localStore.isOutboxPending(dependency)) {
          return pushed;
        }
        if (sha256HexBytes(object.payload) != object.payloadHash) {
          throw RemoteObjectCorruptedException(
            'Local outbox payload is corrupted: ${object.objectKey}',
          );
        }
        try {
          await remoteStore.putImmutable(object.objectKey, object.payload);
        } on Object catch (error) {
          await localStore.recordOutboxFailure(
            object.outboxId,
            error,
            retryAfter: retryDelay,
          );
          rethrow;
        }
        await localStore.acknowledgeOutbox(object.outboxId);
        pushed += 1;
        madeProgress = true;
      }
      if (!madeProgress) {
        return pushed;
      }
    }
  }

  Future<void> _verifyOrCreateVault() async {
    final local = await localStore.vaultIdentity();
    final localBytes = local.toBytes();
    final existing = await remoteStore.get(ProtocolPaths.vaultConfig);
    if (existing == null) {
      try {
        await remoteStore.putImmutable(ProtocolPaths.vaultConfig, localBytes);
      } on ObjectStoreException {
        final afterFailure = await remoteStore.get(ProtocolPaths.vaultConfig);
        if (afterFailure == null) {
          rethrow;
        }
        _verifyRemoteVault(local, afterFailure.bytes);
      }
      return;
    }
    _verifyRemoteVault(local, existing.bytes);
  }

  Future<void> _collectRevisionTree(
    String objectKey,
    String? expectedHash,
    VaultIdentity vault,
    List<Revision> ordered,
    Set<String> visiting,
  ) async {
    final object = await remoteStore.get(objectKey);
    if (object == null) {
      throw RemoteObjectCorruptedException(
        'Referenced revision is missing: $objectKey',
      );
    }
    if (expectedHash != null && sha256HexBytes(object.bytes) != expectedHash) {
      throw RemoteObjectCorruptedException(
        'Revision object hash mismatch: $objectKey',
      );
    }
    final revision = _parseRevision(object.bytes, objectKey);
    _verifyIdentity(vault, revision.vaultId, revision.vaultGeneration);
    final expectedKey = ProtocolPaths.revision(
      revision.noteId,
      revision.revisionId,
    );
    if (expectedKey != objectKey) {
      throw RemoteObjectCorruptedException(
        'Revision identity does not match object key: $objectKey',
      );
    }
    if (await localStore.hasRevision(revision.revisionId) ||
        ordered.any((item) => item.revisionId == revision.revisionId)) {
      return;
    }
    if (!visiting.add(revision.revisionId)) {
      throw RemoteObjectCorruptedException(
        'Revision cycle detected at ${revision.revisionId}',
      );
    }
    for (final parent in revision.parentRevisionIds) {
      await _collectRevisionTree(
        ProtocolPaths.revision(revision.noteId, parent),
        null,
        vault,
        ordered,
        visiting,
      );
    }
    visiting.remove(revision.revisionId);
    ordered.add(revision);
  }
}

SyncEvent _parseEvent(List<int> bytes, String key) {
  try {
    return SyncEvent.fromBytes(bytes);
  } on Object catch (error) {
    throw RemoteObjectCorruptedException('Invalid event $key: $error');
  }
}

Revision _parseRevision(List<int> bytes, String key) {
  try {
    return Revision.fromBytes(bytes);
  } on Object catch (error) {
    throw RemoteObjectCorruptedException('Invalid revision $key: $error');
  }
}

void _verifyRemoteVault(VaultIdentity local, List<int> remoteBytes) {
  VaultIdentity remote;
  try {
    remote = VaultIdentity.fromBytes(remoteBytes);
  } on Object catch (error) {
    throw RemoteObjectCorruptedException('Invalid remote vault config: $error');
  }
  _verifyIdentity(local, remote.vaultId, remote.generation);
  if (remote.protocolVersion != local.protocolVersion) {
    throw SyncException(
      'Remote protocol ${remote.protocolVersion} does not match '
      '${local.protocolVersion}',
    );
  }
}

void _verifyIdentity(VaultIdentity expected, String vaultId, int generation) {
  if (vaultId != expected.vaultId) {
    throw VaultMismatchException(
      'Remote vault $vaultId does not match ${expected.vaultId}',
    );
  }
  if (generation != expected.generation) {
    throw VaultGenerationChangedException(
      'Remote generation $generation does not match ${expected.generation}',
    );
  }
}
