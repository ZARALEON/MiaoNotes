PRAGMA foreign_keys = ON;
PRAGMA journal_mode = WAL;
PRAGMA synchronous = NORMAL;
PRAGMA busy_timeout = 5000;

CREATE TABLE vault_state (
  singleton_id INTEGER PRIMARY KEY CHECK (singleton_id = 1),
  vault_id TEXT NOT NULL,
  vault_generation INTEGER NOT NULL CHECK (vault_generation > 0),
  protocol_version INTEGER NOT NULL CHECK (protocol_version = 1),
  schema_version INTEGER NOT NULL CHECK (schema_version = 1),
  local_device_id TEXT NOT NULL,
  next_event_sequence INTEGER NOT NULL DEFAULT 1 CHECK (next_event_sequence > 0),
  created_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL
) STRICT;

CREATE TABLE devices (
  device_id TEXT PRIMARY KEY,
  display_name TEXT NOT NULL,
  created_at_ms INTEGER NOT NULL,
  last_seen_at_ms INTEGER,
  retired_at_ms INTEGER
) STRICT;

CREATE TABLE notes (
  note_id TEXT PRIMARY KEY,
  format TEXT NOT NULL CHECK (format IN ('markdown', 'miaodoc')),
  title TEXT NOT NULL DEFAULT '',
  draft_json TEXT NOT NULL CHECK (json_valid(draft_json)),
  body_text TEXT NOT NULL DEFAULT '',
  tags_json TEXT NOT NULL DEFAULT '[]' CHECK (json_valid(tags_json)),
  tags_text TEXT NOT NULL DEFAULT '',
  base_revision_ids_json TEXT NOT NULL DEFAULT '[]'
    CHECK (json_valid(base_revision_ids_json)),
  dirty INTEGER NOT NULL DEFAULT 0 CHECK (dirty IN (0, 1)),
  is_deleted INTEGER NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1)),
  last_committed_revision_id TEXT,
  created_at_ms INTEGER NOT NULL,
  updated_at_ms INTEGER NOT NULL
) STRICT;

CREATE INDEX notes_recent_idx
  ON notes(is_deleted, updated_at_ms DESC, note_id);
CREATE INDEX notes_dirty_idx
  ON notes(updated_at_ms)
  WHERE dirty = 1;

CREATE VIRTUAL TABLE notes_fts USING fts5(
  note_id UNINDEXED,
  title,
  body_text,
  tags_text,
  tokenize = 'unicode61 remove_diacritics 2'
);

CREATE TRIGGER notes_fts_insert
AFTER INSERT ON notes
WHEN new.is_deleted = 0
BEGIN
  INSERT INTO notes_fts(note_id, title, body_text, tags_text)
  VALUES (new.note_id, new.title, new.body_text, new.tags_text);
END;

CREATE TRIGGER notes_fts_update
AFTER UPDATE OF title, body_text, tags_text, is_deleted ON notes
BEGIN
  DELETE FROM notes_fts WHERE note_id = old.note_id;
  INSERT INTO notes_fts(note_id, title, body_text, tags_text)
  SELECT new.note_id, new.title, new.body_text, new.tags_text
  WHERE new.is_deleted = 0;
END;

CREATE TRIGGER notes_fts_delete
AFTER DELETE ON notes
BEGIN
  DELETE FROM notes_fts WHERE note_id = old.note_id;
END;

CREATE TABLE revisions (
  revision_id TEXT PRIMARY KEY,
  vault_id TEXT NOT NULL,
  vault_generation INTEGER NOT NULL CHECK (vault_generation > 0),
  note_id TEXT NOT NULL,
  device_id TEXT NOT NULL,
  operation TEXT NOT NULL CHECK (operation IN ('upsert', 'tombstone')),
  format TEXT NOT NULL CHECK (format IN ('markdown', 'miaodoc')),
  title TEXT NOT NULL,
  body_json TEXT NOT NULL CHECK (json_valid(body_json)),
  body_text TEXT NOT NULL,
  tags_json TEXT NOT NULL CHECK (json_valid(tags_json)),
  canonical_payload_json TEXT NOT NULL CHECK (json_valid(canonical_payload_json)),
  payload_hash TEXT NOT NULL CHECK (length(payload_hash) = 64),
  created_at_ms INTEGER NOT NULL
) STRICT;

CREATE INDEX revisions_note_time_idx
  ON revisions(note_id, created_at_ms, revision_id);
CREATE INDEX revisions_device_idx
  ON revisions(device_id, created_at_ms);

