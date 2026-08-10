import 'dart:io';

import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

void main() {
  test('standalone SQL and Drift schema stay in lockstep', () {
    final sql = _findSchema().readAsStringSync();
    final drift = _findDriftSchema().readAsStringSync();
    final productStatements = sql
        .split('\n')
        .where((line) => !line.trimLeft().startsWith('PRAGMA '))
        .join('\n')
        .trim();
    expect(drift.trim(), productStatements);
  });

  test('Schema v1 installs, indexes notes, and passes integrity check', () {
    final schemaFile = _findSchema();
    final database = sqlite3.openInMemory();
    addTearDown(database.close);

    database.execute(schemaFile.readAsStringSync());
    expect(database.userVersion, 1);

    database.execute('''
      INSERT INTO vault_state (
        singleton_id, vault_id, vault_generation, protocol_version,
        schema_version, local_device_id, created_at_ms, updated_at_ms
      ) VALUES (1, 'vault', 1, 1, 1, 'device-a', 1, 1)
    ''');
    database.execute('''
      INSERT INTO notes (
        note_id, format, title, draft_json, body_text, tags_json,
        tags_text, base_revision_ids_json, created_at_ms, updated_at_ms
      ) VALUES (
        'note-1', 'markdown', 'Shopping', '{}', 'buy milk', '["home"]',
        'home', '[]', 1, 1
      )
    ''');
    final matches = database.select(
      "SELECT note_id FROM notes_fts WHERE notes_fts MATCH 'milk'",
    );
    expect(matches.single['note_id'], 'note-1');

    database.execute(
      "UPDATE notes SET is_deleted = 1 WHERE note_id = 'note-1'",
    );
    final deletedMatches = database.select(
      "SELECT note_id FROM notes_fts WHERE notes_fts MATCH 'milk'",
    );
    expect(deletedMatches, isEmpty);
    expect(
      database.select('PRAGMA integrity_check').single.values.single,
      'ok',
    );
  });
}

File _findDriftSchema() {
  final candidates = <File>[
    File('lib/src/database/schema_v1.drift'),
    File('packages/miaonotes_core/lib/src/database/schema_v1.drift'),
  ];
  return candidates.firstWhere(
    (file) => file.existsSync(),
    orElse: () => throw StateError('Cannot locate Drift Schema v1'),
  );
}

File _findSchema() {
  final candidates = <File>[
    File('schema/schema_v1.sql'),
    File('packages/miaonotes_core/schema/schema_v1.sql'),
  ];
  return candidates.firstWhere(
    (file) => file.existsSync(),
    orElse: () => throw StateError('Cannot locate Schema v1 SQL'),
  );
}
