import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:miaonotes_core/miaonotes_core.dart';

import 'package:miaonotes_windows/src/application/vault_export_service.dart';

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
