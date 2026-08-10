import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:miaonotes_core/miaonotes_core.dart';

enum DraftSaveState { idle, saving, saved, failed }

final class NoteWorkspaceController extends ChangeNotifier {
  NoteWorkspaceController({
    required this.store,
    IdFactory? idFactory,
    DateTime Function()? clock,
  }) : idFactory = idFactory ?? UuidV7IdFactory(),
       clock = clock ?? (() => DateTime.now().toUtc());

  final PersistentNoteStore store;
  final IdFactory idFactory;
  final DateTime Function() clock;

  List<StoredNoteSummary> _notes = const <StoredNoteSummary>[];
  NoteDraft? _currentDraft;
  DraftSaveState _saveState = DraftSaveState.idle;
  DateTime? _lastSavedAtUtc;
  Object? _saveError;
  NoteDraft? _pendingSave;
  Future<void>? _saveLoop;
  Future<int>? _commitLoop;
  int _localSaveGeneration = 0;
  bool _commitInProgress = false;
  bool _initialized = false;
  bool _disposed = false;

  List<StoredNoteSummary> get notes => _notes;
  NoteDraft? get currentDraft => _currentDraft;
  DraftSaveState get saveState => _saveState;
  DateTime? get lastSavedAtUtc => _lastSavedAtUtc;
  Object? get saveError => _saveError;
  bool get initialized => _initialized;
  bool get commitInProgress => _commitInProgress;
  int get localSaveGeneration => _localSaveGeneration;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _notes = await store.recentNotes();
    if (_notes.isEmpty) {
      _currentDraft = _newDraft();
    } else {
      _currentDraft = await store.loadDraft(_notes.first.noteId) ?? _newDraft();
    }
    _initialized = true;
    _notify();
  }

  Future<void> createNote() async {
    if (!await _flushBeforeNavigation()) {
      return;
    }
    _currentDraft = _newDraft();
    _saveState = DraftSaveState.idle;
    _lastSavedAtUtc = null;
    _notify();
  }

  Future<void> selectNote(String noteId) async {
    if (_currentDraft?.noteId == noteId || !await _flushBeforeNavigation()) {
      return;
    }
    final selected = await store.loadDraft(noteId);
    if (selected == null) {
      _notes = await store.recentNotes();
      _notify();
      return;
    }
    _currentDraft = selected;
    _saveState = DraftSaveState.saved;
    _lastSavedAtUtc = selected.updatedAtUtc;
    _notify();
  }

  void updateTitle(String title) {
    final draft = _currentDraft;
    if (draft == null || draft.title == title) {
      return;
    }
    _replaceDraft(title: title, body: draft.body);
  }

  void updateBody(String body) {
    final draft = _currentDraft;
    if (draft == null || draft.body == body) {
      return;
    }
    _replaceDraft(title: draft.title, body: body);
  }

  Future<void> retrySave() async {
    final draft = _currentDraft;
    if (draft == null) {
      return;
    }
    _saveError = null;
    _pendingSave = draft;
    _startSaveLoop();
    await flush();
  }

  /// Reloads remote materialization only when no local editor mutation is in
  /// flight. Dirty local Drafts always win this race and stay on screen.
  Future<void> refreshAfterRemotePull() async {
    if (_pendingSave != null ||
        _saveLoop != null ||
        _commitInProgress ||
        _saveState == DraftSaveState.saving) {
      return;
    }
    final currentId = _currentDraft?.noteId;
    _notes = await store.recentNotes();
    if (currentId != null) {
      final refreshed = await store.loadDraft(currentId);
      if (refreshed != null) {
        _currentDraft = refreshed;
        _saveState = DraftSaveState.saved;
        _lastSavedAtUtc = refreshed.updatedAtUtc;
      } else if (_notes.isNotEmpty) {
        _currentDraft = await store.loadDraft(_notes.first.noteId);
      }
    } else if (_notes.isNotEmpty) {
      _currentDraft = await store.loadDraft(_notes.first.noteId);
    }
    _notify();
  }

  Future<CommittedRevisionBundle> resolveConflict({
    required String conflictId,
    required ContentFormat format,
    required String title,
    required Object body,
    required List<String> tags,
    bool deleted = false,
  }) async {
    await flush();
    final bundle = await store.resolveConflict(
      conflictId: conflictId,
      format: format,
      title: title,
      body: body,
      tags: tags,
      deleted: deleted,
    );
    await refreshAfterRemotePull();
    return bundle;
  }

  Future<void> flush() async {
    while (true) {
      final commit = _commitLoop;
      if (commit != null) {
        await commit;
        await Future<void>.value();
        continue;
      }
      await _flushSaves();
      if (_commitLoop != null) {
        continue;
      }
      return;
    }
  }

  Future<int> commitSavedDrafts() {
    final running = _commitLoop;
    if (running != null) {
      return running;
    }
    final operation = _commitSavedDrafts();
    _commitLoop = operation;
    unawaited(
      operation.then<void>(
        (_) => _clearCommitLoop(operation),
        onError: (Object _, StackTrace _) => _clearCommitLoop(operation),
      ),
    );
    return operation;
  }

  Future<void> _flushSaves({bool allowDuringCommit = false}) async {
    while (true) {
      if (_pendingSave != null && _saveLoop == null && _saveError == null) {
        _startSaveLoop(allowDuringCommit: allowDuringCommit);
      }
      final loop = _saveLoop;
      if (loop != null) {
        await loop;
        await Future<void>.value();
        continue;
      }
      if (_pendingSave != null) {
        if (_commitInProgress && !allowDuringCommit) {
          return;
        }
        throw StateError('The current draft could not be saved: $_saveError');
      }
      return;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _replaceDraft({required String title, required Object body}) {
    final previous = _currentDraft!;
    final updated = NoteDraft(
      noteId: previous.noteId,
      format: previous.format,
      title: title,
      body: body,
      tags: previous.tags,
      baseRevisionIds: previous.baseRevisionIds,
      updatedAtUtc: clock().toUtc(),
      deleted: previous.deleted,
    );
    _currentDraft = updated;
    _pendingSave = updated;
    _saveError = null;
    _startSaveLoop();
    _notify();
  }

  void _startSaveLoop({bool allowDuringCommit = false}) {
    if (_saveLoop != null ||
        _pendingSave == null ||
        (_commitInProgress && !allowDuringCommit)) {
      return;
    }
    final loop = _drainSaves();
    _saveLoop = loop;
    unawaited(
      loop.whenComplete(() {
        if (identical(_saveLoop, loop)) {
          _saveLoop = null;
          if (_pendingSave != null &&
              _saveError == null &&
              !_commitInProgress) {
            _startSaveLoop();
          }
        }
      }),
    );
  }

  Future<void> _drainSaves() async {
    while (_pendingSave != null) {
      final snapshot = _pendingSave!;
      _pendingSave = null;
      _saveState = DraftSaveState.saving;
      _notify();
      try {
        await store.saveDraft(snapshot);
      } on Object catch (error) {
        _pendingSave ??= snapshot;
        _saveError = error;
        _saveState = DraftSaveState.failed;
        _notify();
        return;
      }
      _upsertSummary(snapshot);
      _localSaveGeneration += 1;
      _lastSavedAtUtc = snapshot.updatedAtUtc;
      _saveState = DraftSaveState.saved;
      _notify();
    }
  }

  Future<int> _commitSavedDrafts() async {
    _commitInProgress = true;
    _notify();
    try {
      await _flushSaves(allowDuringCommit: true);
      final committed = await store.commitAllDirtyDrafts();
      await _rebaseCurrentDraft();
      return committed;
    } finally {
      _commitInProgress = false;
      if (_pendingSave != null && _saveError == null) {
        _startSaveLoop();
      }
      _notify();
    }
  }

  Future<void> _rebaseCurrentDraft() async {
    final current = _currentDraft;
    if (current == null) {
      return;
    }
    var pending = _pendingSave;
    if (pending == null) {
      final stored = await store.loadDraft(current.noteId);
      pending = _pendingSave;
      if (pending == null && stored != null) {
        _currentDraft = stored;
        _upsertSummary(stored);
        return;
      }
    }
    if (pending == null) {
      return;
    }
    var heads = await store.noteHeads(pending.noteId);
    final latest = _pendingSave ?? pending;
    if (latest.noteId != pending.noteId) {
      heads = await store.noteHeads(latest.noteId);
    }
    if (heads.isEmpty) {
      return;
    }
    final rebased = NoteDraft(
      noteId: latest.noteId,
      format: latest.format,
      title: latest.title,
      body: latest.body,
      tags: latest.tags,
      baseRevisionIds: heads,
      updatedAtUtc: latest.updatedAtUtc,
      deleted: latest.deleted,
    );
    _pendingSave = rebased;
    if (_currentDraft?.noteId == rebased.noteId) {
      _currentDraft = rebased;
    }
  }

  void _clearCommitLoop(Future<int> operation) {
    if (identical(_commitLoop, operation)) {
      _commitLoop = null;
    }
  }

  Future<bool> _flushBeforeNavigation() async {
    try {
      await flush();
      return true;
    } on Object catch (error) {
      _saveError = error;
      _saveState = DraftSaveState.failed;
      _notify();
      return false;
    }
  }

  void _upsertSummary(NoteDraft draft) {
    final updated = _notes
        .where((note) => note.noteId != draft.noteId)
        .toList(growable: true);
    if (!draft.deleted) {
      updated.add(
        StoredNoteSummary(
          noteId: draft.noteId,
          title: draft.title,
          bodyPreview: draft.body as String,
          format: draft.format,
          updatedAtUtc: draft.updatedAtUtc,
          deleted: false,
        ),
      );
    }
    updated.sort((left, right) {
      final timeOrder = right.updatedAtUtc.compareTo(left.updatedAtUtc);
      return timeOrder != 0 ? timeOrder : left.noteId.compareTo(right.noteId);
    });
    _notes = List.unmodifiable(updated);
  }

  NoteDraft _newDraft() {
    final now = clock().toUtc();
    return NoteDraft(
      noteId: idFactory.next(now),
      format: ContentFormat.markdown,
      title: '',
      body: '',
      tags: const <String>[],
      baseRevisionIds: const <String>[],
      updatedAtUtc: now,
    );
  }

  void _notify() {
    if (!_disposed) {
      notifyListeners();
    }
  }
}
