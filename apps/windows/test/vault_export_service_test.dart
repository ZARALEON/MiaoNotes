import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:miaonotes_core/miaonotes_core.dart';

import 'package:miaonotes_windows/src/application/vault_export_service.dart';
import 'package:miaonotes_windows/src/application/vault_import_service.dart';

void main() {
  late MiaoNotesDatabase database;
  late PersistentNoteStore store;
  late Directory destination;

  setUp(() async {
    database = MiaoNotesDatabase.inMemory();
    store = PersistentNoteStore(
      database: database,
      idFactory: SequenceIdFactory('export'),
      clock: () => DateTime.utc(2026, 8, 10, 12),
    );
    await store.initializeVault(
      vault: VaultIdentity(
        vaultId: 'vault-export-test',
        generation: 1,
        createdAtUtc: DateTime.utc(2026, 8, 10),
      ),
      deviceId: 'device-a',
      deviceName: 'Export test',
    );
    destination = await Directory.systemTemp.createTemp('miaonotes-export-');
  });

  tearDown(() async {
    await database.close();
    if (await destination.exists()) {
      await destination.delete(recursive: true);
    }
  });

  test('writes a verified portable export including the dirty draft', () async {
    await store.saveDraft(_draft('first version'));
    final committed = await store.commitDraft('note-unsafe');
    await store.saveDraft(
      _draft(
        'latest saved keystrokes',
        bases: <String>[committed!.revision.revisionId],
      ),
    );
    final service = VaultExportService(
      store: store,
      destinationRoot: destination,
      clock: () => DateTime.utc(2026, 8, 10, 12),
    );

    final result = await service.exportPortableSnapshot();

    expect(result.noteCount, 1);
    expect(result.revisionCount, 1);
    expect(
      await File('${result.directory.path}/manifest.json').exists(),
      isTrue,
    );
    await VaultExportService.verifyExport(result.directory);
    final allFiles = await result.directory
        .list(recursive: true)
        .where((entry) => entry is File)
        .cast<File>()
        .toList();
    expect(
      allFiles.map((file) => file.path),
      everyElement(isNot(contains('unsafe'))),
    );
    final noteMetadata = allFiles.singleWhere(
      (file) => file.path.endsWith('${Platform.pathSeparator}note.json'),
    );
    final noteJson = jsonDecode(await noteMetadata.readAsString()) as Map;
    expect(noteJson['dirty'], isTrue);
    final content = allFiles.singleWhere(
      (file) => file.path.endsWith('content.md'),
    );
    expect(await content.readAsString(), 'latest saved keystrokes');
  });

  test('detects tampering after export', () async {
    await store.saveDraft(_draft('protected content'));
    final result = await VaultExportService(
      store: store,
      destinationRoot: destination,
    ).exportPortableSnapshot();
    final content = await result.directory
        .list(recursive: true)
        .where((entry) => entry is File && entry.path.endsWith('content.md'))
        .cast<File>()
        .single;
    await content.writeAsString('tampered');

    await expectLater(
      VaultExportService.verifyExport(result.directory),
      throwsA(isA<ExportVerificationException>()),
    );
  });

  test('removes the partial directory when a write fails', () async {
    await store.saveDraft(_draft('content'));
    final service = VaultExportService(
      store: store,
      destinationRoot: destination,
      writeHook: (path) {
        if (path.endsWith('content.md')) {
          throw StateError('injected disk failure');
        }
      },
    );

    await expectLater(service.exportPortableSnapshot(), throwsStateError);
    expect(await destination.list().toList(), isEmpty);
  });

  test('previews and atomically imports a verified export', () async {
    await store.saveDraft(_draft('first version'));
    final committed = await store.commitDraft('note-unsafe');
    await store.saveDraft(
      _draft(
        'latest dirty text',
        bases: <String>[committed!.revision.revisionId],
      ),
    );
    final exported = await VaultExportService(
      store: store,
      destinationRoot: destination,
    ).exportPortableSnapshot();
    final targetDatabase = MiaoNotesDatabase.inMemory();
    final target = PersistentNoteStore(
      database: targetDatabase,
      idFactory: SequenceIdFactory('import'),
      clock: () => DateTime.utc(2026, 8, 10, 13),
    );
    await target.initializeVault(
      vault: VaultIdentity(
        vaultId: 'placeholder',
        generation: 1,
        createdAtUtc: DateTime.utc(2026, 8, 10, 13),
      ),
      deviceId: 'restore-device',
      deviceName: 'Restore test',
    );
    addTearDown(targetDatabase.close);
    final importer = VaultImportService(store: target);

    final preview = await importer.inspectPortableExport(exported.directory);
    final result = await importer.importPortableExport(exported.directory);

    expect(preview.noteCount, 1);
    expect(preview.revisionCount, 1);
    expect(preview.snapshot.vault.vaultId, 'vault-export-test');
    expect(result.imported.queuedObjectCount, 2);
    expect((await target.loadDraft('note-unsafe'))!.body, 'latest dirty text');
  });

  test('rechecks file digests after preview before importing', () async {
    await store.saveDraft(_draft('protected content'));
    final exported = await VaultExportService(
      store: store,
      destinationRoot: destination,
    ).exportPortableSnapshot();
    final targetDatabase = MiaoNotesDatabase.inMemory();
    final target = PersistentNoteStore(
      database: targetDatabase,
      idFactory: SequenceIdFactory('import'),
    );
    await target.initializeVault(
      vault: VaultIdentity(
        vaultId: 'placeholder',
        generation: 1,
        createdAtUtc: DateTime.utc(2026, 8, 10),
      ),
      deviceId: 'restore-device',
      deviceName: 'Restore test',
    );
    addTearDown(targetDatabase.close);
    final importer = VaultImportService(store: target);
    await importer.inspectPortableExport(exported.directory);
    final content = await exported.directory
        .list(recursive: true)
        .where((entity) => entity is File && entity.path.endsWith('content.md'))
        .cast<File>()
        .single;
    await content.writeAsString('changed after preview');

    await expectLater(
      importer.importPortableExport(exported.directory),
      throwsA(isA<ImportVerificationException>()),
    );
    expect(await target.recentNotes(), isEmpty);
  });

  test('rejects undeclared files and inconsistent manifest counts', () async {
    await store.saveDraft(_draft('content'));
    final first = await VaultExportService(
      store: store,
      destinationRoot: destination,
    ).exportPortableSnapshot();
    final importer = VaultImportService(store: store);
    await File('${first.directory.path}/unexpected.txt').writeAsString('no');
    await expectLater(
      importer.inspectPortableExport(first.directory),
      throwsA(isA<ImportVerificationException>()),
    );

    final second = await VaultExportService(
      store: store,
      destinationRoot: destination,
    ).exportPortableSnapshot();
    final manifestFile = File('${second.directory.path}/manifest.json');
    final manifest = jsonDecode(await manifestFile.readAsString()) as Map;
    (manifest['counts'] as Map)['notes'] = 999;
    await manifestFile.writeAsString(jsonEncode(manifest));
    await expectLater(
      importer.inspectPortableExport(second.directory),
      throwsA(isA<ImportVerificationException>()),
    );
  });
}

NoteDraft _draft(String body, {List<String> bases = const <String>[]}) =>
    NoteDraft(
      noteId: 'note-unsafe',
      format: ContentFormat.markdown,
      title: 'Export note',
      body: body,
      tags: const <String>['backup'],
      baseRevisionIds: bases,
      updatedAtUtc: DateTime.utc(2026, 8, 10, 12),
    );
