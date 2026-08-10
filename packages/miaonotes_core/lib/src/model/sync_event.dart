import 'dart:convert';
import 'dart:typed_data';

import 'canonical_json.dart';

final class SyncEvent {
  const SyncEvent({
    required this.schema,
    required this.vaultId,
    required this.vaultGeneration,
    required this.eventId,
    required this.deviceId,
    required this.sequence,
    required this.eventType,
    required this.objectKey,
    required this.objectHash,
    required this.occurredAtUtc,
  });

  factory SyncEvent.revisionCommitted({
    required String vaultId,
    required int vaultGeneration,
    required String eventId,
    required String deviceId,
    required int sequence,
    required String objectKey,
    required String objectHash,
    required DateTime occurredAtUtc,
  }) => SyncEvent(
    schema: 1,
    vaultId: vaultId,
    vaultGeneration: vaultGeneration,
    eventId: eventId,
    deviceId: deviceId,
    sequence: sequence,
    eventType: 'revision_committed',
    objectKey: objectKey,
    objectHash: objectHash,
    occurredAtUtc: occurredAtUtc.toUtc(),
  );

  factory SyncEvent.fromJson(Map<String, Object?> json) {
    final event = SyncEvent(
      schema: json['schema']! as int,
      vaultId: json['vaultId']! as String,
      vaultGeneration: json['vaultGeneration']! as int,
      eventId: json['eventId']! as String,
      deviceId: json['deviceId']! as String,
      sequence: json['sequence']! as int,
      eventType: json['eventType']! as String,
      objectKey: json['objectKey']! as String,
      objectHash: json['objectHash']! as String,
      occurredAtUtc: DateTime.parse(json['occurredAt']! as String).toUtc(),
    );
    if (event.schema != 1 || event.eventType != 'revision_committed') {
      throw const FormatException('Unsupported sync event');
    }
    if (event.sequence < 1 || event.objectHash.length != 64) {
      throw const FormatException('Invalid sync event sequence or hash');
    }
    return event;
  }

  factory SyncEvent.fromBytes(List<int> bytes) {
    final decoded = jsonDecode(utf8.decode(bytes));
    if (decoded is! Map<String, Object?>) {
      throw const FormatException('Sync event must be a JSON object');
    }
    return SyncEvent.fromJson(decoded);
  }

  final int schema;
  final String vaultId;
  final int vaultGeneration;
  final String eventId;
  final String deviceId;
  final int sequence;
  final String eventType;
  final String objectKey;
  final String objectHash;
  final DateTime occurredAtUtc;

  Map<String, Object?> toJson() => <String, Object?>{
    'deviceId': deviceId,
    'eventId': eventId,
    'eventType': eventType,
    'objectHash': objectHash,
    'objectKey': objectKey,
    'occurredAt': occurredAtUtc.toUtc().toIso8601String(),
    'schema': schema,
    'sequence': sequence,
    'vaultGeneration': vaultGeneration,
    'vaultId': vaultId,
  };

  Uint8List toBytes() => canonicalJsonBytes(toJson());
}
