enum ContentFormat {
  markdown('markdown'),
  miaoDoc('miaodoc');

  const ContentFormat(this.wireName);

  final String wireName;

  static ContentFormat fromWireName(String value) => switch (value) {
    'markdown' => ContentFormat.markdown,
    'miaodoc' => ContentFormat.miaoDoc,
    _ => throw FormatException('Unsupported content format: $value'),
  };
}

enum RevisionOperation {
  upsert('upsert'),
  tombstone('tombstone');

  const RevisionOperation(this.wireName);

  final String wireName;

  static RevisionOperation fromWireName(String value) => switch (value) {
    'upsert' => RevisionOperation.upsert,
    'tombstone' => RevisionOperation.tombstone,
    _ => throw FormatException('Unsupported revision operation: $value'),
  };
}
