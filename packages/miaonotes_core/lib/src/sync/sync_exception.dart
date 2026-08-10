class SyncException implements Exception {
  const SyncException(this.message);

  final String message;

  @override
  String toString() => 'SyncException: $message';
}

final class VaultMismatchException extends SyncException {
  const VaultMismatchException(super.message);
}

final class VaultGenerationChangedException extends SyncException {
  const VaultGenerationChangedException(super.message);
}

final class VaultAdoptionNotAllowedException extends SyncException {
  const VaultAdoptionNotAllowedException(super.message);
}

final class RemoteObjectCorruptedException extends SyncException {
  const RemoteObjectCorruptedException(super.message);
}

final class EventGapException extends SyncException {
  const EventGapException(super.message);
}
