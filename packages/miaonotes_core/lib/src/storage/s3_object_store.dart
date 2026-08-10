import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:xml/xml.dart';

import '../model/canonical_json.dart';
import 'object_store.dart';

typedef S3Clock = DateTime Function();

/// Credentials for an S3-compatible object store.
///
/// This value deliberately has a redacted [toString]. Callers should keep it
/// in memory and supply it from an operating-system secret boundary.
final class S3Credentials {
  const S3Credentials({
    required this.accessKeyId,
    required this.secretAccessKey,
    this.sessionToken,
  });

  final String accessKeyId;
  final String secretAccessKey;
  final String? sessionToken;

  @override
  String toString() => 'S3Credentials(<redacted>)';
}

final class AwsSigV4Signature {
  const AwsSigV4Signature({
    required this.headers,
    required this.signature,
    required this.canonicalRequest,
  });

  final Map<String, String> headers;
  final String signature;
  final String canonicalRequest;
}

/// AWS Signature Version 4 signer with S3's path encoding rules.
final class AwsSigV4Signer {
  const AwsSigV4Signer({
    required this.credentials,
    required this.region,
    this.service = 's3',
  });

  final S3Credentials credentials;
  final String region;
  final String service;

  AwsSigV4Signature sign({
    required String method,
    required String canonicalUri,
    required String canonicalQuery,
    required Map<String, String> headers,
    required String payloadHash,
    required DateTime time,
  }) {
    final utc = time.toUtc();
    final dateStamp = _dateStamp(utc);
    final amzDate = _amzDate(utc);
    final normalizedHeaders = <String, String>{
      for (final entry in headers.entries)
        entry.key.toLowerCase(): _normalizeHeaderValue(entry.value),
      'x-amz-content-sha256': payloadHash,
      'x-amz-date': amzDate,
    };
    final sessionToken = credentials.sessionToken;
    if (sessionToken != null && sessionToken.isNotEmpty) {
      normalizedHeaders['x-amz-security-token'] = sessionToken;
    }

    final signedHeaderNames = normalizedHeaders.keys.toList()..sort();
    final canonicalHeaders = signedHeaderNames
        .map((name) => '$name:${normalizedHeaders[name]}')
        .join('\n');
    final signedHeaders = signedHeaderNames.join(';');
    final canonicalRequest = <String>[
      method.toUpperCase(),
      canonicalUri,
      canonicalQuery,
      '$canonicalHeaders\n',
      signedHeaders,
      payloadHash,
    ].join('\n');
    final credentialScope = '$dateStamp/$region/$service/aws4_request';
    final stringToSign = <String>[
      'AWS4-HMAC-SHA256',
      amzDate,
      credentialScope,
      sha256.convert(utf8.encode(canonicalRequest)).toString(),
    ].join('\n');
    final dateKey = _hmac(
      utf8.encode('AWS4${credentials.secretAccessKey}'),
      dateStamp,
    );
    final regionKey = _hmac(dateKey, region);
    final serviceKey = _hmac(regionKey, service);
    final signingKey = _hmac(serviceKey, 'aws4_request');
    final signature = _hex(_hmac(signingKey, stringToSign));
    final authorization =
        'AWS4-HMAC-SHA256 '
        'Credential=${credentials.accessKeyId}/$credentialScope,'
        'SignedHeaders=$signedHeaders,'
        'Signature=$signature';

    return AwsSigV4Signature(
      headers: Map.unmodifiable({
        ...normalizedHeaders,
        'authorization': authorization,
      }),
      signature: signature,
      canonicalRequest: canonicalRequest,
    );
  }
}

