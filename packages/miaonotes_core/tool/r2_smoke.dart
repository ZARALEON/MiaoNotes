import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:miaonotes_core/miaonotes_core.dart';

Future<void> main() async {
  final environment = Platform.environment;
  final endpoint = _required(environment, 'MIAONOTES_R2_ENDPOINT');
  final bucket = _required(environment, 'MIAONOTES_R2_BUCKET');
  final accessKeyId = _required(environment, 'MIAONOTES_R2_ACCESS_KEY_ID');
  final secretAccessKey = _required(
    environment,
    'MIAONOTES_R2_SECRET_ACCESS_KEY',
  );
  final runId = _randomHex(16);
  final store = S3ObjectStore(
    endpoint: Uri.parse(endpoint),
    bucket: bucket,
    credentials: S3Credentials(
      accessKeyId: accessKeyId,
      secretAccessKey: secretAccessKey,
    ),
    objectPrefix: '_miaonotes-temporary-tests/$runId',
  );
  const firstKey = 'revisions/smoke-a.json';
  const secondKey = 'events/smoke-b.json';
  final cleanupKeys = <String>[firstKey, secondKey];

  try {
    final firstBytes = utf8.encode('{"kind":"revision","test":"$runId"}');
    final secondBytes = utf8.encode('{"kind":"event","test":"$runId"}');
    await store.putImmutable(firstKey, firstBytes);
    await store.putImmutable(firstKey, firstBytes);
    final fetched = await store.get(firstKey);
    if (fetched == null || !_sameBytes(fetched.bytes, firstBytes)) {
      throw StateError('R2 read-after-write verification failed');
    }
    await store.putImmutable(secondKey, secondBytes);
    final listed = await store.listKeys('');
    if (!listed.contains(firstKey) || !listed.contains(secondKey)) {
      throw StateError('R2 paginated list verification failed');
    }
    try {
      await store.putImmutable(firstKey, utf8.encode('different'));
      throw StateError('R2 accepted an immutable overwrite');
    } on ImmutableObjectConflict {
      // Expected: If-None-Match protected the existing object.
    }
    stdout.writeln('R2 smoke test passed in isolated run $runId.');
  } finally {
    Object? cleanupFailure;
    for (final key in cleanupKeys) {
      try {
        await store.deleteObject(key);
      } catch (error) {
        cleanupFailure ??= error;
      }
    }
    if (cleanupFailure == null && (await store.listKeys('')).isNotEmpty) {
      cleanupFailure = StateError('Temporary R2 prefix is not empty');
    }
    store.close(force: true);
    if (cleanupFailure != null) {
      throw StateError('R2 temporary object cleanup failed');
    }
  }
}

String _required(Map<String, String> environment, String name) {
  final value = environment[name];
  if (value == null || value.isEmpty) {
    throw StateError('Missing required environment variable: $name');
  }
  return value;
}

String _randomHex(int bytes) {
  final random = Random.secure();
  return List.generate(
    bytes,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

bool _sameBytes(List<int> left, List<int> right) {
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
