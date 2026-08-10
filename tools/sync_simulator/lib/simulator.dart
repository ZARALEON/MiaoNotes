import 'dart:async';

import 'package:miaonotes_core/miaonotes_core.dart';

typedef ScenarioBody = Future<void> Function();

final class ScenarioResult {
  const ScenarioResult({required this.name, required this.passed, this.error});

  final String name;
  final bool passed;
  final Object? error;
}

Future<List<ScenarioResult>> runAllScenarios() async {
  final scenarios = <String, ScenarioBody>{
    'three devices converge': _threeDevicesConverge,
    'concurrent edits preserve both heads': _concurrentEdits,
    'ambiguous upload is idempotent': _ambiguousUploadRetry,
    'tombstone does not erase offline work': _tombstoneVersusOfflineEdit,
    'remote outage keeps local outbox': _remoteOutage,
    'corrupt remote object does not advance cursor': _corruptRemoteObject,
  };
  final results = <ScenarioResult>[];
  for (final entry in scenarios.entries) {
    try {
      await entry.value();
      results.add(ScenarioResult(name: entry.key, passed: true));
    } on Object catch (error) {
      results.add(ScenarioResult(name: entry.key, passed: false, error: error));
    }
  }
  return results;
}

Future<void> _threeDevicesConverge() async {
  final fixture = _Fixture();
  final a = fixture.replica('a');
  final b = fixture.replica('b');
  final c = fixture.replica('c');
  final noteId = a.createMarkdownNote(
    title: 'Shopping',
    body: 'milk',
    tags: const <String>['home'],
  );

  await fixture.engine(a).syncOnce();
  await fixture.engine(b).syncOnce();
  await fixture.engine(c).syncOnce();

  _expect(a.markdownBody(noteId) == 'milk', 'device A lost the note');
  _expect(
    b.markdownBody(noteId) == 'milk',
    'device B did not receive the note',
  );
  _expect(
    c.markdownBody(noteId) == 'milk',
    'device C did not receive the note',
  );
  _expect(
    a.noteHeads(noteId).single == b.noteHeads(noteId).single &&
        b.noteHeads(noteId).single == c.noteHeads(noteId).single,
    'devices did not converge on the same head',
  );
}

Future<void> _concurrentEdits() async {
  final fixture = _Fixture();
  final a = fixture.replica('a');
  final b = fixture.replica('b');
  final c = fixture.replica('c');
  final noteId = a.createMarkdownNote(body: 'base');
  await fixture.engine(a).syncOnce();
  await fixture.engine(b).syncOnce();
  await fixture.engine(c).syncOnce();

  b.editMarkdownNote(noteId, body: 'edit from B');
  c.editMarkdownNote(noteId, body: 'edit from C');
  await fixture.engine(b).syncOnce();
  await fixture.engine(c).syncOnce();
  await fixture.engine(b).syncOnce();
  await fixture.engine(a).syncOnce();

  for (final replica in <SyncReplica>[a, b, c]) {
    _expect(replica.hasConflict(noteId), '${replica.deviceId} hid a conflict');
    final bodies = replica
        .noteHeads(noteId)
        .map((head) => replica.revisionById(head)!.body)
        .toSet();
    _expect(
      bodies.containsAll(const <String>{'edit from B', 'edit from C'}),
      '${replica.deviceId} did not preserve both concurrent bodies',
    );
  }
}

Future<void> _ambiguousUploadRetry() async {
  final fixture = _Fixture();
  final a = fixture.replica('a');
  final b = fixture.replica('b');
  await fixture.engine(a).syncOnce();

  final noteId = a.createMarkdownNote(body: 'survives retry');
  fixture.store.failPutsAfterWriteRemaining = 1;
  await _expectThrows<ObjectStoreUnavailable>(fixture.engine(a).syncOnce);
  _expect(a.outboxCount == 2, 'ambiguous result was incorrectly acknowledged');

  await fixture.engine(a).syncOnce();
  _expect(a.outboxCount == 0, 'retry did not drain the outbox');
  await fixture.engine(b).syncOnce();
  _expect(
    b.markdownBody(noteId) == 'survives retry',
    'retry lost the revision',
  );
}

