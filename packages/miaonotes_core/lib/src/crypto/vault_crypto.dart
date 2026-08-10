import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../model/canonical_json.dart';

const int vaultCryptoSchemaV1 = 1;
const String vaultCryptoAlgorithmV1 = 'AES-256-GCM';

final class Argon2idParameters {
  const Argon2idParameters({
    this.memoryKiB = 19456,
    this.iterations = 2,
    this.parallelism = 1,
    this.hashLength = 32,
  });

  final int memoryKiB;
  final int iterations;
  final int parallelism;
  final int hashLength;

  void validate() {
    if (memoryKiB < 8 ||
        iterations < 1 ||
        parallelism < 1 ||
        hashLength != 32) {
      throw const VaultCryptoFormatException('Invalid Argon2id parameters');
    }
  }

  Map<String, Object> toJson() => <String, Object>{
    'algorithm': 'Argon2id',
    'hashLength': hashLength,
    'iterations': iterations,
    'memoryKiB': memoryKiB,
    'parallelism': parallelism,
    'version': 19,
  };

  factory Argon2idParameters.fromJson(Map<String, Object?> json) {
    if (json['algorithm'] != 'Argon2id' || json['version'] != 19) {
      throw const VaultCryptoFormatException('Unsupported password KDF');
    }
    final value = Argon2idParameters(
      memoryKiB: _requiredInt(json, 'memoryKiB'),
      iterations: _requiredInt(json, 'iterations'),
      parallelism: _requiredInt(json, 'parallelism'),
      hashLength: _requiredInt(json, 'hashLength'),
    );
    value.validate();
    return value;
  }
}

final class WrappedVaultKey {
  WrappedVaultKey({
    required List<int> nonce,
    required List<int> cipherText,
    required List<int> mac,
  }) : nonce = Uint8List.fromList(nonce),
       cipherText = Uint8List.fromList(cipherText),
       mac = Uint8List.fromList(mac) {
    if (this.nonce.length != 12 || this.mac.length != 16) {
      throw const VaultCryptoFormatException('Invalid wrapped-key lengths');
    }
  }

  final Uint8List nonce;
  final Uint8List cipherText;
  final Uint8List mac;

  Map<String, Object> toJson() => <String, Object>{
    'algorithm': vaultCryptoAlgorithmV1,
    'ciphertext': base64Encode(cipherText),
    'mac': base64Encode(mac),
    'nonce': base64Encode(nonce),
  };

  factory WrappedVaultKey.fromJson(Map<String, Object?> json) {
    if (json['algorithm'] != vaultCryptoAlgorithmV1) {
      throw const VaultCryptoFormatException('Unsupported key-wrap cipher');
    }
    try {
      return WrappedVaultKey(
        nonce: base64Decode(_requiredString(json, 'nonce')),
        cipherText: base64Decode(_requiredString(json, 'ciphertext')),
        mac: base64Decode(_requiredString(json, 'mac')),
      );
    } on FormatException catch (error) {
      throw VaultCryptoFormatException('Invalid wrapped-key encoding: $error');
    }
  }
}

final class PasswordKeyEnvelope {
  PasswordKeyEnvelope({
    required this.parameters,
    required List<int> salt,
    required this.wrappedKey,
  }) : salt = Uint8List.fromList(salt) {
    if (this.salt.length != 16) {
      throw const VaultCryptoFormatException('Password salt must be 16 bytes');
    }
  }

  final Argon2idParameters parameters;
  final Uint8List salt;
  final WrappedVaultKey wrappedKey;

  Map<String, Object> toJson() => <String, Object>{
    'kdf': parameters.toJson(),
    'salt': base64Encode(salt),
    'wrappedKey': wrappedKey.toJson(),
  };

  factory PasswordKeyEnvelope.fromJson(Map<String, Object?> json) {
    try {
      return PasswordKeyEnvelope(
        parameters: Argon2idParameters.fromJson(_requiredMap(json, 'kdf')),
        salt: base64Decode(_requiredString(json, 'salt')),
        wrappedKey: WrappedVaultKey.fromJson(_requiredMap(json, 'wrappedKey')),
      );
    } on FormatException catch (error) {
      throw VaultCryptoFormatException('Invalid password envelope: $error');
    }
  }
}

final class RecoveryKeyEnvelope {
  RecoveryKeyEnvelope({required List<int> salt, required this.wrappedKey})
    : salt = Uint8List.fromList(salt) {
    if (this.salt.length != 16) {
      throw const VaultCryptoFormatException('Recovery salt must be 16 bytes');
    }
  }

