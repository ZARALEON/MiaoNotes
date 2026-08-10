import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

import '../model/canonical_json.dart';
import '../storage/object_store.dart';
import '../sync/protocol_paths.dart';
import 'vault_crypto.dart';

/// Encrypts protocol payloads without changing their logical object keys.
///
/// Vault and crypto configs are intentionally readable bootstrap metadata. All
/// other objects are protected with a per-path HKDF key and AES-256-GCM.
final class EncryptedObjectStore implements ObjectStore {
  EncryptedObjectStore({required ObjectStore inner, required VaultKeyring keys})
    : _inner = inner,
      _keys = keys;

  final ObjectStore _inner;
  final VaultKeyring _keys;
  final AesGcm _aes = AesGcm.with256bits();
  final Hkdf _hkdf = Hkdf(hmac: Hmac.sha256(), outputLength: 32);
  final Hmac _nonceMac = Hmac.sha256();

  @override
  Future<StoredObject?> get(String key) async {
    final stored = await _inner.get(key);
    if (stored == null || _isBootstrapMetadata(key)) {
      return stored;
    }
    return StoredObject(key: key, bytes: await _decrypt(key, stored.bytes));
  }

  @override
  Future<List<String>> listKeys(String prefix) => _inner.listKeys(prefix);

  @override
  Future<void> putImmutable(String key, List<int> bytes) async {
    if (_isBootstrapMetadata(key)) {
      await _inner.putImmutable(key, bytes);
      return;
    }
    await _inner.putImmutable(key, await _encrypt(key, bytes));
  }

  bool _isBootstrapMetadata(String key) =>
      key == ProtocolPaths.vaultConfig || key == ProtocolPaths.cryptoConfig;

  Future<Uint8List> _encrypt(String objectKey, List<int> clearText) async {
    final keyId = _keys.activeKeyId;
    final objectKeyBytes = _keys.keyBytesFor(keyId)!;
    final secretKey = await _deriveObjectKey(keyId, objectKey, objectKeyBytes);
    final aad = _aad(keyId, objectKey);
    final nonceMac = await _nonceMac.calculateMac(
      clearText,
      secretKey: secretKey,
      aad: aad,
    );
    final nonce = nonceMac.bytes.sublist(0, 12);
    final box = await _aes.encrypt(
      clearText,
      secretKey: secretKey,
      nonce: nonce,
      aad: aad,
    );
    return canonicalJsonBytes(<String, Object>{
      'algorithm': vaultCryptoAlgorithmV1,
      'ciphertext': base64Encode(box.cipherText),
      'keyId': keyId,
      'mac': base64Encode(box.mac.bytes),
      'nonce': base64Encode(box.nonce),
      'schema': vaultCryptoSchemaV1,
    });
  }

  Future<Uint8List> _decrypt(String objectKey, List<int> payload) async {
    try {
      final decoded = jsonDecode(utf8.decode(payload));
      if (decoded is! Map<String, dynamic> ||
          decoded['schema'] != vaultCryptoSchemaV1 ||
          decoded['algorithm'] != vaultCryptoAlgorithmV1) {
        throw const EncryptedObjectCorrupted('Invalid encrypted-object header');
      }
      final keyId = decoded['keyId'];
      final nonceText = decoded['nonce'];
      final cipherText = decoded['ciphertext'];
      final macText = decoded['mac'];
      if (keyId is! String ||
          nonceText is! String ||
          cipherText is! String ||
          macText is! String) {
        throw const EncryptedObjectCorrupted('Invalid encrypted-object fields');
      }
      final masterKey = _keys.keyBytesFor(keyId);
      if (masterKey == null) {
        throw VaultKeyUnavailable('Vault key is unavailable: $keyId');
      }
      final nonce = base64Decode(nonceText);
      final mac = base64Decode(macText);
      if (nonce.length != 12 || mac.length != 16) {
        throw const EncryptedObjectCorrupted('Invalid nonce or MAC length');
      }
      final secretKey = await _deriveObjectKey(keyId, objectKey, masterKey);
      final clearText = await _aes.decrypt(
        SecretBox(base64Decode(cipherText), nonce: nonce, mac: Mac(mac)),
        secretKey: secretKey,
        aad: _aad(keyId, objectKey),
      );
      return Uint8List.fromList(clearText);
    } on VaultKeyUnavailable {
      rethrow;
    } on EncryptedObjectCorrupted {
      rethrow;
    } on Object {
      throw EncryptedObjectCorrupted(
        'Encrypted object authentication failed: $objectKey',
      );
    }
  }

  Future<SecretKey> _deriveObjectKey(
    String keyId,
    String objectKey,
    List<int> masterKey,
  ) {
    return _hkdf.deriveKey(
      secretKey: SecretKey(masterKey),
      nonce: utf8.encode('MiaoNotes object salt v1'),
      info: utf8.encode('MiaoNotes object key v1\u0000$keyId\u0000$objectKey'),
    );
  }

  Uint8List _aad(String keyId, String objectKey) => Uint8List.fromList(
    utf8.encode('MiaoNotes encrypted object v1\u0000$keyId\u0000$objectKey'),
  );
}

final class EncryptedObjectCorrupted extends ObjectStoreException {
  const EncryptedObjectCorrupted(super.message);
}

final class VaultKeyUnavailable extends ObjectStoreException {
  const VaultKeyUnavailable(super.message);
}
