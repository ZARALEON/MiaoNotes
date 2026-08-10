import 'dart:convert';
import 'dart:io';

import 'package:miaonotes_core/miaonotes_core.dart';

import 'vault_export_service.dart';

final class VaultImportPreview {
  const VaultImportPreview({
    required this.directory,
    required this.snapshot,
    required this.fileCount,
  });

  final Directory directory;
  final ExportSnapshot snapshot;
  final int fileCount;

  int get noteCount => snapshot.notes.length;
  int get revisionCount => snapshot.revisions.length;
  int get conflictCount => snapshot.conflicts.length;
}

final class VaultImportResult {
  const VaultImportResult({required this.preview, required this.imported});

  final VaultImportPreview preview;
  final PortableImportResult imported;
}

final class ImportVerificationException implements Exception {
  const ImportVerificationException(this.message);

  final String message;

  @override
  String toString() => 'ImportVerificationException: $message';
}

/// Reads and verifies Export v1 before delegating one atomic write to Core.
final class VaultImportService {
  const VaultImportService({required this.store});

  final PersistentNoteStore store;

  Future<VaultImportPreview> inspectPortableExport(Directory directory) async {
    final root = directory.absolute;
    if (!await root.exists()) {
      throw const ImportVerificationException(
        'Import directory does not exist',
      );
    }
    try {
      await VaultExportService.verifyExport(root);
      final manifest = await _readJson(root, 'manifest.json');
      final entries = _list(manifest, 'files');
      final declaredPaths = <String>{};
      final caseInsensitivePaths = <String>{};
      var declaredBytes = 0;
      for (final item in entries) {
        final entry = _map(item, 'manifest file entry');
        final path = _string(entry, 'path');
        final bytes = _integer(entry, 'bytes');
        if (!declaredPaths.add(path) ||
            !caseInsensitivePaths.add(path.toLowerCase())) {
          throw ImportVerificationException('Ambiguous file path: $path');
        }
        declaredBytes += bytes;
        if (declaredBytes > 2 * 1024 * 1024 * 1024) {
          throw const ImportVerificationException(
            'Portable export exceeds the 2 GiB import limit',
          );
        }
      }
      await _verifyDirectoryEntities(root, declaredPaths);

      final vault = VaultIdentity.fromBytes(
        await File(_join(root.path, 'vault.json')).readAsBytes(),
      );
      if (_string(manifest, 'kind') != 'miaonotes-portable-export' ||
          _integer(manifest, 'schema') != 1 ||
          manifest['plaintext'] != true ||
          _string(manifest, 'vaultId') != vault.vaultId ||
          _integer(manifest, 'vaultGeneration') != vault.generation) {
        throw const ImportVerificationException(
          'Manifest and Vault identity do not match',
        );
      }

      final recognized = <String>{'vault.json', 'conflicts.json'};
      final notes = <ExportNoteState>[];
      final notePaths =
          declaredPaths
              .where(
                (path) => RegExp(r'^notes/[^/]+/note\.json$').hasMatch(path),
              )
              .toList()
            ..sort();
      for (final metadataPath in notePaths) {
        final metadata = await _readJson(root, metadataPath);
        if (_integer(metadata, 'schema') != 1) {
          throw ImportVerificationException(
            'Unsupported note metadata: $metadataPath',
          );
        }
        final noteId = _string(metadata, 'noteId');
        final component = metadataPath.split('/')[1];
        if (component != _stableComponent(noteId)) {
          throw ImportVerificationException(
            'Note path does not match its identifier: $metadataPath',
          );
        }
        final format = ContentFormat.fromWireName(_string(metadata, 'format'));
        final expectedContentName = format == ContentFormat.markdown
            ? 'content.md'
            : 'content.miaodoc.json';
        final contentName = _string(metadata, 'contentFile');
        if (contentName != expectedContentName) {
          throw ImportVerificationException(
            'Unexpected note content file: $metadataPath',
          );
        }
        final contentPath = 'notes/$component/$contentName';
        if (!declaredPaths.contains(contentPath)) {
          throw ImportVerificationException('Missing file: $contentPath');
        }
        final contentBytes = await File(
          _join(root.path, contentPath),
        ).readAsBytes();
        final Object body;
        if (format == ContentFormat.markdown) {
          body = utf8.decode(contentBytes);
        } else {
          final decoded = jsonDecode(utf8.decode(contentBytes));
          if (decoded is! Map<String, Object?>) {
            throw ImportVerificationException(
              'MiaoDoc content must be a JSON object: $contentPath',
            );
          }
          body = decoded;
        }
        final lastCommitted = metadata['lastCommittedRevisionId'];
        if (lastCommitted != null && lastCommitted is! String) {
          throw ImportVerificationException(
            'Invalid committed revision ID: $metadataPath',
          );
        }
        notes.add(
          ExportNoteState(
            draft: NoteDraft(
              noteId: noteId,
              format: format,
              title: _string(metadata, 'title'),
              body: body,
              tags: _stringList(metadata, 'tags'),
              baseRevisionIds: _stringList(metadata, 'baseRevisionIds'),
              updatedAtUtc: _date(metadata, 'updatedAt'),
              deleted: _boolean(metadata, 'deleted'),
            ),
            createdAtUtc: _date(metadata, 'createdAt'),
            dirty: _boolean(metadata, 'dirty'),
            lastCommittedRevisionId: lastCommitted as String?,
          ),
        );
        recognized
          ..add(metadataPath)
          ..add(contentPath);
      }

      final revisions = <Revision>[];
      final revisionPattern = RegExp(r'^revisions/([^/]+)/([^/]+)\.json$');
      final revisionPaths =
          declaredPaths.where((path) => revisionPattern.hasMatch(path)).toList()
            ..sort();
      for (final path in revisionPaths) {
        final revision = Revision.fromBytes(
          await File(_join(root.path, path)).readAsBytes(),
        );
        final match = revisionPattern.firstMatch(path)!;
        if (match.group(1) != _stableComponent(revision.noteId) ||
            match.group(2) != _stableComponent(revision.revisionId)) {
          throw ImportVerificationException(
            'Revision path does not match its identifiers: $path',
          );
        }
        revisions.add(revision);
        recognized.add(path);
      }

      final conflictsDocument = await _readJson(root, 'conflicts.json');
      if (_integer(conflictsDocument, 'schema') != 1) {
        throw const ImportVerificationException(
          'Unsupported conflict document',
        );
      }
      final conflicts = <ExportConflictRecord>[];
      for (final item in _list(conflictsDocument, 'conflicts')) {
        final conflict = _map(item, 'conflict');
        final status = switch (_string(conflict, 'status')) {
          'open' => ExportConflictStatus.open,
          'resolved' => ExportConflictStatus.resolved,
          final value => throw ImportVerificationException(
            'Unsupported conflict status: $value',
          ),
        };
        final resolvedAt = conflict['resolvedAt'];
        if (resolvedAt != null && resolvedAt is! String) {
          throw const ImportVerificationException(
            'Invalid conflict resolution timestamp',
          );
        }
        conflicts.add(
          ExportConflictRecord(
            conflictId: _string(conflict, 'conflictId'),
            noteId: _string(conflict, 'noteId'),
            headRevisionIds: _stringList(conflict, 'headRevisionIds'),
            status: status,
            createdAtUtc: _date(conflict, 'createdAt'),
            resolvedAtUtc: resolvedAt == null
                ? null
                : DateTime.parse(resolvedAt as String).toUtc(),
          ),
        );
      }

      if (recognized.length != declaredPaths.length ||
          !recognized.containsAll(declaredPaths)) {
        final unknown = declaredPaths.difference(recognized).toList()..sort();
        throw ImportVerificationException(
          'Unsupported files in export: ${unknown.join(', ')}',
        );
      }
      final counts = _map(manifest['counts'], 'manifest counts');
      if (_integer(counts, 'notes') != notes.length ||
          _integer(counts, 'revisions') != revisions.length ||
          _integer(counts, 'conflicts') != conflicts.length) {
        throw const ImportVerificationException(
          'Manifest counts do not match the exported files',
        );
      }
      final snapshot = ExportSnapshot(
        vault: vault,
        exportedAtUtc: _date(manifest, 'exportedAt'),
        notes: List.unmodifiable(notes),
        revisions: List.unmodifiable(revisions),
        conflicts: List.unmodifiable(conflicts),
      );
      return VaultImportPreview(
        directory: root,
        snapshot: snapshot,
        fileCount: declaredPaths.length + 1,
      );
    } on ImportVerificationException {
      rethrow;
    } on Object catch (error) {
      throw ImportVerificationException('Invalid portable export: $error');
    }
  }

