import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miaonotes_core/miaonotes_core.dart';
import 'package:miaonotes_windows/src/application/miaonotes_application.dart';
import 'package:miaonotes_windows/src/ui/miaonotes_shell.dart';

void main() {
  setUpAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  testWidgets('conflict center creates a visible merge revision', (
    tester,
  ) async {
    final clock = _AdvancingClock();
    final app = await MiaoNotesApplication.open(
      database: MiaoNotesDatabase.inMemory(),
      idFactory: SequenceIdFactory('windows-a'),
      clock: clock.call,
    );
    final remote = FakeObjectStore();
    final aEngine = PersistentSyncEngine(
      localStore: app.store,
      remoteStore: remote,
      retryDelay: Duration.zero,
    );
    final vault = await app.store.vaultIdentity();
    final b = await _TestDevice.open('b', vault, remote, clock);
    final c = await _TestDevice.open('c', vault, remote, clock);
    addTearDown(() async {
      await b.close();
      await c.close();
      await app.close();
    });
    await app.startBackgroundWork();

    final noteId = app.workspace.currentDraft!.noteId;
    app.workspace.updateTitle('Shared note');
    app.workspace.updateBody('base');
    await app.workspace.flush();
    expect(await app.localCommits.commitNow(), 1);
    await aEngine.syncCommitted();
    await b.engine.syncCommitted();
    await c.engine.syncCommitted();

    await b.edit(noteId, 'version from B');
    await c.edit(noteId, 'version from C');
    await b.engine.syncCommitted();
    await c.engine.syncCommitted();
    await aEngine.syncCommitted();
    await app.workspace.refreshAfterRemotePull();
    await app.localCommits.refreshPendingRemoteObjects();

    expect(app.localCommits.openConflicts, 1);
    await tester.pumpWidget(
      MiaoNotesShell(workspace: app.workspace, localCommits: app.localCommits),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('conflict-center-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('conflict-center-button')));
    await tester.pumpAndSettle();
    expect(find.text('version from B'), findsWidgets);
    expect(find.text('version from C'), findsWidgets);
    expect(find.byKey(const Key('conflict-merged-body-field')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('conflict-merged-title-field')),
      'Merged safely',
    );
    await tester.enterText(
      find.byKey(const Key('conflict-merged-body-field')),
      'combined B and C',
    );
    await tester.tap(find.byKey(const Key('resolve-conflict-button')));
    await tester.pumpAndSettle();

    expect(find.text('没有需要处理的同步冲突'), findsOneWidget);
    expect(app.localCommits.openConflicts, 0);
    final heads = await app.store.noteHeads(noteId);
    expect(heads, hasLength(1));
    final merged = (await app.store.loadRevision(heads.single))!;
    expect(merged.parentRevisionIds, hasLength(2));
    expect(merged.title, 'Merged safely');
    expect(merged.body, 'combined B and C');
    final materialized = (await app.store.loadDraft(noteId))!;
    expect(materialized.title, 'Merged safely');
    expect(materialized.body, 'combined B and C');
    expect((await app.store.recoveryState()).pendingObjects, 2);

    await tester.tap(find.text('关闭'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('conflict-center-button')), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}

final class _TestDevice {
  const _TestDevice(this.database, this.store, this.engine, this.clock);

  static Future<_TestDevice> open(
    String name,
    VaultIdentity vault,
    ObjectStore remote,
    _AdvancingClock clock,
  ) async {
    final database = MiaoNotesDatabase.inMemory();
    final store = PersistentNoteStore(
      database: database,
      idFactory: SequenceIdFactory('windows-$name'),
      clock: clock.call,
    );
    await store.initializeVault(
      vault: vault,
      deviceId: 'device-$name',
      deviceName: name,
    );
    return _TestDevice(
      database,
      store,
      PersistentSyncEngine(
        localStore: store,
        remoteStore: remote,
        retryDelay: Duration.zero,
      ),
      clock,
    );
  }

  final MiaoNotesDatabase database;
  final PersistentNoteStore store;
  final PersistentSyncEngine engine;
  final _AdvancingClock clock;

  Future<void> edit(String noteId, String body) async {
    final draft = (await store.loadDraft(noteId))!;
    await store.saveDraft(
      NoteDraft(
        noteId: noteId,
        format: draft.format,
        title: draft.title,
        body: body,
        tags: draft.tags,
        baseRevisionIds: await store.noteHeads(noteId),
        updatedAtUtc: clock.call(),
      ),
    );
    await store.commitDraft(noteId);
  }

  Future<void> close() => database.close();
}

final class _AdvancingClock {
  DateTime _now = DateTime.utc(2026, 8, 10, 20);

  DateTime call() {
    final value = _now;
    _now = _now.add(const Duration(milliseconds: 1));
    return value;
  }
}
