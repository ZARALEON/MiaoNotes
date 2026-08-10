import 'dart:convert';
import 'dart:typed_data';

import 'canonical_json.dart';

final class VaultIdentity {
  const VaultIdentity({
    required this.vaultId,
    required this.generation,
    required this.createdAtUtc,
    this.protocolVersion = 1,
  });

  factory VaultIdentity.fromBytes(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Vault identity must be a JSON object');
    }
    final schema = decoded['schema']! as int;
    final protocol = decoded['protocolVersion']! as int;
    if (schema != 1 || protocol != 1) {
      throw const FormatException('Unsupported vault identity version');
    }
    return VaultIdentity(
      vaultId: decoded['vaultId']! as String,
      generation: decoded['generation']! as int,
      protocolVersion: protocol,
      createdAtUtc: DateTime.parse(decoded['createdAt']! as String).toUtc(),
    );
  }

  final String vaultId;
  final int generation;
  final int protocolVersion;
  final DateTime createdAtUtc;

  Map<String, Object?> toJson() => <String, Object?>{
    'createdAt': createdAtUtc.toUtc().toIso8601String(),
    'generation': generation,
    'protocolVersion': protocolVersion,
    'schema': 1,
    'vaultId': vaultId,
  };

  Uint8List toBytes() => canonicalJsonBytes(toJson());
}
