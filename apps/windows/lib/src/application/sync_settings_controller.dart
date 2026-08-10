import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:miaonotes_core/miaonotes_core.dart';

import 'local_commit_coordinator.dart';
import 'note_workspace_controller.dart';
import 'remote_sync_coordinator.dart';
import 'sync_configuration.dart';

enum SyncSettingsState {
  dormant,
  loading,
  notConfigured,
  connecting,
  ready,
  vaultMismatch,
  failed,
}

enum SyncConnectResult { connected, requiresVaultAdoption }

typedef ConfiguredObjectStore = ({ObjectStore store, void Function() dispose});

typedef ConfiguredObjectStoreFactory =
    ConfiguredObjectStore Function(
      SyncProfile profile,
      SyncCredentials credentials,
    );

/// Owns post-frame configuration loading and the dynamically replaceable remote
/// coordinator. Network access, Argon2id and key loading never run on the
/// startup-to-editor path.
final class SyncSettingsController extends ChangeNotifier {
  SyncSettingsController({
    required this.localStore,
    required this.workspace,
    required this.localCommits,
    required this.profileStore,
    required this.credentialStore,
    required this.vaultKeyStore,
    ConfiguredObjectStoreFactory? objectStoreFactory,
    VaultCryptoService? cryptoService,
    this.passwordParameters = const Argon2idParameters(),
    this.pollInterval = const Duration(minutes: 1),
  }) : objectStoreFactory = objectStoreFactory ?? _createS3Store,
       cryptoService = cryptoService ?? VaultCryptoService();

  final PersistentNoteStore localStore;
  final NoteWorkspaceController workspace;
  final LocalCommitCoordinator localCommits;
  final SyncProfileStore profileStore;
  final SyncCredentialStore credentialStore;
  final VaultKeyStore vaultKeyStore;
  final ConfiguredObjectStoreFactory objectStoreFactory;
  final VaultCryptoService cryptoService;
  final Argon2idParameters passwordParameters;
  final Duration pollInterval;

  SyncSettingsState _state = SyncSettingsState.dormant;
  SyncProfile? _profile;
  VaultIdentity? _pendingRemoteVault;
  RemoteSyncCoordinator? _remoteSync;
  VaultCryptoConfig? _activeCrypto;
  String? _pendingRecoveryCode;
  Object? _error;
  bool _started = false;
  bool _disposed = false;

  SyncSettingsState get state => _state;
  SyncProfile? get profile => _profile;
  VaultIdentity? get pendingRemoteVault => _pendingRemoteVault;
  RemoteSyncCoordinator? get remoteSync => _remoteSync;
  Object? get error => _error;
  bool get isConfigured => _profile != null;
  bool get hasPendingRecoveryCode => _pendingRecoveryCode != null;

  /// Returns a newly created recovery code exactly once.
  String? takeRecoveryCode() {
    final value = _pendingRecoveryCode;
    _pendingRecoveryCode = null;
    return value;
  }

  Future<void> start() async {
    if (_started || _disposed) {
      return;
    }
    _started = true;
    _state = SyncSettingsState.loading;
    _notify();
    _PreparedStore? candidate;
    try {
      final profile = await profileStore.read();
      if (profile == null) {
        _state = SyncSettingsState.notConfigured;
        _notify();
        return;
      }
      _profile = profile;
      final credentials = await credentialStore.read();
      if (credentials == null) {
        throw const SyncConfigurationException(
          'The Windows S3 credential is missing',
        );
      }
      candidate = await _prepareCandidate(profile, credentials);
      if (candidate.remoteVault case final remote?
          when !_sameVault(candidate.localVault, remote)) {
        candidate.dispose();
        candidate = null;
        _pendingRemoteVault = remote;
        _state = SyncSettingsState.vaultMismatch;
        _notify();
        return;
      }
      candidate = await _secureCandidate(candidate, allowCreate: false);
      await _activate(candidate);
      candidate = null;
      _state = SyncSettingsState.ready;
      _error = null;
    } on Object catch (error) {
      candidate?.dispose();
      _error = error;
      _state = SyncSettingsState.failed;
    }
    _notify();
  }

