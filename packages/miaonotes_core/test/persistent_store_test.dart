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

    test('search treats user input as safe prefix terms', () async {
      await store.saveDraft(
        _draft(
          noteId: 'note-search',
          body: 'buy milk after work',
          updatedAtUtc: clock.call(),
        ),
      );

      expect((await store.searchNotes('mil')).single.noteId, 'note-search');
      expect(
        (await store.searchNotes('milk work')).single.noteId,
        'note-search',
      );
      expect((await store.searchNotes('mil !!!')).single.noteId, 'note-search');
      expect(await store.searchNotes('!!!'), isEmpty);
      expect(await store.searchNotes('milk "unterminated'), isEmpty);
    });

    test('tag summaries and exact filters compose with search', () async {
      await store.saveDraft(
        _draft(
          noteId: 'work-alpha',
          body: 'alpha roadmap',
          tags: const <String>['work', 'urgent'],
          updatedAtUtc: clock.call(),
        ),
      );
      await store.saveDraft(
        _draft(
          noteId: 'work-beta',
          body: 'beta roadmap',
          tags: const <String>['work'],
          updatedAtUtc: clock.call(),
        ),
      );
      await store.saveDraft(
        _draft(
          noteId: 'personal-alpha',
          body: 'alpha journal',
          tags: const <String>['personal'],
          updatedAtUtc: clock.call(),
        ),
      );

      expect(
        (await store.recentNotes(tag: 'work')).map((note) => note.noteId),
        <String>['work-beta', 'work-alpha'],
      );
      expect(await store.recentNotes(tag: 'workshop'), isEmpty);
      expect(
        (await store.searchNotes('alpha', tag: 'work')).single.noteId,
        'work-alpha',
      );
      expect(
        (await store.tagSummaries()).map(
          (summary) => (summary.tag, summary.noteCount),
        ),
        <(String, int)>[('personal', 1), ('urgent', 1), ('work', 2)],
      );

      await store.setNoteDeleted('personal-alpha', deleted: true);
      expect((await store.tagSummaries()).map((tag) => tag.tag), <String>[
        'urgent',
        'work',
      ]);
    });

    test('local pinning stays first and sort preference persists', () async {
      await store.saveDraft(
        _draft(
          noteId: 'z-latest',
          title: 'Zulu',
          body: 'latest body',
          updatedAtUtc: clock.call(),
        ),
      );
      await store.saveDraft(
        _draft(
          noteId: 'a-older',
          title: 'Alpha',
          body: 'older body',
          updatedAtUtc: clock.call(),
        ),
      );

      await store.setNotePinned('z-latest', pinned: true);
      await store.setNoteSortOrder(NoteSortOrder.titleAscending);

      expect(await store.isNotePinned('z-latest'), isTrue);
      expect(await store.loadNoteSortOrder(), NoteSortOrder.titleAscending);
      expect(
        (await store.recentNotes(
          sortOrder: NoteSortOrder.titleAscending,
        )).map((note) => (note.noteId, note.pinned)),
        <(String, bool)>[('z-latest', true), ('a-older', false)],
      );
      expect((await store.searchNotes('body')).first.noteId, 'z-latest');

      await store.setNotePinned('z-latest', pinned: false);
      expect(await store.isNotePinned('z-latest'), isFalse);
      expect(
        (await store.recentNotes(
          sortOrder: NoteSortOrder.titleAscending,
        )).map((note) => note.noteId),
        <String>['a-older', 'z-latest'],
      );
      expect((await store.recentNotes()).map((note) => note.noteId), <String>[
        'a-older',
        'z-latest',
      ]);
      expect(
        (await store.recentNotes(
          sortOrder: NoteSortOrder.updatedOldest,
        )).map((note) => note.noteId),
        <String>['z-latest', 'a-older'],
      );
      expect((await store.recoveryState()).pendingObjects, 0);
    });

    test('delete and restore append reversible protocol revisions', () async {
      await store.saveDraft(
        _draft(
          noteId: 'note-recycle',
          body: 'content survives deletion',
          updatedAtUtc: clock.call(),
        ),
      );
      final original = await store.commitDraft('note-recycle');

      final deleted = await store.setNoteDeleted('note-recycle', deleted: true);
      expect(deleted!.revision.operation, RevisionOperation.tombstone);
      expect(deleted.revision.parentRevisionIds, <String>[
        original!.revision.revisionId,
      ]);
      expect(await store.recentNotes(), isEmpty);
      expect(await store.searchNotes('survives'), isEmpty);
      expect((await store.deletedNotes()).single.noteId, 'note-recycle');

      final restored = await store.setNoteDeleted(
        'note-recycle',
        deleted: false,
      );
      expect(restored!.revision.operation, RevisionOperation.upsert);
      expect(restored.revision.parentRevisionIds, <String>[
        deleted.revision.revisionId,
      ]);
      expect(restored.revision.body, 'content survives deletion');
      expect((await store.recentNotes()).single.noteId, 'note-recycle');
      expect(await store.deletedNotes(), isEmpty);
      expect(
        (await store.searchNotes('survives')).single.noteId,
        'note-recycle',
      );
      expect((await store.recoveryState()).pendingObjects, 6);
    });

    test(
      'deleting a never-committed note stays local until restored',
      () async {
        await store.saveDraft(
          _draft(
            noteId: 'local-only',
            body: 'not announced remotely',
            updatedAtUtc: clock.call(),
          ),
        );

        expect(await store.setNoteDeleted('local-only', deleted: true), isNull);
        expect((await store.deletedNotes()).single.noteId, 'local-only');
        var recovery = await store.recoveryState();
        expect(recovery.dirtyDrafts, 0);
        expect(recovery.pendingObjects, 0);

        final restored = await store.setNoteDeleted(
          'local-only',
          deleted: false,
        );
        expect(restored, isNotNull);
        recovery = await store.recoveryState();
        expect(recovery.revisions, 1);
        expect(recovery.pendingObjects, 2);
      },
    );

    test(
      'delete rolls back its flag and protocol rows after a fault',
      () async {
        await store.saveDraft(
          _draft(
            noteId: 'delete-rollback',
            body: 'must remain visible',
            updatedAtUtc: clock.call(),
          ),
        );
        final original = await store.commitDraft('delete-rollback');

        await expectLater(
          store.setNoteDeleted(
            'delete-rollback',
            deleted: true,
            faultHook: () => throw StateError('injected delete crash'),
          ),
          throwsStateError,
        );

        expect((await store.loadDraft('delete-rollback'))!.deleted, isFalse);
        expect((await store.recentNotes()).single.noteId, 'delete-rollback');
        expect(await store.deletedNotes(), isEmpty);
        expect(await store.noteHeads('delete-rollback'), <String>[
          original!.revision.revisionId,
        ]);
        final recovery = await store.recoveryState();
        expect(recovery.revisions, 1);
        expect(recovery.pendingObjects, 2);
        expect(recovery.nextEventSequence, 2);
      },
    );

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
      'portable import restores history and queues it for synchronization',
      () async {
        await store.saveDraft(
          _draft(
            noteId: 'restored-note',
            body: 'first version',
            updatedAtUtc: clock.call(),
          ),
        );
        final first = await store.commitDraft('restored-note');
        await store.saveDraft(
          _draft(
            noteId: 'restored-note',
            body: 'second version',
            baseRevisionIds: <String>[first!.revision.revisionId],
            updatedAtUtc: clock.call(),
          ),
        );
        final second = await store.commitDraft('restored-note');
        await store.saveDraft(
          _draft(
            noteId: 'restored-note',
            body: 'latest dirty text',
            baseRevisionIds: <String>[second!.revision.revisionId],
            updatedAtUtc: clock.call(),
          ),
        );
        final snapshot = await store.createExportSnapshot();
        final targetDatabase = MiaoNotesDatabase.inMemory();
        final target = PersistentNoteStore(
          database: targetDatabase,
          idFactory: SequenceIdFactory('import'),
          clock: clock.call,
        );
        await target.initializeVault(
          vault: VaultIdentity(
            vaultId: 'placeholder',
            generation: 1,
            createdAtUtc: clock.call(),
          ),
          deviceId: 'restore-device',
          deviceName: 'Restore test',
        );
        addTearDown(targetDatabase.close);

        final result = await target.importPortableSnapshot(snapshot);

        expect(result.noteCount, 1);
        expect(result.revisionCount, 2);
        expect(result.queuedObjectCount, 4);
        expect((await target.vaultIdentity()).vaultId, _vault.vaultId);
        expect(
          (await target.loadDraft('restored-note'))!.body,
          'latest dirty text',
        );
        expect(await target.noteHeads('restored-note'), <String>[
          second.revision.revisionId,
        ]);
        expect(await target.searchNotes('latest'), hasLength(1));
        final recovery = await target.recoveryState();
        expect(recovery.dirtyDrafts, 1);
        expect(recovery.revisions, 2);
        expect(recovery.pendingObjects, 4);
        expect(recovery.nextEventSequence, 3);
      },
    );

    test(
      'portable import rolls back every row after an injected fault',
      () async {
        await store.saveDraft(
          _draft(
            noteId: 'rollback-note',
            body: 'committed',
            updatedAtUtc: clock.call(),
          ),
        );
        await store.commitDraft('rollback-note');
        final snapshot = await store.createExportSnapshot();
        final targetDatabase = MiaoNotesDatabase.inMemory();
        final target = PersistentNoteStore(
          database: targetDatabase,
          idFactory: SequenceIdFactory('rollback'),
          clock: clock.call,
        );
        await target.initializeVault(
          vault: VaultIdentity(
            vaultId: 'placeholder',
            generation: 1,
            createdAtUtc: clock.call(),
          ),
          deviceId: 'restore-device',
          deviceName: 'Restore test',
        );
        addTearDown(targetDatabase.close);

        await expectLater(
          target.importPortableSnapshot(
            snapshot,
            applyHook: (_) => throw StateError('injected import failure'),
          ),
          throwsStateError,
        );

        expect((await target.vaultIdentity()).vaultId, 'placeholder');
        final recovery = await target.recoveryState();
        expect(recovery.revisions, 0);
        expect(recovery.pendingObjects, 0);
        expect(recovery.nextEventSequence, 1);
        expect(await target.recentNotes(), isEmpty);
      },
    );

    test('portable import rejects history with a missing parent', () async {
      await store.saveDraft(
        _draft(
          noteId: 'broken-note',
          body: 'first',
          updatedAtUtc: clock.call(),
        ),
      );
      final first = await store.commitDraft('broken-note');
      await store.saveDraft(
        _draft(
          noteId: 'broken-note',
          body: 'second',
          baseRevisionIds: <String>[first!.revision.revisionId],
          updatedAtUtc: clock.call(),
        ),
      );
      final second = await store.commitDraft('broken-note');
      final valid = await store.createExportSnapshot();
      final broken = ExportSnapshot(
        vault: valid.vault,
        exportedAtUtc: valid.exportedAtUtc,
        notes: valid.notes,
        revisions: <Revision>[second!.revision],
        conflicts: valid.conflicts,
      );
      final targetDatabase = MiaoNotesDatabase.inMemory();
      final target = PersistentNoteStore(
        database: targetDatabase,
        idFactory: SequenceIdFactory('broken'),
        clock: clock.call,
      );
      await target.initializeVault(
        vault: VaultIdentity(
          vaultId: 'placeholder',
          generation: 1,
          createdAtUtc: clock.call(),
        ),
        deviceId: 'restore-device',
        deviceName: 'Restore test',
      );
      addTearDown(targetDatabase.close);

      await expectLater(
        target.importPortableSnapshot(broken),
        throwsA(isA<PortableImportException>()),
      );
      expect(await target.recentNotes(), isEmpty);
    });

    test(
      'portable import reconstructs concurrent heads and open conflict',
      () async {
        final createdAt = clock.call();
        final leftDraft = _draft(
          noteId: 'conflicted-note',
          body: 'left version',
          updatedAtUtc: createdAt,
        );
        final rightDraft = _draft(
          noteId: 'conflicted-note',
          body: 'right version',
          updatedAtUtc: createdAt,
        );
        final left = Revision.create(
          vaultId: _vault.vaultId,
          vaultGeneration: _vault.generation,
          revisionId: 'left-revision',
          deviceId: 'left-device',
          createdAtUtc: createdAt,
          draft: leftDraft,
        );
        final right = Revision.create(
          vaultId: _vault.vaultId,
          vaultGeneration: _vault.generation,
          revisionId: 'right-revision',
          deviceId: 'right-device',
          createdAtUtc: createdAt,
          draft: rightDraft,
        );
        final snapshot = ExportSnapshot(
          vault: _vault,
          exportedAtUtc: createdAt,
          notes: <ExportNoteState>[
            ExportNoteState(
              draft: NoteDraft(
                noteId: leftDraft.noteId,
                format: leftDraft.format,
                title: leftDraft.title,
                body: leftDraft.body,
                tags: leftDraft.tags,
                baseRevisionIds: const <String>[
                  'left-revision',
                  'right-revision',
                ],
                updatedAtUtc: createdAt,
              ),
              createdAtUtc: createdAt,
              dirty: false,
              lastCommittedRevisionId: left.revisionId,
            ),
          ],
          revisions: <Revision>[left, right],
          conflicts: <ExportConflictRecord>[
            ExportConflictRecord(
              conflictId: 'open-conflict',
              noteId: left.noteId,
              headRevisionIds: const <String>[
                'left-revision',
                'right-revision',
              ],
              status: ExportConflictStatus.open,
              createdAtUtc: createdAt,
            ),
          ],
        );
        final targetDatabase = MiaoNotesDatabase.inMemory();
        final target = PersistentNoteStore(
          database: targetDatabase,
          idFactory: SequenceIdFactory('conflict-import'),
          clock: clock.call,
        );
        await target.initializeVault(
          vault: VaultIdentity(
            vaultId: 'placeholder',
            generation: 1,
            createdAtUtc: createdAt,
          ),
          deviceId: 'restore-device',
          deviceName: 'Restore test',
        );
        addTearDown(targetDatabase.close);

        final result = await target.importPortableSnapshot(snapshot);

        expect(result.conflictCount, 1);
        expect(await target.noteHeads('conflicted-note'), <String>[
          'left-revision',
          'right-revision',
        ]);
        expect(
          (await target.openConflicts()).single.conflictId,
          'open-conflict',
        );
        expect((await target.recoveryState()).openConflicts, 1);
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
  String title = 'Title',
  Iterable<String> baseRevisionIds = const <String>[],
  Iterable<String> tags = const <String>['test'],
}) => NoteDraft(
  noteId: noteId,
  format: ContentFormat.markdown,
  title: title,
  body: body,
  tags: tags,
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