  Future<VaultImportResult> importPortableExport(Directory directory) async {
    // Inspection is intentionally repeated after preview to close the window
    // for a modified file to be imported without a fresh digest pass.
    final preview = await inspectPortableExport(directory);
    final imported = await store.importPortableSnapshot(preview.snapshot);
    return VaultImportResult(preview: preview, imported: imported);
  }

  static Future<List<Directory>> discoverExports(Directory root) async {
    if (!await root.exists()) {
      return const <Directory>[];
    }
    final candidates = <({Directory directory, DateTime modified})>[];
    await for (final entity in root.list(followLinks: false)) {
      if (entity is Directory &&
          entity.path
              .split(Platform.pathSeparator)
              .last
              .startsWith('MiaoNotes-') &&
          await File(_join(entity.path, 'manifest.json')).exists()) {
        candidates.add((
          directory: entity,
          modified: (await entity.stat()).modified,
        ));
      }
    }
    candidates.sort((left, right) => right.modified.compareTo(left.modified));
    return List.unmodifiable(
      candidates.map((candidate) => candidate.directory),
    );
  }
}

Future<Map<String, Object?>> _readJson(
  Directory root,
  String relativePath,
) async {
  final decoded = jsonDecode(
    await File(_join(root.path, relativePath)).readAsString(),
  );
  return _map(decoded, relativePath);
}

