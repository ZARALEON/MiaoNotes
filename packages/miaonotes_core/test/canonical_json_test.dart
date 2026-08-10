import 'dart:convert';

import 'package:miaonotes_core/miaonotes_core.dart';
import 'package:test/test.dart';

void main() {
  test('canonical JSON recursively sorts keys', () {
    final first = <String, Object?>{
      'z': 1,
      'a': <String, Object?>{'d': 4, 'b': 2},
    };
    final second = <String, Object?>{
      'a': <String, Object?>{'b': 2, 'd': 4},
      'z': 1,
    };
    expect(canonicalJson(first), canonicalJson(second));
    expect(sha256HexJson(first), sha256HexJson(second));
    expect(jsonDecode(canonicalJson(first)), equals(first));
  });
}
