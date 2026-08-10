import 'canonical_json.dart';
import 'content_format.dart';

/// A locally durable working copy. It is not itself part of the sync protocol.
final class NoteDraft {
  NoteDraft({
    required this.noteId,
    required this.format,
    required this.title,
    required Object body,
    required Iterable<String> tags,
    required Iterable<String> baseRevisionIds,
    required this.updatedAtUtc,
    this.deleted = false,
  }) : body = deepCopyJson(body),
       tags = _normalizeTags(tags),
       baseRevisionIds = _normalizeIds(baseRevisionIds);

  final String noteId;
  final ContentFormat format;
  final String title;
  final Object body;
  final List<String> tags;
  final List<String> baseRevisionIds;
  final DateTime updatedAtUtc;
  final bool deleted;

  Map<String, Object?> get contentPayload => <String, Object?>{
    'body': body,
    'deleted': deleted,
    'format': format.wireName,
    'noteId': noteId,
    'tags': tags,
    'title': title,
  };
}

List<String> _normalizeTags(Iterable<String> tags) {
  final normalized =
      tags
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .toList()
        ..sort();
  return List.unmodifiable(normalized);
}

List<String> _normalizeIds(Iterable<String> ids) {
  final normalized = ids.toSet().toList()..sort();
  return List.unmodifiable(normalized);
}
