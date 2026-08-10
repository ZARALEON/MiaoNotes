import 'package:miaonotes_core/miaonotes_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'editing back to committed content does not create an empty revision',
    () {
      DateTime clock() => DateTime.utc(2026, 8, 10);
      final replica = SyncReplica(
        vault: VaultIdentity(
          vaultId: 'vault',
          generation: 1,
          createdAtUtc: clock(),
        ),
        deviceId: 'device-a',
        idFactory: SequenceIdFactory('id'),
        clock: clock,
      );
      final noteId = replica.createMarkdownNote(body: 'same');
      expect(replica.commitDraft(noteId), isNotNull);
      final before = replica.revisionCount;

      replica.editMarkdownNote(noteId, body: 'changed');
      replica.editMarkdownNote(noteId, body: 'same');
      expect(replica.commitDraft(noteId), isNull);
      expect(replica.revisionCount, before);
    },
  );
}
