import 'dart:io';

import 'package:miaonotes_core/miaonotes_core.dart';

import 'local_commit_coordinator.dart';
import 'note_workspace_controller.dart';
import 'remote_sync_coordinator.dart';
import 'sync_configuration.dart';
import 'sync_settings_controller.dart';
import 'windows_credential_store.dart';

typedef BackgroundTask = Future<void> Function(MiaoNotesApplication app);

final class MiaoNotesApplication {
  MiaoNotesApplication._({
    required this.database,
    required this.store,
    required this.workspace,
    required this.localCommits,
    required this.remoteSync,
    required this.syncSettings,
    required this._backgroundTask,
  });

  static Future<MiaoNotesApplication> open({
    MiaoNotesDatabase? database,
    Directory? dataDirectory,
    BackgroundTask? backgroundTask,
    DateTime Function()? clock,
    IdFactory? idFactory,
    Duration localCommitIdleDelay = const Duration(seconds: 2),
    ObjectStore? remoteStore,
    Duration remotePollInterval = const Duration(minutes: 1),
    void Function()? disposeRemoteStore,
    SyncProfileStore? syncProfileStore,
    SyncCredentialStore? syncCredentialStore,
    VaultKeyStore? vaultKeyStore,
    ConfiguredObjectStoreFactory? configuredObjectStoreFactory,
    Argon2idParameters syncPasswordParameters = const Argon2idParameters(),
  }) async {
    final effectiveClock = clock ?? (() => DateTime.now().toUtc());
    final effectiveIds = idFactory ?? UuidV7IdFactory();
    final effectiveDirectory = database == null
        ? dataDirectory ?? _defaultDataDirectory()
        : dataDirectory;
    if (effectiveDirectory != null && !await effectiveDirectory.exists()) {
      await effectiveDirectory.create(recursive: true);
    }
    final effectiveDatabase =
        database ??
        MiaoNotesDatabase.openFile(
          File(
            '${effectiveDirectory!.path}${Platform.pathSeparator}miaonotes.db',
          ),
        );
    try {
      final store = PersistentNoteStore(
        database: effectiveDatabase,
        clock: effectiveClock,
        idFactory: effectiveIds,
      );

      if (await store.loadVaultIdentity() == null) {
        final now = effectiveClock().toUtc();
        await store.initializeVault(
          vault: VaultIdentity(
            vaultId: effectiveIds.next(now),
            generation: 1,
            createdAtUtc: now,
          ),
          deviceId: effectiveIds.next(now),
          deviceName: Platform.localHostname,
        );
      }

      final workspace = NoteWorkspaceController(
        store: store,
        clock: effectiveClock,
        idFactory: effectiveIds,
      );
      await workspace.initialize();
      final localCommits = LocalCommitCoordinator(
        workspace: workspace,
        store: store,
        idleDelay: localCommitIdleDelay,
      );
      final remoteSync = remoteStore == null
          ? null
          : RemoteSyncCoordinator(
              localStore: store,
              remoteStore: remoteStore,
              workspace: workspace,
              localCommits: localCommits,
              pollInterval: remotePollInterval,
              disposeRemoteStore: disposeRemoteStore,
            );
      final useDefaultSyncStores =
          database == null &&
          remoteStore == null &&
          syncProfileStore == null &&
          syncCredentialStore == null &&
          vaultKeyStore == null;
      final effectiveProfileStore =
          syncProfileStore ??
          (useDefaultSyncStores
              ? FileSyncProfileStore(
                  File(
                    '${effectiveDirectory!.path}${Platform.pathSeparator}'
                    'sync-profile.json',
                  ),
                )
              : null);
      final effectiveCredentialStore =
          syncCredentialStore ??
          (useDefaultSyncStores ? const WindowsCredentialStore() : null);
      final effectiveVaultKeyStore =
          vaultKeyStore ??
          (useDefaultSyncStores ? const WindowsVaultKeyStore() : null);
      if ((effectiveProfileStore == null) !=
              (effectiveCredentialStore == null) ||
          (effectiveProfileStore == null) != (effectiveVaultKeyStore == null)) {
        throw ArgumentError(
          'Sync profile, S3 credential and Vault key stores must be supplied together',
        );
      }
      final syncSettings = effectiveProfileStore == null
          ? null
          : SyncSettingsController(
              localStore: store,
              workspace: workspace,
              localCommits: localCommits,
              profileStore: effectiveProfileStore,
              credentialStore: effectiveCredentialStore!,
              vaultKeyStore: effectiveVaultKeyStore!,
              objectStoreFactory: configuredObjectStoreFactory,
              passwordParameters: syncPasswordParameters,
              pollInterval: remotePollInterval,
            );
      return MiaoNotesApplication._(
        database: effectiveDatabase,
        store: store,
        workspace: workspace,
        localCommits: localCommits,
        remoteSync: remoteSync,
        syncSettings: syncSettings,
        backgroundTask: backgroundTask,
      );
    } on Object {
      await effectiveDatabase.close();
      rethrow;
    }
  }

  final MiaoNotesDatabase database;
  final PersistentNoteStore store;
  final NoteWorkspaceController workspace;
  final LocalCommitCoordinator localCommits;
  final RemoteSyncCoordinator? remoteSync;
  final SyncSettingsController? syncSettings;
  final BackgroundTask? _backgroundTask;

  bool _backgroundStarted = false;
  bool _closed = false;
  Object? backgroundError;
  StackTrace? backgroundStackTrace;

  Future<void> startBackgroundWork() async {
    if (_backgroundStarted || _closed) {
      return;
    }
    _backgroundStarted = true;
    await localCommits.start();
    await remoteSync?.start();
    await syncSettings?.start();
    final task = _backgroundTask;
    if (task == null) {
      return;
    }
    try {
      await task(this);
    } on Object catch (error, stackTrace) {
      backgroundError = error;
      backgroundStackTrace = stackTrace;
    }
  }

  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await syncSettings?.close();
    await remoteSync?.close();
    localCommits.dispose();
    try {
      await workspace.flush();
    } finally {
      workspace.dispose();
      await database.close();
    }
  }
}

Directory _defaultDataDirectory() {
  if (!Platform.isWindows) {
    throw UnsupportedError('The current application shell supports Windows');
  }
  final localAppData = Platform.environment['LOCALAPPDATA'];
  if (localAppData == null || localAppData.isEmpty) {
    throw StateError('LOCALAPPDATA is unavailable');
  }
  return Directory('$localAppData${Platform.pathSeparator}MiaoNotes');
}