  final Uint8List salt;
  final WrappedVaultKey wrappedKey;

  Map<String, Object> toJson() => <String, Object>{
    'kdf': <String, Object>{'algorithm': 'HKDF-SHA256', 'outputLength': 32},
    'salt': base64Encode(salt),
    'wrappedKey': wrappedKey.toJson(),
  };

  factory RecoveryKeyEnvelope.fromJson(Map<String, Object?> json) {
    final kdf = _requiredMap(json, 'kdf');
    if (kdf['algorithm'] != 'HKDF-SHA256' || kdf['outputLength'] != 32) {
      throw const VaultCryptoFormatException('Unsupported recovery KDF');
    }
    try {
      return RecoveryKeyEnvelope(
        salt: base64Decode(_requiredString(json, 'salt')),
        wrappedKey: WrappedVaultKey.fromJson(_requiredMap(json, 'wrappedKey')),
      );
    } on FormatException catch (error) {
      throw VaultCryptoFormatException('Invalid recovery envelope: $error');
    }
  }
}

final class VaultCryptoConfig {
  const VaultCryptoConfig({
    required this.vaultId,
    required this.generation,
    required this.activeKeyId,
    required this.createdAt,
    required this.passwordEnvelope,
    required this.recoveryEnvelope,
  });

  final String vaultId;
  final int generation;
  final String activeKeyId;
  final DateTime createdAt;
  final PasswordKeyEnvelope passwordEnvelope;
  final RecoveryKeyEnvelope recoveryEnvelope;

  Map<String, Object> toJson() => <String, Object>{
    'activeKeyId': activeKeyId,
    'createdAt': createdAt.toUtc().toIso8601String(),
    'generation': generation,
    'passwordEnvelope': passwordEnvelope.toJson(),
    'recoveryEnvelope': recoveryEnvelope.toJson(),
    'schema': vaultCryptoSchemaV1,
    'vaultId': vaultId,
  };

  Uint8List toBytes() => canonicalJsonBytes(toJson());

  factory VaultCryptoConfig.fromBytes(List<int> bytes) {
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const VaultCryptoFormatException('Crypto config must be JSON');
      }
      return VaultCryptoConfig.fromJson(decoded);
    } on VaultCryptoException {
      rethrow;
    } on Object catch (error) {
      throw VaultCryptoFormatException('Invalid crypto config: $error');
    }
  }

  factory VaultCryptoConfig.fromJson(Map<String, Object?> json) {
    if (json['schema'] != vaultCryptoSchemaV1) {
      throw const VaultCryptoFormatException('Unsupported crypto schema');
    }
    final vaultId = _requiredString(json, 'vaultId');
    final generation = _requiredInt(json, 'generation');
    final activeKeyId = _requiredString(json, 'activeKeyId');
    if (vaultId.isEmpty || generation < 1 || activeKeyId.isEmpty) {
      throw const VaultCryptoFormatException('Invalid crypto identity');
    }
    final createdAt = DateTime.tryParse(_requiredString(json, 'createdAt'));
    if (createdAt == null || !createdAt.isUtc) {
      throw const VaultCryptoFormatException('createdAt must be UTC');
    }
    return VaultCryptoConfig(
      vaultId: vaultId,
      generation: generation,
      activeKeyId: activeKeyId,
      createdAt: createdAt,
      passwordEnvelope: PasswordKeyEnvelope.fromJson(
        _requiredMap(json, 'passwordEnvelope'),
      ),
      recoveryEnvelope: RecoveryKeyEnvelope.fromJson(
        _requiredMap(json, 'recoveryEnvelope'),
      ),
    );
  }
}

final class VaultKeyring {
  VaultKeyring({
    required this.activeKeyId,
    required Map<String, List<int>> keys,
  }) : _keys = Map.unmodifiable(
         keys.map((id, bytes) {
           if (id.isEmpty || bytes.length != 32) {
             throw ArgumentError(
               'Vault keys require a non-empty ID and 32 bytes',
             );
           }
           return MapEntry(id, Uint8List.fromList(bytes));
         }),
       ) {
    if (!_keys.containsKey(activeKeyId)) {
      throw ArgumentError.value(activeKeyId, 'activeKeyId', 'Key is missing');
    }
  }

  factory VaultKeyring.single(String keyId, List<int> keyBytes) => VaultKeyring(
    activeKeyId: keyId,
    keys: <String, List<int>>{keyId: keyBytes},
  );