/// S3-compatible implementation used by Sync Protocol v1.
///
/// [objectPrefix] is a hard namespace boundary: all logical keys are mapped
/// below it. It is especially useful for isolated integration tests.
final class S3ObjectStore implements ObjectStore {
  S3ObjectStore({
    required Uri endpoint,
    required this.bucket,
    required S3Credentials credentials,
    this.region = 'auto',
    String objectPrefix = '',
    this.connectionTimeout = const Duration(seconds: 10),
    this.requestTimeout = const Duration(seconds: 30),
    bool allowInsecure = false,
    HttpClient? httpClient,
    S3Clock? clock,
  }) : endpoint = _validateEndpoint(endpoint, allowInsecure: allowInsecure),
       objectPrefix = _normalizeObjectPrefix(objectPrefix),
       _signer = AwsSigV4Signer(credentials: credentials, region: region),
       _httpClient = httpClient ?? HttpClient(),
       _ownsHttpClient = httpClient == null,
       _clock = clock ?? DateTime.now {
    _validateBucket(bucket);
    _httpClient.connectionTimeout = connectionTimeout;
  }

  final Uri endpoint;
  final String bucket;
  final String region;
  final String objectPrefix;
  final Duration connectionTimeout;
  final Duration requestTimeout;
  final AwsSigV4Signer _signer;
  final HttpClient _httpClient;
  final bool _ownsHttpClient;
  final S3Clock _clock;

  String get _physicalPrefix => objectPrefix.isEmpty ? '' : '$objectPrefix/';

  void close({bool force = false}) {
    if (_ownsHttpClient) {
      _httpClient.close(force: force);
    }
  }

  @override
  Future<StoredObject?> get(String key) async {
    _validateLogicalKey(key);
    final response = await _request(
      method: 'GET',
      physicalKey: '$_physicalPrefix$key',
    );
    if (response.statusCode == HttpStatus.notFound) {
      return null;
    }
    _throwForStatus(response.statusCode);
    return StoredObject(key: key, bytes: response.body);
  }

