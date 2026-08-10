import 'dart:convert';
import 'dart:io';

import 'package:miaonotes_core/miaonotes_core.dart';

final class SyncProfile {
  SyncProfile({
    required Uri endpoint,
    required this.bucket,
    this.objectPrefix = '',
    this.region = 'auto',
  }) : endpoint = _validateEndpoint(endpoint) {
    _validateBucket(bucket);
    _validatePrefix(objectPrefix);
    if (region.trim().isEmpty) {
      throw ArgumentError.value(region, 'region', 'Must not be empty');
    }
  }

  factory SyncProfile.fromJson(Map<String, Object?> json) => SyncProfile(
    endpoint: Uri.parse(json['endpoint']! as String),
    bucket: json['bucket']! as String,
    objectPrefix: json['objectPrefix']! as String,
    region: json['region']! as String,
  );

  final Uri endpoint;
  final String bucket;
  final String objectPrefix;
  final String region;

  Map<String, Object?> toJson() => <String, Object?>{
    'bucket': bucket,
    'endpoint': endpoint.toString(),
    'objectPrefix': objectPrefix,
    'region': region,
    'schema': 1,
  };
}

final class SyncCredentials {
  const SyncCredentials({
    required this.accessKeyId,
    required this.secretAccessKey,
  });

  final String accessKeyId;
  final String secretAccessKey;

  S3Credentials toS3Credentials() =>
      S3Credentials(accessKeyId: accessKeyId, secretAccessKey: secretAccessKey);

  @override
  String toString() => 'SyncCredentials(<redacted>)';
}

abstract interface class SyncProfileStore {
  Future<SyncProfile?> read();

  Future<void> write(SyncProfile profile);

  Future<void> delete();
}

abstract interface class SyncCredentialStore {
  Future<SyncCredentials?> read();

  Future<void> write(SyncCredentials credentials);

  Future<void> delete();
}

/// Stores only the already-random 256-bit vault key in the operating system's
/// protected credential set. Passwords and recovery codes are never stored.
abstract interface class VaultKeyStore {
  Future<List<int>?> read(String vaultId, String keyId);

  Future<void> write(String vaultId, String keyId, List<int> keyBytes);

  Future<void> delete(String vaultId, String keyId);
}

final class FileSyncProfileStore implements SyncProfileStore {
  const FileSyncProfileStore(this.file);

  final File file;

  @override
  Future<SyncProfile?> read() async {
    if (!await file.exists()) {
      return null;
    }
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, Object?> || decoded['schema'] != 1) {
        throw const FormatException('Unsupported sync profile');
      }
      return SyncProfile.fromJson(decoded);
    } on Object catch (error) {
      throw SyncConfigurationException('Sync profile is invalid: $error');
    }
  }

  @override
  Future<void> write(SyncProfile profile) async {
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    try {
      await temporary.writeAsString(
        canonicalJson(profile.toJson()),
        flush: true,
      );
      if (await file.exists()) {
        await file.delete();
      }
      await temporary.rename(file.path);
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }

  @override
  Future<void> delete() async {
    if (await file.exists()) {
      await file.delete();
    }
  }
}

final class SyncConfigurationException implements Exception {
  const SyncConfigurationException(this.message);

  final String message;

  @override
  String toString() => 'SyncConfigurationException: $message';
}

final class VaultPasswordRequiredException implements Exception {
  const VaultPasswordRequiredException(this.message);

  final String message;

  @override
  String toString() => 'VaultPasswordRequiredException: $message';
}

final class UnencryptedRemoteVaultException implements Exception {
  const UnencryptedRemoteVaultException(this.message);

  final String message;

  @override
  String toString() => 'UnencryptedRemoteVaultException: $message';
}

Uri _validateEndpoint(Uri endpoint) {
  if (endpoint.scheme != 'https' ||
      !endpoint.hasAuthority ||
      endpoint.userInfo.isNotEmpty ||
      endpoint.hasQuery ||
      endpoint.hasFragment ||
      (endpoint.path.isNotEmpty && endpoint.path != '/')) {
    throw ArgumentError.value(
      endpoint,
      'endpoint',
      'Must be an HTTPS origin URL',
    );
  }
  return endpoint.replace(path: '');
}

void _validateBucket(String bucket) {
  final valid = RegExp(r'^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$');
  if (!valid.hasMatch(bucket)) {
    throw ArgumentError.value(bucket, 'bucket', 'Invalid S3 bucket name');
  }
}

void _validatePrefix(String prefix) {
  if (prefix.startsWith('/') ||
      prefix.endsWith('/') ||
      prefix.contains('\\') ||
      prefix.contains('\u0000') ||
      prefix.split('/').any((part) => part == '.' || part == '..')) {
    throw ArgumentError.value(prefix, 'objectPrefix', 'Unsafe object prefix');
  }
}