Future<void> _tombstoneVersusOfflineEdit() async {
  final fixture = _Fixture();
  final a = fixture.replica('a');
  final b = fixture.replica('b');
  final c = fixture.replica('c');
  final noteId = a.createMarkdownNote(body: 'base');
  await fixture.engine(a).syncOnce();
  await fixture.engine(b).syncOnce();
  await fixture.engine(c).syncOnce();

  a.deleteNote(noteId);
  await fixture.engine(a).syncOnce();
  await fixture.engine(b).syncOnce();
  _expect(b.isDeleted(noteId), 'clean old device resurrected a deleted note');

  c.editMarkdownNote(noteId, body: 'new offline work');
  await fixture.engine(c).syncOnce();
  await fixture.engine(a).syncOnce();
  _expect(a.hasConflict(noteId), 'delete-versus-edit conflict was hidden');
  final operations = a
      .noteHeads(noteId)
      .map((head) => a.revisionById(head)!.operation)
      .toSet();
  _expect(
    operations.containsAll(const <RevisionOperation>{
      RevisionOperation.tombstone,
      RevisionOperation.upsert,
    }),
    'tombstone or offline work was discarded',
  );
}

Future<void> _remoteOutage() async {
  final fixture = _Fixture();
  final a = fixture.replica('a');
  final b = fixture.replica('b');
  await fixture.engine(a).syncOnce();

  final noteId = a.createMarkdownNote(body: 'written while offline');
  fixture.store.online = false;
  await _expectThrows<ObjectStoreUnavailable>(fixture.engine(a).syncOnce);
  _expect(a.draftCount == 0, 'draft was not protected as a local revision');
  _expect(a.revisionCount == 1, 'local revision was lost during outage');
  _expect(a.outboxCount == 2, 'outbox was lost during outage');

  fixture.store.online = true;
  await fixture.engine(a).syncOnce();
  await fixture.engine(b).syncOnce();
  _expect(
    b.markdownBody(noteId) == 'written while offline',
    'recovery lost data',
  );
}

Future<void> _corruptRemoteObject() async {
  final fixture = _Fixture();
  final a = fixture.replica('a');
  final b = fixture.replica('b');
  final noteId = a.createMarkdownNote(body: 'do not apply corrupt bytes');
  await fixture.engine(a).syncOnce();
  final revisionKey = ProtocolPaths.revision(
    noteId,
    a.noteHeads(noteId).single,
  );
  fixture.store.corruptForTest(revisionKey, <int>[0, 1, 2, 3]);

  await _expectThrows<RemoteObjectCorruptedException>(
    fixture.engine(b).syncOnce,
  );
  _expect(b.cursorFor(a.deviceId) == 0, 'cursor advanced past corruption');
  _expect(b.revisionCount == 0, 'corrupt revision changed local state');
}

final class _Fixture {
  _Fixture()
    : vault = VaultIdentity(
        vaultId: 'vault-simulator',
        generation: 1,
        createdAtUtc: DateTime.utc(2026, 8, 10),
      );

  final VaultIdentity vault;
  final FakeObjectStore store = FakeObjectStore();
  final _AdvancingClock clock = _AdvancingClock();

  SyncReplica replica(String name) => SyncReplica(
    vault: vault,
    deviceId: 'device-$name',
    idFactory: SequenceIdFactory(name),
    clock: clock.call,
  );

  SyncEngine engine(SyncReplica replica) =>
      SyncEngine(replica: replica, store: store);
}

final class _AdvancingClock {
  DateTime _current = DateTime.utc(2026, 8, 10, 12);

  DateTime call() {
    final result = _current;
    _current = _current.add(const Duration(milliseconds: 1));
    return result;
  }
}

void _expect(bool condition, String message) {
  if (!condition) {
    throw StateError(message);
  }
}

Future<void> _expectThrows<T extends Object>(
  FutureOr<Object?> Function() action,
) async {
  try {
    await action();
  } on T {
    return;
  }
  throw StateError('Expected $T');
}
