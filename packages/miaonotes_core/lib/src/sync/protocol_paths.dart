abstract final class ProtocolPaths {
  static const String root = 'MiaoNotes/';
  static const String vaultConfig = '${root}vault/config.json';
  static const String cryptoConfig = '${root}crypto/config.json';
  static const String eventsPrefix = '${root}events/';

  static String revision(String noteId, String revisionId) {
    _validateSegment(noteId);
    _validateSegment(revisionId);
    return '${root}revisions/$noteId/$revisionId.json';
  }

  static String event(String deviceId, int sequence, String eventId) {
    _validateSegment(deviceId);
    _validateSegment(eventId);
    if (sequence < 1) {
      throw ArgumentError.value(sequence, 'sequence', 'Must be positive');
    }
    final padded = sequence.toString().padLeft(20, '0');
    return '$eventsPrefix$deviceId/$padded-$eventId.json';
  }

  static void _validateSegment(String value) {
    if (value.isEmpty ||
        value.contains('/') ||
        value.contains('\\') ||
        value == '.' ||
        value == '..') {
      throw ArgumentError.value(value, 'value', 'Unsafe object-key segment');
    }
  }
}
