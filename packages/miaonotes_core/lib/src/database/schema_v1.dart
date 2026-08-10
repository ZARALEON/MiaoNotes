/// Metadata for the canonical SQLite schema shipped with this package.
abstract final class SchemaV1 {
  static const int version = 1;

  /// Repository-relative location used by build and verification tooling.
  static const String sourcePath = 'schema/schema_v1.sql';

  /// Drift's type-generation mirror of [sourcePath]. CI verifies parity.
  static const String driftSourcePath = 'lib/src/database/schema_v1.drift';
}