  Future<SyncConnectResult> configure({
    required SyncProfile profile,
    SyncCredentials? credentials,
    String? vaultPassword,
    String? recoveryCode,
    bool adoptRemoteVault = false,
  }) async {
    if (_disposed) {
      throw StateError('Sync settings are closed');
    }
    _state = SyncSettingsState.connecting;
    _error = null;
    _pendingRemoteVault = null;
    _notify();

    _PreparedStore? candidate;
    try {
      final previousCredentials = await credentialStore.read();
      final effectiveCredentials = credentials ?? previousCredentials;
      if (effectiveCredentials == null) {
        throw const SyncConfigurationException(
          'Access key ID and secret access key are required',
        );
      }
      candidate = await _prepareCandidate(profile, effectiveCredentials);
      final remoteVault = candidate.remoteVault;
      if (remoteVault != null &&
          !_sameVault(candidate.localVault, remoteVault)) {
        if (!adoptRemoteVault) {
          candidate.dispose();
          candidate = null;
          _pendingRemoteVault = remoteVault;
          _state = _remoteSync == null
              ? SyncSettingsState.vaultMismatch
              : SyncSettingsState.ready;
          _notify();
          return SyncConnectResult.requiresVaultAdoption;
        }
        await localStore.adoptRemoteVault(remoteVault);
        candidate = candidate.withLocalVault(remoteVault);
      }

      candidate = await _secureCandidate(
        candidate,
        password: vaultPassword,
        recoveryCode: recoveryCode,
        allowCreate: true,
      );

      var credentialChanged = false;
      try {
        if (credentials != null) {
          await credentialStore.write(credentials);
          credentialChanged = true;
        }
        await profileStore.write(profile);
      } on Object {
        if (credentialChanged) {
          if (previousCredentials == null) {
            await credentialStore.delete();
          } else {
            await credentialStore.write(previousCredentials);
          }
        }
        rethrow;
      }

      await vaultKeyStore.write(
        candidate.cryptoConfig!.vaultId,
        candidate.cryptoConfig!.activeKeyId,
        candidate.keyring!.keyBytesFor(candidate.cryptoConfig!.activeKeyId)!,
      );
      if (candidate.recoveryCode != null) {
        _pendingRecoveryCode = candidate.recoveryCode;
      }
      await _activate(candidate);
      candidate = null;
      _profile = profile;
      _pendingRemoteVault = null;
      _error = null;
      _state = SyncSettingsState.ready;
      _notify();
      return SyncConnectResult.connected;
    } on Object catch (error) {
      if (candidate?.recoveryCode case final recovery?) {
        _pendingRecoveryCode = recovery;
      }
      candidate?.dispose();
      _error = error;
      _state = _remoteSync == null
          ? SyncSettingsState.failed
          : SyncSettingsState.ready;
      _notify();
      rethrow;
    }
  }

  Future<void> disconnect() async {
    if (_disposed) {
      return;
    }
    final remote = _remoteSync;
    final crypto = _activeCrypto;
    _remoteSync = null;
    _activeCrypto = null;
    if (remote != null) {
      remote.removeListener(_onRemoteChanged);
      await remote.close();
    }
    try {
      await profileStore.delete();
      await credentialStore.delete();
      if (crypto != null) {
        await vaultKeyStore.delete(crypto.vaultId, crypto.activeKeyId);
      }
      _profile = null;
      _pendingRemoteVault = null;
      _pendingRecoveryCode = null;
      _error = null;
      _state = SyncSettingsState.notConfigured;
    } on Object catch (error) {
      _error = error;
      _state = SyncSettingsState.failed;
    }
    _notify();
  }

  Future<SyncRunStats?> syncNow() =>
      _remoteSync?.syncNow() ?? Future<SyncRunStats?>.value();

