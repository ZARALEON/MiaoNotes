import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Encodes JSON with recursively sorted object keys.
String canonicalJson(Object? value) => jsonEncode(_normalize(value));

String sha256HexBytes(List<int> bytes) => sha256.convert(bytes).toString();

String sha256HexJson(Object? value) =>
    sha256HexBytes(utf8.encode(canonicalJson(value)));

Uint8List canonicalJsonBytes(Object? value) =>
    Uint8List.fromList(utf8.encode(canonicalJson(value)));

/// Returns a detached JSON-compatible value with no caller-owned mutable maps.
Object deepCopyJson(Object value) =>
    jsonDecode(canonicalJson(value))! as Object;

bool bytesEqual(List<int> left, List<int> right) {
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

Object? _normalize(Object? value) {
  if (value == null || value is num || value is bool || value is String) {
    return value;
  }
  if (value is DateTime) {
    return value.toUtc().toIso8601String();
  }
  if (value is Map) {
    if (value.keys.any((key) => key is! String)) {
      throw ArgumentError.value(
        value,
        'value',
        'JSON object keys must be strings',
      );
    }
    final keys = value.keys.cast<String>().toList()..sort();
    final normalized = <String, Object?>{};
    for (final key in keys) {
      normalized[key] = _normalize(value[key]);
    }
    return normalized;
  }
  if (value is Iterable) {
    return value.map(_normalize).toList(growable: false);
  }
  throw ArgumentError.value(value, 'value', 'Not a JSON-compatible value');
}
