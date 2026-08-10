import 'dart:collection';
import 'dart:typed_data';

import '../model/canonical_json.dart';
import 'object_store.dart';

/// Deterministic in-memory store with injectable S3-like failures.
final class FakeObjectStore implements ObjectStore {
  final SplayTreeMap<String, Uint8List> _objects = SplayTreeMap();

  bool online = true;
  int failReadsRemaining = 0;
  int failPutsBeforeWriteRemaining = 0;
  int failPutsAfterWriteRemaining = 0;

  int get objectCount => _objects.length;

  @override
  Future<StoredObject?> get(String key) async {
    _checkOnline();
    if (failReadsRemaining > 0) {
      failReadsRemaining -= 1;
      throw const ObjectStoreUnavailable('Injected read failure');
    }
    final bytes = _objects[key];
    return bytes == null ? null : StoredObject(key: key, bytes: bytes);
  }

  @override
  Future<List<String>> listKeys(String prefix) async {
    _checkOnline();
    if (failReadsRemaining > 0) {
      failReadsRemaining -= 1;
      throw const ObjectStoreUnavailable('Injected list failure');
    }
    return List.unmodifiable(
      _objects.keys.where((key) => key.startsWith(prefix)),
    );
  }

  @override
  Future<void> putImmutable(String key, List<int> bytes) async {
    _checkOnline();
    if (failPutsBeforeWriteRemaining > 0) {
      failPutsBeforeWriteRemaining -= 1;
      throw const ObjectStoreUnavailable('Injected failure before write');
    }

    final existing = _objects[key];
    if (existing != null && !bytesEqual(existing, bytes)) {
      throw ImmutableObjectConflict('Immutable key already differs: $key');
    }
    _objects[key] = Uint8List.fromList(bytes);

    if (failPutsAfterWriteRemaining > 0) {
      failPutsAfterWriteRemaining -= 1;
      throw const ObjectStoreUnavailable('Injected ambiguous write result');
    }
  }

  /// Deliberately bypasses immutable semantics for corruption tests only.
  void corruptForTest(String key, List<int> replacement) {
    if (!_objects.containsKey(key)) {
      throw ArgumentError.value(key, 'key', 'Object does not exist');
    }
    _objects[key] = Uint8List.fromList(replacement);
  }

  void _checkOnline() {
    if (!online) {
      throw const ObjectStoreUnavailable('Object store is offline');
    }
  }
}
