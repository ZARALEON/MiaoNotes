import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:miaonotes_core/miaonotes_core.dart';
import 'package:test/test.dart';

void main() {
  group('AWS Signature Version 4', () {
    test('matches the published S3 header-auth signature example', () {
      const signer = AwsSigV4Signer(
        credentials: S3Credentials(
          accessKeyId: 'AKIAIOSFODNN7EXAMPLE',
          secretAccessKey: 'wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY',
        ),
        region: 'us-east-1',
      );
      final signature = signer.sign(
        method: 'GET',
        canonicalUri: '/test.txt',
        canonicalQuery: '',
        headers: const {
          'host': 'examplebucket.s3.amazonaws.com',
          'range': 'bytes=0-9',
        },
        payloadHash:
            'e3b0c44298fc1c149afbf4c8996fb924'
            '27ae41e4649b934ca495991b7852b855',
        time: DateTime.utc(2013, 5, 24),
      );

      expect(
        signature.signature,
        'f0e8bdb87c964420e857bd35b5d6ed31'
        '0bd44f0170aba48dd91039c6036bdb41',
      );
    });

    test('uses S3 byte-wise URI encoding rules', () {
      expect(
        awsUriEncode('a b/喵.txt', encodeSlash: false),
        'a%20b/%E5%96%B5.txt',
      );
      expect(awsUriEncode('a/b'), 'a%2Fb');
    });

    test('never renders credential values', () {
      const credentials = S3Credentials(
        accessKeyId: 'visible-id-is-not-allowed',
        secretAccessKey: 'visible-secret-is-not-allowed',
      );

      expect(credentials.toString(), isNot(contains(credentials.accessKeyId)));
      expect(
        credentials.toString(),
        isNot(contains(credentials.secretAccessKey)),
      );
    });
  });

  group('S3ObjectStore', () {
    late _FakeS3Server server;
    late S3ObjectStore store;

    setUp(() async {
      server = await _FakeS3Server.start();
      store = S3ObjectStore(
        endpoint: server.endpoint,
        bucket: 'notes',
        credentials: const S3Credentials(
          accessKeyId: 'test-access-key',
          secretAccessKey: 'test-secret-key',
        ),
        objectPrefix: 'isolated/run-1',
        allowInsecure: true,
        clock: () => DateTime.utc(2026, 8, 10, 12),
      );
    });

    tearDown(() async {
      store.close(force: true);
      await server.close();
    });

    test('supports immutable idempotency and rejects changed bytes', () async {
      final bytes = utf8.encode('{"kind":"revision"}');

      await store.putImmutable('revisions/r1.json', bytes);
      await store.putImmutable('revisions/r1.json', bytes);
      expect((await store.get('revisions/r1.json'))?.bytes, bytes);
      await expectLater(
        store.putImmutable('revisions/r1.json', utf8.encode('different')),
        throwsA(isA<ImmutableObjectConflict>()),
      );

      expect(server.objects.keys, contains('isolated/run-1/revisions/r1.json'));
      expect(server.sawConditionalPut, isTrue);
      expect(server.sawSignedRequest, isTrue);
    });

    test(
      'lists paginated Unicode keys and hides the physical prefix',
      () async {
        await store.putImmutable('events/a space.json', utf8.encode('a'));
        await store.putImmutable('events/喵.json', utf8.encode('b'));

        expect(await store.listKeys('events/'), [
          'events/a space.json',
          'events/喵.json',
        ]);
        expect(server.listRequestCount, 2);
      },
    );

    test('deletes only the requested key', () async {
      await store.putImmutable('temporary/a', utf8.encode('a'));
      await store.putImmutable('temporary/b', utf8.encode('b'));

      await store.deleteObject('temporary/a');

      expect(await store.get('temporary/a'), isNull);
      expect(await store.get('temporary/b'), isNotNull);
    });
  });
}

final class _FakeS3Server {
  _FakeS3Server._(this._server) {
    _subscription = _server.listen(_handle);
  }

  static Future<_FakeS3Server> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _FakeS3Server._(server);
  }

  final HttpServer _server;
  late final StreamSubscription<HttpRequest> _subscription;
  final Map<String, List<int>> objects = {};
  bool sawConditionalPut = false;
  bool sawSignedRequest = false;
  int listRequestCount = 0;

  Uri get endpoint => Uri.parse('http://127.0.0.1:${_server.port}');

  Future<void> close() async {
    await _subscription.cancel();
    await _server.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    sawSignedRequest =
        request.headers
            .value(HttpHeaders.authorizationHeader)
            ?.startsWith('AWS4-HMAC-SHA256 ') ==
        true;
    final segments = request.uri.pathSegments;
    if (segments.isEmpty || segments.first != 'notes') {
      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
      return;
    }

    if (request.method == 'GET' &&
        request.uri.queryParameters['list-type'] == '2') {
      await request.drain<void>();
      _writeListResponse(request);
      return;
    }

    final key = segments.skip(1).join('/');
    switch (request.method) {
      case 'PUT':
        final body = await request.fold<List<int>>(
          <int>[],
          (all, chunk) => all..addAll(chunk),
        );
        sawConditionalPut =
            request.headers.value(HttpHeaders.ifNoneMatchHeader) == '*';
        if (objects.containsKey(key)) {
          request.response.statusCode = HttpStatus.preconditionFailed;
        } else {
          objects[key] = body;
          request.response.statusCode = HttpStatus.ok;
        }
      case 'GET':
        await request.drain<void>();
        final body = objects[key];
        if (body == null) {
          request.response.statusCode = HttpStatus.notFound;
        } else {
          request.response
            ..statusCode = HttpStatus.ok
            ..add(body);
        }
      case 'DELETE':
        await request.drain<void>();
        objects.remove(key);
        request.response.statusCode = HttpStatus.noContent;
      default:
        await request.drain<void>();
        request.response.statusCode = HttpStatus.methodNotAllowed;
    }
    await request.response.close();
  }

  void _writeListResponse(HttpRequest request) {
    listRequestCount += 1;
    final prefix = request.uri.queryParameters['prefix'] ?? '';
    final token = request.uri.queryParameters['continuation-token'];
    final matches = objects.keys.where((key) => key.startsWith(prefix)).toList()
      ..sort();
    final start = token == null ? 0 : int.parse(token);
    final page = matches.skip(start).take(1).toList();
    final next = start + page.length;
    final isTruncated = next < matches.length;
    final contents = page
        .map(
          (key) =>
              '<Contents><Key>${Uri.encodeComponent(key)}</Key>'
              '<ETag>"${md5.convert(objects[key]!)}"</ETag></Contents>',
        )
        .join();
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType(
        'application',
        'xml',
        charset: 'utf-8',
      )
      ..write(
        '<?xml version="1.0" encoding="UTF-8"?>'
        '<ListBucketResult>'
        '<IsTruncated>$isTruncated</IsTruncated>'
        '$contents'
        '${isTruncated ? '<NextContinuationToken>$next</NextContinuationToken>' : ''}'
        '</ListBucketResult>',
      );
    unawaited(request.response.close());
  }
}
