import 'dart:convert';
import 'dart:typed_data';

import 'canonical_json.dart';
import 'content_format.dart';
import 'note_draft.dart';

final class Revision {
  Revision._({
    required this.schema,
    required this.vaultId,
    required this.vaultGeneration,
    required this.revisionId,
    required this.noteId,
    required this.parentRevisionIds,
    required this.deviceId,
    required this.createdAtUtc,
    required this.operation,
    required this.format,
    required this.title,
    required this.body,
    required this.tags,
    required this.payloadHash,
  });

  factory Revision.create({
    required String vaultId,
    required int vaultGeneration,
    required String revisionId,
    required String deviceId,
    required DateTime createdAtUtc,
    required NoteDraft draft,
  }) {
    final parents = draft.baseRevisionIds.toSet().toList()..sort();
    final fields = _payloadFields(
      schema: 1,
      vaultId: vaultId,
      vaultGeneration: vaultGeneration,
      revisionId: revisionId,
      noteId: draft.noteId,
      parentRevisionIds: parents,
      deviceId: deviceId,
      createdAtUtc: createdAtUtc,
      operation: draft.deleted
          ? RevisionOperation.tombstone
          : RevisionOperation.upsert,
      format: draft.format,
      title: draft.title,
      body: deepCopyJson(draft.body),
      tags: draft.tags,
    );
    return Revision._(
      schema: 1,
      vaultId: vaultId,
      vaultGeneration: vaultGeneration,
      revisionId: revisionId,
      noteId: draft.noteId,
      parentRevisionIds: List.unmodifiable(parents),
      deviceId: deviceId,
      createdAtUtc: createdAtUtc.toUtc(),
      operation: draft.deleted
          ? RevisionOperation.tombstone
          : RevisionOperation.upsert,
      format: draft.format,
      title: draft.title,
      body: draft.body,
      tags: List.unmodifiable(draft.tags),
      payloadHash: sha256HexJson(fields),
    );
  }

  factory Revision.fromJson(Map<String, Object?> json) {
    final revision = Revision._(
      schema: json['schema']! as int,
      vaultId: json['vaultId']! as String,
      vaultGeneration: json['vaultGeneration']! as int,
      revisionId: json['revisionId']! as String,
      noteId: json['noteId']! as String,
      parentRevisionIds: List.unmodifiable(
        (json['parentRevisionIds']! as List).cast<String>(),
      ),
      deviceId: json['deviceId']! as String,
      createdAtUtc: DateTime.parse(json['createdAt']! as String).toUtc(),
      operation: RevisionOperation.fromWireName(json['operation']! as String),
      format: ContentFormat.fromWireName(json['format']! as String),
      title: json['title']! as String,
      body: deepCopyJson(json['body']!),
      tags: List.unmodifiable((json['tags']! as List<Object?>).cast<String>()),
      payloadHash: json['payloadHash']! as String,
    );
    if (revision.schema != 1) {
      throw FormatException('Unsupported revision schema: ${revision.schema}');
    }
    if (revision.payloadHash != sha256HexJson(revision.payloadFields)) {
      throw const FormatException('Revision payload hash mismatch');
    }
    return revision;
  }

  factory Revision.fromBytes(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Revision must be a JSON object');
    }
    return Revision.fromJson(decoded);
  }

  final int schema;
  final String vaultId;
  final int vaultGeneration;
  final String revisionId;
  final String noteId;
  final List<String> parentRevisionIds;
  final String deviceId;
  final DateTime createdAtUtc;
  final RevisionOperation operation;
  final ContentFormat format;
  final String title;
  final Object body;
  final List<String> tags;
  final String payloadHash;

  Map<String, Object?> get payloadFields => _payloadFields(
    schema: schema,
    vaultId: vaultId,
    vaultGeneration: vaultGeneration,
    revisionId: revisionId,
    noteId: noteId,
    parentRevisionIds: parentRevisionIds,
    deviceId: deviceId,
    createdAtUtc: createdAtUtc,
    operation: operation,
    format: format,
    title: title,
    body: body,
    tags: tags,
  );

  Map<String, Object?> get contentPayload => <String, Object?>{
    'body': body,
    'deleted': operation == RevisionOperation.tombstone,
    'format': format.wireName,
    'noteId': noteId,
    'tags': tags,
    'title': title,
  };

  String get contentHash => sha256HexJson(contentPayload);

  Map<String, Object?> toJson() => <String, Object?>{
    ...payloadFields,
    'payloadHash': payloadHash,
  };

  Uint8List toBytes() => canonicalJsonBytes(toJson());
}

Map<String, Object?> _payloadFields({
  required int schema,
  required String vaultId,
  required int vaultGeneration,
  required String revisionId,
  required String noteId,
  required List<String> parentRevisionIds,
  required String deviceId,
  required DateTime createdAtUtc,
  required RevisionOperation operation,
  required ContentFormat format,
  required String title,
  required Object body,
  required List<String> tags,
}) => <String, Object?>{
  'body': body,
  'createdAt': createdAtUtc.toUtc().toIso8601String(),
  'deviceId': deviceId,
  'format': format.wireName,
  'noteId': noteId,
  'operation': operation.wireName,
  'parentRevisionIds': parentRevisionIds,
  'revisionId': revisionId,
  'schema': schema,
  'tags': tags,
  'title': title,
  'vaultGeneration': vaultGeneration,
  'vaultId': vaultId,
};
