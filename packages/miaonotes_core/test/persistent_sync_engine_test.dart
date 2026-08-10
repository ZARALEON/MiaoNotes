import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:miaonotes_core/miaonotes_core.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() {
    // Each simulated device intentionally owns an independent database.
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  tearDownAll(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = false;
  });

  test(
    'three persistent devices converge through the remote event log',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.close);
      final a = await fixture.device('a');
      final b = await fixture.device('b');
      final c = await fixture.device('c');
      const noteId = 'note-converge';
      await a.save(noteId, 'hello from A');

      await a.engine.syncOnce();
      await b.engine.syncOnce();
      await c.engine.syncOnce();

      expect(await b.body(noteId), 'hello from A');
      expect(await c.body(noteId), 'hello from A');
      expect(await a.store.noteHeads(noteId), await b.store.noteHeads(noteId));
      expect(await b.store.noteHeads(noteId), await c.store.noteHeads(noteId));
      expect((await a.store.recoveryState()).pendingObjects, 0);
    },
  );

  test(
    'persistent devices preserve concurrent heads and conflict state',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.close);
      final a = await fixture.device('a');
      final b = await fixture.device('b');
      final c = await fixture.device('c');
      const noteId = 'note-conflict';
      await a.save(noteId, 'base');
      await a.engine.syncOnce();
      await b.engine.syncOnce();
      await c.engine.syncOnce();

      await b.edit(noteId, 'edit from B');
      await c.edit(noteId, 'edit from C');
      await b.engine.syncOnce();
      await c.engine.syncOnce();
      await b.engine.syncOnce();
      await a.engine.syncOnce();

      for (final device in <_Device>[a, b, c]) {
        final heads = await device.store.noteHeads(noteId);
        expect(heads, hasLength(2));
        final bodies = <Object>{};
        for (final head in heads) {
          bodies.add((await device.store.loadRevision(head))!.body);
        }
        expect(bodies, containsAll(<String>['edit from B', 'edit from C']));
        expect((await device.store.recoveryState()).openConflicts, 1);
      }

      final conflicts = await a.store.openConflicts();
      expect(conflicts, hasLength(1));
      final details = await a.store.loadConflictDetails(
        conflicts.single.conflictId,
      );
      expect(details, isNotNull);
      expect(
        details!.versions.map((revision) => revision.body),
        containsAll(<String>['edit from B', 'edit from C']),
      );
      final previousHeads = await a.store.noteHeads(noteId);
      final merged = await a.store.resolveConflict(
        conflictId: conflicts.single.conflictId,
        format: ContentFormat.markdown,
        title: 'Merged note',
        body: 'merged B and C',
        tags: const <String>['merged'],
      );

      expect(merged.revision.parentRevisionIds, previousHeads);
      expect(await a.store.noteHeads(noteId), <String>[
        merged.revision.revisionId,
      ]);
      expect((await a.store.recoveryState()).openConflicts, 0);
      expect((await a.store.recoveryState()).pendingObjects, 2);

      await a.engine.syncOnce();
      await b.engine.syncOnce();
      await c.engine.syncOnce();
      for (final device in <_Device>[a, b, c]) {
        expect(await device.body(noteId), 'merged B and C');
        expect(await device.store.noteHeads(noteId), <String>[
          merged.revision.revisionId,
        ]);
        expect((await device.store.recoveryState()).openConflicts, 0);
      }
    },
  );

  test(
    'conflict resolution refuses to overwrite a dirty local draft',
    () async {
      final fixture = _Fixture();
      addTearDown(fixture.close);
      final a = await fixture.device('a');
      final b = await fixture.device('b');
      final c = await fixture.device('c');
      const noteId = 'note-dirty-conflict';
      await a.save(noteId, 'base');
      await a.engine.syncOnce();
      await b.engine.syncOnce();
      await c.engine.syncOnce();
      await b.edit(noteId, 'edit from B');
      await c.edit(noteId, 'edit from C');
      await b.engine.syncOnce();
      await c.engine.syncOnce();
      await a.engine.syncOnce();
      final conflict = (await a.store.openConflicts()).single;
      await a.store.saveDraft(
        NoteDraft(
          noteId: noteId,
          format: ContentFormat.markdown,
          title: '',
          body: 'unsaved local choice',
          tags: const <String>[],
          baseRevisionIds: await a.store.noteHeads(noteId),
          updatedAtUtc: fixture.clock.call(),
        ),
      );

      await expectLater(
        a.store.resolveConflict(
          conflictId: conflict.conflictId,
          format: ContentFormat.markdown,
          title: '',
          body: 'must not overwrite dirty content',
          tags: const <String>[],
        ),
        throwsA(isA<ConflictResolutionException>()),
      );
      expect((await a.store.loadDraft(noteId))!.body, 'unsaved local choice');
      expect((await a.store.recoveryState()).openConflicts, 1);
    },
  );

  test('ambiguous remote write retries from the durable outbox', () async {
    final fixture = _Fixture();
    addTearDown(fixture.close);
    final a = await fixture.device('a');
    final b = await fixture.device('b');
    await a.engine.syncOnce();
    await a.save('note-retry', 'survives an ambiguous response');
    fixture.remote.failPutsAfterWriteRemaining = 1;

    await expectLater(
      a.engine.syncOnce(),
      throwsA(isA<ObjectStoreUnavailable>()),
    );
    expect((await a.store.recoveryState()).pendingObjects, 2);

    await a.engine.syncOnce();
    expect((await a.store.recoveryState()).pendingObjects, 0);
    await b.engine.syncOnce();
    expect(await b.body('note-retry'), 'survives an ambiguous response');
  });

  test(
    'offline outbox survives database close and resumes after restart',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'miaonotes-sync-',
      );
      addTearDown(() async {
        if (directory.existsSync()) {
          await directory.delete(recursive: true);
        }
      });
      final fixture = _Fixture();
      addTearDown(fixture.close);
      final file = File(
        '${directory.path}${Platform.pathSeparator}device-a.db',
      );
      var a = await fixture.fileDevice('a', file);
      final b = await fixture.device('b');
      await a.engine.syncOnce();
      fixture.remote.online = false;
      await a.save('note-offline', 'written without a network');

      await expectLater(
        a.engine.syncOnce(),
        throwsA(isA<ObjectStoreUnavailable>()),
      );
      expect((await a.store.recoveryState()).pendingObjects, 2);
      await a.close();

      fixture.remote.online = true;
      a = await fixture.fileDevice('a-restarted', file, deviceId: 'device-a');
      await a.engine.syncOnce();
      await b.engine.syncOnce();
      expect(await b.body('note-offline'), 'written without a network');
    },
  );

  test('corrupt remote revision does not advance persistent cursor', () async {
    final fixture = _Fixture();
    addTearDown(fixture.close);
    final a = await fixture.device('a');
    final b = await fixture.device('b');
    const noteId = 'note-corrupt';
    await a.save(noteId, 'valid local content');
    await a.engine.syncOnce();
    final revisionKey = ProtocolPaths.revision(
      noteId,
      (await a.store.noteHeads(noteId)).single,
    );
    fixture.remote.corruptForTest(revisionKey, <int>[0, 1, 2, 3]);

    await expectLater(
      b.engine.syncOnce(),
      throwsA(isA<RemoteObjectCorruptedException>()),
    );
    expect(await b.store.cursorFor('device-a'), 0);
    expect((await b.store.recoveryState()).revisions, 0);
    expect(await b.store.loadDraft(noteId), isNull);
  });

  test('tombstone and genuine offline edit remain concurrent', () async {
    final fixture = _Fixture();
    addTearDown(fixture.close);
    final a = await fixture.device('a');
    final b = await fixture.device('b');
    final c = await fixture.device('c');
    const noteId = 'note-delete';
    await a.save(noteId, 'base');
    await a.engine.syncOnce();
    await b.engine.syncOnce();
    await c.engine.syncOnce();

    await a.delete(noteId);
    await a.engine.syncOnce();
    await b.engine.syncOnce();
    expect((await b.store.loadDraft(noteId))!.deleted, isTrue);

    await c.edit(noteId, 'new offline work');
    await c.engine.syncOnce();
    await a.engine.syncOnce();
    final heads = await a.store.noteHeads(noteId);
    expect(heads, hasLength(2));
    final operations = <RevisionOperation>{};
    for (final head in heads) {
      operations.add((await a.store.loadRevision(head))!.operation);
    }
    expect(
      operations,
      containsAll(<RevisionOperation>[
        RevisionOperation.tombstone,
        RevisionOperation.upsert,
      ]),
    );
  });
}