CREATE TABLE revision_parents (
  revision_id TEXT NOT NULL REFERENCES revisions(revision_id)
    ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED,
  parent_revision_id TEXT NOT NULL REFERENCES revisions(revision_id)
    ON DELETE RESTRICT DEFERRABLE INITIALLY DEFERRED,
  parent_order INTEGER NOT NULL CHECK (parent_order >= 0),
  PRIMARY KEY (revision_id, parent_revision_id),
  UNIQUE (revision_id, parent_order)
) STRICT, WITHOUT ROWID;

CREATE INDEX revision_parents_parent_idx
  ON revision_parents(parent_revision_id, revision_id);

CREATE TABLE note_heads (
  note_id TEXT NOT NULL,
  revision_id TEXT NOT NULL REFERENCES revisions(revision_id) ON DELETE RESTRICT,
  PRIMARY KEY (note_id, revision_id)
) STRICT, WITHOUT ROWID;

CREATE TABLE sync_events (
  event_id TEXT PRIMARY KEY,
  vault_id TEXT NOT NULL,
  vault_generation INTEGER NOT NULL CHECK (vault_generation > 0),
  device_id TEXT NOT NULL,
  sequence INTEGER NOT NULL CHECK (sequence > 0),
  event_type TEXT NOT NULL CHECK (event_type = 'revision_committed'),
  object_key TEXT NOT NULL,
  object_hash TEXT NOT NULL CHECK (length(object_hash) = 64),
  occurred_at_ms INTEGER NOT NULL,
  UNIQUE (device_id, sequence)
) STRICT;

CREATE INDEX sync_events_order_idx
  ON sync_events(device_id, sequence);

CREATE TABLE sync_outbox (
  outbox_id INTEGER PRIMARY KEY AUTOINCREMENT,
  object_key TEXT NOT NULL UNIQUE,
  object_kind TEXT NOT NULL CHECK (object_kind IN ('revision', 'event')),
  payload BLOB NOT NULL,
  payload_hash TEXT NOT NULL CHECK (length(payload_hash) = 64),
  dependency_key TEXT,
  attempt_count INTEGER NOT NULL DEFAULT 0 CHECK (attempt_count >= 0),
  next_attempt_at_ms INTEGER NOT NULL DEFAULT 0,
  last_error TEXT,
  created_at_ms INTEGER NOT NULL
) STRICT;

CREATE INDEX sync_outbox_ready_idx
  ON sync_outbox(next_attempt_at_ms, outbox_id);

CREATE TABLE sync_cursors (
  remote_device_id TEXT PRIMARY KEY,
  last_sequence INTEGER NOT NULL DEFAULT 0 CHECK (last_sequence >= 0),
  updated_at_ms INTEGER NOT NULL
) STRICT, WITHOUT ROWID;

CREATE TABLE conflicts (
  conflict_id TEXT PRIMARY KEY,
  note_id TEXT NOT NULL,
  head_revision_ids_json TEXT NOT NULL CHECK (json_valid(head_revision_ids_json)),
  status TEXT NOT NULL CHECK (status IN ('open', 'resolved')),
  created_at_ms INTEGER NOT NULL,
  resolved_at_ms INTEGER
) STRICT;

CREATE INDEX conflicts_open_idx
  ON conflicts(created_at_ms DESC)
  WHERE status = 'open';

CREATE TABLE attachments (
  attachment_id TEXT PRIMARY KEY,
  content_hash TEXT NOT NULL UNIQUE CHECK (length(content_hash) = 64),
  byte_length INTEGER NOT NULL CHECK (byte_length >= 0),
  media_type TEXT NOT NULL,
  local_state TEXT NOT NULL
    CHECK (local_state IN ('local_available', 'remote_only', 'downloading', 'missing', 'corrupted')),
  local_path TEXT,
  created_at_ms INTEGER NOT NULL,
  last_accessed_at_ms INTEGER
) STRICT;

CREATE TABLE note_attachments (
  note_id TEXT NOT NULL,
  attachment_id TEXT NOT NULL REFERENCES attachments(attachment_id) ON DELETE RESTRICT,
  display_order INTEGER NOT NULL CHECK (display_order >= 0),
  PRIMARY KEY (note_id, attachment_id)
) STRICT, WITHOUT ROWID;

CREATE TABLE settings (
  setting_key TEXT PRIMARY KEY,
  value_json TEXT NOT NULL CHECK (json_valid(value_json)),
  updated_at_ms INTEGER NOT NULL
) STRICT, WITHOUT ROWID;

PRAGMA user_version = 1;