  final String activeKeyId;
  final Map<String, Uint8List> _keys;

  List<int>? keyBytesFor(String keyId) {
    final bytes = _keys[keyId];
    return bytes == null ? null : Uint8List.fromList(bytes);
  }
}

final class VaultCryptoBootstrap {
  const VaultCryptoBootstrap({
    required this.config,
    required this.keyring,
    required this.recoveryCode,
  });

  final VaultCryptoConfig config;
  final VaultKeyring keyring;
  final String recoveryCode;
}

final class VaultCryptoService {
  VaultCryptoService({Random? random}) : _random = random ?? Random.secure();

  final Random _random;
  final AesGcm _aes = AesGcm.with256bits();

  Future<VaultCryptoBootstrap> create({
    required String vaultId,
    required int generation,
    required String password,
    DateTime? createdAt,
    Argon2idParameters passwordParameters = const Argon2idParameters(),
  }) async {
    if (vaultId.isEmpty || generation < 1 || password.isEmpty) {
      throw ArgumentError('Vault identity and password must not be empty');
    }
    passwordParameters.validate();
    final keyId = 'key-1';
    final masterKey = _randomBytes(32);
    final passwordSalt = _randomBytes(16);
    final recoverySalt = _randomBytes(16);
    final recoveryKey = _randomBytes(32);
    final passwordKek = await _derivePasswordKey(
      password,
      passwordSalt,
      passwordParameters,
    );
    final recoveryKek = await _deriveRecoveryKey(recoveryKey, recoverySalt);
    final identity = _EnvelopeIdentity(vaultId, generation, keyId);
    final passwordWrapped = await _wrap(
      masterKey,
      passwordKek,
      identity.aad('password'),
    );
    final recoveryWrapped = await _wrap(
      masterKey,
      recoveryKek,
      identity.aad('recovery'),
    );
    final config = VaultCryptoConfig(
      vaultId: vaultId,
      generation: generation,
      activeKeyId: keyId,
      createdAt: (createdAt ?? DateTime.now()).toUtc(),
      passwordEnvelope: PasswordKeyEnvelope(
        parameters: passwordParameters,
        salt: passwordSalt,
        wrappedKey: passwordWrapped,
      ),
      recoveryEnvelope: RecoveryKeyEnvelope(
        salt: recoverySalt,
        wrappedKey: recoveryWrapped,
      ),
    );
    return VaultCryptoBootstrap(
      config: config,
      keyring: VaultKeyring.single(keyId, masterKey),
      recoveryCode: encodeRecoveryCode(recoveryKey),
    );
  }

  Future<VaultKeyring> unlockWithPassword(
    VaultCryptoConfig config,
    String password,
  ) async {
    try {
      final kek = await _derivePasswordKey(
        password,
        config.passwordEnvelope.salt,
        config.passwordEnvelope.parameters,
      );
      return await _unwrapConfigKey(
        config,
        kek,
        config.passwordEnvelope.wrappedKey,
        'password',
      );
    } on VaultCryptoException {
      rethrow;
    } on Object {
      throw const VaultUnlockFailed();
    }
  }

  Future<VaultKeyring> unlockWithRecoveryCode(
    VaultCryptoConfig config,
    String recoveryCode,
  ) async {
    try {
      final recoveryKey = decodeRecoveryCode(recoveryCode);
      final kek = await _deriveRecoveryKey(
        recoveryKey,
        config.recoveryEnvelope.salt,
      );
      return await _unwrapConfigKey(
        config,
        kek,
        config.recoveryEnvelope.wrappedKey,
        'recovery',
      );
    } on Object {
      throw const VaultUnlockFailed();
    }
  }

  Future<VaultKeyring> _unwrapConfigKey(
    VaultCryptoConfig config,
    SecretKey kek,
    WrappedVaultKey wrapped,
    String purpose,
  ) async {
    try {
      final identity = _EnvelopeIdentity(
        config.vaultId,
        config.generation,
        config.activeKeyId,
      );
      final bytes = await _aes.decrypt(
        SecretBox(
          wrapped.cipherText,
          nonce: wrapped.nonce,
          mac: Mac(wrapped.mac),
        ),
        secretKey: kek,
        aad: identity.aad(purpose),
      );
      if (bytes.length != 32) {
        throw const VaultUnlockFailed();
      }
      return VaultKeyring.single(config.activeKeyId, bytes);
    } on Object {
      throw const VaultUnlockFailed();
    }
  }