final class _Fixture {
  _Fixture()
    : vault = VaultIdentity(
        vaultId: 'persistent-vault',
        generation: 1,
        createdAtUtc: DateTime.utc(2026, 8, 10),
      );

  final VaultIdentity vault;
  final FakeObjectStore remote = FakeObjectStore();
  final _AdvancingClock clock = _AdvancingClock();
  final List<_Device> _devices = <_Device>[];

  Future<_Device> device(String name) async {
    final database = MiaoNotesDatabase.inMemory();
    return _open(name, database, deviceId: 'device-$name');
  }

  Future<_Device> fileDevice(String name, File file, {String? deviceId}) =>
      _open(
        name,
        MiaoNotesDatabase.openFile(file),
        deviceId: deviceId ?? 'device-$name',
      );

  Future<_Device> _open(
    String name,
    MiaoNotesDatabase database, {
    required String deviceId,
  }) async {
    final store = PersistentNoteStore(
      database: database,
      idFactory: SequenceIdFactory(name),
      clock: clock.call,
    );
    await store.initializeVault(
      vault: vault,
      deviceId: deviceId,
      deviceName: name,
    );
    final device = _Device(
      store: store,
      database: database,
      engine: PersistentSyncEngine(
        localStore: store,
        remoteStore: remote,
        retryDelay: Duration.zero,
      ),
      clock: clock,
    );
    _devices.add(device);
    return device;
  }

