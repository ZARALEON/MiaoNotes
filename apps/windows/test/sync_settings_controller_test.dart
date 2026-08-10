import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miaonotes_core/miaonotes_core.dart';
import 'package:miaonotes_windows/src/application/miaonotes_application.dart';
import 'package:miaonotes_windows/src/application/sync_configuration.dart';
import 'package:miaonotes_windows/src/application/sync_settings_controller.dart';
import 'package:miaonotes_windows/src/application/windows_credential_store.dart';
import 'package:miaonotes_windows/src/ui/miaonotes_bootstrap.dart';
import 'package:miaonotes_windows/src/ui/miaonotes_shell.dart';

void main() {
  test('sync profile file stores only non-sensitive configuration', () async {
    final directory = await Directory.systemTemp.createTemp(
      'miaonotes-sync-profile-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}${Platform.pathSeparator}sync.json');
    final store = FileSyncProfileStore(file);
    final profile = _profile();

    await store.write(profile);
    final loaded = await store.read();

    expect(loaded!.endpoint, profile.endpoint);
    expect(loaded.bucket, profile.bucket);
    expect(loaded.objectPrefix, profile.objectPrefix);
    final raw = await file.readAsString();
    expect(raw, isNot(contains('access-key')));
    expect(raw, isNot(contains('secret-key')));
  });

  test(
    'Windows Credential Manager round-trips and deletes an exact key',
    () async {
      final target = 'MiaoNotes/Test/${DateTime.now().microsecondsSinceEpoch}';
      final store = WindowsCredentialStore(targetName: target);
      const credentials = SyncCredentials(
        accessKeyId: 'temporary-test-access',
        secretAccessKey: 'temporary-test-secret',
      );
      addTearDown(store.delete);

      await store.write(credentials);
      final loaded = await store.read();
      expect(loaded!.accessKeyId, credentials.accessKeyId);
      expect(loaded.secretAccessKey, credentials.secretAccessKey);
      expect(loaded.toString(), isNot(contains(credentials.secretAccessKey)));
      await store.delete();
      expect(await store.read(), isNull);
    },
  );

  test(
    'first connection persists credentials and initializes an empty remote',
    () async {
      final remote = FakeObjectStore();
      final fixture = await _Fixture.open(remote: remote);
      addTearDown(fixture.close);
      final settings = fixture.app.syncSettings!;

      expect(settings.state, SyncSettingsState.notConfigured);
      final result = await settings.configure(
        profile: _profile(),
        credentials: _credentials,
        vaultPassword: _vaultPassword,
      );

      expect(result, SyncConnectResult.connected);
      expect(settings.state, SyncSettingsState.ready);
      expect(fixture.profileStore.profile, isNotNull);
      expect(fixture.credentialStore.credentials, isNotNull);
      expect(await remote.get(ProtocolPaths.vaultConfig), isNotNull);
      expect(await remote.get(ProtocolPaths.cryptoConfig), isNotNull);
      expect(settings.takeRecoveryCode(), startsWith('MN1-'));
    },
  );

  test(
    'Windows Credential Manager protects an exact Vault master key',
    () async {
      final prefix =
          'MiaoNotes/TestVault/${DateTime.now().microsecondsSinceEpoch}';
      final store = WindowsVaultKeyStore(targetPrefix: prefix);
      final keyBytes = List<int>.generate(32, (index) => index);
      addTearDown(() => store.delete('vault-test', 'key-1'));

      await store.write('vault-test', 'key-1', keyBytes);
      expect(await store.read('vault-test', 'key-1'), keyBytes);
      expect(await store.read('vault-test', 'key-2'), isNull);
      await store.delete('vault-test', 'key-1');
      expect(await store.read('vault-test', 'key-1'), isNull);
    },
  );

  test(
    'mismatched remote stays read-only until an empty local adopts it',
    () async {
      final remote = FakeObjectStore();
      final remoteVault = VaultIdentity(
        vaultId: 'remote-existing',
        generation: 2,
        createdAtUtc: DateTime.utc(2025, 3, 4),
      );
      await remote.putImmutable(
        ProtocolPaths.vaultConfig,
        remoteVault.toBytes(),
      );
      final fixture = await _Fixture.open(remote: remote);
      addTearDown(fixture.close);
      final settings = fixture.app.syncSettings!;
      final originalVault = await fixture.app.store.vaultIdentity();

      final first = await settings.configure(
        profile: _profile(),
        credentials: _credentials,
        vaultPassword: _vaultPassword,
      );
      expect(first, SyncConnectResult.requiresVaultAdoption);
      expect(
        (await fixture.app.store.vaultIdentity()).vaultId,
        originalVault.vaultId,
      );
      expect(remote.objectCount, 1);

      final adopted = await settings.configure(
        profile: _profile(),
        credentials: _credentials,
        vaultPassword: _vaultPassword,
        adoptRemoteVault: true,
      );
      expect(adopted, SyncConnectResult.connected);
      expect(
        (await fixture.app.store.vaultIdentity()).vaultId,
        remoteVault.vaultId,
      );
      expect(remote.objectCount, 2);
    },
  );

  test('saved local content blocks a mismatched Vault adoption', () async {
    final remote = FakeObjectStore();
    final remoteVault = VaultIdentity(
      vaultId: 'remote-existing',
      generation: 1,
      createdAtUtc: DateTime.utc(2025, 3, 4),
    );
    await remote.putImmutable(ProtocolPaths.vaultConfig, remoteVault.toBytes());
    final fixture = await _Fixture.open(remote: remote);
    addTearDown(fixture.close);
    fixture.app.workspace.updateBody('local data must survive');
    await fixture.app.workspace.flush();

    await expectLater(
      fixture.app.syncSettings!.configure(
        profile: _profile(),
        credentials: _credentials,
        vaultPassword: _vaultPassword,
        adoptRemoteVault: true,
      ),
      throwsA(isA<VaultAdoptionNotAllowedException>()),
    );
    expect(remote.objectCount, 1);
    expect(fixture.app.workspace.currentDraft!.body, 'local data must survive');
  });

  test(
    'legacy plaintext remote objects are never mixed with E2E data',
    () async {
      final remote = FakeObjectStore();
      final fixture = await _Fixture.open(remote: remote);
      addTearDown(fixture.close);
      final localVault = await fixture.app.store.vaultIdentity();
      await remote.putImmutable(
        ProtocolPaths.vaultConfig,
        localVault.toBytes(),
      );
      await remote.putImmutable(
        ProtocolPaths.revision('legacy-note', 'legacy-revision'),
        <int>[1, 2, 3],
      );

      await expectLater(
        fixture.app.syncSettings!.configure(
          profile: _profile(),
          credentials: _credentials,
          vaultPassword: _vaultPassword,
        ),
        throwsA(isA<UnencryptedRemoteVaultException>()),
      );
      expect(await remote.get(ProtocolPaths.cryptoConfig), isNull);
    },
  );

  test(
    'background sync uploads committed note payloads as ciphertext',
    () async {
      final remote = FakeObjectStore();
      final fixture = await _Fixture.open(remote: remote);
      addTearDown(fixture.close);
      final settings = fixture.app.syncSettings!;
      await settings.configure(
        profile: _profile(),
        credentials: _credentials,
        vaultPassword: _vaultPassword,
      );
      settings.takeRecoveryCode();

      fixture.app.workspace.updateBody('secret note must not appear in R2');
      await fixture.app.workspace.flush();
      expect(await fixture.app.localCommits.commitNow(), 1);
      await settings.syncNow();

      final revisions = await remote.listKeys(
        '${ProtocolPaths.root}revisions/',
      );
      expect(revisions, isNotEmpty);
      final rawPayload = String.fromCharCodes(
        (await remote.get(revisions.first))!.bytes,
      );
      expect(rawPayload, isNot(contains('secret note must not appear in R2')));
      expect(rawPayload, contains('AES-256-GCM'));
    },
  );

  testWidgets('settings dialog connects without blocking the editor shell', (
    tester,
  ) async {
    final remote = FakeObjectStore();
    final fixture = await _Fixture.open(remote: remote);
    await tester.pumpWidget(
      MiaoNotesShell(
        workspace: fixture.app.workspace,
        localCommits: fixture.app.localCommits,
        syncSettings: fixture.app.syncSettings,
      ),
    );

    expect(find.byKey(const Key('note-body-field')), findsOneWidget);
    await tester.tap(find.byKey(const Key('sync-settings-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('sync-endpoint-field')),
      'https://example.invalid',
    );
    await tester.enterText(find.byKey(const Key('sync-bucket-field')), 'notes');
    await tester.enterText(
      find.byKey(const Key('sync-access-key-field')),
      _credentials.accessKeyId,
    );
    await tester.enterText(
      find.byKey(const Key('sync-secret-key-field')),
      _credentials.secretAccessKey,
    );
    await tester.enterText(
      find.byKey(const Key('sync-vault-password-field')),
      _vaultPassword,
    );
    await tester.enterText(
      find.byKey(const Key('sync-vault-password-confirm-field')),
      _vaultPassword,
    );
    await tester.tap(find.byKey(const Key('sync-connect-button')));
    for (var attempt = 0; attempt < 50; attempt += 1) {
      await tester.pump(const Duration(milliseconds: 20));
      if (find.byKey(const Key('sync-new-recovery-code')).evaluate().isNotEmpty) {
        break;
      }
    }
    expect(find.byKey(const Key('sync-new-recovery-code')), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('sync-confirm-recovery-saved-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('R2 同步设置'), findsNothing);
    expect(fixture.app.syncSettings!.state, SyncSettingsState.ready);
    expect(find.byKey(const Key('note-body-field')), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await fixture.close();
  });

  testWidgets('credential loading starts only after the editor renders', (
    tester,
  ) async {
    final profileStore = _BlockingProfileStore();
    final credentialStore = _MemoryCredentialStore();
    late MiaoNotesApplication app;
    await tester.pumpWidget(
      MiaoNotesBootstrap(
        openApplication: () async {
          app = await MiaoNotesApplication.open(
            database: MiaoNotesDatabase.inMemory(),
            idFactory: SequenceIdFactory('post-frame'),
            clock: _AdvancingClock().call,
            syncProfileStore: profileStore,
            syncCredentialStore: credentialStore,
            vaultKeyStore: _MemoryVaultKeyStore(),
          );
          return app;
        },
      ),
    );
    for (var attempt = 0; attempt < 20; attempt += 1) {
      await tester.pump(const Duration(milliseconds: 10));
      if (find.byKey(const Key('note-body-field')).evaluate().isNotEmpty) {
        break;
      }
    }

    expect(find.byKey(const Key('note-body-field')), findsOneWidget);
    expect(profileStore.readStarted.isCompleted, isTrue);
    expect(credentialStore.readCount, 0);

    profileStore.release.complete();
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await app.close();
  });
}

const _credentials = SyncCredentials(
  accessKeyId: 'access-key',
  secretAccessKey: 'secret-key',
);

const _vaultPassword = 'local test vault password';

SyncProfile _profile() => SyncProfile(
  endpoint: Uri.parse('https://example.invalid'),
  bucket: 'notes',
  objectPrefix: 'personal',
);

final class _Fixture {
  _Fixture({
    required this.app,
    required this.profileStore,
    required this.credentialStore,
  });

  static Future<_Fixture> open({required FakeObjectStore remote}) async {
    final profileStore = _MemoryProfileStore();
    final credentialStore = _MemoryCredentialStore();
    final app = await MiaoNotesApplication.open(
      database: MiaoNotesDatabase.inMemory(),
      idFactory: SequenceIdFactory('settings'),
      clock: _AdvancingClock().call,
      syncProfileStore: profileStore,
      syncCredentialStore: credentialStore,
      vaultKeyStore: _MemoryVaultKeyStore(),
      configuredObjectStoreFactory: (_, _) => (store: remote, dispose: () {}),
      syncPasswordParameters: const Argon2idParameters(
        memoryKiB: 64,
        iterations: 1,
        parallelism: 1,
      ),
    );
    await app.startBackgroundWork();
    return _Fixture(
      app: app,
      profileStore: profileStore,
      credentialStore: credentialStore,
    );
  }

  final MiaoNotesApplication app;
  final _MemoryProfileStore profileStore;
  final _MemoryCredentialStore credentialStore;

  Future<void> close() => app.close();
}

final class _MemoryProfileStore implements SyncProfileStore {
  SyncProfile? profile;

  @override
  Future<void> delete() async => profile = null;

  @override
  Future<SyncProfile?> read() async => profile;

  @override
  Future<void> write(SyncProfile value) async => profile = value;
}

final class _MemoryCredentialStore implements SyncCredentialStore {
  SyncCredentials? credentials;
  int readCount = 0;

  @override
  Future<void> delete() async => credentials = null;

  @override
  Future<SyncCredentials?> read() async {
    readCount += 1;
    return credentials;
  }

  @override
  Future<void> write(SyncCredentials value) async => credentials = value;
}

final class _MemoryVaultKeyStore implements VaultKeyStore {
  final Map<String, List<int>> _keys = <String, List<int>>{};

  String _key(String vaultId, String keyId) => '$vaultId/$keyId';

  @override
  Future<void> delete(String vaultId, String keyId) async {
    _keys.remove(_key(vaultId, keyId));
  }

  @override
  Future<List<int>?> read(String vaultId, String keyId) async {
    final bytes = _keys[_key(vaultId, keyId)];
    return bytes == null ? null : List<int>.of(bytes);
  }

  @override
  Future<void> write(String vaultId, String keyId, List<int> keyBytes) async {
    _keys[_key(vaultId, keyId)] = List<int>.of(keyBytes);
  }
}

final class _BlockingProfileStore implements SyncProfileStore {
  final readStarted = Completer<void>();
  final release = Completer<void>();

  @override
  Future<void> delete() async {}

  @override
  Future<SyncProfile?> read() async {
    readStarted.complete();
    await release.future;
    return null;
  }

  @override
  Future<void> write(SyncProfile profile) async {}
}

final class _AdvancingClock {
  DateTime _now = DateTime.utc(2026, 8, 10, 18);

  DateTime call() {
    final result = _now;
    _now = _now.add(const Duration(milliseconds: 1));
    return result;
  }
}