  Future<WrappedVaultKey> _wrap(
    List<int> masterKey,
    SecretKey kek,
    List<int> aad,
  ) async {
    final box = await _aes.encrypt(
      masterKey,
      secretKey: kek,
      nonce: _randomBytes(12),
      aad: aad,
    );
    return WrappedVaultKey(
      nonce: box.nonce,
      cipherText: box.cipherText,
      mac: box.mac.bytes,
    );
  }

  Future<SecretKey> _derivePasswordKey(
    String password,
    List<int> salt,
    Argon2idParameters parameters,
  ) {
    return Argon2id(
      parallelism: parameters.parallelism,
      memory: parameters.memoryKiB,
      iterations: parameters.iterations,
      hashLength: parameters.hashLength,
    ).deriveKey(secretKey: SecretKey(utf8.encode(password)), nonce: salt);
  }

  Future<SecretKey> _deriveRecoveryKey(List<int> key, List<int> salt) {
    return Hkdf(hmac: Hmac.sha256(), outputLength: 32).deriveKey(
      secretKey: SecretKey(key),
      nonce: salt,
      info: utf8.encode('MiaoNotes recovery KEK v1'),
    );
  }

  Uint8List _randomBytes(int length) => Uint8List.fromList(
    List<int>.generate(length, (_) => _random.nextInt(256), growable: false),
  );
}

String encodeRecoveryCode(List<int> bytes) {
  if (bytes.length != 32) {
    throw ArgumentError.value(bytes.length, 'bytes', 'Must contain 32 bytes');
  }
  final body = base64UrlEncode(bytes).replaceAll('=', '');
  final groups = <String>[];
  for (var offset = 0; offset < body.length; offset += 4) {
    groups.add(body.substring(offset, min(offset + 4, body.length)));
  }
  return 'MN1-${groups.join('-')}';
}

Uint8List decodeRecoveryCode(String value) {
  if (!value.startsWith('MN1-')) {
    throw const VaultUnlockFailed();
  }
  final encoded = value.substring(4);
  final bodyBuffer = StringBuffer();
  var encodedOffset = 0;
  var bodyLength = 0;
  // The recovery body is 43 Base64URL characters, displayed in groups of
  // four. A hyphen is also a legal Base64URL character, so separators must be
  // consumed by position instead of deleting every hyphen.
  while (bodyLength < 43) {
    if (encodedOffset >= encoded.length) {
      throw const VaultUnlockFailed();
    }
    bodyBuffer.write(encoded[encodedOffset]);
    encodedOffset += 1;
    bodyLength += 1;
    if (bodyLength < 43 && bodyLength % 4 == 0) {
      if (encodedOffset >= encoded.length || encoded[encodedOffset] != '-') {
        throw const VaultUnlockFailed();
      }
      encodedOffset += 1;
    }
  }
  if (encodedOffset != encoded.length) {
    throw const VaultUnlockFailed();
  }
  final body = bodyBuffer.toString();
  final padding = '=' * ((4 - body.length % 4) % 4);
  try {
    final bytes = base64Url.decode('$body$padding');
    if (bytes.length != 32) {
      throw const VaultUnlockFailed();
    }
    return Uint8List.fromList(bytes);
  } on FormatException {
    throw const VaultUnlockFailed();
  }
}

sealed class VaultCryptoException implements Exception {
  const VaultCryptoException(this.message);

  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

final class VaultCryptoFormatException extends VaultCryptoException {
  const VaultCryptoFormatException(super.message);
}

final class VaultUnlockFailed extends VaultCryptoException {
  const VaultUnlockFailed() : super('The password or recovery key is invalid');
}

final class _EnvelopeIdentity {
  const _EnvelopeIdentity(this.vaultId, this.generation, this.keyId);

  final String vaultId;
  final int generation;
  final String keyId;

  Uint8List aad(String purpose) => Uint8List.fromList(
    utf8.encode(
      'MiaoNotes key envelope v1\u0000$vaultId\u0000$generation\u0000$keyId\u0000$purpose',
    ),
  );
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String) {
    throw VaultCryptoFormatException('$key must be a string');
  }
  return value;
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw VaultCryptoFormatException('$key must be an integer');
  }
  return value;
}

Map<String, Object?> _requiredMap(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! Map) {
    throw VaultCryptoFormatException('$key must be an object');
  }
  return value.cast<String, Object?>();
}
