import 'dart:math';
import 'dart:typed_data';

abstract interface class IdFactory {
  String next(DateTime nowUtc);
}

/// Generates UUIDv7 identifiers without adding a runtime UUID dependency.
final class UuidV7IdFactory implements IdFactory {
  UuidV7IdFactory({Random? random}) : _random = random ?? Random.secure();

  final Random _random;

  @override
  String next(DateTime nowUtc) {
    final bytes = Uint8List(16);
    var milliseconds = nowUtc.toUtc().millisecondsSinceEpoch;
    for (var index = 5; index >= 0; index -= 1) {
      bytes[index] = milliseconds & 0xff;
      milliseconds >>= 8;
    }
    for (var index = 6; index < 16; index += 1) {
      bytes[index] = _random.nextInt(256);
    }
    bytes[6] = 0x70 | (bytes[6] & 0x0f);
    bytes[8] = 0x80 | (bytes[8] & 0x3f);

    final hex = bytes
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-'
        '${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-'
        '${hex.substring(16, 20)}-'
        '${hex.substring(20)}';
  }
}

/// Predictable IDs for tests and simulations.
final class SequenceIdFactory implements IdFactory {
  SequenceIdFactory(this.prefix);

  final String prefix;
  int _nextValue = 1;

  @override
  String next(DateTime nowUtc) {
    final value = _nextValue;
    _nextValue += 1;
    return '$prefix-${value.toString().padLeft(8, '0')}';
  }
}
