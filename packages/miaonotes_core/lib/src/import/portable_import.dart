import 'dart:async';

typedef ImportApplyHook = FutureOr<void> Function(int importedRevisions);

final class PortableImportException implements Exception {
  const PortableImportException(this.message);

  final String message;

  @override
  String toString() => 'PortableImportException: $message';
}

final class PortableImportResult {
  const PortableImportResult({
    required this.noteCount,
    required this.revisionCount,
    required this.conflictCount,
    required this.queuedObjectCount,
  });

  final int noteCount;
  final int revisionCount;
  final int conflictCount;
  final int queuedObjectCount;
}
