import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:sqlite3/common.dart' as sqlite;

part 'database.g.dart';

@DriftDatabase(include: {'schema_v1.drift'})
final class MiaoNotesDatabase extends _$MiaoNotesDatabase {
  MiaoNotesDatabase(super.executor);

  factory MiaoNotesDatabase.openFile(File file, {bool logStatements = false}) =>
      MiaoNotesDatabase(
        NativeDatabase(
          file,
          logStatements: logStatements,
          setup: _configureConnection,
        ),
      );

  factory MiaoNotesDatabase.inMemory({bool logStatements = false}) =>
      MiaoNotesDatabase(
        NativeDatabase.memory(
          logStatements: logStatements,
          setup: _configureConnection,
        ),
      );

  @override
  int get schemaVersion => SchemaVersion.current;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    onUpgrade: (migrator, from, to) async {
      if (from == to) {
        return;
      }
      throw StateError(
        'No automatic migration exists from Schema v$from to v$to. '
        'Open in read-only safe mode.',
      );
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
      await customStatement('PRAGMA busy_timeout = 5000');
    },
  );
}

abstract final class SchemaVersion {
  static const int current = 1;
}

void _configureConnection(sqlite.CommonDatabase database) {
  database
    ..execute('PRAGMA foreign_keys = ON')
    ..execute('PRAGMA journal_mode = WAL')
    ..execute('PRAGMA synchronous = NORMAL')
    ..execute('PRAGMA busy_timeout = 5000');
}
