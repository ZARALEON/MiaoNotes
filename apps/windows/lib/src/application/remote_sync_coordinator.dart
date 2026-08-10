import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:miaonotes_core/miaonotes_core.dart';

import 'local_commit_coordinator.dart';
import 'note_workspace_controller.dart';

enum RemoteSyncState { idle, syncing, offline, authenticationFailed, failed }

/// Starts only after the local workspace has rendered.
///
/// It observes completed local revisions, polls for remote events, and never
/// commits mutable Drafts itself.
final class RemoteSyncCoordinator extends ChangeNotifier {
  RemoteSyncCoordinator({
    required PersistentNoteStore localStore,
    required ObjectStore remoteStore,
    required this.workspace,
    required this.localCommits,
    this.pollInterval = const Duration(minutes: 1),
    this.disposeRemoteStore,
  }) : _engine = PersistentSyncEngine(
         localStore: localStore,
         remoteStore: remoteStore,
       );

  final NoteWorkspaceController workspace;
  final LocalCommitCoordinator localCommits;
  final Duration pollInterval;
  final void Function()? disposeRemoteStore;
  final PersistentSyncEngine _engine;

  RemoteSyncState _state = RemoteSyncState.idle;
  Object? _error;
  SyncRunStats? _lastStats;
  DateTime? _lastCompletedAtUtc;
  Future<SyncRunStats?>? _syncTask;
  Timer? _pollTimer;
  bool _started = false;
  bool _disposed = false;
  bool _notifierDisposed = false;

  RemoteSyncState get state => _state;
  Object? get error => _error;
  SyncRunStats? get lastStats => _lastStats;
  DateTime? get lastCompletedAtUtc => _lastCompletedAtUtc;

  Future<void> start() async {
    if (_started || _disposed) {
      return;
    }
    _started = true;
    localCommits.addListener(_onLocalCommitChanged);
    _pollTimer = Timer.periodic(pollInterval, (_) => unawaited(syncNow()));
    await syncNow();
  }

  Future<SyncRunStats?> syncNow() {
    if (_disposed) {
      return Future<SyncRunStats?>.value();
    }
    final running = _syncTask;
    if (running != null) {
      return running;
    }
    final operation = _synchronize();
    _syncTask = operation;
    unawaited(
      operation.whenComplete(() {
        if (identical(_syncTask, operation)) {
          _syncTask = null;
        }
      }),
    );
    return operation;
  }

  @override
  void dispose() {
    _beginDispose();
    if (!_notifierDisposed) {
      _notifierDisposed = true;
      super.dispose();
    }
  }

  Future<void> close() async {
    _beginDispose();
    await _syncTask;
    if (!_notifierDisposed) {
      _notifierDisposed = true;
      super.dispose();
    }
  }

  void _onLocalCommitChanged() {
    if (!_disposed &&
        localCommits.state == LocalCommitState.idle &&
        localCommits.pendingRemoteObjects > 0) {
      unawaited(syncNow());
    }
  }

  Future<SyncRunStats?> _synchronize() async {
    _state = RemoteSyncState.syncing;
    _error = null;
    _notify();
    try {
      final stats = await _engine.syncCommitted();
      if (stats.pulledEvents > 0) {
        await workspace.refreshAfterRemotePull();
      }
      await localCommits.refreshPendingRemoteObjects();
      _lastStats = stats;
      _lastCompletedAtUtc = DateTime.now().toUtc();
      _state = RemoteSyncState.idle;
      _notify();
      return stats;
    } on ObjectStoreAuthenticationFailed catch (error) {
      _error = error;
      _state = RemoteSyncState.authenticationFailed;
    } on ObjectStoreUnavailable catch (error) {
      _error = error;
      _state = RemoteSyncState.offline;
    } on Object catch (error) {
      _error = error;
      _state = RemoteSyncState.failed;
    }
    _notify();
    return null;
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }

  void _beginDispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    _pollTimer?.cancel();
    if (_started) {
      localCommits.removeListener(_onLocalCommitChanged);
    }
    disposeRemoteStore?.call();
  }
}