  @override
  Future<void> putImmutable(String key, List<int> bytes) async {
    _validateLogicalKey(key);
    final response = await _request(
      method: 'PUT',
      physicalKey: '$_physicalPrefix$key',
      headers: const {'if-none-match': '*'},
      body: bytes,
    );
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }
    if (response.statusCode == HttpStatus.preconditionFailed ||
        response.statusCode == HttpStatus.conflict) {
      final existing = await get(key);
      if (existing != null && bytesEqual(existing.bytes, bytes)) {
        return;
      }
      throw ImmutableObjectConflict('Immutable object already differs: $key');
    }
    _throwForStatus(response.statusCode);
  }

  @override
  Future<List<String>> listKeys(String prefix) async {
    _validateLogicalPrefix(prefix);
    final physicalPrefix = '$_physicalPrefix$prefix';
    final keys = <String>[];
    String? continuationToken;
    final seenTokens = <String>{};

    do {
      final query = <String, String>{
        'encoding-type': 'url',
        'list-type': '2',
        'prefix': physicalPrefix,
        'continuation-token': ?continuationToken,
      };
      final response = await _request(method: 'GET', query: query);
      _throwForStatus(response.statusCode);
      final page = _parseListPage(response.body);
      for (final physicalKey in page.keys) {
        if (!physicalKey.startsWith(_physicalPrefix)) {
          throw const ObjectStoreException(
            'Object store returned a key outside the configured prefix',
          );
        }
        keys.add(physicalKey.substring(_physicalPrefix.length));
      }
      continuationToken = page.isTruncated ? page.nextContinuationToken : null;
      if (page.isTruncated &&
          (continuationToken == null ||
              continuationToken.isEmpty ||
              !seenTokens.add(continuationToken))) {
        throw const ObjectStoreException(
          'Object store returned an invalid pagination cursor',
        );
      }
    } while (continuationToken != null);

    keys.sort();
    return List.unmodifiable(keys);
  }

  /// Deletes one exact logical key. Sync Protocol v1 never calls this method;
  /// it exists for bounded administrative cleanup and integration tests.
  Future<void> deleteObject(String key) async {
    _validateLogicalKey(key);
    final response = await _request(
      method: 'DELETE',
      physicalKey: '$_physicalPrefix$key',
    );
    if (response.statusCode == HttpStatus.notFound) {
      return;
    }
    _throwForStatus(response.statusCode);
  }

  Future<_S3Response> _request({
    required String method,
    String? physicalKey,
    Map<String, String> query = const {},
    Map<String, String> headers = const {},
    List<int> body = const [],
  }) async {
    final canonicalUri = physicalKey == null
        ? '/${awsUriEncode(bucket)}'
        : '/${awsUriEncode(bucket)}/${awsUriEncode(physicalKey, encodeSlash: false)}';
    final canonicalQuery = _canonicalQuery(query);
    final requestUri = Uri.parse(
      '${endpoint.scheme}://${endpoint.authority}$canonicalUri'
      '${canonicalQuery.isEmpty ? '' : '?$canonicalQuery'}',
    );
    final payload = Uint8List.fromList(body);
    final payloadHash = sha256.convert(payload).toString();
    final signature = _signer.sign(
      method: method,
      canonicalUri: canonicalUri,
      canonicalQuery: canonicalQuery,
      headers: {'host': endpoint.authority, ...headers},
      payloadHash: payloadHash,
      time: _clock(),
    );

    try {
      final request = await _httpClient
          .openUrl(method, requestUri)
          .timeout(connectionTimeout);
      for (final entry in signature.headers.entries) {
        request.headers.set(entry.key, entry.value);
      }
      if (payload.isNotEmpty) {
        request.contentLength = payload.length;
        request.add(payload);
      }
      final response = await request.close().timeout(requestTimeout);
      final responseBytes = await response
          .fold<BytesBuilder>(
            BytesBuilder(copy: false),
            (builder, chunk) => builder..add(chunk),
          )
          .timeout(requestTimeout);
      return _S3Response(
        statusCode: response.statusCode,
        body: responseBytes.takeBytes(),
      );
    } on ObjectStoreException {
      rethrow;
    } on TimeoutException {
      throw const ObjectStoreUnavailable('Object store request timed out');
    } on SocketException {
      throw const ObjectStoreUnavailable('Object store is unreachable');
    } on HandshakeException {
      throw const ObjectStoreUnavailable('Object store TLS handshake failed');
    } on HttpException {
      throw const ObjectStoreUnavailable('Object store HTTP request failed');
    }
  }

  void _throwForStatus(int statusCode) {
    if (statusCode >= 200 && statusCode < 300) {
      return;
    }
    if (statusCode == HttpStatus.unauthorized ||
        statusCode == HttpStatus.forbidden) {
      throw const ObjectStoreAuthenticationFailed(
        'Object store rejected the supplied credentials',
      );
    }
    if (statusCode == HttpStatus.requestTimeout ||
        statusCode == HttpStatus.tooManyRequests ||
        statusCode >= 500) {
      throw ObjectStoreUnavailable(
        'Object store is temporarily unavailable (HTTP $statusCode)',
      );
    }
    throw ObjectStoreRequestFailed(
      'Object store request failed (HTTP $statusCode)',
      statusCode: statusCode,
    );
  }
}

String awsUriEncode(String value, {bool encodeSlash = true}) {
  const hex = '0123456789ABCDEF';
  final output = StringBuffer();
  for (final byte in utf8.encode(value)) {
    final isUnreserved =
        (byte >= 0x41 && byte <= 0x5A) ||
        (byte >= 0x61 && byte <= 0x7A) ||
        (byte >= 0x30 && byte <= 0x39) ||
        byte == 0x2D ||
        byte == 0x2E ||
        byte == 0x5F ||
        byte == 0x7E;
    if (isUnreserved || (!encodeSlash && byte == 0x2F)) {
      output.writeCharCode(byte);
    } else {
      output
        ..write('%')
        ..write(hex[(byte >> 4) & 0x0F])
        ..write(hex[byte & 0x0F]);
    }
  }
  return output.toString();
}

