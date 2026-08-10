import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:miaonotes_core/miaonotes_core.dart';

typedef ExportWriteHook = FutureOr<void> Function(String relativePath);

final class VaultExportResult {
  const VaultExportResult({
    required this.directory,
    required this.noteCount,
    required this.revisionCount,
    required this.conflictCount,
    required this.fileCount,
  });

  final Directory directory;
  final int noteCount;
  final int revisionCount;
  final int conflictCount;
  final int fileCount;
}

final class ExportVerificationException implements Exception {
  const ExportVerificationException(this.message);

  final String message;

  @override
  String toString() => 'ExportVerificationException: $message';
}

/// Writes a plaintext, portable Export v1 snapshot without touching sync state.
final class VaultExportService {
  VaultExportService({
    required this.store,
    Directory? destinationRoot,
    DateTime Function()? clock,
    ExportWriteHook? writeHook,
  }) : _destinationRootOverride = destinationRoot,
       _clock = clock ?? (() => DateTime.now().toUtc()),
       _writeHookCallback = writeHook;

  final PersistentNoteStore store;
  final Directory? _destinationRootOverride;
  final DateTime Function() _clock;
  final ExportWriteHook? _writeHookCallback;

  Directory get destinationRoot =>
      _destinationRootOverride ?? Directory(_defaultDestinationRoot());

  Future<VaultExportResult> exportPortableSnapshot() async {
    final snapshot = await store.createExportSnapshot();
    final root = destinationRoot.absolute;
    await root.create(recursive: true);
    final timestamp = _filenameTimestamp(snapshot.exportedAtUtc);
    final finalDirectory = await _unusedDirectory(root, 'MiaoNotes-$timestamp');
    final partialDirectory = Directory(
      '${finalDirectory.path}.partial-${_clock().microsecondsSinceEpoch}-$pid',
    );
    final files = <_ExportedFile>[];

    try {
      await partialDirectory.create();
      await _writeJson(
        partialDirectory,
        'vault.json',
        snapshot.vault.toJson(),
        files,
      );

      for (final note in snapshot.notes) {
        final noteDirectory = 'notes/${_stableComponent(note.draft.noteId)}';
        final contentName = note.draft.format == ContentFormat.markdown
            ? 'content.md'
            : 'content.miaodoc.json';
        final contentPath = '$noteDirectory/$contentName';
        final contentBytes = note.draft.format == ContentFormat.markdown
            ? Uint8List.fromList(utf8.encode(note.draft.body as String))
            : canonicalJsonBytes(note.draft.body);
        await _writeBytes(partialDirectory, contentPath, contentBytes, files);
        await _writeJson(
          partialDirectory,
          '$noteDirectory/note.json',
          <String, Object?>{
            'baseRevisionIds': note.draft.baseRevisionIds,
            'contentFile': contentName,
            'createdAt': note.createdAtUtc.toUtc().toIso8601String(),
            'deleted': note.draft.deleted,
            'dirty': note.dirty,
            'format': note.draft.format.wireName,
            'lastCommittedRevisionId': note.lastCommittedRevisionId,
            'noteId': note.draft.noteId,
            'schema': 1,
            'tags': note.draft.tags,
            'title': note.draft.title,
            'updatedAt': note.draft.updatedAtUtc.toUtc().toIso8601String(),
          },
          files,
        );
      }

      for (final revision in snapshot.revisions) {
        final path =
            'revisions/${_stableComponent(revision.noteId)}/'
            '${_stableComponent(revision.revisionId)}.json';
        await _writeBytes(partialDirectory, path, revision.toBytes(), files);
      }

      await _writeJson(partialDirectory, 'conflicts.json', <String, Object?>{
        'conflicts': snapshot.conflicts
            .map(
              (conflict) => <String, Object?>{
                'conflictId': conflict.conflictId,
                'createdAt': conflict.createdAtUtc.toIso8601String(),
                'headRevisionIds': conflict.headRevisionIds,
                'noteId': conflict.noteId,
                'resolvedAt': conflict.resolvedAtUtc?.toIso8601String(),
                'status': conflict.status.name,
              },
            )
            .toList(growable: false),
        'schema': 1,
      }, files);

      files.sort((left, right) => left.path.compareTo(right.path));
      final manifest = <String, Object?>{
        'counts': <String, Object?>{
          'conflicts': snapshot.conflicts.length,
          'notes': snapshot.notes.length,
          'revisions': snapshot.revisions.length,
        },
        'exportedAt': snapshot.exportedAtUtc.toUtc().toIso8601String(),
        'files': files.map((file) => file.toJson()).toList(growable: false),
        'kind': 'miaonotes-portable-export',
        'plaintext': true,
        'schema': 1,
        'vaultGeneration': snapshot.vault.generation,
        'vaultId': snapshot.vault.vaultId,
      };
      await _writeManifest(partialDirectory, manifest);
      await verifyExport(partialDirectory);
      final completed = await partialDirectory.rename(finalDirectory.path);
      return VaultExportResult(
        directory: completed,
        noteCount: snapshot.notes.length,
        revisionCount: snapshot.revisions.length,
        conflictCount: snapshot.conflicts.length,
        fileCount: files.length + 1,
      );
    } on Object {
      await _deletePartialSafely(root, partialDirectory);
      rethrow;
    }
  }

