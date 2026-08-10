import 'dart:io';

import 'package:miaonotes_core/miaonotes_core.dart';
import 'package:test/test.dart';

void main() {
  group('PersistentNoteStore', () {
    late MiaoNotesDatabase database;
    late PersistentNoteStore store;
    late _AdvancingClock clock;

    setUp(() async {
      database = MiaoNotesDatabase.inMemory();
      clock = _AdvancingClock();
      store = PersistentNoteStore(
        database: database,
        idFactory: SequenceIdFactory('local'),
        clock: clock.call,
      );
      await store.initializeVault(
        vault: _vault,
        deviceId: 'device-a',
        deviceName: 'Test device',
      );
    });

    tearDown(() => database.close());

    test('draft save is immediately recoverable and searchable', () async {
      final draft = _draft(
        noteId: 'note-1',
        body: 'buy milk after work',
        updatedAtUtc: clock.call(),
      );
      await store.saveDraft(draft);

      final recovered = await store.loadDirtyDrafts();
      expect(recovered, hasLength(1));
      expect(recovered.single.body, 'buy milk after work');
      expect((await store.searchNotes('milk')).single.noteId, 'note-1');

      final state = await store.recoveryState();
      expect(state.dirtyDrafts, 1);
      expect(state.revisions, 0);
      expect(state.pendingObjects, 0);
      expect(state.nextEventSequence, 1);
    });

    test(
      'export snapshot includes committed history and dirty drafts',
      () async {
        await store.saveDraft(
          _draft(
            noteId: 'committed-note',
            body: 'first version',
            updatedAtUtc: clock.call(),
          ),
        );
        final committed = await store.commitDraft('committed-note');
        final heads = await store.noteHeads('committed-note');
        await store.saveDraft(
          _draft(
            noteId: 'committed-note',
            body: 'latest unsynced keystrokes',
            baseRevisionIds: heads,
            updatedAtUtc: clock.call(),
          ),
        );
        await store.saveDraft(
          _draft(
            noteId: 'draft-only',
            body: 'never committed',
            updatedAtUtc: clock.call(),
          ),
        );

        final snapshot = await store.createExportSnapshot();

        expect(snapshot.vault.vaultId, _vault.vaultId);
        expect(snapshot.notes, hasLength(2));
        expect(snapshot.revisions, hasLength(1));
        expect(
          snapshot.revisions.single.revisionId,
          committed!.revision.revisionId,
        );
        final changed = snapshot.notes.singleWhere(
          (note) => note.draft.noteId == 'committed-note',
        );
        expect(changed.dirty, isTrue);
        expect(changed.draft.body, 'latest unsynced keystrokes');
        expect(changed.lastCommittedRevisionId, committed.revision.revisionId);
        expect(snapshot.conflicts, isEmpty);
      },
    );

    test(
      'commit atomically creates revision, event, heads, and outbox',
      () async {
        await store.saveDraft(
          _draft(
            noteId: 'note-1',
            body: 'durable content',
            updatedAtUtc: clock.call(),
          ),
        );
        final bundle = await store.commitDraft('note-1');

        expect(bundle, isNotNull);
        expect(bundle!.event.sequence, 1);
        expect(await store.noteHeads('note-1'), <String>[
          bundle.revision.revisionId,
        ]);
        final outbox = await store.loadReadyOutbox();
        expect(outbox.map((entry) => entry.kind), <String>[
          'revision',
          'event',
        ]);
        expect(outbox.last.dependencyKey, outbox.first.objectKey);
        final state = await store.recoveryState();
        expect(state.dirtyDrafts, 0);
        expect(state.revisions, 1);
        expect(state.pendingObjects, 2);
        expect(state.nextEventSequence, 2);
        expect(await store.integrityCheck(), isTrue);
      },
    );

    test('exception inside commit rolls back every protocol write', () async {
      await store.saveDraft(
        _draft(
          noteId: 'note-rollback',
          body: 'must remain a draft',
          updatedAtUtc: clock.call(),
        ),
      );

      await expectLater(
        store.commitDraft(
          'note-rollback',
          faultHook: () => throw StateError('injected crash'),
        ),
        throwsStateError,
      );

      final state = await store.recoveryState();
      expect(state.dirtyDrafts, 1);
      expect(state.revisions, 0);
      expect(state.pendingObjects, 0);
      expect(state.nextEventSequence, 1);
      expect(await store.noteHeads('note-rollback'), isEmpty);
    });

    test(
      'returning content to its base does not allocate a revision',
      () async {
        await store.saveDraft(
          _draft(noteId: 'note-1', body: 'same', updatedAtUtc: clock.call()),
        );
        final first = await store.commitDraft('note-1');
        final heads = await store.noteHeads('note-1');
        await store.saveDraft(
          _draft(
            noteId: 'note-1',
            body: 'same',
            baseRevisionIds: heads,
            updatedAtUtc: clock.call(),
          ),
        );

        expect(await store.commitDraft('note-1'), isNull);
        final state = await store.recoveryState();
        expect(state.revisions, 1);
        expect(state.nextEventSequence, 2);
        expect(await store.noteHeads('note-1'), <String>[
          first!.revision.revisionId,
        ]);
      },
    );

    test('outbox failures persist retry metadata', () async {
      await store.saveDraft(
        _draft(noteId: 'note-1', body: 'retry me', updatedAtUtc: clock.call()),
      );
      await store.commitDraft('note-1');
      final first = (await store.loadReadyOutbox()).first;
      await store.recordOutboxFailure(
        first.outboxId,
        const ObjectStoreUnavailable('offline'),
      );

      final delayed = await store.loadReadyOutbox(
        nowUtc: clock.call().add(const Duration(seconds: 1)),
      );
      expect(
        delayed.map((entry) => entry.outboxId),
        isNot(contains(first.outboxId)),
      );
      final readyLater = await store.loadReadyOutbox(
        nowUtc: clock.call().add(const Duration(seconds: 10)),
      );
      final retried = readyLater.singleWhere(
        (entry) => entry.outboxId == first.outboxId,
      );
      expect(retried.attemptCount, 1);
      expect(retried.lastError, contains('offline'));
    });

    test('vault identity mismatch stops opening the local store', () async {
      await expectLater(
        store.initializeVault(
          vault: VaultIdentity(
            vaultId: 'another-vault',
            generation: 1,
            createdAtUtc: _vault.createdAtUtc,
          ),
          deviceId: 'device-a',
          deviceName: 'Test device',
        ),
        throwsA(isA<VaultMismatchException>()),
      );
    });

    test(
      'an empty local database can adopt an existing remote vault',
      () async {
        final remote = VaultIdentity(
          vaultId: 'remote-vault',
          generation: 3,
          createdAtUtc: DateTime.utc(2025, 1, 2),
        );

        await store.adoptRemoteVault(remote);

        final adopted = await store.loadVaultIdentity();
        expect(adopted!.vaultId, remote.vaultId);
        expect(adopted.generation, remote.generation);
        expect(adopted.createdAtUtc, remote.createdAtUtc);
      },
    );

    test('a saved draft permanently blocks remote vault adoption', () async {
      await store.saveDraft(
        _draft(
          noteId: 'local-note',
          body: 'must not be rebound',
          updatedAtUtc: clock.call(),
        ),
      );
      final remote = VaultIdentity(
        vaultId: 'remote-vault',
        generation: 1,
        createdAtUtc: DateTime.utc(2025, 1, 2),
      );

      await expectLater(
        store.adoptRemoteVault(remote),
        throwsA(isA<VaultAdoptionNotAllowedException>()),
      );
      expect((await store.loadVaultIdentity())!.vaultId, _vault.vaultId);
    });
  });

  test('dirty draft and outbox survive a real database restart', () async {
    final directory = await Directory.systemTemp.createTemp('miaonotes-store-');
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
    final file = File('${directory.path}${Platform.pathSeparator}notes.db');
    final clock = _AdvancingClock();

    var database = MiaoNotesDatabase.openFile(file);
    var store = PersistentNoteStore(
      database: database,
      idFactory: SequenceIdFactory('restart'),
      clock: clock.call,
    );
    await store.initializeVault(
      vault: _vault,
      deviceId: 'device-a',
      deviceName: 'Test device',
    );
    await store.saveDraft(
      _draft(
        noteId: 'note-restart',
        body: 'saved before restart',
        updatedAtUtc: clock.call(),
      ),
    );
    await database.close();

    database = MiaoNotesDatabase.openFile(file);
    store = PersistentNoteStore(
      database: database,
      idFactory: SequenceIdFactory('restart'),
      clock: clock.call,
    );
    await store.initializeVault(
      vault: _vault,
      deviceId: 'device-a',
      deviceName: 'Test device',
    );
    expect((await store.loadDirtyDrafts()).single.body, 'saved before restart');
    await store.commitDraft('note-restart');
    await database.close();

    database = MiaoNotesDatabase.openFile(file);
    store = PersistentNoteStore(database: database, clock: clock.call);
    await store.initializeVault(
      vault: _vault,
      deviceId: 'device-a',
      deviceName: 'Test device',
    );
    final state = await store.recoveryState();
    expect(state.dirtyDrafts, 0);
    expect(state.revisions, 1);
    expect(state.pendingObjects, 2);
    await database.close();
  });

  test('reopen-to-recent-notes path stays below the phase-1 budget', () async {
    final directory = await Directory.systemTemp.createTemp('miaonotes-perf-');
    addTearDown(() async {
      if (directory.existsSync()) {
        await directory.delete(recursive: true);
      }
    });
    final file = File('${directory.path}${Platform.pathSeparator}notes.db');
    final clock = _AdvancingClock();
    var database = MiaoNotesDatabase.openFile(file);
    var store = PersistentNoteStore(database: database, clock: clock.call);
    await store.initializeVault(
      vault: _vault,
      deviceId: 'device-a',
      deviceName: 'Performance test',
    );
    for (var index = 0; index < 100; index += 1) {
      await store.saveDraft(
        _draft(
          noteId: 'note-$index',
          body: 'body $index',
          updatedAtUtc: clock.call(),
        ),
      );
    }
    await database.close();

    final stopwatch = Stopwatch()..start();
    database = MiaoNotesDatabase.openFile(file);
    store = PersistentNoteStore(database: database, clock: clock.call);
    final recent = await store.recentNotes(limit: 20);
    stopwatch.stop();
    expect(recent, hasLength(20));
    expect(
      stopwatch.elapsed,
      lessThan(const Duration(milliseconds: 1500)),
      reason: 'Local database startup must stay inside the cold-start budget',
    );
    await database.close();
  });
}

final _vault = VaultIdentity(
  vaultId: 'vault-test',
  generation: 1,
  createdAtUtc: DateTime.utc(2026, 8, 10),
);

NoteDraft _draft({
  required String noteId,
  required String body,
  required DateTime updatedAtUtc,
  Iterable<String> baseRevisionIds = const <String>[],
}) => NoteDraft(
  noteId: noteId,
  format: ContentFormat.markdown,
  title: 'Title',
  body: body,
  tags: const <String>['test'],
  baseRevisionIds: baseRevisionIds,
  updatedAtUtc: updatedAtUtc,
);

final class _AdvancingClock {
  DateTime _current = DateTime.utc(2026, 8, 10, 12);

  DateTime call() {
    final result = _current;
    _current = _current.add(const Duration(milliseconds: 1));
    return result;
  }
}
