import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:miaonotes_core/miaonotes_core.dart';

import 'package:miaonotes_windows/src/application/miaonotes_application.dart';
import 'package:miaonotes_windows/src/application/vault_export_service.dart';
import 'package:miaonotes_windows/src/ui/miaonotes_shell.dart';

void main() {
  testWidgets('previews and restores a verified export into an empty app', (
    tester,
  ) async {
    final directory = await Directory.systemTemp.createTemp(
      'miaonotes-import-dialog-',
    );
    final sourceDatabase = MiaoNotesDatabase.inMemory();
    final source = PersistentNoteStore(
      database: sourceDatabase,
      idFactory: SequenceIdFactory('source'),
      clock: () => DateTime.utc(2026, 8, 10, 12),
    );
    await source.initializeVault(
      vault: VaultIdentity(
        vaultId: 'vault-import-dialog',
        generation: 1,
        createdAtUtc: DateTime.utc(2026, 8, 10),
      ),
      deviceId: 'source-device',
      deviceName: 'Source',
    );
    await source.saveDraft(
      NoteDraft(
        noteId: 'restored-note',
        format: ContentFormat.markdown,
        title: 'Recovered title',
        body: 'Recovered body',
        tags: const <String>['backup'],
        baseRevisionIds: const <String>[],
        updatedAtUtc: DateTime.utc(2026, 8, 10, 12),
      ),
    );
    await source.commitDraft('restored-note');
    final exported = await VaultExportService(
      store: source,
      destinationRoot: directory,
    ).exportPortableSnapshot();
    await sourceDatabase.close();

    final targetDatabase = MiaoNotesDatabase.inMemory();
    final app = await MiaoNotesApplication.open(
      database: targetDatabase,
      idFactory: SequenceIdFactory('target'),
      clock: () => DateTime.utc(2026, 8, 10, 13),
    );
    addTearDown(() async {
      await app.close();
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
    });
    await tester.pumpWidget(
      MiaoNotesShell(workspace: app.workspace, localCommits: app.localCommits),
    );

    await tester.tap(find.byKey(const Key('import-notes-button')));
    await _pumpUntilFound(
      tester,
      find.byKey(const Key('import-directory-field')),
    );
    await tester.enterText(
      find.byKey(const Key('import-directory-field')),
      exported.directory.path,
    );
    await tester.tap(find.byKey(const Key('inspect-import-button')));
    await _pumpUntilFound(tester, find.text('备份已通过完整性与结构校验'));

    expect(find.text('备份已通过完整性与结构校验'), findsOneWidget);
    expect(find.textContaining('1 条便签'), findsOneWidget);

    await tester.tap(find.byKey(const Key('confirm-import-button')));
    await _pumpUntilFound(tester, find.text('备份已完整恢复'));

    expect(find.text('备份已完整恢复'), findsOneWidget);
    expect(app.workspace.currentDraft?.title, 'Recovered title');
    expect(app.workspace.currentDraft?.body, 'Recovered body');
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 100; attempt += 1) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }
  fail('Timed out waiting for the expected widget');
}