  Future<void> close() async {
    for (final device in _devices) {
      await device.close();
    }
  }
}

final class _Device {
  _Device({
    required this.store,
    required this.database,
    required this.engine,
    required this.clock,
  });

  final PersistentNoteStore store;
  final MiaoNotesDatabase database;
  final PersistentSyncEngine engine;
  final _AdvancingClock clock;
  bool _closed = false;

  Future<void> save(String noteId, String body) => store.saveDraft(
    NoteDraft(
      noteId: noteId,
      format: ContentFormat.markdown,
      title: '',
      body: body,
      tags: const <String>[],
      baseRevisionIds: const <String>[],
      updatedAtUtc: clock.call(),
    ),
  );

  Future<void> edit(String noteId, String body) async {
    final current = await store.loadDraft(noteId);
    await store.saveDraft(
      NoteDraft(
        noteId: noteId,
        format: ContentFormat.markdown,
        title: current!.title,
        body: body,
        tags: current.tags,
        baseRevisionIds: await store.noteHeads(noteId),
        updatedAtUtc: clock.call(),
      ),
    );
  }

  Future<void> delete(String noteId) async {
    final current = await store.loadDraft(noteId);
    await store.saveDraft(
      NoteDraft(
        noteId: noteId,
        format: current!.format,
        title: current.title,
        body: current.body,
        tags: current.tags,
        baseRevisionIds: await store.noteHeads(noteId),
        updatedAtUtc: clock.call(),
        deleted: true,
      ),
    );
  }

  Future<Object?> body(String noteId) async =>
      (await store.loadDraft(noteId))?.body;

  Future<void> close() async {
    if (!_closed) {
      _closed = true;
      await database.close();
    }
  }
}

final class _AdvancingClock {
  DateTime _current = DateTime.utc(2026, 8, 10, 12);

  DateTime call() {
    final result = _current;
    _current = _current.add(const Duration(milliseconds: 1));
    return result;
  }
}
