// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class VaultState extends Table with TableInfo<VaultState, VaultStateData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  VaultState(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _singletonIdMeta = const VerificationMeta(
    'singletonId',
  );
  late final GeneratedColumn<int> singletonId = GeneratedColumn<int>(
    'singleton_id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY CHECK (singleton_id = 1)',
  );
  static const VerificationMeta _vaultIdMeta = const VerificationMeta(
    'vaultId',
  );
  late final GeneratedColumn<String> vaultId = GeneratedColumn<String>(
    'vault_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _vaultGenerationMeta = const VerificationMeta(
    'vaultGeneration',
  );
  late final GeneratedColumn<int> vaultGeneration = GeneratedColumn<int>(
    'vault_generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (vault_generation > 0)',
  );
  static const VerificationMeta _protocolVersionMeta = const VerificationMeta(
    'protocolVersion',
  );
  late final GeneratedColumn<int> protocolVersion = GeneratedColumn<int>(
    'protocol_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (protocol_version = 1)',
  );
  static const VerificationMeta _schemaVersionMeta = const VerificationMeta(
    'schemaVersion',
  );
  late final GeneratedColumn<int> schemaVersion = GeneratedColumn<int>(
    'schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (schema_version = 1)',
  );
  static const VerificationMeta _localDeviceIdMeta = const VerificationMeta(
    'localDeviceId',
  );
  late final GeneratedColumn<String> localDeviceId = GeneratedColumn<String>(
    'local_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _nextEventSequenceMeta = const VerificationMeta(
    'nextEventSequence',
  );
  late final GeneratedColumn<int> nextEventSequence = GeneratedColumn<int>(
    'next_event_sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 1 CHECK (next_event_sequence > 0)',
    defaultValue: const CustomExpression('1'),
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    singletonId,
    vaultId,
    vaultGeneration,
    protocolVersion,
    schemaVersion,
    localDeviceId,
    nextEventSequence,
    createdAtMs,
    updatedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'vault_state';
  @override
  VerificationContext validateIntegrity(
    Insertable<VaultStateData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('singleton_id')) {
      context.handle(
        _singletonIdMeta,
        singletonId.isAcceptableOrUnknown(
          data['singleton_id']!,
          _singletonIdMeta,
        ),
      );
    }
    if (data.containsKey('vault_id')) {
      context.handle(
        _vaultIdMeta,
        vaultId.isAcceptableOrUnknown(data['vault_id']!, _vaultIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vaultIdMeta);
    }
    if (data.containsKey('vault_generation')) {
      context.handle(
        _vaultGenerationMeta,
        vaultGeneration.isAcceptableOrUnknown(
          data['vault_generation']!,
          _vaultGenerationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vaultGenerationMeta);
    }
    if (data.containsKey('protocol_version')) {
      context.handle(
        _protocolVersionMeta,
        protocolVersion.isAcceptableOrUnknown(
          data['protocol_version']!,
          _protocolVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_protocolVersionMeta);
    }
    if (data.containsKey('schema_version')) {
      context.handle(
        _schemaVersionMeta,
        schemaVersion.isAcceptableOrUnknown(
          data['schema_version']!,
          _schemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_schemaVersionMeta);
    }
    if (data.containsKey('local_device_id')) {
      context.handle(
        _localDeviceIdMeta,
        localDeviceId.isAcceptableOrUnknown(
          data['local_device_id']!,
          _localDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_localDeviceIdMeta);
    }
    if (data.containsKey('next_event_sequence')) {
      context.handle(
        _nextEventSequenceMeta,
        nextEventSequence.isAcceptableOrUnknown(
          data['next_event_sequence']!,
          _nextEventSequenceMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {singletonId};
  @override
  VaultStateData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return VaultStateData(
      singletonId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}singleton_id'],
      )!,
      vaultId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vault_id'],
      )!,
      vaultGeneration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vault_generation'],
      )!,
      protocolVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}protocol_version'],
      )!,
      schemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}schema_version'],
      )!,
      localDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_device_id'],
      )!,
      nextEventSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_event_sequence'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
    );
  }

  @override
  VaultState createAlias(String alias) {
    return VaultState(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class VaultStateData extends DataClass implements Insertable<VaultStateData> {
  final int singletonId;
  final String vaultId;
  final int vaultGeneration;
  final int protocolVersion;
  final int schemaVersion;
  final String localDeviceId;
  final int nextEventSequence;
  final int createdAtMs;
  final int updatedAtMs;
  const VaultStateData({
    required this.singletonId,
    required this.vaultId,
    required this.vaultGeneration,
    required this.protocolVersion,
    required this.schemaVersion,
    required this.localDeviceId,
    required this.nextEventSequence,
    required this.createdAtMs,
    required this.updatedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['singleton_id'] = Variable<int>(singletonId);
    map['vault_id'] = Variable<String>(vaultId);
    map['vault_generation'] = Variable<int>(vaultGeneration);
    map['protocol_version'] = Variable<int>(protocolVersion);
    map['schema_version'] = Variable<int>(schemaVersion);
    map['local_device_id'] = Variable<String>(localDeviceId);
    map['next_event_sequence'] = Variable<int>(nextEventSequence);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  VaultStateCompanion toCompanion(bool nullToAbsent) {
    return VaultStateCompanion(
      singletonId: Value(singletonId),
      vaultId: Value(vaultId),
      vaultGeneration: Value(vaultGeneration),
      protocolVersion: Value(protocolVersion),
      schemaVersion: Value(schemaVersion),
      localDeviceId: Value(localDeviceId),
      nextEventSequence: Value(nextEventSequence),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory VaultStateData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return VaultStateData(
      singletonId: serializer.fromJson<int>(json['singleton_id']),
      vaultId: serializer.fromJson<String>(json['vault_id']),
      vaultGeneration: serializer.fromJson<int>(json['vault_generation']),
      protocolVersion: serializer.fromJson<int>(json['protocol_version']),
      schemaVersion: serializer.fromJson<int>(json['schema_version']),
      localDeviceId: serializer.fromJson<String>(json['local_device_id']),
      nextEventSequence: serializer.fromJson<int>(json['next_event_sequence']),
      createdAtMs: serializer.fromJson<int>(json['created_at_ms']),
      updatedAtMs: serializer.fromJson<int>(json['updated_at_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'singleton_id': serializer.toJson<int>(singletonId),
      'vault_id': serializer.toJson<String>(vaultId),
      'vault_generation': serializer.toJson<int>(vaultGeneration),
      'protocol_version': serializer.toJson<int>(protocolVersion),
      'schema_version': serializer.toJson<int>(schemaVersion),
      'local_device_id': serializer.toJson<String>(localDeviceId),
      'next_event_sequence': serializer.toJson<int>(nextEventSequence),
      'created_at_ms': serializer.toJson<int>(createdAtMs),
      'updated_at_ms': serializer.toJson<int>(updatedAtMs),
    };
  }

  VaultStateData copyWith({
    int? singletonId,
    String? vaultId,
    int? vaultGeneration,
    int? protocolVersion,
    int? schemaVersion,
    String? localDeviceId,
    int? nextEventSequence,
    int? createdAtMs,
    int? updatedAtMs,
  }) => VaultStateData(
    singletonId: singletonId ?? this.singletonId,
    vaultId: vaultId ?? this.vaultId,
    vaultGeneration: vaultGeneration ?? this.vaultGeneration,
    protocolVersion: protocolVersion ?? this.protocolVersion,
    schemaVersion: schemaVersion ?? this.schemaVersion,
    localDeviceId: localDeviceId ?? this.localDeviceId,
    nextEventSequence: nextEventSequence ?? this.nextEventSequence,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
  );
  VaultStateData copyWithCompanion(VaultStateCompanion data) {
    return VaultStateData(
      singletonId: data.singletonId.present
          ? data.singletonId.value
          : this.singletonId,
      vaultId: data.vaultId.present ? data.vaultId.value : this.vaultId,
      vaultGeneration: data.vaultGeneration.present
          ? data.vaultGeneration.value
          : this.vaultGeneration,
      protocolVersion: data.protocolVersion.present
          ? data.protocolVersion.value
          : this.protocolVersion,
      schemaVersion: data.schemaVersion.present
          ? data.schemaVersion.value
          : this.schemaVersion,
      localDeviceId: data.localDeviceId.present
          ? data.localDeviceId.value
          : this.localDeviceId,
      nextEventSequence: data.nextEventSequence.present
          ? data.nextEventSequence.value
          : this.nextEventSequence,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('VaultStateData(')
          ..write('singletonId: $singletonId, ')
          ..write('vaultId: $vaultId, ')
          ..write('vaultGeneration: $vaultGeneration, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('localDeviceId: $localDeviceId, ')
          ..write('nextEventSequence: $nextEventSequence, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    singletonId,
    vaultId,
    vaultGeneration,
    protocolVersion,
    schemaVersion,
    localDeviceId,
    nextEventSequence,
    createdAtMs,
    updatedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is VaultStateData &&
          other.singletonId == this.singletonId &&
          other.vaultId == this.vaultId &&
          other.vaultGeneration == this.vaultGeneration &&
          other.protocolVersion == this.protocolVersion &&
          other.schemaVersion == this.schemaVersion &&
          other.localDeviceId == this.localDeviceId &&
          other.nextEventSequence == this.nextEventSequence &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs);
}

class VaultStateCompanion extends UpdateCompanion<VaultStateData> {
  final Value<int> singletonId;
  final Value<String> vaultId;
  final Value<int> vaultGeneration;
  final Value<int> protocolVersion;
  final Value<int> schemaVersion;
  final Value<String> localDeviceId;
  final Value<int> nextEventSequence;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  const VaultStateCompanion({
    this.singletonId = const Value.absent(),
    this.vaultId = const Value.absent(),
    this.vaultGeneration = const Value.absent(),
    this.protocolVersion = const Value.absent(),
    this.schemaVersion = const Value.absent(),
    this.localDeviceId = const Value.absent(),
    this.nextEventSequence = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
  });
  VaultStateCompanion.insert({
    this.singletonId = const Value.absent(),
    required String vaultId,
    required int vaultGeneration,
    required int protocolVersion,
    required int schemaVersion,
    required String localDeviceId,
    this.nextEventSequence = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
  }) : vaultId = Value(vaultId),
       vaultGeneration = Value(vaultGeneration),
       protocolVersion = Value(protocolVersion),
       schemaVersion = Value(schemaVersion),
       localDeviceId = Value(localDeviceId),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<VaultStateData> custom({
    Expression<int>? singletonId,
    Expression<String>? vaultId,
    Expression<int>? vaultGeneration,
    Expression<int>? protocolVersion,
    Expression<int>? schemaVersion,
    Expression<String>? localDeviceId,
    Expression<int>? nextEventSequence,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
  }) {
    return RawValuesInsertable({
      if (singletonId != null) 'singleton_id': singletonId,
      if (vaultId != null) 'vault_id': vaultId,
      if (vaultGeneration != null) 'vault_generation': vaultGeneration,
      if (protocolVersion != null) 'protocol_version': protocolVersion,
      if (schemaVersion != null) 'schema_version': schemaVersion,
      if (localDeviceId != null) 'local_device_id': localDeviceId,
      if (nextEventSequence != null) 'next_event_sequence': nextEventSequence,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
    });
  }

  VaultStateCompanion copyWith({
    Value<int>? singletonId,
    Value<String>? vaultId,
    Value<int>? vaultGeneration,
    Value<int>? protocolVersion,
    Value<int>? schemaVersion,
    Value<String>? localDeviceId,
    Value<int>? nextEventSequence,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
  }) {
    return VaultStateCompanion(
      singletonId: singletonId ?? this.singletonId,
      vaultId: vaultId ?? this.vaultId,
      vaultGeneration: vaultGeneration ?? this.vaultGeneration,
      protocolVersion: protocolVersion ?? this.protocolVersion,
      schemaVersion: schemaVersion ?? this.schemaVersion,
      localDeviceId: localDeviceId ?? this.localDeviceId,
      nextEventSequence: nextEventSequence ?? this.nextEventSequence,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (singletonId.present) {
      map['singleton_id'] = Variable<int>(singletonId.value);
    }
    if (vaultId.present) {
      map['vault_id'] = Variable<String>(vaultId.value);
    }
    if (vaultGeneration.present) {
      map['vault_generation'] = Variable<int>(vaultGeneration.value);
    }
    if (protocolVersion.present) {
      map['protocol_version'] = Variable<int>(protocolVersion.value);
    }
    if (schemaVersion.present) {
      map['schema_version'] = Variable<int>(schemaVersion.value);
    }
    if (localDeviceId.present) {
      map['local_device_id'] = Variable<String>(localDeviceId.value);
    }
    if (nextEventSequence.present) {
      map['next_event_sequence'] = Variable<int>(nextEventSequence.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('VaultStateCompanion(')
          ..write('singletonId: $singletonId, ')
          ..write('vaultId: $vaultId, ')
          ..write('vaultGeneration: $vaultGeneration, ')
          ..write('protocolVersion: $protocolVersion, ')
          ..write('schemaVersion: $schemaVersion, ')
          ..write('localDeviceId: $localDeviceId, ')
          ..write('nextEventSequence: $nextEventSequence, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }
}

class Devices extends Table with TableInfo<Devices, Device> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Devices(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _lastSeenAtMsMeta = const VerificationMeta(
    'lastSeenAtMs',
  );
  late final GeneratedColumn<int> lastSeenAtMs = GeneratedColumn<int>(
    'last_seen_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _retiredAtMsMeta = const VerificationMeta(
    'retiredAtMs',
  );
  late final GeneratedColumn<int> retiredAtMs = GeneratedColumn<int>(
    'retired_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    deviceId,
    displayName,
    createdAtMs,
    lastSeenAtMs,
    retiredAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'devices';
  @override
  VerificationContext validateIntegrity(
    Insertable<Device> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('last_seen_at_ms')) {
      context.handle(
        _lastSeenAtMsMeta,
        lastSeenAtMs.isAcceptableOrUnknown(
          data['last_seen_at_ms']!,
          _lastSeenAtMsMeta,
        ),
      );
    }
    if (data.containsKey('retired_at_ms')) {
      context.handle(
        _retiredAtMsMeta,
        retiredAtMs.isAcceptableOrUnknown(
          data['retired_at_ms']!,
          _retiredAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deviceId};
  @override
  Device map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Device(
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      lastSeenAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_seen_at_ms'],
      ),
      retiredAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retired_at_ms'],
      ),
    );
  }

  @override
  Devices createAlias(String alias) {
    return Devices(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class Device extends DataClass implements Insertable<Device> {
  final String deviceId;
  final String displayName;
  final int createdAtMs;
  final int? lastSeenAtMs;
  final int? retiredAtMs;
  const Device({
    required this.deviceId,
    required this.displayName,
    required this.createdAtMs,
    this.lastSeenAtMs,
    this.retiredAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['device_id'] = Variable<String>(deviceId);
    map['display_name'] = Variable<String>(displayName);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    if (!nullToAbsent || lastSeenAtMs != null) {
      map['last_seen_at_ms'] = Variable<int>(lastSeenAtMs);
    }
    if (!nullToAbsent || retiredAtMs != null) {
      map['retired_at_ms'] = Variable<int>(retiredAtMs);
    }
    return map;
  }

  DevicesCompanion toCompanion(bool nullToAbsent) {
    return DevicesCompanion(
      deviceId: Value(deviceId),
      displayName: Value(displayName),
      createdAtMs: Value(createdAtMs),
      lastSeenAtMs: lastSeenAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSeenAtMs),
      retiredAtMs: retiredAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(retiredAtMs),
    );
  }

  factory Device.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Device(
      deviceId: serializer.fromJson<String>(json['device_id']),
      displayName: serializer.fromJson<String>(json['display_name']),
      createdAtMs: serializer.fromJson<int>(json['created_at_ms']),
      lastSeenAtMs: serializer.fromJson<int?>(json['last_seen_at_ms']),
      retiredAtMs: serializer.fromJson<int?>(json['retired_at_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'device_id': serializer.toJson<String>(deviceId),
      'display_name': serializer.toJson<String>(displayName),
      'created_at_ms': serializer.toJson<int>(createdAtMs),
      'last_seen_at_ms': serializer.toJson<int?>(lastSeenAtMs),
      'retired_at_ms': serializer.toJson<int?>(retiredAtMs),
    };
  }

  Device copyWith({
    String? deviceId,
    String? displayName,
    int? createdAtMs,
    Value<int?> lastSeenAtMs = const Value.absent(),
    Value<int?> retiredAtMs = const Value.absent(),
  }) => Device(
    deviceId: deviceId ?? this.deviceId,
    displayName: displayName ?? this.displayName,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    lastSeenAtMs: lastSeenAtMs.present ? lastSeenAtMs.value : this.lastSeenAtMs,
    retiredAtMs: retiredAtMs.present ? retiredAtMs.value : this.retiredAtMs,
  );
  Device copyWithCompanion(DevicesCompanion data) {
    return Device(
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      lastSeenAtMs: data.lastSeenAtMs.present
          ? data.lastSeenAtMs.value
          : this.lastSeenAtMs,
      retiredAtMs: data.retiredAtMs.present
          ? data.retiredAtMs.value
          : this.retiredAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Device(')
          ..write('deviceId: $deviceId, ')
          ..write('displayName: $displayName, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('lastSeenAtMs: $lastSeenAtMs, ')
          ..write('retiredAtMs: $retiredAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    deviceId,
    displayName,
    createdAtMs,
    lastSeenAtMs,
    retiredAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Device &&
          other.deviceId == this.deviceId &&
          other.displayName == this.displayName &&
          other.createdAtMs == this.createdAtMs &&
          other.lastSeenAtMs == this.lastSeenAtMs &&
          other.retiredAtMs == this.retiredAtMs);
}

class DevicesCompanion extends UpdateCompanion<Device> {
  final Value<String> deviceId;
  final Value<String> displayName;
  final Value<int> createdAtMs;
  final Value<int?> lastSeenAtMs;
  final Value<int?> retiredAtMs;
  final Value<int> rowid;
  const DevicesCompanion({
    this.deviceId = const Value.absent(),
    this.displayName = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.lastSeenAtMs = const Value.absent(),
    this.retiredAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DevicesCompanion.insert({
    required String deviceId,
    required String displayName,
    required int createdAtMs,
    this.lastSeenAtMs = const Value.absent(),
    this.retiredAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : deviceId = Value(deviceId),
       displayName = Value(displayName),
       createdAtMs = Value(createdAtMs);
  static Insertable<Device> custom({
    Expression<String>? deviceId,
    Expression<String>? displayName,
    Expression<int>? createdAtMs,
    Expression<int>? lastSeenAtMs,
    Expression<int>? retiredAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deviceId != null) 'device_id': deviceId,
      if (displayName != null) 'display_name': displayName,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (lastSeenAtMs != null) 'last_seen_at_ms': lastSeenAtMs,
      if (retiredAtMs != null) 'retired_at_ms': retiredAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DevicesCompanion copyWith({
    Value<String>? deviceId,
    Value<String>? displayName,
    Value<int>? createdAtMs,
    Value<int?>? lastSeenAtMs,
    Value<int?>? retiredAtMs,
    Value<int>? rowid,
  }) {
    return DevicesCompanion(
      deviceId: deviceId ?? this.deviceId,
      displayName: displayName ?? this.displayName,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      lastSeenAtMs: lastSeenAtMs ?? this.lastSeenAtMs,
      retiredAtMs: retiredAtMs ?? this.retiredAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (lastSeenAtMs.present) {
      map['last_seen_at_ms'] = Variable<int>(lastSeenAtMs.value);
    }
    if (retiredAtMs.present) {
      map['retired_at_ms'] = Variable<int>(retiredAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DevicesCompanion(')
          ..write('deviceId: $deviceId, ')
          ..write('displayName: $displayName, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('lastSeenAtMs: $lastSeenAtMs, ')
          ..write('retiredAtMs: $retiredAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Notes extends Table with TableInfo<Notes, Note> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Notes(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (format IN (\'markdown\', \'miaodoc\'))',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _draftJsonMeta = const VerificationMeta(
    'draftJson',
  );
  late final GeneratedColumn<String> draftJson = GeneratedColumn<String>(
    'draft_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (json_valid(draft_json))',
  );
  static const VerificationMeta _bodyTextMeta = const VerificationMeta(
    'bodyText',
  );
  late final GeneratedColumn<String> bodyText = GeneratedColumn<String>(
    'body_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'[]\' CHECK (json_valid(tags_json))',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _tagsTextMeta = const VerificationMeta(
    'tagsText',
  );
  late final GeneratedColumn<String> tagsText = GeneratedColumn<String>(
    'tags_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT \'\'',
    defaultValue: const CustomExpression('\'\''),
  );
  static const VerificationMeta _baseRevisionIdsJsonMeta =
      const VerificationMeta('baseRevisionIdsJson');
  late final GeneratedColumn<String>
  baseRevisionIdsJson = GeneratedColumn<String>(
    'base_revision_ids_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints:
        'NOT NULL DEFAULT \'[]\' CHECK (json_valid(base_revision_ids_json))',
    defaultValue: const CustomExpression('\'[]\''),
  );
  static const VerificationMeta _dirtyMeta = const VerificationMeta('dirty');
  late final GeneratedColumn<int> dirty = GeneratedColumn<int>(
    'dirty',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (dirty IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  late final GeneratedColumn<int> isDeleted = GeneratedColumn<int>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (is_deleted IN (0, 1))',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _lastCommittedRevisionIdMeta =
      const VerificationMeta('lastCommittedRevisionId');
  late final GeneratedColumn<String> lastCommittedRevisionId =
      GeneratedColumn<String>(
        'last_committed_revision_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
        $customConstraints: '',
      );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    noteId,
    format,
    title,
    draftJson,
    bodyText,
    tagsJson,
    tagsText,
    baseRevisionIdsJson,
    dirty,
    isDeleted,
    lastCommittedRevisionId,
    createdAtMs,
    updatedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<Note> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('draft_json')) {
      context.handle(
        _draftJsonMeta,
        draftJson.isAcceptableOrUnknown(data['draft_json']!, _draftJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_draftJsonMeta);
    }
    if (data.containsKey('body_text')) {
      context.handle(
        _bodyTextMeta,
        bodyText.isAcceptableOrUnknown(data['body_text']!, _bodyTextMeta),
      );
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    }
    if (data.containsKey('tags_text')) {
      context.handle(
        _tagsTextMeta,
        tagsText.isAcceptableOrUnknown(data['tags_text']!, _tagsTextMeta),
      );
    }
    if (data.containsKey('base_revision_ids_json')) {
      context.handle(
        _baseRevisionIdsJsonMeta,
        baseRevisionIdsJson.isAcceptableOrUnknown(
          data['base_revision_ids_json']!,
          _baseRevisionIdsJsonMeta,
        ),
      );
    }
    if (data.containsKey('dirty')) {
      context.handle(
        _dirtyMeta,
        dirty.isAcceptableOrUnknown(data['dirty']!, _dirtyMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('last_committed_revision_id')) {
      context.handle(
        _lastCommittedRevisionIdMeta,
        lastCommittedRevisionId.isAcceptableOrUnknown(
          data['last_committed_revision_id']!,
          _lastCommittedRevisionIdMeta,
        ),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {noteId};
  @override
  Note map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Note(
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      draftJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}draft_json'],
      )!,
      bodyText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_text'],
      )!,
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      tagsText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_text'],
      )!,
      baseRevisionIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}base_revision_ids_json'],
      )!,
      dirty: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}dirty'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_deleted'],
      )!,
      lastCommittedRevisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_committed_revision_id'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
    );
  }

  @override
  Notes createAlias(String alias) {
    return Notes(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class Note extends DataClass implements Insertable<Note> {
  final String noteId;
  final String format;
  final String title;
  final String draftJson;
  final String bodyText;
  final String tagsJson;
  final String tagsText;
  final String baseRevisionIdsJson;
  final int dirty;
  final int isDeleted;
  final String? lastCommittedRevisionId;
  final int createdAtMs;
  final int updatedAtMs;
  const Note({
    required this.noteId,
    required this.format,
    required this.title,
    required this.draftJson,
    required this.bodyText,
    required this.tagsJson,
    required this.tagsText,
    required this.baseRevisionIdsJson,
    required this.dirty,
    required this.isDeleted,
    this.lastCommittedRevisionId,
    required this.createdAtMs,
    required this.updatedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<String>(noteId);
    map['format'] = Variable<String>(format);
    map['title'] = Variable<String>(title);
    map['draft_json'] = Variable<String>(draftJson);
    map['body_text'] = Variable<String>(bodyText);
    map['tags_json'] = Variable<String>(tagsJson);
    map['tags_text'] = Variable<String>(tagsText);
    map['base_revision_ids_json'] = Variable<String>(baseRevisionIdsJson);
    map['dirty'] = Variable<int>(dirty);
    map['is_deleted'] = Variable<int>(isDeleted);
    if (!nullToAbsent || lastCommittedRevisionId != null) {
      map['last_committed_revision_id'] = Variable<String>(
        lastCommittedRevisionId,
      );
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  NotesCompanion toCompanion(bool nullToAbsent) {
    return NotesCompanion(
      noteId: Value(noteId),
      format: Value(format),
      title: Value(title),
      draftJson: Value(draftJson),
      bodyText: Value(bodyText),
      tagsJson: Value(tagsJson),
      tagsText: Value(tagsText),
      baseRevisionIdsJson: Value(baseRevisionIdsJson),
      dirty: Value(dirty),
      isDeleted: Value(isDeleted),
      lastCommittedRevisionId: lastCommittedRevisionId == null && nullToAbsent
          ? const Value.absent()
          : Value(lastCommittedRevisionId),
      createdAtMs: Value(createdAtMs),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory Note.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Note(
      noteId: serializer.fromJson<String>(json['note_id']),
      format: serializer.fromJson<String>(json['format']),
      title: serializer.fromJson<String>(json['title']),
      draftJson: serializer.fromJson<String>(json['draft_json']),
      bodyText: serializer.fromJson<String>(json['body_text']),
      tagsJson: serializer.fromJson<String>(json['tags_json']),
      tagsText: serializer.fromJson<String>(json['tags_text']),
      baseRevisionIdsJson: serializer.fromJson<String>(
        json['base_revision_ids_json'],
      ),
      dirty: serializer.fromJson<int>(json['dirty']),
      isDeleted: serializer.fromJson<int>(json['is_deleted']),
      lastCommittedRevisionId: serializer.fromJson<String?>(
        json['last_committed_revision_id'],
      ),
      createdAtMs: serializer.fromJson<int>(json['created_at_ms']),
      updatedAtMs: serializer.fromJson<int>(json['updated_at_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'note_id': serializer.toJson<String>(noteId),
      'format': serializer.toJson<String>(format),
      'title': serializer.toJson<String>(title),
      'draft_json': serializer.toJson<String>(draftJson),
      'body_text': serializer.toJson<String>(bodyText),
      'tags_json': serializer.toJson<String>(tagsJson),
      'tags_text': serializer.toJson<String>(tagsText),
      'base_revision_ids_json': serializer.toJson<String>(baseRevisionIdsJson),
      'dirty': serializer.toJson<int>(dirty),
      'is_deleted': serializer.toJson<int>(isDeleted),
      'last_committed_revision_id': serializer.toJson<String?>(
        lastCommittedRevisionId,
      ),
      'created_at_ms': serializer.toJson<int>(createdAtMs),
      'updated_at_ms': serializer.toJson<int>(updatedAtMs),
    };
  }

  Note copyWith({
    String? noteId,
    String? format,
    String? title,
    String? draftJson,
    String? bodyText,
    String? tagsJson,
    String? tagsText,
    String? baseRevisionIdsJson,
    int? dirty,
    int? isDeleted,
    Value<String?> lastCommittedRevisionId = const Value.absent(),
    int? createdAtMs,
    int? updatedAtMs,
  }) => Note(
    noteId: noteId ?? this.noteId,
    format: format ?? this.format,
    title: title ?? this.title,
    draftJson: draftJson ?? this.draftJson,
    bodyText: bodyText ?? this.bodyText,
    tagsJson: tagsJson ?? this.tagsJson,
    tagsText: tagsText ?? this.tagsText,
    baseRevisionIdsJson: baseRevisionIdsJson ?? this.baseRevisionIdsJson,
    dirty: dirty ?? this.dirty,
    isDeleted: isDeleted ?? this.isDeleted,
    lastCommittedRevisionId: lastCommittedRevisionId.present
        ? lastCommittedRevisionId.value
        : this.lastCommittedRevisionId,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
  );
  Note copyWithCompanion(NotesCompanion data) {
    return Note(
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      format: data.format.present ? data.format.value : this.format,
      title: data.title.present ? data.title.value : this.title,
      draftJson: data.draftJson.present ? data.draftJson.value : this.draftJson,
      bodyText: data.bodyText.present ? data.bodyText.value : this.bodyText,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      tagsText: data.tagsText.present ? data.tagsText.value : this.tagsText,
      baseRevisionIdsJson: data.baseRevisionIdsJson.present
          ? data.baseRevisionIdsJson.value
          : this.baseRevisionIdsJson,
      dirty: data.dirty.present ? data.dirty.value : this.dirty,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      lastCommittedRevisionId: data.lastCommittedRevisionId.present
          ? data.lastCommittedRevisionId.value
          : this.lastCommittedRevisionId,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Note(')
          ..write('noteId: $noteId, ')
          ..write('format: $format, ')
          ..write('title: $title, ')
          ..write('draftJson: $draftJson, ')
          ..write('bodyText: $bodyText, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('tagsText: $tagsText, ')
          ..write('baseRevisionIdsJson: $baseRevisionIdsJson, ')
          ..write('dirty: $dirty, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastCommittedRevisionId: $lastCommittedRevisionId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    noteId,
    format,
    title,
    draftJson,
    bodyText,
    tagsJson,
    tagsText,
    baseRevisionIdsJson,
    dirty,
    isDeleted,
    lastCommittedRevisionId,
    createdAtMs,
    updatedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Note &&
          other.noteId == this.noteId &&
          other.format == this.format &&
          other.title == this.title &&
          other.draftJson == this.draftJson &&
          other.bodyText == this.bodyText &&
          other.tagsJson == this.tagsJson &&
          other.tagsText == this.tagsText &&
          other.baseRevisionIdsJson == this.baseRevisionIdsJson &&
          other.dirty == this.dirty &&
          other.isDeleted == this.isDeleted &&
          other.lastCommittedRevisionId == this.lastCommittedRevisionId &&
          other.createdAtMs == this.createdAtMs &&
          other.updatedAtMs == this.updatedAtMs);
}

class NotesCompanion extends UpdateCompanion<Note> {
  final Value<String> noteId;
  final Value<String> format;
  final Value<String> title;
  final Value<String> draftJson;
  final Value<String> bodyText;
  final Value<String> tagsJson;
  final Value<String> tagsText;
  final Value<String> baseRevisionIdsJson;
  final Value<int> dirty;
  final Value<int> isDeleted;
  final Value<String?> lastCommittedRevisionId;
  final Value<int> createdAtMs;
  final Value<int> updatedAtMs;
  final Value<int> rowid;
  const NotesCompanion({
    this.noteId = const Value.absent(),
    this.format = const Value.absent(),
    this.title = const Value.absent(),
    this.draftJson = const Value.absent(),
    this.bodyText = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.tagsText = const Value.absent(),
    this.baseRevisionIdsJson = const Value.absent(),
    this.dirty = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastCommittedRevisionId = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesCompanion.insert({
    required String noteId,
    required String format,
    this.title = const Value.absent(),
    required String draftJson,
    this.bodyText = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.tagsText = const Value.absent(),
    this.baseRevisionIdsJson = const Value.absent(),
    this.dirty = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.lastCommittedRevisionId = const Value.absent(),
    required int createdAtMs,
    required int updatedAtMs,
    this.rowid = const Value.absent(),
  }) : noteId = Value(noteId),
       format = Value(format),
       draftJson = Value(draftJson),
       createdAtMs = Value(createdAtMs),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<Note> custom({
    Expression<String>? noteId,
    Expression<String>? format,
    Expression<String>? title,
    Expression<String>? draftJson,
    Expression<String>? bodyText,
    Expression<String>? tagsJson,
    Expression<String>? tagsText,
    Expression<String>? baseRevisionIdsJson,
    Expression<int>? dirty,
    Expression<int>? isDeleted,
    Expression<String>? lastCommittedRevisionId,
    Expression<int>? createdAtMs,
    Expression<int>? updatedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (noteId != null) 'note_id': noteId,
      if (format != null) 'format': format,
      if (title != null) 'title': title,
      if (draftJson != null) 'draft_json': draftJson,
      if (bodyText != null) 'body_text': bodyText,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (tagsText != null) 'tags_text': tagsText,
      if (baseRevisionIdsJson != null)
        'base_revision_ids_json': baseRevisionIdsJson,
      if (dirty != null) 'dirty': dirty,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (lastCommittedRevisionId != null)
        'last_committed_revision_id': lastCommittedRevisionId,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesCompanion copyWith({
    Value<String>? noteId,
    Value<String>? format,
    Value<String>? title,
    Value<String>? draftJson,
    Value<String>? bodyText,
    Value<String>? tagsJson,
    Value<String>? tagsText,
    Value<String>? baseRevisionIdsJson,
    Value<int>? dirty,
    Value<int>? isDeleted,
    Value<String?>? lastCommittedRevisionId,
    Value<int>? createdAtMs,
    Value<int>? updatedAtMs,
    Value<int>? rowid,
  }) {
    return NotesCompanion(
      noteId: noteId ?? this.noteId,
      format: format ?? this.format,
      title: title ?? this.title,
      draftJson: draftJson ?? this.draftJson,
      bodyText: bodyText ?? this.bodyText,
      tagsJson: tagsJson ?? this.tagsJson,
      tagsText: tagsText ?? this.tagsText,
      baseRevisionIdsJson: baseRevisionIdsJson ?? this.baseRevisionIdsJson,
      dirty: dirty ?? this.dirty,
      isDeleted: isDeleted ?? this.isDeleted,
      lastCommittedRevisionId:
          lastCommittedRevisionId ?? this.lastCommittedRevisionId,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (draftJson.present) {
      map['draft_json'] = Variable<String>(draftJson.value);
    }
    if (bodyText.present) {
      map['body_text'] = Variable<String>(bodyText.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (tagsText.present) {
      map['tags_text'] = Variable<String>(tagsText.value);
    }
    if (baseRevisionIdsJson.present) {
      map['base_revision_ids_json'] = Variable<String>(
        baseRevisionIdsJson.value,
      );
    }
    if (dirty.present) {
      map['dirty'] = Variable<int>(dirty.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<int>(isDeleted.value);
    }
    if (lastCommittedRevisionId.present) {
      map['last_committed_revision_id'] = Variable<String>(
        lastCommittedRevisionId.value,
      );
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesCompanion(')
          ..write('noteId: $noteId, ')
          ..write('format: $format, ')
          ..write('title: $title, ')
          ..write('draftJson: $draftJson, ')
          ..write('bodyText: $bodyText, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('tagsText: $tagsText, ')
          ..write('baseRevisionIdsJson: $baseRevisionIdsJson, ')
          ..write('dirty: $dirty, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('lastCommittedRevisionId: $lastCommittedRevisionId, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('updatedAtMs: $updatedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class NotesFts extends Table
    with TableInfo<NotesFts, NotesFt>, VirtualTableInfo<NotesFts, NotesFt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  NotesFts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _bodyTextMeta = const VerificationMeta(
    'bodyText',
  );
  late final GeneratedColumn<String> bodyText = GeneratedColumn<String>(
    'body_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  static const VerificationMeta _tagsTextMeta = const VerificationMeta(
    'tagsText',
  );
  late final GeneratedColumn<String> tagsText = GeneratedColumn<String>(
    'tags_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [noteId, title, bodyText, tagsText];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'notes_fts';
  @override
  VerificationContext validateIntegrity(
    Insertable<NotesFt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body_text')) {
      context.handle(
        _bodyTextMeta,
        bodyText.isAcceptableOrUnknown(data['body_text']!, _bodyTextMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyTextMeta);
    }
    if (data.containsKey('tags_text')) {
      context.handle(
        _tagsTextMeta,
        tagsText.isAcceptableOrUnknown(data['tags_text']!, _tagsTextMeta),
      );
    } else if (isInserting) {
      context.missing(_tagsTextMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => const {};
  @override
  NotesFt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NotesFt(
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      bodyText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_text'],
      )!,
      tagsText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_text'],
      )!,
    );
  }

  @override
  NotesFts createAlias(String alias) {
    return NotesFts(attachedDatabase, alias);
  }

  @override
  bool get dontWriteConstraints => true;
  @override
  String get moduleAndArgs =>
      'fts5(note_id UNINDEXED, title, body_text, tags_text, tokenize = \'unicode61 remove_diacritics 2\')';
}

class NotesFt extends DataClass implements Insertable<NotesFt> {
  final String noteId;
  final String title;
  final String bodyText;
  final String tagsText;
  const NotesFt({
    required this.noteId,
    required this.title,
    required this.bodyText,
    required this.tagsText,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<String>(noteId);
    map['title'] = Variable<String>(title);
    map['body_text'] = Variable<String>(bodyText);
    map['tags_text'] = Variable<String>(tagsText);
    return map;
  }

  NotesFtsCompanion toCompanion(bool nullToAbsent) {
    return NotesFtsCompanion(
      noteId: Value(noteId),
      title: Value(title),
      bodyText: Value(bodyText),
      tagsText: Value(tagsText),
    );
  }

  factory NotesFt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NotesFt(
      noteId: serializer.fromJson<String>(json['note_id']),
      title: serializer.fromJson<String>(json['title']),
      bodyText: serializer.fromJson<String>(json['body_text']),
      tagsText: serializer.fromJson<String>(json['tags_text']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'note_id': serializer.toJson<String>(noteId),
      'title': serializer.toJson<String>(title),
      'body_text': serializer.toJson<String>(bodyText),
      'tags_text': serializer.toJson<String>(tagsText),
    };
  }

  NotesFt copyWith({
    String? noteId,
    String? title,
    String? bodyText,
    String? tagsText,
  }) => NotesFt(
    noteId: noteId ?? this.noteId,
    title: title ?? this.title,
    bodyText: bodyText ?? this.bodyText,
    tagsText: tagsText ?? this.tagsText,
  );
  NotesFt copyWithCompanion(NotesFtsCompanion data) {
    return NotesFt(
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      title: data.title.present ? data.title.value : this.title,
      bodyText: data.bodyText.present ? data.bodyText.value : this.bodyText,
      tagsText: data.tagsText.present ? data.tagsText.value : this.tagsText,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NotesFt(')
          ..write('noteId: $noteId, ')
          ..write('title: $title, ')
          ..write('bodyText: $bodyText, ')
          ..write('tagsText: $tagsText')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(noteId, title, bodyText, tagsText);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NotesFt &&
          other.noteId == this.noteId &&
          other.title == this.title &&
          other.bodyText == this.bodyText &&
          other.tagsText == this.tagsText);
}

class NotesFtsCompanion extends UpdateCompanion<NotesFt> {
  final Value<String> noteId;
  final Value<String> title;
  final Value<String> bodyText;
  final Value<String> tagsText;
  final Value<int> rowid;
  const NotesFtsCompanion({
    this.noteId = const Value.absent(),
    this.title = const Value.absent(),
    this.bodyText = const Value.absent(),
    this.tagsText = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NotesFtsCompanion.insert({
    required String noteId,
    required String title,
    required String bodyText,
    required String tagsText,
    this.rowid = const Value.absent(),
  }) : noteId = Value(noteId),
       title = Value(title),
       bodyText = Value(bodyText),
       tagsText = Value(tagsText);
  static Insertable<NotesFt> custom({
    Expression<String>? noteId,
    Expression<String>? title,
    Expression<String>? bodyText,
    Expression<String>? tagsText,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (noteId != null) 'note_id': noteId,
      if (title != null) 'title': title,
      if (bodyText != null) 'body_text': bodyText,
      if (tagsText != null) 'tags_text': tagsText,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NotesFtsCompanion copyWith({
    Value<String>? noteId,
    Value<String>? title,
    Value<String>? bodyText,
    Value<String>? tagsText,
    Value<int>? rowid,
  }) {
    return NotesFtsCompanion(
      noteId: noteId ?? this.noteId,
      title: title ?? this.title,
      bodyText: bodyText ?? this.bodyText,
      tagsText: tagsText ?? this.tagsText,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (bodyText.present) {
      map['body_text'] = Variable<String>(bodyText.value);
    }
    if (tagsText.present) {
      map['tags_text'] = Variable<String>(tagsText.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NotesFtsCompanion(')
          ..write('noteId: $noteId, ')
          ..write('title: $title, ')
          ..write('bodyText: $bodyText, ')
          ..write('tagsText: $tagsText, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Revisions extends Table with TableInfo<Revisions, Revision> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Revisions(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _revisionIdMeta = const VerificationMeta(
    'revisionId',
  );
  late final GeneratedColumn<String> revisionId = GeneratedColumn<String>(
    'revision_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _vaultIdMeta = const VerificationMeta(
    'vaultId',
  );
  late final GeneratedColumn<String> vaultId = GeneratedColumn<String>(
    'vault_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _vaultGenerationMeta = const VerificationMeta(
    'vaultGeneration',
  );
  late final GeneratedColumn<int> vaultGeneration = GeneratedColumn<int>(
    'vault_generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (vault_generation > 0)',
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _operationMeta = const VerificationMeta(
    'operation',
  );
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
    'operation',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (operation IN (\'upsert\', \'tombstone\'))',
  );
  static const VerificationMeta _formatMeta = const VerificationMeta('format');
  late final GeneratedColumn<String> format = GeneratedColumn<String>(
    'format',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (format IN (\'markdown\', \'miaodoc\'))',
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _bodyJsonMeta = const VerificationMeta(
    'bodyJson',
  );
  late final GeneratedColumn<String> bodyJson = GeneratedColumn<String>(
    'body_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (json_valid(body_json))',
  );
  static const VerificationMeta _bodyTextMeta = const VerificationMeta(
    'bodyText',
  );
  late final GeneratedColumn<String> bodyText = GeneratedColumn<String>(
    'body_text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _tagsJsonMeta = const VerificationMeta(
    'tagsJson',
  );
  late final GeneratedColumn<String> tagsJson = GeneratedColumn<String>(
    'tags_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (json_valid(tags_json))',
  );
  static const VerificationMeta _canonicalPayloadJsonMeta =
      const VerificationMeta('canonicalPayloadJson');
  late final GeneratedColumn<String> canonicalPayloadJson =
      GeneratedColumn<String>(
        'canonical_payload_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL CHECK (json_valid(canonical_payload_json))',
      );
  static const VerificationMeta _payloadHashMeta = const VerificationMeta(
    'payloadHash',
  );
  late final GeneratedColumn<String> payloadHash = GeneratedColumn<String>(
    'payload_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(payload_hash) = 64)',
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    revisionId,
    vaultId,
    vaultGeneration,
    noteId,
    deviceId,
    operation,
    format,
    title,
    bodyJson,
    bodyText,
    tagsJson,
    canonicalPayloadJson,
    payloadHash,
    createdAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'revisions';
  @override
  VerificationContext validateIntegrity(
    Insertable<Revision> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('revision_id')) {
      context.handle(
        _revisionIdMeta,
        revisionId.isAcceptableOrUnknown(data['revision_id']!, _revisionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionIdMeta);
    }
    if (data.containsKey('vault_id')) {
      context.handle(
        _vaultIdMeta,
        vaultId.isAcceptableOrUnknown(data['vault_id']!, _vaultIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vaultIdMeta);
    }
    if (data.containsKey('vault_generation')) {
      context.handle(
        _vaultGenerationMeta,
        vaultGeneration.isAcceptableOrUnknown(
          data['vault_generation']!,
          _vaultGenerationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vaultGenerationMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(
        _operationMeta,
        operation.isAcceptableOrUnknown(data['operation']!, _operationMeta),
      );
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('format')) {
      context.handle(
        _formatMeta,
        format.isAcceptableOrUnknown(data['format']!, _formatMeta),
      );
    } else if (isInserting) {
      context.missing(_formatMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('body_json')) {
      context.handle(
        _bodyJsonMeta,
        bodyJson.isAcceptableOrUnknown(data['body_json']!, _bodyJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyJsonMeta);
    }
    if (data.containsKey('body_text')) {
      context.handle(
        _bodyTextMeta,
        bodyText.isAcceptableOrUnknown(data['body_text']!, _bodyTextMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyTextMeta);
    }
    if (data.containsKey('tags_json')) {
      context.handle(
        _tagsJsonMeta,
        tagsJson.isAcceptableOrUnknown(data['tags_json']!, _tagsJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_tagsJsonMeta);
    }
    if (data.containsKey('canonical_payload_json')) {
      context.handle(
        _canonicalPayloadJsonMeta,
        canonicalPayloadJson.isAcceptableOrUnknown(
          data['canonical_payload_json']!,
          _canonicalPayloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_canonicalPayloadJsonMeta);
    }
    if (data.containsKey('payload_hash')) {
      context.handle(
        _payloadHashMeta,
        payloadHash.isAcceptableOrUnknown(
          data['payload_hash']!,
          _payloadHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadHashMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {revisionId};
  @override
  Revision map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Revision(
      revisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision_id'],
      )!,
      vaultId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vault_id'],
      )!,
      vaultGeneration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vault_generation'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      operation: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation'],
      )!,
      format: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}format'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      bodyJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_json'],
      )!,
      bodyText: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body_text'],
      )!,
      tagsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tags_json'],
      )!,
      canonicalPayloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}canonical_payload_json'],
      )!,
      payloadHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_hash'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  Revisions createAlias(String alias) {
    return Revisions(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class Revision extends DataClass implements Insertable<Revision> {
  final String revisionId;
  final String vaultId;
  final int vaultGeneration;
  final String noteId;
  final String deviceId;
  final String operation;
  final String format;
  final String title;
  final String bodyJson;
  final String bodyText;
  final String tagsJson;
  final String canonicalPayloadJson;
  final String payloadHash;
  final int createdAtMs;
  const Revision({
    required this.revisionId,
    required this.vaultId,
    required this.vaultGeneration,
    required this.noteId,
    required this.deviceId,
    required this.operation,
    required this.format,
    required this.title,
    required this.bodyJson,
    required this.bodyText,
    required this.tagsJson,
    required this.canonicalPayloadJson,
    required this.payloadHash,
    required this.createdAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['revision_id'] = Variable<String>(revisionId);
    map['vault_id'] = Variable<String>(vaultId);
    map['vault_generation'] = Variable<int>(vaultGeneration);
    map['note_id'] = Variable<String>(noteId);
    map['device_id'] = Variable<String>(deviceId);
    map['operation'] = Variable<String>(operation);
    map['format'] = Variable<String>(format);
    map['title'] = Variable<String>(title);
    map['body_json'] = Variable<String>(bodyJson);
    map['body_text'] = Variable<String>(bodyText);
    map['tags_json'] = Variable<String>(tagsJson);
    map['canonical_payload_json'] = Variable<String>(canonicalPayloadJson);
    map['payload_hash'] = Variable<String>(payloadHash);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  RevisionsCompanion toCompanion(bool nullToAbsent) {
    return RevisionsCompanion(
      revisionId: Value(revisionId),
      vaultId: Value(vaultId),
      vaultGeneration: Value(vaultGeneration),
      noteId: Value(noteId),
      deviceId: Value(deviceId),
      operation: Value(operation),
      format: Value(format),
      title: Value(title),
      bodyJson: Value(bodyJson),
      bodyText: Value(bodyText),
      tagsJson: Value(tagsJson),
      canonicalPayloadJson: Value(canonicalPayloadJson),
      payloadHash: Value(payloadHash),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory Revision.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Revision(
      revisionId: serializer.fromJson<String>(json['revision_id']),
      vaultId: serializer.fromJson<String>(json['vault_id']),
      vaultGeneration: serializer.fromJson<int>(json['vault_generation']),
      noteId: serializer.fromJson<String>(json['note_id']),
      deviceId: serializer.fromJson<String>(json['device_id']),
      operation: serializer.fromJson<String>(json['operation']),
      format: serializer.fromJson<String>(json['format']),
      title: serializer.fromJson<String>(json['title']),
      bodyJson: serializer.fromJson<String>(json['body_json']),
      bodyText: serializer.fromJson<String>(json['body_text']),
      tagsJson: serializer.fromJson<String>(json['tags_json']),
      canonicalPayloadJson: serializer.fromJson<String>(
        json['canonical_payload_json'],
      ),
      payloadHash: serializer.fromJson<String>(json['payload_hash']),
      createdAtMs: serializer.fromJson<int>(json['created_at_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'revision_id': serializer.toJson<String>(revisionId),
      'vault_id': serializer.toJson<String>(vaultId),
      'vault_generation': serializer.toJson<int>(vaultGeneration),
      'note_id': serializer.toJson<String>(noteId),
      'device_id': serializer.toJson<String>(deviceId),
      'operation': serializer.toJson<String>(operation),
      'format': serializer.toJson<String>(format),
      'title': serializer.toJson<String>(title),
      'body_json': serializer.toJson<String>(bodyJson),
      'body_text': serializer.toJson<String>(bodyText),
      'tags_json': serializer.toJson<String>(tagsJson),
      'canonical_payload_json': serializer.toJson<String>(canonicalPayloadJson),
      'payload_hash': serializer.toJson<String>(payloadHash),
      'created_at_ms': serializer.toJson<int>(createdAtMs),
    };
  }

  Revision copyWith({
    String? revisionId,
    String? vaultId,
    int? vaultGeneration,
    String? noteId,
    String? deviceId,
    String? operation,
    String? format,
    String? title,
    String? bodyJson,
    String? bodyText,
    String? tagsJson,
    String? canonicalPayloadJson,
    String? payloadHash,
    int? createdAtMs,
  }) => Revision(
    revisionId: revisionId ?? this.revisionId,
    vaultId: vaultId ?? this.vaultId,
    vaultGeneration: vaultGeneration ?? this.vaultGeneration,
    noteId: noteId ?? this.noteId,
    deviceId: deviceId ?? this.deviceId,
    operation: operation ?? this.operation,
    format: format ?? this.format,
    title: title ?? this.title,
    bodyJson: bodyJson ?? this.bodyJson,
    bodyText: bodyText ?? this.bodyText,
    tagsJson: tagsJson ?? this.tagsJson,
    canonicalPayloadJson: canonicalPayloadJson ?? this.canonicalPayloadJson,
    payloadHash: payloadHash ?? this.payloadHash,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
  Revision copyWithCompanion(RevisionsCompanion data) {
    return Revision(
      revisionId: data.revisionId.present
          ? data.revisionId.value
          : this.revisionId,
      vaultId: data.vaultId.present ? data.vaultId.value : this.vaultId,
      vaultGeneration: data.vaultGeneration.present
          ? data.vaultGeneration.value
          : this.vaultGeneration,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      operation: data.operation.present ? data.operation.value : this.operation,
      format: data.format.present ? data.format.value : this.format,
      title: data.title.present ? data.title.value : this.title,
      bodyJson: data.bodyJson.present ? data.bodyJson.value : this.bodyJson,
      bodyText: data.bodyText.present ? data.bodyText.value : this.bodyText,
      tagsJson: data.tagsJson.present ? data.tagsJson.value : this.tagsJson,
      canonicalPayloadJson: data.canonicalPayloadJson.present
          ? data.canonicalPayloadJson.value
          : this.canonicalPayloadJson,
      payloadHash: data.payloadHash.present
          ? data.payloadHash.value
          : this.payloadHash,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Revision(')
          ..write('revisionId: $revisionId, ')
          ..write('vaultId: $vaultId, ')
          ..write('vaultGeneration: $vaultGeneration, ')
          ..write('noteId: $noteId, ')
          ..write('deviceId: $deviceId, ')
          ..write('operation: $operation, ')
          ..write('format: $format, ')
          ..write('title: $title, ')
          ..write('bodyJson: $bodyJson, ')
          ..write('bodyText: $bodyText, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('canonicalPayloadJson: $canonicalPayloadJson, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    revisionId,
    vaultId,
    vaultGeneration,
    noteId,
    deviceId,
    operation,
    format,
    title,
    bodyJson,
    bodyText,
    tagsJson,
    canonicalPayloadJson,
    payloadHash,
    createdAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Revision &&
          other.revisionId == this.revisionId &&
          other.vaultId == this.vaultId &&
          other.vaultGeneration == this.vaultGeneration &&
          other.noteId == this.noteId &&
          other.deviceId == this.deviceId &&
          other.operation == this.operation &&
          other.format == this.format &&
          other.title == this.title &&
          other.bodyJson == this.bodyJson &&
          other.bodyText == this.bodyText &&
          other.tagsJson == this.tagsJson &&
          other.canonicalPayloadJson == this.canonicalPayloadJson &&
          other.payloadHash == this.payloadHash &&
          other.createdAtMs == this.createdAtMs);
}

class RevisionsCompanion extends UpdateCompanion<Revision> {
  final Value<String> revisionId;
  final Value<String> vaultId;
  final Value<int> vaultGeneration;
  final Value<String> noteId;
  final Value<String> deviceId;
  final Value<String> operation;
  final Value<String> format;
  final Value<String> title;
  final Value<String> bodyJson;
  final Value<String> bodyText;
  final Value<String> tagsJson;
  final Value<String> canonicalPayloadJson;
  final Value<String> payloadHash;
  final Value<int> createdAtMs;
  final Value<int> rowid;
  const RevisionsCompanion({
    this.revisionId = const Value.absent(),
    this.vaultId = const Value.absent(),
    this.vaultGeneration = const Value.absent(),
    this.noteId = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.operation = const Value.absent(),
    this.format = const Value.absent(),
    this.title = const Value.absent(),
    this.bodyJson = const Value.absent(),
    this.bodyText = const Value.absent(),
    this.tagsJson = const Value.absent(),
    this.canonicalPayloadJson = const Value.absent(),
    this.payloadHash = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  RevisionsCompanion.insert({
    required String revisionId,
    required String vaultId,
    required int vaultGeneration,
    required String noteId,
    required String deviceId,
    required String operation,
    required String format,
    required String title,
    required String bodyJson,
    required String bodyText,
    required String tagsJson,
    required String canonicalPayloadJson,
    required String payloadHash,
    required int createdAtMs,
    this.rowid = const Value.absent(),
  }) : revisionId = Value(revisionId),
       vaultId = Value(vaultId),
       vaultGeneration = Value(vaultGeneration),
       noteId = Value(noteId),
       deviceId = Value(deviceId),
       operation = Value(operation),
       format = Value(format),
       title = Value(title),
       bodyJson = Value(bodyJson),
       bodyText = Value(bodyText),
       tagsJson = Value(tagsJson),
       canonicalPayloadJson = Value(canonicalPayloadJson),
       payloadHash = Value(payloadHash),
       createdAtMs = Value(createdAtMs);
  static Insertable<Revision> custom({
    Expression<String>? revisionId,
    Expression<String>? vaultId,
    Expression<int>? vaultGeneration,
    Expression<String>? noteId,
    Expression<String>? deviceId,
    Expression<String>? operation,
    Expression<String>? format,
    Expression<String>? title,
    Expression<String>? bodyJson,
    Expression<String>? bodyText,
    Expression<String>? tagsJson,
    Expression<String>? canonicalPayloadJson,
    Expression<String>? payloadHash,
    Expression<int>? createdAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (revisionId != null) 'revision_id': revisionId,
      if (vaultId != null) 'vault_id': vaultId,
      if (vaultGeneration != null) 'vault_generation': vaultGeneration,
      if (noteId != null) 'note_id': noteId,
      if (deviceId != null) 'device_id': deviceId,
      if (operation != null) 'operation': operation,
      if (format != null) 'format': format,
      if (title != null) 'title': title,
      if (bodyJson != null) 'body_json': bodyJson,
      if (bodyText != null) 'body_text': bodyText,
      if (tagsJson != null) 'tags_json': tagsJson,
      if (canonicalPayloadJson != null)
        'canonical_payload_json': canonicalPayloadJson,
      if (payloadHash != null) 'payload_hash': payloadHash,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  RevisionsCompanion copyWith({
    Value<String>? revisionId,
    Value<String>? vaultId,
    Value<int>? vaultGeneration,
    Value<String>? noteId,
    Value<String>? deviceId,
    Value<String>? operation,
    Value<String>? format,
    Value<String>? title,
    Value<String>? bodyJson,
    Value<String>? bodyText,
    Value<String>? tagsJson,
    Value<String>? canonicalPayloadJson,
    Value<String>? payloadHash,
    Value<int>? createdAtMs,
    Value<int>? rowid,
  }) {
    return RevisionsCompanion(
      revisionId: revisionId ?? this.revisionId,
      vaultId: vaultId ?? this.vaultId,
      vaultGeneration: vaultGeneration ?? this.vaultGeneration,
      noteId: noteId ?? this.noteId,
      deviceId: deviceId ?? this.deviceId,
      operation: operation ?? this.operation,
      format: format ?? this.format,
      title: title ?? this.title,
      bodyJson: bodyJson ?? this.bodyJson,
      bodyText: bodyText ?? this.bodyText,
      tagsJson: tagsJson ?? this.tagsJson,
      canonicalPayloadJson: canonicalPayloadJson ?? this.canonicalPayloadJson,
      payloadHash: payloadHash ?? this.payloadHash,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (revisionId.present) {
      map['revision_id'] = Variable<String>(revisionId.value);
    }
    if (vaultId.present) {
      map['vault_id'] = Variable<String>(vaultId.value);
    }
    if (vaultGeneration.present) {
      map['vault_generation'] = Variable<int>(vaultGeneration.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (format.present) {
      map['format'] = Variable<String>(format.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (bodyJson.present) {
      map['body_json'] = Variable<String>(bodyJson.value);
    }
    if (bodyText.present) {
      map['body_text'] = Variable<String>(bodyText.value);
    }
    if (tagsJson.present) {
      map['tags_json'] = Variable<String>(tagsJson.value);
    }
    if (canonicalPayloadJson.present) {
      map['canonical_payload_json'] = Variable<String>(
        canonicalPayloadJson.value,
      );
    }
    if (payloadHash.present) {
      map['payload_hash'] = Variable<String>(payloadHash.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RevisionsCompanion(')
          ..write('revisionId: $revisionId, ')
          ..write('vaultId: $vaultId, ')
          ..write('vaultGeneration: $vaultGeneration, ')
          ..write('noteId: $noteId, ')
          ..write('deviceId: $deviceId, ')
          ..write('operation: $operation, ')
          ..write('format: $format, ')
          ..write('title: $title, ')
          ..write('bodyJson: $bodyJson, ')
          ..write('bodyText: $bodyText, ')
          ..write('tagsJson: $tagsJson, ')
          ..write('canonicalPayloadJson: $canonicalPayloadJson, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class RevisionParents extends Table
    with TableInfo<RevisionParents, RevisionParent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  RevisionParents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _revisionIdMeta = const VerificationMeta(
    'revisionId',
  );
  late final GeneratedColumn<String> revisionId = GeneratedColumn<String>(
    'revision_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES revisions(revision_id)ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED',
  );
  static const VerificationMeta _parentRevisionIdMeta = const VerificationMeta(
    'parentRevisionId',
  );
  late final GeneratedColumn<String> parentRevisionId = GeneratedColumn<String>(
    'parent_revision_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES revisions(revision_id)ON DELETE RESTRICT DEFERRABLE INITIALLY DEFERRED',
  );
  static const VerificationMeta _parentOrderMeta = const VerificationMeta(
    'parentOrder',
  );
  late final GeneratedColumn<int> parentOrder = GeneratedColumn<int>(
    'parent_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (parent_order >= 0)',
  );
  @override
  List<GeneratedColumn> get $columns => [
    revisionId,
    parentRevisionId,
    parentOrder,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'revision_parents';
  @override
  VerificationContext validateIntegrity(
    Insertable<RevisionParent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('revision_id')) {
      context.handle(
        _revisionIdMeta,
        revisionId.isAcceptableOrUnknown(data['revision_id']!, _revisionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionIdMeta);
    }
    if (data.containsKey('parent_revision_id')) {
      context.handle(
        _parentRevisionIdMeta,
        parentRevisionId.isAcceptableOrUnknown(
          data['parent_revision_id']!,
          _parentRevisionIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_parentRevisionIdMeta);
    }
    if (data.containsKey('parent_order')) {
      context.handle(
        _parentOrderMeta,
        parentOrder.isAcceptableOrUnknown(
          data['parent_order']!,
          _parentOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_parentOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {revisionId, parentRevisionId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {revisionId, parentOrder},
  ];
  @override
  RevisionParent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return RevisionParent(
      revisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision_id'],
      )!,
      parentRevisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_revision_id'],
      )!,
      parentOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}parent_order'],
      )!,
    );
  }

  @override
  RevisionParents createAlias(String alias) {
    return RevisionParents(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(revision_id, parent_revision_id)',
    'UNIQUE(revision_id, parent_order)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class RevisionParent extends DataClass implements Insertable<RevisionParent> {
  final String revisionId;
  final String parentRevisionId;
  final int parentOrder;
  const RevisionParent({
    required this.revisionId,
    required this.parentRevisionId,
    required this.parentOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['revision_id'] = Variable<String>(revisionId);
    map['parent_revision_id'] = Variable<String>(parentRevisionId);
    map['parent_order'] = Variable<int>(parentOrder);
    return map;
  }

  RevisionParentsCompanion toCompanion(bool nullToAbsent) {
    return RevisionParentsCompanion(
      revisionId: Value(revisionId),
      parentRevisionId: Value(parentRevisionId),
      parentOrder: Value(parentOrder),
    );
  }

  factory RevisionParent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return RevisionParent(
      revisionId: serializer.fromJson<String>(json['revision_id']),
      parentRevisionId: serializer.fromJson<String>(json['parent_revision_id']),
      parentOrder: serializer.fromJson<int>(json['parent_order']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'revision_id': serializer.toJson<String>(revisionId),
      'parent_revision_id': serializer.toJson<String>(parentRevisionId),
      'parent_order': serializer.toJson<int>(parentOrder),
    };
  }

  RevisionParent copyWith({
    String? revisionId,
    String? parentRevisionId,
    int? parentOrder,
  }) => RevisionParent(
    revisionId: revisionId ?? this.revisionId,
    parentRevisionId: parentRevisionId ?? this.parentRevisionId,
    parentOrder: parentOrder ?? this.parentOrder,
  );
  RevisionParent copyWithCompanion(RevisionParentsCompanion data) {
    return RevisionParent(
      revisionId: data.revisionId.present
          ? data.revisionId.value
          : this.revisionId,
      parentRevisionId: data.parentRevisionId.present
          ? data.parentRevisionId.value
          : this.parentRevisionId,
      parentOrder: data.parentOrder.present
          ? data.parentOrder.value
          : this.parentOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('RevisionParent(')
          ..write('revisionId: $revisionId, ')
          ..write('parentRevisionId: $parentRevisionId, ')
          ..write('parentOrder: $parentOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(revisionId, parentRevisionId, parentOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is RevisionParent &&
          other.revisionId == this.revisionId &&
          other.parentRevisionId == this.parentRevisionId &&
          other.parentOrder == this.parentOrder);
}

class RevisionParentsCompanion extends UpdateCompanion<RevisionParent> {
  final Value<String> revisionId;
  final Value<String> parentRevisionId;
  final Value<int> parentOrder;
  const RevisionParentsCompanion({
    this.revisionId = const Value.absent(),
    this.parentRevisionId = const Value.absent(),
    this.parentOrder = const Value.absent(),
  });
  RevisionParentsCompanion.insert({
    required String revisionId,
    required String parentRevisionId,
    required int parentOrder,
  }) : revisionId = Value(revisionId),
       parentRevisionId = Value(parentRevisionId),
       parentOrder = Value(parentOrder);
  static Insertable<RevisionParent> custom({
    Expression<String>? revisionId,
    Expression<String>? parentRevisionId,
    Expression<int>? parentOrder,
  }) {
    return RawValuesInsertable({
      if (revisionId != null) 'revision_id': revisionId,
      if (parentRevisionId != null) 'parent_revision_id': parentRevisionId,
      if (parentOrder != null) 'parent_order': parentOrder,
    });
  }

  RevisionParentsCompanion copyWith({
    Value<String>? revisionId,
    Value<String>? parentRevisionId,
    Value<int>? parentOrder,
  }) {
    return RevisionParentsCompanion(
      revisionId: revisionId ?? this.revisionId,
      parentRevisionId: parentRevisionId ?? this.parentRevisionId,
      parentOrder: parentOrder ?? this.parentOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (revisionId.present) {
      map['revision_id'] = Variable<String>(revisionId.value);
    }
    if (parentRevisionId.present) {
      map['parent_revision_id'] = Variable<String>(parentRevisionId.value);
    }
    if (parentOrder.present) {
      map['parent_order'] = Variable<int>(parentOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('RevisionParentsCompanion(')
          ..write('revisionId: $revisionId, ')
          ..write('parentRevisionId: $parentRevisionId, ')
          ..write('parentOrder: $parentOrder')
          ..write(')'))
        .toString();
  }
}

class NoteHeads extends Table with TableInfo<NoteHeads, NoteHead> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  NoteHeads(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _revisionIdMeta = const VerificationMeta(
    'revisionId',
  );
  late final GeneratedColumn<String> revisionId = GeneratedColumn<String>(
    'revision_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES revisions(revision_id)ON DELETE RESTRICT',
  );
  @override
  List<GeneratedColumn> get $columns => [noteId, revisionId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_heads';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteHead> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('revision_id')) {
      context.handle(
        _revisionIdMeta,
        revisionId.isAcceptableOrUnknown(data['revision_id']!, _revisionIdMeta),
      );
    } else if (isInserting) {
      context.missing(_revisionIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {noteId, revisionId};
  @override
  NoteHead map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteHead(
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      revisionId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}revision_id'],
      )!,
    );
  }

  @override
  NoteHeads createAlias(String alias) {
    return NoteHeads(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(note_id, revision_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class NoteHead extends DataClass implements Insertable<NoteHead> {
  final String noteId;
  final String revisionId;
  const NoteHead({required this.noteId, required this.revisionId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<String>(noteId);
    map['revision_id'] = Variable<String>(revisionId);
    return map;
  }

  NoteHeadsCompanion toCompanion(bool nullToAbsent) {
    return NoteHeadsCompanion(
      noteId: Value(noteId),
      revisionId: Value(revisionId),
    );
  }

  factory NoteHead.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteHead(
      noteId: serializer.fromJson<String>(json['note_id']),
      revisionId: serializer.fromJson<String>(json['revision_id']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'note_id': serializer.toJson<String>(noteId),
      'revision_id': serializer.toJson<String>(revisionId),
    };
  }

  NoteHead copyWith({String? noteId, String? revisionId}) => NoteHead(
    noteId: noteId ?? this.noteId,
    revisionId: revisionId ?? this.revisionId,
  );
  NoteHead copyWithCompanion(NoteHeadsCompanion data) {
    return NoteHead(
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      revisionId: data.revisionId.present
          ? data.revisionId.value
          : this.revisionId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteHead(')
          ..write('noteId: $noteId, ')
          ..write('revisionId: $revisionId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(noteId, revisionId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteHead &&
          other.noteId == this.noteId &&
          other.revisionId == this.revisionId);
}

class NoteHeadsCompanion extends UpdateCompanion<NoteHead> {
  final Value<String> noteId;
  final Value<String> revisionId;
  const NoteHeadsCompanion({
    this.noteId = const Value.absent(),
    this.revisionId = const Value.absent(),
  });
  NoteHeadsCompanion.insert({
    required String noteId,
    required String revisionId,
  }) : noteId = Value(noteId),
       revisionId = Value(revisionId);
  static Insertable<NoteHead> custom({
    Expression<String>? noteId,
    Expression<String>? revisionId,
  }) {
    return RawValuesInsertable({
      if (noteId != null) 'note_id': noteId,
      if (revisionId != null) 'revision_id': revisionId,
    });
  }

  NoteHeadsCompanion copyWith({
    Value<String>? noteId,
    Value<String>? revisionId,
  }) {
    return NoteHeadsCompanion(
      noteId: noteId ?? this.noteId,
      revisionId: revisionId ?? this.revisionId,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (revisionId.present) {
      map['revision_id'] = Variable<String>(revisionId.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteHeadsCompanion(')
          ..write('noteId: $noteId, ')
          ..write('revisionId: $revisionId')
          ..write(')'))
        .toString();
  }
}

class SyncEvents extends Table with TableInfo<SyncEvents, SyncEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncEvents(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _vaultIdMeta = const VerificationMeta(
    'vaultId',
  );
  late final GeneratedColumn<String> vaultId = GeneratedColumn<String>(
    'vault_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _vaultGenerationMeta = const VerificationMeta(
    'vaultGeneration',
  );
  late final GeneratedColumn<int> vaultGeneration = GeneratedColumn<int>(
    'vault_generation',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (vault_generation > 0)',
  );
  static const VerificationMeta _deviceIdMeta = const VerificationMeta(
    'deviceId',
  );
  late final GeneratedColumn<String> deviceId = GeneratedColumn<String>(
    'device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (sequence > 0)',
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (event_type = \'revision_committed\')',
  );
  static const VerificationMeta _objectKeyMeta = const VerificationMeta(
    'objectKey',
  );
  late final GeneratedColumn<String> objectKey = GeneratedColumn<String>(
    'object_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _objectHashMeta = const VerificationMeta(
    'objectHash',
  );
  late final GeneratedColumn<String> objectHash = GeneratedColumn<String>(
    'object_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(object_hash) = 64)',
  );
  static const VerificationMeta _occurredAtMsMeta = const VerificationMeta(
    'occurredAtMs',
  );
  late final GeneratedColumn<int> occurredAtMs = GeneratedColumn<int>(
    'occurred_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    vaultId,
    vaultGeneration,
    deviceId,
    sequence,
    eventType,
    objectKey,
    objectHash,
    occurredAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('vault_id')) {
      context.handle(
        _vaultIdMeta,
        vaultId.isAcceptableOrUnknown(data['vault_id']!, _vaultIdMeta),
      );
    } else if (isInserting) {
      context.missing(_vaultIdMeta);
    }
    if (data.containsKey('vault_generation')) {
      context.handle(
        _vaultGenerationMeta,
        vaultGeneration.isAcceptableOrUnknown(
          data['vault_generation']!,
          _vaultGenerationMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_vaultGenerationMeta);
    }
    if (data.containsKey('device_id')) {
      context.handle(
        _deviceIdMeta,
        deviceId.isAcceptableOrUnknown(data['device_id']!, _deviceIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deviceIdMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('object_key')) {
      context.handle(
        _objectKeyMeta,
        objectKey.isAcceptableOrUnknown(data['object_key']!, _objectKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_objectKeyMeta);
    }
    if (data.containsKey('object_hash')) {
      context.handle(
        _objectHashMeta,
        objectHash.isAcceptableOrUnknown(data['object_hash']!, _objectHashMeta),
      );
    } else if (isInserting) {
      context.missing(_objectHashMeta);
    }
    if (data.containsKey('occurred_at_ms')) {
      context.handle(
        _occurredAtMsMeta,
        occurredAtMs.isAcceptableOrUnknown(
          data['occurred_at_ms']!,
          _occurredAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {deviceId, sequence},
  ];
  @override
  SyncEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncEvent(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      vaultId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}vault_id'],
      )!,
      vaultGeneration: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}vault_generation'],
      )!,
      deviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}device_id'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      objectKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}object_key'],
      )!,
      objectHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}object_hash'],
      )!,
      occurredAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at_ms'],
      )!,
    );
  }

  @override
  SyncEvents createAlias(String alias) {
    return SyncEvents(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const ['UNIQUE(device_id, sequence)'];
  @override
  bool get dontWriteConstraints => true;
}

class SyncEvent extends DataClass implements Insertable<SyncEvent> {
  final String eventId;
  final String vaultId;
  final int vaultGeneration;
  final String deviceId;
  final int sequence;
  final String eventType;
  final String objectKey;
  final String objectHash;
  final int occurredAtMs;
  const SyncEvent({
    required this.eventId,
    required this.vaultId,
    required this.vaultGeneration,
    required this.deviceId,
    required this.sequence,
    required this.eventType,
    required this.objectKey,
    required this.objectHash,
    required this.occurredAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['vault_id'] = Variable<String>(vaultId);
    map['vault_generation'] = Variable<int>(vaultGeneration);
    map['device_id'] = Variable<String>(deviceId);
    map['sequence'] = Variable<int>(sequence);
    map['event_type'] = Variable<String>(eventType);
    map['object_key'] = Variable<String>(objectKey);
    map['object_hash'] = Variable<String>(objectHash);
    map['occurred_at_ms'] = Variable<int>(occurredAtMs);
    return map;
  }

  SyncEventsCompanion toCompanion(bool nullToAbsent) {
    return SyncEventsCompanion(
      eventId: Value(eventId),
      vaultId: Value(vaultId),
      vaultGeneration: Value(vaultGeneration),
      deviceId: Value(deviceId),
      sequence: Value(sequence),
      eventType: Value(eventType),
      objectKey: Value(objectKey),
      objectHash: Value(objectHash),
      occurredAtMs: Value(occurredAtMs),
    );
  }

  factory SyncEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncEvent(
      eventId: serializer.fromJson<String>(json['event_id']),
      vaultId: serializer.fromJson<String>(json['vault_id']),
      vaultGeneration: serializer.fromJson<int>(json['vault_generation']),
      deviceId: serializer.fromJson<String>(json['device_id']),
      sequence: serializer.fromJson<int>(json['sequence']),
      eventType: serializer.fromJson<String>(json['event_type']),
      objectKey: serializer.fromJson<String>(json['object_key']),
      objectHash: serializer.fromJson<String>(json['object_hash']),
      occurredAtMs: serializer.fromJson<int>(json['occurred_at_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'event_id': serializer.toJson<String>(eventId),
      'vault_id': serializer.toJson<String>(vaultId),
      'vault_generation': serializer.toJson<int>(vaultGeneration),
      'device_id': serializer.toJson<String>(deviceId),
      'sequence': serializer.toJson<int>(sequence),
      'event_type': serializer.toJson<String>(eventType),
      'object_key': serializer.toJson<String>(objectKey),
      'object_hash': serializer.toJson<String>(objectHash),
      'occurred_at_ms': serializer.toJson<int>(occurredAtMs),
    };
  }

  SyncEvent copyWith({
    String? eventId,
    String? vaultId,
    int? vaultGeneration,
    String? deviceId,
    int? sequence,
    String? eventType,
    String? objectKey,
    String? objectHash,
    int? occurredAtMs,
  }) => SyncEvent(
    eventId: eventId ?? this.eventId,
    vaultId: vaultId ?? this.vaultId,
    vaultGeneration: vaultGeneration ?? this.vaultGeneration,
    deviceId: deviceId ?? this.deviceId,
    sequence: sequence ?? this.sequence,
    eventType: eventType ?? this.eventType,
    objectKey: objectKey ?? this.objectKey,
    objectHash: objectHash ?? this.objectHash,
    occurredAtMs: occurredAtMs ?? this.occurredAtMs,
  );
  SyncEvent copyWithCompanion(SyncEventsCompanion data) {
    return SyncEvent(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      vaultId: data.vaultId.present ? data.vaultId.value : this.vaultId,
      vaultGeneration: data.vaultGeneration.present
          ? data.vaultGeneration.value
          : this.vaultGeneration,
      deviceId: data.deviceId.present ? data.deviceId.value : this.deviceId,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      objectKey: data.objectKey.present ? data.objectKey.value : this.objectKey,
      objectHash: data.objectHash.present
          ? data.objectHash.value
          : this.objectHash,
      occurredAtMs: data.occurredAtMs.present
          ? data.occurredAtMs.value
          : this.occurredAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncEvent(')
          ..write('eventId: $eventId, ')
          ..write('vaultId: $vaultId, ')
          ..write('vaultGeneration: $vaultGeneration, ')
          ..write('deviceId: $deviceId, ')
          ..write('sequence: $sequence, ')
          ..write('eventType: $eventType, ')
          ..write('objectKey: $objectKey, ')
          ..write('objectHash: $objectHash, ')
          ..write('occurredAtMs: $occurredAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    eventId,
    vaultId,
    vaultGeneration,
    deviceId,
    sequence,
    eventType,
    objectKey,
    objectHash,
    occurredAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncEvent &&
          other.eventId == this.eventId &&
          other.vaultId == this.vaultId &&
          other.vaultGeneration == this.vaultGeneration &&
          other.deviceId == this.deviceId &&
          other.sequence == this.sequence &&
          other.eventType == this.eventType &&
          other.objectKey == this.objectKey &&
          other.objectHash == this.objectHash &&
          other.occurredAtMs == this.occurredAtMs);
}

class SyncEventsCompanion extends UpdateCompanion<SyncEvent> {
  final Value<String> eventId;
  final Value<String> vaultId;
  final Value<int> vaultGeneration;
  final Value<String> deviceId;
  final Value<int> sequence;
  final Value<String> eventType;
  final Value<String> objectKey;
  final Value<String> objectHash;
  final Value<int> occurredAtMs;
  final Value<int> rowid;
  const SyncEventsCompanion({
    this.eventId = const Value.absent(),
    this.vaultId = const Value.absent(),
    this.vaultGeneration = const Value.absent(),
    this.deviceId = const Value.absent(),
    this.sequence = const Value.absent(),
    this.eventType = const Value.absent(),
    this.objectKey = const Value.absent(),
    this.objectHash = const Value.absent(),
    this.occurredAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncEventsCompanion.insert({
    required String eventId,
    required String vaultId,
    required int vaultGeneration,
    required String deviceId,
    required int sequence,
    required String eventType,
    required String objectKey,
    required String objectHash,
    required int occurredAtMs,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       vaultId = Value(vaultId),
       vaultGeneration = Value(vaultGeneration),
       deviceId = Value(deviceId),
       sequence = Value(sequence),
       eventType = Value(eventType),
       objectKey = Value(objectKey),
       objectHash = Value(objectHash),
       occurredAtMs = Value(occurredAtMs);
  static Insertable<SyncEvent> custom({
    Expression<String>? eventId,
    Expression<String>? vaultId,
    Expression<int>? vaultGeneration,
    Expression<String>? deviceId,
    Expression<int>? sequence,
    Expression<String>? eventType,
    Expression<String>? objectKey,
    Expression<String>? objectHash,
    Expression<int>? occurredAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (vaultId != null) 'vault_id': vaultId,
      if (vaultGeneration != null) 'vault_generation': vaultGeneration,
      if (deviceId != null) 'device_id': deviceId,
      if (sequence != null) 'sequence': sequence,
      if (eventType != null) 'event_type': eventType,
      if (objectKey != null) 'object_key': objectKey,
      if (objectHash != null) 'object_hash': objectHash,
      if (occurredAtMs != null) 'occurred_at_ms': occurredAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncEventsCompanion copyWith({
    Value<String>? eventId,
    Value<String>? vaultId,
    Value<int>? vaultGeneration,
    Value<String>? deviceId,
    Value<int>? sequence,
    Value<String>? eventType,
    Value<String>? objectKey,
    Value<String>? objectHash,
    Value<int>? occurredAtMs,
    Value<int>? rowid,
  }) {
    return SyncEventsCompanion(
      eventId: eventId ?? this.eventId,
      vaultId: vaultId ?? this.vaultId,
      vaultGeneration: vaultGeneration ?? this.vaultGeneration,
      deviceId: deviceId ?? this.deviceId,
      sequence: sequence ?? this.sequence,
      eventType: eventType ?? this.eventType,
      objectKey: objectKey ?? this.objectKey,
      objectHash: objectHash ?? this.objectHash,
      occurredAtMs: occurredAtMs ?? this.occurredAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (vaultId.present) {
      map['vault_id'] = Variable<String>(vaultId.value);
    }
    if (vaultGeneration.present) {
      map['vault_generation'] = Variable<int>(vaultGeneration.value);
    }
    if (deviceId.present) {
      map['device_id'] = Variable<String>(deviceId.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (objectKey.present) {
      map['object_key'] = Variable<String>(objectKey.value);
    }
    if (objectHash.present) {
      map['object_hash'] = Variable<String>(objectHash.value);
    }
    if (occurredAtMs.present) {
      map['occurred_at_ms'] = Variable<int>(occurredAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncEventsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('vaultId: $vaultId, ')
          ..write('vaultGeneration: $vaultGeneration, ')
          ..write('deviceId: $deviceId, ')
          ..write('sequence: $sequence, ')
          ..write('eventType: $eventType, ')
          ..write('objectKey: $objectKey, ')
          ..write('objectHash: $objectHash, ')
          ..write('occurredAtMs: $occurredAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class SyncOutbox extends Table with TableInfo<SyncOutbox, SyncOutboxData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncOutbox(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _outboxIdMeta = const VerificationMeta(
    'outboxId',
  );
  late final GeneratedColumn<int> outboxId = GeneratedColumn<int>(
    'outbox_id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'PRIMARY KEY AUTOINCREMENT',
  );
  static const VerificationMeta _objectKeyMeta = const VerificationMeta(
    'objectKey',
  );
  late final GeneratedColumn<String> objectKey = GeneratedColumn<String>(
    'object_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE',
  );
  static const VerificationMeta _objectKindMeta = const VerificationMeta(
    'objectKind',
  );
  late final GeneratedColumn<String> objectKind = GeneratedColumn<String>(
    'object_kind',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (object_kind IN (\'revision\', \'event\'))',
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  late final GeneratedColumn<Uint8List> payload = GeneratedColumn<Uint8List>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.blob,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _payloadHashMeta = const VerificationMeta(
    'payloadHash',
  );
  late final GeneratedColumn<String> payloadHash = GeneratedColumn<String>(
    'payload_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (length(payload_hash) = 64)',
  );
  static const VerificationMeta _dependencyKeyMeta = const VerificationMeta(
    'dependencyKey',
  );
  late final GeneratedColumn<String> dependencyKey = GeneratedColumn<String>(
    'dependency_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _attemptCountMeta = const VerificationMeta(
    'attemptCount',
  );
  late final GeneratedColumn<int> attemptCount = GeneratedColumn<int>(
    'attempt_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (attempt_count >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _nextAttemptAtMsMeta = const VerificationMeta(
    'nextAttemptAtMs',
  );
  late final GeneratedColumn<int> nextAttemptAtMs = GeneratedColumn<int>(
    'next_attempt_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    outboxId,
    objectKey,
    objectKind,
    payload,
    payloadHash,
    dependencyKey,
    attemptCount,
    nextAttemptAtMs,
    lastError,
    createdAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('outbox_id')) {
      context.handle(
        _outboxIdMeta,
        outboxId.isAcceptableOrUnknown(data['outbox_id']!, _outboxIdMeta),
      );
    }
    if (data.containsKey('object_key')) {
      context.handle(
        _objectKeyMeta,
        objectKey.isAcceptableOrUnknown(data['object_key']!, _objectKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_objectKeyMeta);
    }
    if (data.containsKey('object_kind')) {
      context.handle(
        _objectKindMeta,
        objectKind.isAcceptableOrUnknown(data['object_kind']!, _objectKindMeta),
      );
    } else if (isInserting) {
      context.missing(_objectKindMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    } else if (isInserting) {
      context.missing(_payloadMeta);
    }
    if (data.containsKey('payload_hash')) {
      context.handle(
        _payloadHashMeta,
        payloadHash.isAcceptableOrUnknown(
          data['payload_hash']!,
          _payloadHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadHashMeta);
    }
    if (data.containsKey('dependency_key')) {
      context.handle(
        _dependencyKeyMeta,
        dependencyKey.isAcceptableOrUnknown(
          data['dependency_key']!,
          _dependencyKeyMeta,
        ),
      );
    }
    if (data.containsKey('attempt_count')) {
      context.handle(
        _attemptCountMeta,
        attemptCount.isAcceptableOrUnknown(
          data['attempt_count']!,
          _attemptCountMeta,
        ),
      );
    }
    if (data.containsKey('next_attempt_at_ms')) {
      context.handle(
        _nextAttemptAtMsMeta,
        nextAttemptAtMs.isAcceptableOrUnknown(
          data['next_attempt_at_ms']!,
          _nextAttemptAtMsMeta,
        ),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {outboxId};
  @override
  SyncOutboxData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxData(
      outboxId: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}outbox_id'],
      )!,
      objectKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}object_key'],
      )!,
      objectKind: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}object_kind'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.blob,
        data['${effectivePrefix}payload'],
      )!,
      payloadHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_hash'],
      )!,
      dependencyKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dependency_key'],
      ),
      attemptCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}attempt_count'],
      )!,
      nextAttemptAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}next_attempt_at_ms'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
    );
  }

  @override
  SyncOutbox createAlias(String alias) {
    return SyncOutbox(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class SyncOutboxData extends DataClass implements Insertable<SyncOutboxData> {
  final int outboxId;
  final String objectKey;
  final String objectKind;
  final Uint8List payload;
  final String payloadHash;
  final String? dependencyKey;
  final int attemptCount;
  final int nextAttemptAtMs;
  final String? lastError;
  final int createdAtMs;
  const SyncOutboxData({
    required this.outboxId,
    required this.objectKey,
    required this.objectKind,
    required this.payload,
    required this.payloadHash,
    this.dependencyKey,
    required this.attemptCount,
    required this.nextAttemptAtMs,
    this.lastError,
    required this.createdAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['outbox_id'] = Variable<int>(outboxId);
    map['object_key'] = Variable<String>(objectKey);
    map['object_kind'] = Variable<String>(objectKind);
    map['payload'] = Variable<Uint8List>(payload);
    map['payload_hash'] = Variable<String>(payloadHash);
    if (!nullToAbsent || dependencyKey != null) {
      map['dependency_key'] = Variable<String>(dependencyKey);
    }
    map['attempt_count'] = Variable<int>(attemptCount);
    map['next_attempt_at_ms'] = Variable<int>(nextAttemptAtMs);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  SyncOutboxCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxCompanion(
      outboxId: Value(outboxId),
      objectKey: Value(objectKey),
      objectKind: Value(objectKind),
      payload: Value(payload),
      payloadHash: Value(payloadHash),
      dependencyKey: dependencyKey == null && nullToAbsent
          ? const Value.absent()
          : Value(dependencyKey),
      attemptCount: Value(attemptCount),
      nextAttemptAtMs: Value(nextAttemptAtMs),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory SyncOutboxData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxData(
      outboxId: serializer.fromJson<int>(json['outbox_id']),
      objectKey: serializer.fromJson<String>(json['object_key']),
      objectKind: serializer.fromJson<String>(json['object_kind']),
      payload: serializer.fromJson<Uint8List>(json['payload']),
      payloadHash: serializer.fromJson<String>(json['payload_hash']),
      dependencyKey: serializer.fromJson<String?>(json['dependency_key']),
      attemptCount: serializer.fromJson<int>(json['attempt_count']),
      nextAttemptAtMs: serializer.fromJson<int>(json['next_attempt_at_ms']),
      lastError: serializer.fromJson<String?>(json['last_error']),
      createdAtMs: serializer.fromJson<int>(json['created_at_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'outbox_id': serializer.toJson<int>(outboxId),
      'object_key': serializer.toJson<String>(objectKey),
      'object_kind': serializer.toJson<String>(objectKind),
      'payload': serializer.toJson<Uint8List>(payload),
      'payload_hash': serializer.toJson<String>(payloadHash),
      'dependency_key': serializer.toJson<String?>(dependencyKey),
      'attempt_count': serializer.toJson<int>(attemptCount),
      'next_attempt_at_ms': serializer.toJson<int>(nextAttemptAtMs),
      'last_error': serializer.toJson<String?>(lastError),
      'created_at_ms': serializer.toJson<int>(createdAtMs),
    };
  }

  SyncOutboxData copyWith({
    int? outboxId,
    String? objectKey,
    String? objectKind,
    Uint8List? payload,
    String? payloadHash,
    Value<String?> dependencyKey = const Value.absent(),
    int? attemptCount,
    int? nextAttemptAtMs,
    Value<String?> lastError = const Value.absent(),
    int? createdAtMs,
  }) => SyncOutboxData(
    outboxId: outboxId ?? this.outboxId,
    objectKey: objectKey ?? this.objectKey,
    objectKind: objectKind ?? this.objectKind,
    payload: payload ?? this.payload,
    payloadHash: payloadHash ?? this.payloadHash,
    dependencyKey: dependencyKey.present
        ? dependencyKey.value
        : this.dependencyKey,
    attemptCount: attemptCount ?? this.attemptCount,
    nextAttemptAtMs: nextAttemptAtMs ?? this.nextAttemptAtMs,
    lastError: lastError.present ? lastError.value : this.lastError,
    createdAtMs: createdAtMs ?? this.createdAtMs,
  );
  SyncOutboxData copyWithCompanion(SyncOutboxCompanion data) {
    return SyncOutboxData(
      outboxId: data.outboxId.present ? data.outboxId.value : this.outboxId,
      objectKey: data.objectKey.present ? data.objectKey.value : this.objectKey,
      objectKind: data.objectKind.present
          ? data.objectKind.value
          : this.objectKind,
      payload: data.payload.present ? data.payload.value : this.payload,
      payloadHash: data.payloadHash.present
          ? data.payloadHash.value
          : this.payloadHash,
      dependencyKey: data.dependencyKey.present
          ? data.dependencyKey.value
          : this.dependencyKey,
      attemptCount: data.attemptCount.present
          ? data.attemptCount.value
          : this.attemptCount,
      nextAttemptAtMs: data.nextAttemptAtMs.present
          ? data.nextAttemptAtMs.value
          : this.nextAttemptAtMs,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxData(')
          ..write('outboxId: $outboxId, ')
          ..write('objectKey: $objectKey, ')
          ..write('objectKind: $objectKind, ')
          ..write('payload: $payload, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('dependencyKey: $dependencyKey, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAtMs: $nextAttemptAtMs, ')
          ..write('lastError: $lastError, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    outboxId,
    objectKey,
    objectKind,
    $driftBlobEquality.hash(payload),
    payloadHash,
    dependencyKey,
    attemptCount,
    nextAttemptAtMs,
    lastError,
    createdAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxData &&
          other.outboxId == this.outboxId &&
          other.objectKey == this.objectKey &&
          other.objectKind == this.objectKind &&
          $driftBlobEquality.equals(other.payload, this.payload) &&
          other.payloadHash == this.payloadHash &&
          other.dependencyKey == this.dependencyKey &&
          other.attemptCount == this.attemptCount &&
          other.nextAttemptAtMs == this.nextAttemptAtMs &&
          other.lastError == this.lastError &&
          other.createdAtMs == this.createdAtMs);
}

class SyncOutboxCompanion extends UpdateCompanion<SyncOutboxData> {
  final Value<int> outboxId;
  final Value<String> objectKey;
  final Value<String> objectKind;
  final Value<Uint8List> payload;
  final Value<String> payloadHash;
  final Value<String?> dependencyKey;
  final Value<int> attemptCount;
  final Value<int> nextAttemptAtMs;
  final Value<String?> lastError;
  final Value<int> createdAtMs;
  const SyncOutboxCompanion({
    this.outboxId = const Value.absent(),
    this.objectKey = const Value.absent(),
    this.objectKind = const Value.absent(),
    this.payload = const Value.absent(),
    this.payloadHash = const Value.absent(),
    this.dependencyKey = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptAtMs = const Value.absent(),
    this.lastError = const Value.absent(),
    this.createdAtMs = const Value.absent(),
  });
  SyncOutboxCompanion.insert({
    this.outboxId = const Value.absent(),
    required String objectKey,
    required String objectKind,
    required Uint8List payload,
    required String payloadHash,
    this.dependencyKey = const Value.absent(),
    this.attemptCount = const Value.absent(),
    this.nextAttemptAtMs = const Value.absent(),
    this.lastError = const Value.absent(),
    required int createdAtMs,
  }) : objectKey = Value(objectKey),
       objectKind = Value(objectKind),
       payload = Value(payload),
       payloadHash = Value(payloadHash),
       createdAtMs = Value(createdAtMs);
  static Insertable<SyncOutboxData> custom({
    Expression<int>? outboxId,
    Expression<String>? objectKey,
    Expression<String>? objectKind,
    Expression<Uint8List>? payload,
    Expression<String>? payloadHash,
    Expression<String>? dependencyKey,
    Expression<int>? attemptCount,
    Expression<int>? nextAttemptAtMs,
    Expression<String>? lastError,
    Expression<int>? createdAtMs,
  }) {
    return RawValuesInsertable({
      if (outboxId != null) 'outbox_id': outboxId,
      if (objectKey != null) 'object_key': objectKey,
      if (objectKind != null) 'object_kind': objectKind,
      if (payload != null) 'payload': payload,
      if (payloadHash != null) 'payload_hash': payloadHash,
      if (dependencyKey != null) 'dependency_key': dependencyKey,
      if (attemptCount != null) 'attempt_count': attemptCount,
      if (nextAttemptAtMs != null) 'next_attempt_at_ms': nextAttemptAtMs,
      if (lastError != null) 'last_error': lastError,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
    });
  }

  SyncOutboxCompanion copyWith({
    Value<int>? outboxId,
    Value<String>? objectKey,
    Value<String>? objectKind,
    Value<Uint8List>? payload,
    Value<String>? payloadHash,
    Value<String?>? dependencyKey,
    Value<int>? attemptCount,
    Value<int>? nextAttemptAtMs,
    Value<String?>? lastError,
    Value<int>? createdAtMs,
  }) {
    return SyncOutboxCompanion(
      outboxId: outboxId ?? this.outboxId,
      objectKey: objectKey ?? this.objectKey,
      objectKind: objectKind ?? this.objectKind,
      payload: payload ?? this.payload,
      payloadHash: payloadHash ?? this.payloadHash,
      dependencyKey: dependencyKey ?? this.dependencyKey,
      attemptCount: attemptCount ?? this.attemptCount,
      nextAttemptAtMs: nextAttemptAtMs ?? this.nextAttemptAtMs,
      lastError: lastError ?? this.lastError,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (outboxId.present) {
      map['outbox_id'] = Variable<int>(outboxId.value);
    }
    if (objectKey.present) {
      map['object_key'] = Variable<String>(objectKey.value);
    }
    if (objectKind.present) {
      map['object_kind'] = Variable<String>(objectKind.value);
    }
    if (payload.present) {
      map['payload'] = Variable<Uint8List>(payload.value);
    }
    if (payloadHash.present) {
      map['payload_hash'] = Variable<String>(payloadHash.value);
    }
    if (dependencyKey.present) {
      map['dependency_key'] = Variable<String>(dependencyKey.value);
    }
    if (attemptCount.present) {
      map['attempt_count'] = Variable<int>(attemptCount.value);
    }
    if (nextAttemptAtMs.present) {
      map['next_attempt_at_ms'] = Variable<int>(nextAttemptAtMs.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxCompanion(')
          ..write('outboxId: $outboxId, ')
          ..write('objectKey: $objectKey, ')
          ..write('objectKind: $objectKind, ')
          ..write('payload: $payload, ')
          ..write('payloadHash: $payloadHash, ')
          ..write('dependencyKey: $dependencyKey, ')
          ..write('attemptCount: $attemptCount, ')
          ..write('nextAttemptAtMs: $nextAttemptAtMs, ')
          ..write('lastError: $lastError, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }
}

class SyncCursors extends Table with TableInfo<SyncCursors, SyncCursor> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  SyncCursors(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _remoteDeviceIdMeta = const VerificationMeta(
    'remoteDeviceId',
  );
  late final GeneratedColumn<String> remoteDeviceId = GeneratedColumn<String>(
    'remote_device_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _lastSequenceMeta = const VerificationMeta(
    'lastSequence',
  );
  late final GeneratedColumn<int> lastSequence = GeneratedColumn<int>(
    'last_sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: 'NOT NULL DEFAULT 0 CHECK (last_sequence >= 0)',
    defaultValue: const CustomExpression('0'),
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [
    remoteDeviceId,
    lastSequence,
    updatedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_cursors';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncCursor> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('remote_device_id')) {
      context.handle(
        _remoteDeviceIdMeta,
        remoteDeviceId.isAcceptableOrUnknown(
          data['remote_device_id']!,
          _remoteDeviceIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_remoteDeviceIdMeta);
    }
    if (data.containsKey('last_sequence')) {
      context.handle(
        _lastSequenceMeta,
        lastSequence.isAcceptableOrUnknown(
          data['last_sequence']!,
          _lastSequenceMeta,
        ),
      );
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {remoteDeviceId};
  @override
  SyncCursor map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncCursor(
      remoteDeviceId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_device_id'],
      )!,
      lastSequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_sequence'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
    );
  }

  @override
  SyncCursors createAlias(String alias) {
    return SyncCursors(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class SyncCursor extends DataClass implements Insertable<SyncCursor> {
  final String remoteDeviceId;
  final int lastSequence;
  final int updatedAtMs;
  const SyncCursor({
    required this.remoteDeviceId,
    required this.lastSequence,
    required this.updatedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['remote_device_id'] = Variable<String>(remoteDeviceId);
    map['last_sequence'] = Variable<int>(lastSequence);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  SyncCursorsCompanion toCompanion(bool nullToAbsent) {
    return SyncCursorsCompanion(
      remoteDeviceId: Value(remoteDeviceId),
      lastSequence: Value(lastSequence),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory SyncCursor.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncCursor(
      remoteDeviceId: serializer.fromJson<String>(json['remote_device_id']),
      lastSequence: serializer.fromJson<int>(json['last_sequence']),
      updatedAtMs: serializer.fromJson<int>(json['updated_at_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'remote_device_id': serializer.toJson<String>(remoteDeviceId),
      'last_sequence': serializer.toJson<int>(lastSequence),
      'updated_at_ms': serializer.toJson<int>(updatedAtMs),
    };
  }

  SyncCursor copyWith({
    String? remoteDeviceId,
    int? lastSequence,
    int? updatedAtMs,
  }) => SyncCursor(
    remoteDeviceId: remoteDeviceId ?? this.remoteDeviceId,
    lastSequence: lastSequence ?? this.lastSequence,
    updatedAtMs: updatedAtMs ?? this.updatedAtMs,
  );
  SyncCursor copyWithCompanion(SyncCursorsCompanion data) {
    return SyncCursor(
      remoteDeviceId: data.remoteDeviceId.present
          ? data.remoteDeviceId.value
          : this.remoteDeviceId,
      lastSequence: data.lastSequence.present
          ? data.lastSequence.value
          : this.lastSequence,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursor(')
          ..write('remoteDeviceId: $remoteDeviceId, ')
          ..write('lastSequence: $lastSequence, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(remoteDeviceId, lastSequence, updatedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncCursor &&
          other.remoteDeviceId == this.remoteDeviceId &&
          other.lastSequence == this.lastSequence &&
          other.updatedAtMs == this.updatedAtMs);
}

class SyncCursorsCompanion extends UpdateCompanion<SyncCursor> {
  final Value<String> remoteDeviceId;
  final Value<int> lastSequence;
  final Value<int> updatedAtMs;
  const SyncCursorsCompanion({
    this.remoteDeviceId = const Value.absent(),
    this.lastSequence = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
  });
  SyncCursorsCompanion.insert({
    required String remoteDeviceId,
    this.lastSequence = const Value.absent(),
    required int updatedAtMs,
  }) : remoteDeviceId = Value(remoteDeviceId),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<SyncCursor> custom({
    Expression<String>? remoteDeviceId,
    Expression<int>? lastSequence,
    Expression<int>? updatedAtMs,
  }) {
    return RawValuesInsertable({
      if (remoteDeviceId != null) 'remote_device_id': remoteDeviceId,
      if (lastSequence != null) 'last_sequence': lastSequence,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
    });
  }

  SyncCursorsCompanion copyWith({
    Value<String>? remoteDeviceId,
    Value<int>? lastSequence,
    Value<int>? updatedAtMs,
  }) {
    return SyncCursorsCompanion(
      remoteDeviceId: remoteDeviceId ?? this.remoteDeviceId,
      lastSequence: lastSequence ?? this.lastSequence,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (remoteDeviceId.present) {
      map['remote_device_id'] = Variable<String>(remoteDeviceId.value);
    }
    if (lastSequence.present) {
      map['last_sequence'] = Variable<int>(lastSequence.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncCursorsCompanion(')
          ..write('remoteDeviceId: $remoteDeviceId, ')
          ..write('lastSequence: $lastSequence, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }
}

class Conflicts extends Table with TableInfo<Conflicts, Conflict> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Conflicts(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _conflictIdMeta = const VerificationMeta(
    'conflictId',
  );
  late final GeneratedColumn<String> conflictId = GeneratedColumn<String>(
    'conflict_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _headRevisionIdsJsonMeta =
      const VerificationMeta('headRevisionIdsJson');
  late final GeneratedColumn<String> headRevisionIdsJson =
      GeneratedColumn<String>(
        'head_revision_ids_json',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
        $customConstraints:
            'NOT NULL CHECK (json_valid(head_revision_ids_json))',
      );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (status IN (\'open\', \'resolved\'))',
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _resolvedAtMsMeta = const VerificationMeta(
    'resolvedAtMs',
  );
  late final GeneratedColumn<int> resolvedAtMs = GeneratedColumn<int>(
    'resolved_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    conflictId,
    noteId,
    headRevisionIdsJson,
    status,
    createdAtMs,
    resolvedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'conflicts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Conflict> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('conflict_id')) {
      context.handle(
        _conflictIdMeta,
        conflictId.isAcceptableOrUnknown(data['conflict_id']!, _conflictIdMeta),
      );
    } else if (isInserting) {
      context.missing(_conflictIdMeta);
    }
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('head_revision_ids_json')) {
      context.handle(
        _headRevisionIdsJsonMeta,
        headRevisionIdsJson.isAcceptableOrUnknown(
          data['head_revision_ids_json']!,
          _headRevisionIdsJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_headRevisionIdsJsonMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('resolved_at_ms')) {
      context.handle(
        _resolvedAtMsMeta,
        resolvedAtMs.isAcceptableOrUnknown(
          data['resolved_at_ms']!,
          _resolvedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {conflictId};
  @override
  Conflict map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Conflict(
      conflictId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}conflict_id'],
      )!,
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      headRevisionIdsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}head_revision_ids_json'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      resolvedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}resolved_at_ms'],
      ),
    );
  }

  @override
  Conflicts createAlias(String alias) {
    return Conflicts(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class Conflict extends DataClass implements Insertable<Conflict> {
  final String conflictId;
  final String noteId;
  final String headRevisionIdsJson;
  final String status;
  final int createdAtMs;
  final int? resolvedAtMs;
  const Conflict({
    required this.conflictId,
    required this.noteId,
    required this.headRevisionIdsJson,
    required this.status,
    required this.createdAtMs,
    this.resolvedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['conflict_id'] = Variable<String>(conflictId);
    map['note_id'] = Variable<String>(noteId);
    map['head_revision_ids_json'] = Variable<String>(headRevisionIdsJson);
    map['status'] = Variable<String>(status);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    if (!nullToAbsent || resolvedAtMs != null) {
      map['resolved_at_ms'] = Variable<int>(resolvedAtMs);
    }
    return map;
  }

  ConflictsCompanion toCompanion(bool nullToAbsent) {
    return ConflictsCompanion(
      conflictId: Value(conflictId),
      noteId: Value(noteId),
      headRevisionIdsJson: Value(headRevisionIdsJson),
      status: Value(status),
      createdAtMs: Value(createdAtMs),
      resolvedAtMs: resolvedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(resolvedAtMs),
    );
  }

  factory Conflict.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Conflict(
      conflictId: serializer.fromJson<String>(json['conflict_id']),
      noteId: serializer.fromJson<String>(json['note_id']),
      headRevisionIdsJson: serializer.fromJson<String>(
        json['head_revision_ids_json'],
      ),
      status: serializer.fromJson<String>(json['status']),
      createdAtMs: serializer.fromJson<int>(json['created_at_ms']),
      resolvedAtMs: serializer.fromJson<int?>(json['resolved_at_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'conflict_id': serializer.toJson<String>(conflictId),
      'note_id': serializer.toJson<String>(noteId),
      'head_revision_ids_json': serializer.toJson<String>(headRevisionIdsJson),
      'status': serializer.toJson<String>(status),
      'created_at_ms': serializer.toJson<int>(createdAtMs),
      'resolved_at_ms': serializer.toJson<int?>(resolvedAtMs),
    };
  }

  Conflict copyWith({
    String? conflictId,
    String? noteId,
    String? headRevisionIdsJson,
    String? status,
    int? createdAtMs,
    Value<int?> resolvedAtMs = const Value.absent(),
  }) => Conflict(
    conflictId: conflictId ?? this.conflictId,
    noteId: noteId ?? this.noteId,
    headRevisionIdsJson: headRevisionIdsJson ?? this.headRevisionIdsJson,
    status: status ?? this.status,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    resolvedAtMs: resolvedAtMs.present ? resolvedAtMs.value : this.resolvedAtMs,
  );
  Conflict copyWithCompanion(ConflictsCompanion data) {
    return Conflict(
      conflictId: data.conflictId.present
          ? data.conflictId.value
          : this.conflictId,
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      headRevisionIdsJson: data.headRevisionIdsJson.present
          ? data.headRevisionIdsJson.value
          : this.headRevisionIdsJson,
      status: data.status.present ? data.status.value : this.status,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      resolvedAtMs: data.resolvedAtMs.present
          ? data.resolvedAtMs.value
          : this.resolvedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Conflict(')
          ..write('conflictId: $conflictId, ')
          ..write('noteId: $noteId, ')
          ..write('headRevisionIdsJson: $headRevisionIdsJson, ')
          ..write('status: $status, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('resolvedAtMs: $resolvedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    conflictId,
    noteId,
    headRevisionIdsJson,
    status,
    createdAtMs,
    resolvedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Conflict &&
          other.conflictId == this.conflictId &&
          other.noteId == this.noteId &&
          other.headRevisionIdsJson == this.headRevisionIdsJson &&
          other.status == this.status &&
          other.createdAtMs == this.createdAtMs &&
          other.resolvedAtMs == this.resolvedAtMs);
}

class ConflictsCompanion extends UpdateCompanion<Conflict> {
  final Value<String> conflictId;
  final Value<String> noteId;
  final Value<String> headRevisionIdsJson;
  final Value<String> status;
  final Value<int> createdAtMs;
  final Value<int?> resolvedAtMs;
  final Value<int> rowid;
  const ConflictsCompanion({
    this.conflictId = const Value.absent(),
    this.noteId = const Value.absent(),
    this.headRevisionIdsJson = const Value.absent(),
    this.status = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.resolvedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ConflictsCompanion.insert({
    required String conflictId,
    required String noteId,
    required String headRevisionIdsJson,
    required String status,
    required int createdAtMs,
    this.resolvedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : conflictId = Value(conflictId),
       noteId = Value(noteId),
       headRevisionIdsJson = Value(headRevisionIdsJson),
       status = Value(status),
       createdAtMs = Value(createdAtMs);
  static Insertable<Conflict> custom({
    Expression<String>? conflictId,
    Expression<String>? noteId,
    Expression<String>? headRevisionIdsJson,
    Expression<String>? status,
    Expression<int>? createdAtMs,
    Expression<int>? resolvedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (conflictId != null) 'conflict_id': conflictId,
      if (noteId != null) 'note_id': noteId,
      if (headRevisionIdsJson != null)
        'head_revision_ids_json': headRevisionIdsJson,
      if (status != null) 'status': status,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (resolvedAtMs != null) 'resolved_at_ms': resolvedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ConflictsCompanion copyWith({
    Value<String>? conflictId,
    Value<String>? noteId,
    Value<String>? headRevisionIdsJson,
    Value<String>? status,
    Value<int>? createdAtMs,
    Value<int?>? resolvedAtMs,
    Value<int>? rowid,
  }) {
    return ConflictsCompanion(
      conflictId: conflictId ?? this.conflictId,
      noteId: noteId ?? this.noteId,
      headRevisionIdsJson: headRevisionIdsJson ?? this.headRevisionIdsJson,
      status: status ?? this.status,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      resolvedAtMs: resolvedAtMs ?? this.resolvedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (conflictId.present) {
      map['conflict_id'] = Variable<String>(conflictId.value);
    }
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (headRevisionIdsJson.present) {
      map['head_revision_ids_json'] = Variable<String>(
        headRevisionIdsJson.value,
      );
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (resolvedAtMs.present) {
      map['resolved_at_ms'] = Variable<int>(resolvedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ConflictsCompanion(')
          ..write('conflictId: $conflictId, ')
          ..write('noteId: $noteId, ')
          ..write('headRevisionIdsJson: $headRevisionIdsJson, ')
          ..write('status: $status, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('resolvedAtMs: $resolvedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class Attachments extends Table with TableInfo<Attachments, Attachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Attachments(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _attachmentIdMeta = const VerificationMeta(
    'attachmentId',
  );
  late final GeneratedColumn<String> attachmentId = GeneratedColumn<String>(
    'attachment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL UNIQUE CHECK (length(content_hash) = 64)',
  );
  static const VerificationMeta _byteLengthMeta = const VerificationMeta(
    'byteLength',
  );
  late final GeneratedColumn<int> byteLength = GeneratedColumn<int>(
    'byte_length',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (byte_length >= 0)',
  );
  static const VerificationMeta _mediaTypeMeta = const VerificationMeta(
    'mediaType',
  );
  late final GeneratedColumn<String> mediaType = GeneratedColumn<String>(
    'media_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _localStateMeta = const VerificationMeta(
    'localState',
  );
  late final GeneratedColumn<String> localState = GeneratedColumn<String>(
    'local_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL CHECK (local_state IN (\'local_available\', \'remote_only\', \'downloading\', \'missing\', \'corrupted\'))',
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  static const VerificationMeta _createdAtMsMeta = const VerificationMeta(
    'createdAtMs',
  );
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
    'created_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _lastAccessedAtMsMeta = const VerificationMeta(
    'lastAccessedAtMs',
  );
  late final GeneratedColumn<int> lastAccessedAtMs = GeneratedColumn<int>(
    'last_accessed_at_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    $customConstraints: '',
  );
  @override
  List<GeneratedColumn> get $columns => [
    attachmentId,
    contentHash,
    byteLength,
    mediaType,
    localState,
    localPath,
    createdAtMs,
    lastAccessedAtMs,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<Attachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('attachment_id')) {
      context.handle(
        _attachmentIdMeta,
        attachmentId.isAcceptableOrUnknown(
          data['attachment_id']!,
          _attachmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attachmentIdMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('byte_length')) {
      context.handle(
        _byteLengthMeta,
        byteLength.isAcceptableOrUnknown(data['byte_length']!, _byteLengthMeta),
      );
    } else if (isInserting) {
      context.missing(_byteLengthMeta);
    }
    if (data.containsKey('media_type')) {
      context.handle(
        _mediaTypeMeta,
        mediaType.isAcceptableOrUnknown(data['media_type']!, _mediaTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_mediaTypeMeta);
    }
    if (data.containsKey('local_state')) {
      context.handle(
        _localStateMeta,
        localState.isAcceptableOrUnknown(data['local_state']!, _localStateMeta),
      );
    } else if (isInserting) {
      context.missing(_localStateMeta);
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
        _createdAtMsMeta,
        createdAtMs.isAcceptableOrUnknown(
          data['created_at_ms']!,
          _createdAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    if (data.containsKey('last_accessed_at_ms')) {
      context.handle(
        _lastAccessedAtMsMeta,
        lastAccessedAtMs.isAcceptableOrUnknown(
          data['last_accessed_at_ms']!,
          _lastAccessedAtMsMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {attachmentId};
  @override
  Attachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Attachment(
      attachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_id'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      byteLength: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}byte_length'],
      )!,
      mediaType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}media_type'],
      )!,
      localState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_state'],
      )!,
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      createdAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_ms'],
      )!,
      lastAccessedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}last_accessed_at_ms'],
      ),
    );
  }

  @override
  Attachments createAlias(String alias) {
    return Attachments(attachedDatabase, alias);
  }

  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class Attachment extends DataClass implements Insertable<Attachment> {
  final String attachmentId;
  final String contentHash;
  final int byteLength;
  final String mediaType;
  final String localState;
  final String? localPath;
  final int createdAtMs;
  final int? lastAccessedAtMs;
  const Attachment({
    required this.attachmentId,
    required this.contentHash,
    required this.byteLength,
    required this.mediaType,
    required this.localState,
    this.localPath,
    required this.createdAtMs,
    this.lastAccessedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['attachment_id'] = Variable<String>(attachmentId);
    map['content_hash'] = Variable<String>(contentHash);
    map['byte_length'] = Variable<int>(byteLength);
    map['media_type'] = Variable<String>(mediaType);
    map['local_state'] = Variable<String>(localState);
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    map['created_at_ms'] = Variable<int>(createdAtMs);
    if (!nullToAbsent || lastAccessedAtMs != null) {
      map['last_accessed_at_ms'] = Variable<int>(lastAccessedAtMs);
    }
    return map;
  }

  AttachmentsCompanion toCompanion(bool nullToAbsent) {
    return AttachmentsCompanion(
      attachmentId: Value(attachmentId),
      contentHash: Value(contentHash),
      byteLength: Value(byteLength),
      mediaType: Value(mediaType),
      localState: Value(localState),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      createdAtMs: Value(createdAtMs),
      lastAccessedAtMs: lastAccessedAtMs == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAccessedAtMs),
    );
  }

  factory Attachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Attachment(
      attachmentId: serializer.fromJson<String>(json['attachment_id']),
      contentHash: serializer.fromJson<String>(json['content_hash']),
      byteLength: serializer.fromJson<int>(json['byte_length']),
      mediaType: serializer.fromJson<String>(json['media_type']),
      localState: serializer.fromJson<String>(json['local_state']),
      localPath: serializer.fromJson<String?>(json['local_path']),
      createdAtMs: serializer.fromJson<int>(json['created_at_ms']),
      lastAccessedAtMs: serializer.fromJson<int?>(json['last_accessed_at_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'attachment_id': serializer.toJson<String>(attachmentId),
      'content_hash': serializer.toJson<String>(contentHash),
      'byte_length': serializer.toJson<int>(byteLength),
      'media_type': serializer.toJson<String>(mediaType),
      'local_state': serializer.toJson<String>(localState),
      'local_path': serializer.toJson<String?>(localPath),
      'created_at_ms': serializer.toJson<int>(createdAtMs),
      'last_accessed_at_ms': serializer.toJson<int?>(lastAccessedAtMs),
    };
  }

  Attachment copyWith({
    String? attachmentId,
    String? contentHash,
    int? byteLength,
    String? mediaType,
    String? localState,
    Value<String?> localPath = const Value.absent(),
    int? createdAtMs,
    Value<int?> lastAccessedAtMs = const Value.absent(),
  }) => Attachment(
    attachmentId: attachmentId ?? this.attachmentId,
    contentHash: contentHash ?? this.contentHash,
    byteLength: byteLength ?? this.byteLength,
    mediaType: mediaType ?? this.mediaType,
    localState: localState ?? this.localState,
    localPath: localPath.present ? localPath.value : this.localPath,
    createdAtMs: createdAtMs ?? this.createdAtMs,
    lastAccessedAtMs: lastAccessedAtMs.present
        ? lastAccessedAtMs.value
        : this.lastAccessedAtMs,
  );
  Attachment copyWithCompanion(AttachmentsCompanion data) {
    return Attachment(
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      byteLength: data.byteLength.present
          ? data.byteLength.value
          : this.byteLength,
      mediaType: data.mediaType.present ? data.mediaType.value : this.mediaType,
      localState: data.localState.present
          ? data.localState.value
          : this.localState,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      createdAtMs: data.createdAtMs.present
          ? data.createdAtMs.value
          : this.createdAtMs,
      lastAccessedAtMs: data.lastAccessedAtMs.present
          ? data.lastAccessedAtMs.value
          : this.lastAccessedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Attachment(')
          ..write('attachmentId: $attachmentId, ')
          ..write('contentHash: $contentHash, ')
          ..write('byteLength: $byteLength, ')
          ..write('mediaType: $mediaType, ')
          ..write('localState: $localState, ')
          ..write('localPath: $localPath, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('lastAccessedAtMs: $lastAccessedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    attachmentId,
    contentHash,
    byteLength,
    mediaType,
    localState,
    localPath,
    createdAtMs,
    lastAccessedAtMs,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Attachment &&
          other.attachmentId == this.attachmentId &&
          other.contentHash == this.contentHash &&
          other.byteLength == this.byteLength &&
          other.mediaType == this.mediaType &&
          other.localState == this.localState &&
          other.localPath == this.localPath &&
          other.createdAtMs == this.createdAtMs &&
          other.lastAccessedAtMs == this.lastAccessedAtMs);
}

class AttachmentsCompanion extends UpdateCompanion<Attachment> {
  final Value<String> attachmentId;
  final Value<String> contentHash;
  final Value<int> byteLength;
  final Value<String> mediaType;
  final Value<String> localState;
  final Value<String?> localPath;
  final Value<int> createdAtMs;
  final Value<int?> lastAccessedAtMs;
  final Value<int> rowid;
  const AttachmentsCompanion({
    this.attachmentId = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.byteLength = const Value.absent(),
    this.mediaType = const Value.absent(),
    this.localState = const Value.absent(),
    this.localPath = const Value.absent(),
    this.createdAtMs = const Value.absent(),
    this.lastAccessedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AttachmentsCompanion.insert({
    required String attachmentId,
    required String contentHash,
    required int byteLength,
    required String mediaType,
    required String localState,
    this.localPath = const Value.absent(),
    required int createdAtMs,
    this.lastAccessedAtMs = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : attachmentId = Value(attachmentId),
       contentHash = Value(contentHash),
       byteLength = Value(byteLength),
       mediaType = Value(mediaType),
       localState = Value(localState),
       createdAtMs = Value(createdAtMs);
  static Insertable<Attachment> custom({
    Expression<String>? attachmentId,
    Expression<String>? contentHash,
    Expression<int>? byteLength,
    Expression<String>? mediaType,
    Expression<String>? localState,
    Expression<String>? localPath,
    Expression<int>? createdAtMs,
    Expression<int>? lastAccessedAtMs,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (contentHash != null) 'content_hash': contentHash,
      if (byteLength != null) 'byte_length': byteLength,
      if (mediaType != null) 'media_type': mediaType,
      if (localState != null) 'local_state': localState,
      if (localPath != null) 'local_path': localPath,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
      if (lastAccessedAtMs != null) 'last_accessed_at_ms': lastAccessedAtMs,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AttachmentsCompanion copyWith({
    Value<String>? attachmentId,
    Value<String>? contentHash,
    Value<int>? byteLength,
    Value<String>? mediaType,
    Value<String>? localState,
    Value<String?>? localPath,
    Value<int>? createdAtMs,
    Value<int?>? lastAccessedAtMs,
    Value<int>? rowid,
  }) {
    return AttachmentsCompanion(
      attachmentId: attachmentId ?? this.attachmentId,
      contentHash: contentHash ?? this.contentHash,
      byteLength: byteLength ?? this.byteLength,
      mediaType: mediaType ?? this.mediaType,
      localState: localState ?? this.localState,
      localPath: localPath ?? this.localPath,
      createdAtMs: createdAtMs ?? this.createdAtMs,
      lastAccessedAtMs: lastAccessedAtMs ?? this.lastAccessedAtMs,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (attachmentId.present) {
      map['attachment_id'] = Variable<String>(attachmentId.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (byteLength.present) {
      map['byte_length'] = Variable<int>(byteLength.value);
    }
    if (mediaType.present) {
      map['media_type'] = Variable<String>(mediaType.value);
    }
    if (localState.present) {
      map['local_state'] = Variable<String>(localState.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    if (lastAccessedAtMs.present) {
      map['last_accessed_at_ms'] = Variable<int>(lastAccessedAtMs.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AttachmentsCompanion(')
          ..write('attachmentId: $attachmentId, ')
          ..write('contentHash: $contentHash, ')
          ..write('byteLength: $byteLength, ')
          ..write('mediaType: $mediaType, ')
          ..write('localState: $localState, ')
          ..write('localPath: $localPath, ')
          ..write('createdAtMs: $createdAtMs, ')
          ..write('lastAccessedAtMs: $lastAccessedAtMs, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class NoteAttachments extends Table
    with TableInfo<NoteAttachments, NoteAttachment> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  NoteAttachments(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  static const VerificationMeta _attachmentIdMeta = const VerificationMeta(
    'attachmentId',
  );
  late final GeneratedColumn<String> attachmentId = GeneratedColumn<String>(
    'attachment_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints:
        'NOT NULL REFERENCES attachments(attachment_id)ON DELETE RESTRICT',
  );
  static const VerificationMeta _displayOrderMeta = const VerificationMeta(
    'displayOrder',
  );
  late final GeneratedColumn<int> displayOrder = GeneratedColumn<int>(
    'display_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (display_order >= 0)',
  );
  @override
  List<GeneratedColumn> get $columns => [noteId, attachmentId, displayOrder];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'note_attachments';
  @override
  VerificationContext validateIntegrity(
    Insertable<NoteAttachment> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('attachment_id')) {
      context.handle(
        _attachmentIdMeta,
        attachmentId.isAcceptableOrUnknown(
          data['attachment_id']!,
          _attachmentIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_attachmentIdMeta);
    }
    if (data.containsKey('display_order')) {
      context.handle(
        _displayOrderMeta,
        displayOrder.isAcceptableOrUnknown(
          data['display_order']!,
          _displayOrderMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayOrderMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {noteId, attachmentId};
  @override
  NoteAttachment map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NoteAttachment(
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      attachmentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}attachment_id'],
      )!,
      displayOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}display_order'],
      )!,
    );
  }

  @override
  NoteAttachments createAlias(String alias) {
    return NoteAttachments(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  bool get isStrict => true;
  @override
  List<String> get customConstraints => const [
    'PRIMARY KEY(note_id, attachment_id)',
  ];
  @override
  bool get dontWriteConstraints => true;
}

class NoteAttachment extends DataClass implements Insertable<NoteAttachment> {
  final String noteId;
  final String attachmentId;
  final int displayOrder;
  const NoteAttachment({
    required this.noteId,
    required this.attachmentId,
    required this.displayOrder,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<String>(noteId);
    map['attachment_id'] = Variable<String>(attachmentId);
    map['display_order'] = Variable<int>(displayOrder);
    return map;
  }

  NoteAttachmentsCompanion toCompanion(bool nullToAbsent) {
    return NoteAttachmentsCompanion(
      noteId: Value(noteId),
      attachmentId: Value(attachmentId),
      displayOrder: Value(displayOrder),
    );
  }

  factory NoteAttachment.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NoteAttachment(
      noteId: serializer.fromJson<String>(json['note_id']),
      attachmentId: serializer.fromJson<String>(json['attachment_id']),
      displayOrder: serializer.fromJson<int>(json['display_order']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'note_id': serializer.toJson<String>(noteId),
      'attachment_id': serializer.toJson<String>(attachmentId),
      'display_order': serializer.toJson<int>(displayOrder),
    };
  }

  NoteAttachment copyWith({
    String? noteId,
    String? attachmentId,
    int? displayOrder,
  }) => NoteAttachment(
    noteId: noteId ?? this.noteId,
    attachmentId: attachmentId ?? this.attachmentId,
    displayOrder: displayOrder ?? this.displayOrder,
  );
  NoteAttachment copyWithCompanion(NoteAttachmentsCompanion data) {
    return NoteAttachment(
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      attachmentId: data.attachmentId.present
          ? data.attachmentId.value
          : this.attachmentId,
      displayOrder: data.displayOrder.present
          ? data.displayOrder.value
          : this.displayOrder,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NoteAttachment(')
          ..write('noteId: $noteId, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('displayOrder: $displayOrder')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(noteId, attachmentId, displayOrder);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NoteAttachment &&
          other.noteId == this.noteId &&
          other.attachmentId == this.attachmentId &&
          other.displayOrder == this.displayOrder);
}

class NoteAttachmentsCompanion extends UpdateCompanion<NoteAttachment> {
  final Value<String> noteId;
  final Value<String> attachmentId;
  final Value<int> displayOrder;
  const NoteAttachmentsCompanion({
    this.noteId = const Value.absent(),
    this.attachmentId = const Value.absent(),
    this.displayOrder = const Value.absent(),
  });
  NoteAttachmentsCompanion.insert({
    required String noteId,
    required String attachmentId,
    required int displayOrder,
  }) : noteId = Value(noteId),
       attachmentId = Value(attachmentId),
       displayOrder = Value(displayOrder);
  static Insertable<NoteAttachment> custom({
    Expression<String>? noteId,
    Expression<String>? attachmentId,
    Expression<int>? displayOrder,
  }) {
    return RawValuesInsertable({
      if (noteId != null) 'note_id': noteId,
      if (attachmentId != null) 'attachment_id': attachmentId,
      if (displayOrder != null) 'display_order': displayOrder,
    });
  }

  NoteAttachmentsCompanion copyWith({
    Value<String>? noteId,
    Value<String>? attachmentId,
    Value<int>? displayOrder,
  }) {
    return NoteAttachmentsCompanion(
      noteId: noteId ?? this.noteId,
      attachmentId: attachmentId ?? this.attachmentId,
      displayOrder: displayOrder ?? this.displayOrder,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (attachmentId.present) {
      map['attachment_id'] = Variable<String>(attachmentId.value);
    }
    if (displayOrder.present) {
      map['display_order'] = Variable<int>(displayOrder.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NoteAttachmentsCompanion(')
          ..write('noteId: $noteId, ')
          ..write('attachmentId: $attachmentId, ')
          ..write('displayOrder: $displayOrder')
          ..write(')'))
        .toString();
  }
}

class Settings extends Table with TableInfo<Settings, Setting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  Settings(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _settingKeyMeta = const VerificationMeta(
    'settingKey',
  );
  late final GeneratedColumn<String> settingKey = GeneratedColumn<String>(
    'setting_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'PRIMARY KEY',
  );
  static const VerificationMeta _valueJsonMeta = const VerificationMeta(
    'valueJson',
  );
  late final GeneratedColumn<String> valueJson = GeneratedColumn<String>(
    'value_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL CHECK (json_valid(value_json))',
  );
  static const VerificationMeta _updatedAtMsMeta = const VerificationMeta(
    'updatedAtMs',
  );
  late final GeneratedColumn<int> updatedAtMs = GeneratedColumn<int>(
    'updated_at_ms',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    $customConstraints: 'NOT NULL',
  );
  @override
  List<GeneratedColumn> get $columns => [settingKey, valueJson, updatedAtMs];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<Setting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('setting_key')) {
      context.handle(
        _settingKeyMeta,
        settingKey.isAcceptableOrUnknown(data['setting_key']!, _settingKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_settingKeyMeta);
    }
    if (data.containsKey('value_json')) {
      context.handle(
        _valueJsonMeta,
        valueJson.isAcceptableOrUnknown(data['value_json']!, _valueJsonMeta),
      );
    } else if (isInserting) {
      context.missing(_valueJsonMeta);
    }
    if (data.containsKey('updated_at_ms')) {
      context.handle(
        _updatedAtMsMeta,
        updatedAtMs.isAcceptableOrUnknown(
          data['updated_at_ms']!,
          _updatedAtMsMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {settingKey};
  @override
  Setting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Setting(
      settingKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}setting_key'],
      )!,
      valueJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_json'],
      )!,
      updatedAtMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_ms'],
      )!,
    );
  }

  @override
  Settings createAlias(String alias) {
    return Settings(attachedDatabase, alias);
  }

  @override
  bool get withoutRowId => true;
  @override
  bool get isStrict => true;
  @override
  bool get dontWriteConstraints => true;
}

class Setting extends DataClass implements Insertable<Setting> {
  final String settingKey;
  final String valueJson;
  final int updatedAtMs;
  const Setting({
    required this.settingKey,
    required this.valueJson,
    required this.updatedAtMs,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['setting_key'] = Variable<String>(settingKey);
    map['value_json'] = Variable<String>(valueJson);
    map['updated_at_ms'] = Variable<int>(updatedAtMs);
    return map;
  }

  SettingsCompanion toCompanion(bool nullToAbsent) {
    return SettingsCompanion(
      settingKey: Value(settingKey),
      valueJson: Value(valueJson),
      updatedAtMs: Value(updatedAtMs),
    );
  }

  factory Setting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Setting(
      settingKey: serializer.fromJson<String>(json['setting_key']),
      valueJson: serializer.fromJson<String>(json['value_json']),
      updatedAtMs: serializer.fromJson<int>(json['updated_at_ms']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'setting_key': serializer.toJson<String>(settingKey),
      'value_json': serializer.toJson<String>(valueJson),
      'updated_at_ms': serializer.toJson<int>(updatedAtMs),
    };
  }

  Setting copyWith({String? settingKey, String? valueJson, int? updatedAtMs}) =>
      Setting(
        settingKey: settingKey ?? this.settingKey,
        valueJson: valueJson ?? this.valueJson,
        updatedAtMs: updatedAtMs ?? this.updatedAtMs,
      );
  Setting copyWithCompanion(SettingsCompanion data) {
    return Setting(
      settingKey: data.settingKey.present
          ? data.settingKey.value
          : this.settingKey,
      valueJson: data.valueJson.present ? data.valueJson.value : this.valueJson,
      updatedAtMs: data.updatedAtMs.present
          ? data.updatedAtMs.value
          : this.updatedAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Setting(')
          ..write('settingKey: $settingKey, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(settingKey, valueJson, updatedAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Setting &&
          other.settingKey == this.settingKey &&
          other.valueJson == this.valueJson &&
          other.updatedAtMs == this.updatedAtMs);
}

class SettingsCompanion extends UpdateCompanion<Setting> {
  final Value<String> settingKey;
  final Value<String> valueJson;
  final Value<int> updatedAtMs;
  const SettingsCompanion({
    this.settingKey = const Value.absent(),
    this.valueJson = const Value.absent(),
    this.updatedAtMs = const Value.absent(),
  });
  SettingsCompanion.insert({
    required String settingKey,
    required String valueJson,
    required int updatedAtMs,
  }) : settingKey = Value(settingKey),
       valueJson = Value(valueJson),
       updatedAtMs = Value(updatedAtMs);
  static Insertable<Setting> custom({
    Expression<String>? settingKey,
    Expression<String>? valueJson,
    Expression<int>? updatedAtMs,
  }) {
    return RawValuesInsertable({
      if (settingKey != null) 'setting_key': settingKey,
      if (valueJson != null) 'value_json': valueJson,
      if (updatedAtMs != null) 'updated_at_ms': updatedAtMs,
    });
  }

  SettingsCompanion copyWith({
    Value<String>? settingKey,
    Value<String>? valueJson,
    Value<int>? updatedAtMs,
  }) {
    return SettingsCompanion(
      settingKey: settingKey ?? this.settingKey,
      valueJson: valueJson ?? this.valueJson,
      updatedAtMs: updatedAtMs ?? this.updatedAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (settingKey.present) {
      map['setting_key'] = Variable<String>(settingKey.value);
    }
    if (valueJson.present) {
      map['value_json'] = Variable<String>(valueJson.value);
    }
    if (updatedAtMs.present) {
      map['updated_at_ms'] = Variable<int>(updatedAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsCompanion(')
          ..write('settingKey: $settingKey, ')
          ..write('valueJson: $valueJson, ')
          ..write('updatedAtMs: $updatedAtMs')
          ..write(')'))
        .toString();
  }
}

abstract class _$MiaoNotesDatabase extends GeneratedDatabase {
  _$MiaoNotesDatabase(QueryExecutor e) : super(e);
  late final VaultState vaultState = VaultState(this);
  late final Devices devices = Devices(this);
  late final Notes notes = Notes(this);
  late final Index notesRecentIdx = Index(
    'notes_recent_idx',
    'CREATE INDEX notes_recent_idx ON notes (is_deleted, updated_at_ms DESC, note_id)',
  );
  late final Index notesDirtyIdx = Index(
    'notes_dirty_idx',
    'CREATE INDEX notes_dirty_idx ON notes (updated_at_ms) WHERE dirty = 1',
  );
  late final NotesFts notesFts = NotesFts(this);
  late final Trigger notesFtsInsert = Trigger(
    'CREATE TRIGGER notes_fts_insert AFTER INSERT ON notes WHEN new.is_deleted = 0 BEGIN INSERT INTO notes_fts (note_id, title, body_text, tags_text) VALUES (new.note_id, new.title, new.body_text, new.tags_text);END',
    'notes_fts_insert',
  );
  late final Trigger notesFtsUpdate = Trigger(
    'CREATE TRIGGER notes_fts_update AFTER UPDATE OF title, body_text, tags_text, is_deleted ON notes BEGIN DELETE FROM notes_fts WHERE note_id = old.note_id;INSERT INTO notes_fts (note_id, title, body_text, tags_text) SELECT new.note_id, new.title, new.body_text, new.tags_text WHERE new.is_deleted = 0;END',
    'notes_fts_update',
  );
  late final Trigger notesFtsDelete = Trigger(
    'CREATE TRIGGER notes_fts_delete AFTER DELETE ON notes BEGIN DELETE FROM notes_fts WHERE note_id = old.note_id;END',
    'notes_fts_delete',
  );
  late final Revisions revisions = Revisions(this);
  late final Index revisionsNoteTimeIdx = Index(
    'revisions_note_time_idx',
    'CREATE INDEX revisions_note_time_idx ON revisions (note_id, created_at_ms, revision_id)',
  );
  late final Index revisionsDeviceIdx = Index(
    'revisions_device_idx',
    'CREATE INDEX revisions_device_idx ON revisions (device_id, created_at_ms)',
  );
  late final RevisionParents revisionParents = RevisionParents(this);
  late final Index revisionParentsParentIdx = Index(
    'revision_parents_parent_idx',
    'CREATE INDEX revision_parents_parent_idx ON revision_parents (parent_revision_id, revision_id)',
  );
  late final NoteHeads noteHeads = NoteHeads(this);
  late final SyncEvents syncEvents = SyncEvents(this);
  late final Index syncEventsOrderIdx = Index(
    'sync_events_order_idx',
    'CREATE INDEX sync_events_order_idx ON sync_events (device_id, sequence)',
  );
  late final SyncOutbox syncOutbox = SyncOutbox(this);
  late final Index syncOutboxReadyIdx = Index(
    'sync_outbox_ready_idx',
    'CREATE INDEX sync_outbox_ready_idx ON sync_outbox (next_attempt_at_ms, outbox_id)',
  );
  late final SyncCursors syncCursors = SyncCursors(this);
  late final Conflicts conflicts = Conflicts(this);
  late final Index conflictsOpenIdx = Index(
    'conflicts_open_idx',
    'CREATE INDEX conflicts_open_idx ON conflicts (created_at_ms DESC) WHERE status = \'open\'',
  );
  late final Attachments attachments = Attachments(this);
  late final NoteAttachments noteAttachments = NoteAttachments(this);
  late final Settings settings = Settings(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    vaultState,
    devices,
    notes,
    notesRecentIdx,
    notesDirtyIdx,
    notesFts,
    notesFtsInsert,
    notesFtsUpdate,
    notesFtsDelete,
    revisions,
    revisionsNoteTimeIdx,
    revisionsDeviceIdx,
    revisionParents,
    revisionParentsParentIdx,
    noteHeads,
    syncEvents,
    syncEventsOrderIdx,
    syncOutbox,
    syncOutboxReadyIdx,
    syncCursors,
    conflicts,
    conflictsOpenIdx,
    attachments,
    noteAttachments,
    settings,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'notes',
        limitUpdateKind: UpdateKind.insert,
      ),
      result: [TableUpdate('notes_fts', kind: UpdateKind.insert)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'notes',
        limitUpdateKind: UpdateKind.update,
      ),
      result: [
        TableUpdate('notes_fts', kind: UpdateKind.delete),
        TableUpdate('notes_fts', kind: UpdateKind.insert),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'notes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('notes_fts', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'revisions',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('revision_parents', kind: UpdateKind.delete)],
    ),
  ]);
}