  static Future<void> verifyExport(Directory directory) async {
    final manifestFile = File(_join(directory.path, 'manifest.json'));
    if (!await manifestFile.exists()) {
      throw const ExportVerificationException('manifest.json is missing');
    }
    final Object? decoded;
    try {
      decoded = jsonDecode(await manifestFile.readAsString());
    } on Object catch (error) {
      throw ExportVerificationException('Invalid manifest: $error');
    }
    if (decoded is! Map<String, Object?> ||
        decoded['schema'] != 1 ||
        decoded['kind'] != 'miaonotes-portable-export' ||
        decoded['files'] is! List<Object?>) {
      throw const ExportVerificationException('Unsupported export manifest');
    }
    final seen = <String>{};
    for (final item in decoded['files']! as List<Object?>) {
      if (item is! Map<String, Object?> ||
          item['path'] is! String ||
          item['sha256'] is! String ||
          item['bytes'] is! int) {
        throw const ExportVerificationException('Invalid file entry');
      }
      final relativePath = item['path']! as String;
      if (!_isSafeRelativePath(relativePath) || !seen.add(relativePath)) {
        throw ExportVerificationException('Unsafe file path: $relativePath');
      }
      final file = File(_join(directory.path, relativePath));
      if (!await file.exists()) {
        throw ExportVerificationException('Missing file: $relativePath');
      }
      final bytes = await file.readAsBytes();
      if (bytes.length != item['bytes'] ||
          sha256HexBytes(bytes) != item['sha256']) {
        throw ExportVerificationException(
          'Integrity check failed: $relativePath',
        );
      }
    }
  }

  Future<void> _writeJson(
    Directory root,
    String relativePath,
    Object value,
    List<_ExportedFile> files,
  ) => _writeBytes(root, relativePath, canonicalJsonBytes(value), files);

  Future<void> _writeBytes(
    Directory root,
    String relativePath,
    List<int> bytes,
    List<_ExportedFile> files,
  ) async {
    if (!_isSafeRelativePath(relativePath)) {
      throw ArgumentError.value(relativePath, 'relativePath');
    }
    final file = File(_join(root.path, relativePath));
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    final written = await file.readAsBytes();
    if (!bytesEqual(bytes, written)) {
      throw ExportVerificationException(
        'Write verification failed: $relativePath',
      );
    }
    files.add(
      _ExportedFile(
        path: relativePath,
        bytes: written.length,
        sha256: sha256HexBytes(written),
      ),
    );
    await _writeHookCallback?.call(relativePath);
  }

  static Future<void> _writeManifest(
    Directory root,
    Map<String, Object?> manifest,
  ) async {
    final file = File(_join(root.path, 'manifest.json'));
    await file.writeAsBytes(canonicalJsonBytes(manifest), flush: true);
  }

  static Future<Directory> _unusedDirectory(
    Directory root,
    String baseName,
  ) async {
    for (var suffix = 0; suffix < 10000; suffix += 1) {
      final name = suffix == 0 ? baseName : '$baseName-$suffix';
      final candidate = Directory(_join(root.path, name));
      if (!await candidate.exists() && !await File(candidate.path).exists()) {
        return candidate;
      }
    }
    throw StateError('Could not allocate a unique export directory');
  }

  static Future<void> _deletePartialSafely(
    Directory root,
    Directory partial,
  ) async {
    if (!await partial.exists()) {
      return;
    }
    final expectedParent = root.absolute.path.toLowerCase();
    final actualParent = partial.parent.absolute.path.toLowerCase();
    if (actualParent != expectedParent || !partial.path.contains('.partial-')) {
      throw StateError('Refusing to remove an unsafe partial export path');
    }
    await partial.delete(recursive: true);
  }
}

final class _ExportedFile {
  const _ExportedFile({
    required this.path,
    required this.bytes,
    required this.sha256,
  });

  final String path;
  final int bytes;
  final String sha256;

  Map<String, Object?> toJson() => <String, Object?>{
    'bytes': bytes,
    'path': path,
    'sha256': sha256,
  };
}

String _stableComponent(String value) =>
    'item-${sha256HexBytes(utf8.encode(value)).substring(0, 24)}';

String _filenameTimestamp(DateTime value) {
  final utc = value.toUtc();
  String two(int part) => part.toString().padLeft(2, '0');
  return '${utc.year}${two(utc.month)}${two(utc.day)}-'
      '${two(utc.hour)}${two(utc.minute)}${two(utc.second)}Z';
}

bool _isSafeRelativePath(String path) {
  if (path.isEmpty ||
      path.startsWith('/') ||
      path.startsWith('\\') ||
      path.contains('\\') ||
      path.contains(':')) {
    return false;
  }
  final parts = path.split('/');
  return parts.every((part) => part.isNotEmpty && part != '.' && part != '..');
}

String _join(String root, String relativePath) =>
    '$root${Platform.pathSeparator}'
    '${relativePath.replaceAll('/', Platform.pathSeparator)}';

String _defaultDestinationRoot() {
  final profile = Platform.environment['USERPROFILE'];
  if (profile != null && profile.isNotEmpty) {
    return '$profile${Platform.pathSeparator}Documents'
        '${Platform.pathSeparator}MiaoNotes Exports';
  }
  final local = Platform.environment['LOCALAPPDATA'] ?? Directory.current.path;
  return '$local${Platform.pathSeparator}MiaoNotes'
      '${Platform.pathSeparator}Exports';
}
