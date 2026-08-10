import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:miaonotes_core/miaonotes_core.dart';

import 'note_workspace_controller.dart';

enum LocalCommitState { idle, waiting, committing, failed }

final class LocalCommitCoordinator extends ChangeNotifier {
  LocalCommitCoordinator({
    required this.workspace,
    required this.store,
    this.idleDelay = const Duration(seconds: 2),
  });

  final NoteWorkspaceController workspace;
  final PersistentNoteStore store;
  final Duration idleDelay;

  LocalCommitState _state = LocalCommitState.idle;
  int _pendingRemoteObjects = 0;
  int _openConflicts = 0;
  int _lastCommittedDrafts = 0;
  Object? _error;
  int _observedLocalSaveGeneration = 0;
  Timer? _timer;
  Future<int>? _commitTask;
  bool _started = false;
  bool _disposed = false;

  LocalCommitState get state => _state;
  int get pendingRemoteObjects => _pendingRemoteObjects;
  int get openConflicts => _openConflicts;
  int get lastCommittedDrafts => _lastCommittedDrafts;
  Object? get error => _error;

  Future<void> start() async {
    if (_started || _disposed) {
      return;
    }
    _started = true;
    workspace.addListener(_onWorkspaceChanged);
    try {
      final recovery = await store.recoveryState();
      _pendingRemoteObjects = recovery.pendingObjects;
      _openConflicts = recovery.openConflicts;
      if (recovery.dirtyDrafts > 0) {
        _scheduleCommit(Duration.zero);
      } else {
        _notify();
      }
    } on Object catch (error) {
      _error = error;
      _state = LocalCommitState.failed;
      _notify();
    }
  }

  Future<int> commitNow() {
    final running = _commitTask;
    if (running != null) {
      return running;
    }
    _timer?.cancel();
    final operation = _commit();
    _commitTask = operation;
    unawaited(
      operation.whenComplete(() {
        if (identical(_commitTask, operation)) {
          _commitTask = null;
        }
      }),
    );
    return operation;
  }

  Future<void> refreshPendingRemoteObjects() async {
    final recovery = await store.recoveryState();
    _pendingRemoteObjects = recovery.pendingObjects;
    _openConflicts = recovery.openConflicts;
    _notify();
  }

  Future<void> refreshAfterImport() async {
    final recovery = await store.recoveryState();
    _pendingRemoteObjects = recovery.pendingObjects;
    _openConflicts = recovery.openConflicts;
    if (_started && recovery.dirtyDrafts > 0) {
      _scheduleCommit(Duration.zero);
    } else {
      _notify();
    }
  }

  @override
  void dispose() {
    if (!_disposed) {
      _disposed = true;
      _timer?.cancel();
      if (_started) {
        workspace.removeListener(_onWorkspaceChanged);
      }
    }
    super.dispose();
  }

  void _onWorkspaceChanged() {
    if (_disposed) {
      return;
    }
    if (workspace.saveState == DraftSaveState.saving) {
      _timer?.cancel();
      return;
    }
    final generation = workspace.localSaveGeneration;
    if (workspace.saveState == DraftSaveState.saved &&
        generation != _observedLocalSaveGeneration) {
      _observedLocalSaveGeneration = generation;
      _scheduleCommit(idleDelay);
    }
  }

  void _scheduleCommit(Duration delay) {
    _timer?.cancel();
    _state = LocalCommitState.waiting;
    _error = null;
    _timer = Timer(delay, () => unawaited(commitNow()));
    _notify();
  }

  Future<int> _commit() async {
    _state = LocalCommitState.committing;
    _error = null;
    _notify();
    try {
      final committed = await workspace.commitSavedDrafts();
      final recovery = await store.recoveryState();
      _lastCommittedDrafts = committed;
      _pendingRemoteObjects = recovery.pendingObjects;
      _openConflicts = recovery.openConflicts;
      _state = LocalCommitState.idle;
      _notify();
      return committed;
    } on Object catch (error) {
      _error = error;
      _state = LocalCommitState.failed;
      _notify();
      return 0;
    }
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
