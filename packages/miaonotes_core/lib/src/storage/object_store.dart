import 'dart:typed_data';

final class StoredObject {
  StoredObject({required this.key, required List<int> bytes})
    : bytes = Uint8List.fromList(bytes);

  final String key;
  final Uint8List bytes;
}

abstract interface class ObjectStore {
  /// Returns null when the key does not exist.
  Future<StoredObject?> get(String key);

  /// Creates an immutable object.
  ///
  /// Repeating a key with identical bytes is an idempotent success. Repeating a
  /// key with different bytes must throw [ImmutableObjectConflict].
  Future<void> putImmutable(String key, List<int> bytes);

  /// Returns lexicographically sorted keys currently visible under [prefix].
  Future<List<String>> listKeys(String prefix);
}

class ObjectStoreException implements Exception {
  const ObjectStoreException(this.message);

  final String message;

  @override
  String toString() => 'ObjectStoreException: $message';
}

final class ObjectStoreUnavailable extends ObjectStoreException {
  const ObjectStoreUnavailable(super.message);
}

final class ObjectStoreAuthenticationFailed extends ObjectStoreException {
  const ObjectStoreAuthenticationFailed(super.message);
}

final class ObjectStoreRequestFailed extends ObjectStoreException {
  const ObjectStoreRequestFailed(super.message, {required this.statusCode});

  final int statusCode;
}

final class ImmutableObjectConflict extends ObjectStoreException {
  const ImmutableObjectConflict(super.message);
}