  Future<void> close() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    final remote = _remoteSync;
    _remoteSync = null;
    if (remote != null) {
      remote.removeListener(_onRemoteChanged);
      await remote.close();
    }
    _pendingRecoveryCode = null;
    super.dispose();
  }

  Future<_PreparedStore> _prepareCandidate(
    SyncProfile profile,
    SyncCredentials credentials,
  ) async {
    final configured = objectStoreFactory(profile, credentials);
    try {
      final remoteKeys = await configured.store.listKeys(ProtocolPaths.root);
      final remoteObject = await configured.store.get(
        ProtocolPaths.vaultConfig,
      );
      VaultIdentity? remoteVault;
      if (remoteObject != null) {
        try {
          remoteVault = VaultIdentity.fromBytes(remoteObject.bytes);
        } on Object {
          throw const RemoteObjectCorruptedException(
            'Remote vault identity is invalid',
          );
        }
      }
      final cryptoObject = await configured.store.get(
        ProtocolPaths.cryptoConfig,
      );
      VaultCryptoConfig? cryptoConfig;
      if (cryptoObject != null) {
        try {
          cryptoConfig = VaultCryptoConfig.fromBytes(cryptoObject.bytes);
        } on Object {
          throw const RemoteObjectCorruptedException(
            'Remote crypto config is invalid',
          );
        }
      }
      return _PreparedStore(
        configured: configured,
        localVault: await localStore.vaultIdentity(),
        remoteVault: remoteVault,
        remoteKeys: remoteKeys,
        cryptoConfig: cryptoConfig,
      );
    } on Object {
      configured.dispose();
      rethrow;
    }
  }

  Future<_PreparedStore> _secureCandidate(
    _PreparedStore candidate, {
    String? password,
    String? recoveryCode,
    required bool allowCreate,
  }) async {
    final identity = candidate.remoteVault ?? candidate.localVault;
    var config = candidate.cryptoConfig;
    VaultKeyring? keyring;
    String? newRecoveryCode;

    if (config == null) {
      final protectedRemoteObjects = candidate.remoteKeys.where(
        (key) =>
            key != ProtocolPaths.vaultConfig &&
            key != ProtocolPaths.cryptoConfig,
      );
      if (protectedRemoteObjects.isNotEmpty) {
        throw const UnencryptedRemoteVaultException(
          'The remote contains legacy plaintext objects; automatic migration is disabled',
        );
      }
      if (!allowCreate || password == null || password.isEmpty) {
        throw const VaultPasswordRequiredException(
          'A Vault password is required to enable end-to-end encryption',
        );
      }
      final bootstrap = await cryptoService.create(
        vaultId: identity.vaultId,
        generation: identity.generation,
        password: password,
        passwordParameters: passwordParameters,
      );
      try {
        await candidate.rawStore.putImmutable(
          ProtocolPaths.cryptoConfig,
          bootstrap.config.toBytes(),
        );
        config = bootstrap.config;
        keyring = bootstrap.keyring;
        newRecoveryCode = bootstrap.recoveryCode;
      } on ImmutableObjectConflict {
        final concurrent = await candidate.rawStore.get(
          ProtocolPaths.cryptoConfig,
        );
        if (concurrent == null) {
          rethrow;
        }
        config = VaultCryptoConfig.fromBytes(concurrent.bytes);
      }
    }

    if (config.vaultId != identity.vaultId ||
        config.generation != identity.generation) {
      throw const RemoteObjectCorruptedException(
        'Crypto config belongs to a different Vault identity',
      );
    }

    if (keyring == null) {
      final storedKey = await vaultKeyStore.read(
        config.vaultId,
        config.activeKeyId,
      );
      if (storedKey != null) {
        keyring = VaultKeyring.single(config.activeKeyId, storedKey);
      } else if (recoveryCode != null && recoveryCode.trim().isNotEmpty) {
        keyring = await cryptoService.unlockWithRecoveryCode(
          config,
          recoveryCode.trim(),
        );
      } else if (password != null && password.isNotEmpty) {
        keyring = await cryptoService.unlockWithPassword(config, password);
      } else {
        throw const VaultPasswordRequiredException(
          'This device needs the Vault password or recovery key',
        );
      }
    }

    return candidate.secured(
      cryptoConfig: config,
      keyring: keyring,
      recoveryCode: newRecoveryCode,
    );
  }

  Future<void> _activate(_PreparedStore candidate) async {
    final previous = _remoteSync;
    if (previous != null) {
      previous.removeListener(_onRemoteChanged);
      await previous.close();
    }
    final remote = RemoteSyncCoordinator(
      localStore: localStore,
      remoteStore: candidate.store,
      workspace: workspace,
      localCommits: localCommits,
      pollInterval: pollInterval,
      disposeRemoteStore: candidate.dispose,
    );
    _remoteSync = remote;
    _activeCrypto = candidate.cryptoConfig;
    remote.addListener(_onRemoteChanged);
    if (_started) {
      await remote.start();
    }
  }

  void _onRemoteChanged() => _notify();

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}

final class _PreparedStore {
  const _PreparedStore({
    required this.configured,
    required this.localVault,
    required this.remoteVault,
    required this.remoteKeys,
    required this.cryptoConfig,
    this.keyring,
    this.recoveryCode,
  });

  final ConfiguredObjectStore configured;
  final VaultIdentity localVault;
  final VaultIdentity? remoteVault;
  final List<String> remoteKeys;
  final VaultCryptoConfig? cryptoConfig;
  final VaultKeyring? keyring;
  final String? recoveryCode;

  ObjectStore get rawStore => configured.store;
  ObjectStore get store {
    final keys = keyring;
    if (keys == null) {
      throw StateError('Remote store has not been unlocked');
    }
    return EncryptedObjectStore(inner: configured.store, keys: keys);
  }

  _PreparedStore withLocalVault(VaultIdentity value) => _PreparedStore(
    configured: configured,
    localVault: value,
    remoteVault: remoteVault,
    remoteKeys: remoteKeys,
    cryptoConfig: cryptoConfig,
    keyring: keyring,
    recoveryCode: recoveryCode,
  );

  _PreparedStore secured({
    required VaultCryptoConfig cryptoConfig,
    required VaultKeyring keyring,
    String? recoveryCode,
  }) => _PreparedStore(
    configured: configured,
    localVault: localVault,
    remoteVault: remoteVault,
    remoteKeys: remoteKeys,
    cryptoConfig: cryptoConfig,
    keyring: keyring,
    recoveryCode: recoveryCode,
  );

  void dispose() => configured.dispose();
}

bool _sameVault(VaultIdentity local, VaultIdentity remote) =>
    local.vaultId == remote.vaultId &&
    local.generation == remote.generation &&
    local.protocolVersion == remote.protocolVersion;

ConfiguredObjectStore _createS3Store(
  SyncProfile profile,
  SyncCredentials credentials,
) {
  final store = S3ObjectStore(
    endpoint: profile.endpoint,
    bucket: profile.bucket,
    credentials: credentials.toS3Credentials(),
    region: profile.region,
    objectPrefix: profile.objectPrefix,
  );
  return (store: store, dispose: () => store.close(force: true));
}
