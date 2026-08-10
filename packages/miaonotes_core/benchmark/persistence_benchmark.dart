import 'dart:io';

import 'package:miaonotes_core/miaonotes_core.dart';

Future<void> main() async {
  final directory = await Directory.systemTemp.createTemp(
    'miaonotes-benchmark-',
  );
  try {
    final file = File('${directory.path}${Platform.pathSeparator}notes.db');
    final vault = VaultIdentity(
      vaultId: 'benchmark-vault',
      generation: 1,
      createdAtUtc: DateTime.now().toUtc(),
    );
    var database = MiaoNotesDatabase.openFile(file);
    var store = PersistentNoteStore(database: database);
    await store.initializeVault(
      vault: vault,
      deviceId: 'benchmark-device',
      deviceName: 'Benchmark',
    );
    for (var index = 0; index < 1000; index += 1) {
      await store.saveDraft(
        NoteDraft(
          noteId: 'note-$index',
          format: ContentFormat.markdown,
          title: 'Benchmark $index',
          body: 'searchable benchmark body $index',
          tags: const <String>['benchmark'],
          baseRevisionIds: const <String>[],
          updatedAtUtc: DateTime.now().toUtc(),
        ),
      );
    }
    await database.close();

    final reopen = Stopwatch()..start();
    database = MiaoNotesDatabase.openFile(file);
    store = PersistentNoteStore(database: database);
    await store.recentNotes(limit: 50);
    reopen.stop();

    final search = Stopwatch()..start();
    await store.searchNotes('searchable', limit: 50);
    search.stop();

    final draftSave = Stopwatch()..start();
    await store.saveDraft(
      NoteDraft(
        noteId: 'quick-note',
        format: ContentFormat.markdown,
        title: '',
        body: 'quick note',
        tags: const <String>[],
        baseRevisionIds: const <String>[],
        updatedAtUtc: DateTime.now().toUtc(),
      ),
    );
    draftSave.stop();
    await database.close();

    stdout.writeln('seed_notes=1000');
    stdout.writeln('reopen_to_recent_ms=${reopen.elapsedMilliseconds}');
    stdout.writeln('search_ms=${search.elapsedMilliseconds}');
    stdout.writeln('draft_save_ms=${draftSave.elapsedMilliseconds}');

    if (reopen.elapsedMilliseconds >= 1500 ||
        search.elapsedMilliseconds >= 100 ||
        draftSave.elapsedMilliseconds >= 150) {
      stderr.writeln('Persistence performance budget exceeded');
      exitCode = 1;
    }
  } finally {
    if (directory.existsSync()) {
      await directory.delete(recursive: true);
    }
  }
}
