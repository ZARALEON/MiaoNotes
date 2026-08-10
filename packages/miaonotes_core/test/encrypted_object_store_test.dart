import 'dart:convert';

import 'package:miaonotes_core/miaonotes_core.dart';
import 'package:test/test.dart';

void main() {
  late FakeObjectStore raw;
  late EncryptedObjectStore encrypted;

  setUp(() {
    raw = FakeObjectStore();
    encrypted = EncryptedObjectStore(
      inner: raw,
      keys: VaultKeyring.single('key-1', List<int>.generate(32, (i) => i)),
    );
  });

  test('round-trips protocol objects without storing plaintext', () async {
    const key = 'MiaoNotes/revisions/note-a/rev-a.json';
    final clearText = utf8.encode('{"body":"private cat note"}');

    await encrypted.putImmutable(key, clearText);

    final stored = (await raw.get(key))!;
    expect(utf8.decode(stored.bytes), isNot(contains('private cat note')));
    expect((await encrypted.get(key))!.bytes, clearText);
    expect(await encrypted.listKeys('MiaoNotes/revisions/'), <String>[key]);
  });

  test(
    'identical retry is deterministic and conflicting retry fails',
    () async {
      const key = 'MiaoNotes/events/device-a/0001-event-a.json';
      final bytes = utf8.encode('same immutable payload');

      await encrypted.putImmutable(key, bytes);
      final firstCipherText = (await raw.get(key))!.bytes;
      await encrypted.putImmutable(key, bytes);
      final secondCipherText = (await raw.get(key))!.bytes;

      expect(secondCipherText, firstCipherText);
      await expectLater(
        encrypted.putImmutable(key, utf8.encode('different payload')),
        throwsA(isA<ImmutableObjectConflict>()),
      );
    },
  );

  test('authentication detects ciphertext corruption', () async {
    const key = 'MiaoNotes/revisions/note-a/rev-a.json';
    await encrypted.putImmutable(key, utf8.encode('private'));
    final payload = (await raw.get(key))!.bytes;
    final replacement = List<int>.from(payload);
    replacement[replacement.length ~/ 2] ^= 1;
    raw.corruptForTest(key, replacement);

    await expectLater(
      encrypted.get(key),
      throwsA(isA<EncryptedObjectCorrupted>()),
    );
  });

  test(
    'path binding rejects copying ciphertext to another object key',
    () async {
      const first = 'MiaoNotes/revisions/note-a/rev-a.json';
      const second = 'MiaoNotes/revisions/note-b/rev-b.json';
      await encrypted.putImmutable(first, utf8.encode('private'));
      await raw.putImmutable(second, (await raw.get(first))!.bytes);

      await expectLater(
        encrypted.get(second),
        throwsA(isA<EncryptedObjectCorrupted>()),
      );
    },
  );

  test('bootstrap metadata remains readable before unlock', () async {
    final vault = utf8.encode('{"vaultId":"vault-a"}');
    final crypto = utf8.encode('{"schema":1}');

    await encrypted.putImmutable(ProtocolPaths.vaultConfig, vault);
    await encrypted.putImmutable(ProtocolPaths.cryptoConfig, crypto);

    expect((await raw.get(ProtocolPaths.vaultConfig))!.bytes, vault);
    expect((await raw.get(ProtocolPaths.cryptoConfig))!.bytes, crypto);
  });
}
