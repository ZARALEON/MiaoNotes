import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:miaonotes_core/miaonotes_core.dart';
import 'package:miaonotes_windows/src/application/miaonotes_application.dart';
import 'package:miaonotes_windows/src/application/note_workspace_controller.dart';

void main() {
  test('first edit is persisted locally and appears in recent notes', () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);

    expect(fixture.app.workspace.notes, isEmpty);
    final noteId = fixture.app.workspace.currentDraft!.noteId;

    fixture.app.workspace
      ..updateTitle('第一条便签')
      ..updateBody('打开就能记录');
    await fixture.app.workspace.flush();

    final stored = await fixture.app.store.loadDraft(noteId);
    expect(stored, isNotNull);
    expect(stored!.title, '第一条便签');
    expect(stored.body, '打开就能记录');
    expect(fixture.app.workspace.notes.single.noteId, noteId);
    expect(fixture.app.workspace.saveState, DraftSaveState.saved);
  });

  test('new and existing notes can switch without losing drafts', () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    final workspace = fixture.app.workspace;

    final firstId = workspace.currentDraft!.noteId;
    workspace.updateBody('first');
    await workspace.flush();
    await workspace.createNote();
    final secondId = workspace.currentDraft!.noteId;
    expect(secondId, isNot(firstId));

    workspace.updateBody('second');
    await workspace.flush();
    await workspace.selectNote(firstId);
    expect(workspace.currentDraft!.body, 'first');
    expect(workspace.notes, hasLength(2));
  });

  test('background work is opt-in, isolated, and starts once', () async {
    var starts = 0;
    final release = Completer<void>();
    final fixture = await _Fixture.open(
      backgroundTask: (_) async {
        starts += 1;
        await release.future;
      },
    );
    addTearDown(fixture.close);

    expect(starts, 0);
    expect(fixture.app.workspace.initialized, isTrue);
    final running = fixture.app.startBackgroundWork();
    await Future<void>.delayed(Duration.zero);
    expect(starts, 1);
    await fixture.app.startBackgroundWork();
    expect(starts, 1);
    release.complete();
    await running;
  });

  test('successive local commits form one linear revision history', () async {
    final fixture = await _Fixture.open();
    addTearDown(fixture.close);
    final app = fixture.app;
    final noteId = app.workspace.currentDraft!.noteId;

    app.workspace.updateBody('version one');
    await app.workspace.flush();
    expect(await app.localCommits.commitNow(), 1);
    final firstHead = (await app.store.noteHeads(noteId)).single;
    expect(app.workspace.currentDraft!.baseRevisionIds, <String>[firstHead]);

    app.workspace.updateBody('version two');
    await app.workspace.flush();
    expect(await app.localCommits.commitNow(), 1);
    final secondHead = (await app.store.noteHeads(noteId)).single;
    expect(secondHead, isNot(firstHead));
    expect(
      (await app.store.loadRevision(secondHead))!.parentRevisionIds,
      <String>[firstHead],
    );
    final recovery = await app.store.recoveryState();
    expect(recovery.openConflicts, 0);
    expect(recovery.pendingObjects, 4);
  });

  test(
    'remote sync never commits a live draft and uploads revisions',
    () async {
      final remote = FakeObjectStore();
      final fixture = await _Fixture.open(remoteStore: remote);
      addTearDown(fixture.close);
      final app = fixture.app;

      await app.startBackgroundWork();
      expect(remote.objectCount, 1);

      app.workspace.updateBody('still a mutable draft');
      await app.workspace.flush();
      await app.remoteSync!.syncNow();
      var recovery = await app.store.recoveryState();
      expect(recovery.dirtyDrafts, 1);
      expect(recovery.revisions, 0);

      expect(await app.localCommits.commitNow(), 1);
      await app.remoteSync!.syncNow();
      recovery = await app.store.recoveryState();
      expect(recovery.pendingObjects, 0);
      expect(remote.objectCount, 3);
    },
  );
}

final class _Fixture {
  _Fixture(this.app);

  static Future<_Fixture> open({
    BackgroundTask? backgroundTask,
    ObjectStore? remoteStore,
  }) async {
    final clock = _AdvancingClock();
    final app = await MiaoNotesApplication.open(
      database: MiaoNotesDatabase.inMemory(),
      idFactory: SequenceIdFactory('windows'),
      clock: clock.call,
      backgroundTask: backgroundTask,
      remoteStore: remoteStore,
    );
    return _Fixture(app);
  }

  final MiaoNotesApplication app;

  Future<void> close() => app.close();
}

final class _AdvancingClock {
  DateTime _now = DateTime.utc(2026, 8, 10, 16);

  DateTime call() {
    final result = _now;
    _now = _now.add(const Duration(milliseconds: 1));
    return result;
  }
}