Future<void> _verifyDirectoryEntities(
  Directory root,
  Set<String> declaredPaths,
) async {
  final actual = <String>{};
  final caseInsensitive = <String>{};
  await for (final entity in root.list(recursive: true, followLinks: false)) {
    final type = await FileSystemEntity.type(entity.path, followLinks: false);
    if (type == FileSystemEntityType.link) {
      throw ImportVerificationException(
        'Symbolic links are not allowed: ${entity.path}',
      );
    }
    if (type != FileSystemEntityType.file) {
      continue;
    }
    final prefix = '${root.path}${Platform.pathSeparator}';
    if (!entity.path.startsWith(prefix)) {
      throw const ImportVerificationException('File escaped import directory');
    }
    final relative = entity.path
        .substring(prefix.length)
        .replaceAll(Platform.pathSeparator, '/');
    if (!actual.add(relative) || !caseInsensitive.add(relative.toLowerCase())) {
      throw ImportVerificationException('Ambiguous file path: $relative');
    }
  }
  final expected = <String>{'manifest.json', ...declaredPaths};
  if (actual.length != expected.length || !actual.containsAll(expected)) {
    throw const ImportVerificationException(
      'Import directory contains missing or undeclared files',
    );
  }
}

Map<String, Object?> _map(Object? value, String label) {
  if (value is! Map<String, Object?>) {
    throw ImportVerificationException('$label must be a JSON object');
  }
  return value;
}

List<Object?> _list(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! List<Object?>) {
    throw ImportVerificationException('$key must be a JSON array');
  }
  return value;
}

String _string(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw ImportVerificationException('$key must be a non-empty string');
  }
  return value;
}

int _integer(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int || value < 0) {
    throw ImportVerificationException('$key must be a non-negative integer');
  }
  return value;
}

bool _boolean(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw ImportVerificationException('$key must be a boolean');
  }
  return value;
}

List<String> _stringList(Map<String, Object?> json, String key) {
  final value = _list(json, key);
  if (value.any((item) => item is! String)) {
    throw ImportVerificationException('$key must contain only strings');
  }
  return List.unmodifiable(value.cast<String>());
}

DateTime _date(Map<String, Object?> json, String key) =>
    DateTime.parse(_string(json, key)).toUtc();

String _stableComponent(String value) =>
    'item-${sha256HexBytes(utf8.encode(value)).substring(0, 24)}';

String _join(String root, String relativePath) =>
    '$root${Platform.pathSeparator}'
    '${relativePath.replaceAll('/', Platform.pathSeparator)}';