String _canonicalQuery(Map<String, String> query) {
  final entries =
      query.entries
          .map(
            (entry) =>
                MapEntry(awsUriEncode(entry.key), awsUriEncode(entry.value)),
          )
          .toList()
        ..sort((left, right) {
          final keyComparison = left.key.compareTo(right.key);
          return keyComparison != 0
              ? keyComparison
              : left.value.compareTo(right.value);
        });
  return entries.map((entry) => '${entry.key}=${entry.value}').join('&');
}

_ListPage _parseListPage(List<int> body) {
  try {
    final document = XmlDocument.parse(utf8.decode(body));
    String? firstText(String localName) {
      for (final element in document.descendants.whereType<XmlElement>()) {
        if (element.name.local == localName) {
          return element.innerText;
        }
      }
      return null;
    }

    final keys = <String>[];
    for (final element in document.descendants.whereType<XmlElement>()) {
      if (element.name.local != 'Contents') {
        continue;
      }
      for (final child in element.childElements) {
        if (child.name.local == 'Key') {
          keys.add(Uri.decodeComponent(child.innerText));
          break;
        }
      }
    }
    return _ListPage(
      keys: keys,
      isTruncated: firstText('IsTruncated')?.toLowerCase() == 'true',
      nextContinuationToken: firstText('NextContinuationToken'),
    );
  } on FormatException {
    throw const ObjectStoreException('Object store returned invalid list XML');
  }
}

Uri _validateEndpoint(Uri endpoint, {required bool allowInsecure}) {
  if (!endpoint.hasAuthority ||
      endpoint.userInfo.isNotEmpty ||
      endpoint.hasQuery ||
      endpoint.hasFragment ||
      (endpoint.path.isNotEmpty && endpoint.path != '/')) {
    throw ArgumentError.value(endpoint, 'endpoint', 'Must be an origin URL');
  }
  if (endpoint.scheme != 'https' &&
      !(allowInsecure && endpoint.scheme == 'http')) {
    throw ArgumentError.value(endpoint, 'endpoint', 'HTTPS is required');
  }
  return endpoint.replace(path: '');
}

void _validateBucket(String bucket) {
  final valid = RegExp(r'^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$');
  if (!valid.hasMatch(bucket)) {
    throw ArgumentError.value(bucket, 'bucket', 'Invalid S3 bucket name');
  }
}

String _normalizeObjectPrefix(String prefix) {
  final normalized = prefix.replaceAll(RegExp(r'^/+|/+$'), '');
  _validateLogicalPrefix(normalized);
  return normalized;
}

void _validateLogicalKey(String key) {
  if (key.isEmpty) {
    throw ArgumentError.value(key, 'key', 'Must not be empty');
  }
  _validateLogicalPrefix(key);
}

void _validateLogicalPrefix(String prefix) {
  if (prefix.startsWith('/') ||
      prefix.contains('\\') ||
      prefix.contains('\u0000') ||
      prefix.split('/').any((segment) => segment == '.' || segment == '..')) {
    throw ArgumentError.value(prefix, 'key', 'Unsafe object key');
  }
}

String _normalizeHeaderValue(String value) =>
    value.trim().replaceAll(RegExp(r'[\t\r\n ]+'), ' ');

String _dateStamp(DateTime time) =>
    '${time.year.toString().padLeft(4, '0')}'
    '${time.month.toString().padLeft(2, '0')}'
    '${time.day.toString().padLeft(2, '0')}';

String _amzDate(DateTime time) =>
    '${_dateStamp(time)}T'
    '${time.hour.toString().padLeft(2, '0')}'
    '${time.minute.toString().padLeft(2, '0')}'
    '${time.second.toString().padLeft(2, '0')}Z';

List<int> _hmac(List<int> key, String value) =>
    Hmac(sha256, key).convert(utf8.encode(value)).bytes;

String _hex(List<int> bytes) =>
    bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

final class _S3Response {
  const _S3Response({required this.statusCode, required this.body});

  final int statusCode;
  final Uint8List body;
}

final class _ListPage {
  const _ListPage({
    required this.keys,
    required this.isTruncated,
    required this.nextContinuationToken,
  });

  final List<String> keys;
  final bool isTruncated;
  final String? nextContinuationToken;
}
