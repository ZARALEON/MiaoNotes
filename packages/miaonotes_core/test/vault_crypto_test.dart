import 'dart:convert';

import 'package:miaonotes_core/miaonotes_core.dart';
import 'package:test/test.dart';

void main() {
  const fastParameters = Argon2idParameters(
    memoryKiB: 64,
    iterations: 1,
    parallelism: 1,
  );

  test('password and recovery code unlock the same master key', () async {
    final service = VaultCryptoService();
    final bootstrap = await service.create(
      vaultId: 'vault-a',
      generation: 1,
      password: 'correct horse battery staple',
      createdAt: DateTime.utc(2026, 8, 10),
      passwordParameters: fastParameters,
    );

    final decoded = VaultCryptoConfig.fromBytes(bootstrap.config.toBytes());
    final fromPassword = await service.unlockWithPassword(
      decoded,
      'correct horse battery staple',
    );
    final fromRecovery = await service.unlockWithRecoveryCode(
      decoded,
      bootstrap.recoveryCode,
    );

    expect(
      fromPassword.keyBytesFor(decoded.activeKeyId),
      bootstrap.keyring.keyBytesFor(decoded.activeKeyId),
    );
    expect(
      fromRecovery.keyBytesFor(decoded.activeKeyId),
      bootstrap.keyring.keyBytesFor(decoded.activeKeyId),
    );
  });

  test(
    'config contains wrapped keys but no password or recovery key',
    () async {
      final service = VaultCryptoService();
      final bootstrap = await service.create(
        vaultId: 'vault-a',
        generation: 1,
        password: 'never-store-this-password',
        passwordParameters: fastParameters,
      );
      final text = utf8.decode(bootstrap.config.toBytes());
      final masterKeyText = base64Encode(
        bootstrap.keyring.keyBytesFor(bootstrap.config.activeKeyId)!,
      );

      expect(text, contains('Argon2id'));
      expect(text, contains('HKDF-SHA256'));
      expect(text, isNot(contains('never-store-this-password')));
      expect(text, isNot(contains(bootstrap.recoveryCode)));
      expect(text, isNot(contains(masterKeyText)));
    },
  );

  test('wrong password and modified identity fail generically', () async {
    final service = VaultCryptoService();
    final bootstrap = await service.create(
      vaultId: 'vault-a',
      generation: 1,
      password: 'right-password',
      passwordParameters: fastParameters,
    );

    await expectLater(
      service.unlockWithPassword(bootstrap.config, 'wrong-password'),
      throwsA(isA<VaultUnlockFailed>()),
    );

    final json = bootstrap.config.toJson()..['vaultId'] = 'vault-b';
    final changed = VaultCryptoConfig.fromJson(json);
    await expectLater(
      service.unlockWithPassword(changed, 'right-password'),
      throwsA(isA<VaultUnlockFailed>()),
    );
  });

  test('recovery code round-trips and rejects malformed input', () {
    final bytes = List<int>.generate(32, (index) => index);
    final code = encodeRecoveryCode(bytes);

    expect(code, startsWith('MN1-'));
    expect(decodeRecoveryCode(code), bytes);
    expect(
      () => decodeRecoveryCode('MN1-not-a-valid-recovery-key'),
      throwsA(isA<VaultUnlockFailed>()),
    );
  });

  test('recovery code preserves Base64URL hyphens inside groups', () {
    final bytes = List<int>.filled(32, 251);
    final code = encodeRecoveryCode(bytes);

    expect(code, startsWith('MN1--'));
    expect(decodeRecoveryCode(code), bytes);
  });
}
