// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $SyncOutboxTableTable extends SyncOutboxTable
    with TableInfo<$SyncOutboxTableTable, SyncOutboxTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOutboxTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadJsonMeta = const VerificationMeta(
    'payloadJson',
  );
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
    'payload_json',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lastErrorMeta = const VerificationMeta(
    'lastError',
  );
  @override
  late final GeneratedColumn<String> lastError = GeneratedColumn<String>(
    'last_error',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    action,
    payloadJson,
    createdAt,
    retryCount,
    lastError,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_outbox_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOutboxTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
        _payloadJsonMeta,
        payloadJson.isAcceptableOrUnknown(
          data['payload_json']!,
          _payloadJsonMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('last_error')) {
      context.handle(
        _lastErrorMeta,
        lastError.isAcceptableOrUnknown(data['last_error']!, _lastErrorMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOutboxTableData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOutboxTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      payloadJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload_json'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      lastError: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}last_error'],
      ),
    );
  }

  @override
  $SyncOutboxTableTable createAlias(String alias) {
    return $SyncOutboxTableTable(attachedDatabase, alias);
  }
}

class SyncOutboxTableData extends DataClass
    implements Insertable<SyncOutboxTableData> {
  final String id;
  final String entityType;
  final String entityId;
  final String action;
  final String payloadJson;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;
  const SyncOutboxTableData({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.payloadJson,
    required this.createdAt,
    required this.retryCount,
    this.lastError,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['action'] = Variable<String>(action);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['retry_count'] = Variable<int>(retryCount);
    if (!nullToAbsent || lastError != null) {
      map['last_error'] = Variable<String>(lastError);
    }
    return map;
  }

  SyncOutboxTableCompanion toCompanion(bool nullToAbsent) {
    return SyncOutboxTableCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      action: Value(action),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      retryCount: Value(retryCount),
      lastError: lastError == null && nullToAbsent
          ? const Value.absent()
          : Value(lastError),
    );
  }

  factory SyncOutboxTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOutboxTableData(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      action: serializer.fromJson<String>(json['action']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      lastError: serializer.fromJson<String?>(json['lastError']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'action': serializer.toJson<String>(action),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'retryCount': serializer.toJson<int>(retryCount),
      'lastError': serializer.toJson<String?>(lastError),
    };
  }

  SyncOutboxTableData copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? action,
    String? payloadJson,
    DateTime? createdAt,
    int? retryCount,
    Value<String?> lastError = const Value.absent(),
  }) => SyncOutboxTableData(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    action: action ?? this.action,
    payloadJson: payloadJson ?? this.payloadJson,
    createdAt: createdAt ?? this.createdAt,
    retryCount: retryCount ?? this.retryCount,
    lastError: lastError.present ? lastError.value : this.lastError,
  );
  SyncOutboxTableData copyWithCompanion(SyncOutboxTableCompanion data) {
    return SyncOutboxTableData(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      action: data.action.present ? data.action.value : this.action,
      payloadJson: data.payloadJson.present
          ? data.payloadJson.value
          : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      lastError: data.lastError.present ? data.lastError.value : this.lastError,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxTableData(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    entityType,
    entityId,
    action,
    payloadJson,
    createdAt,
    retryCount,
    lastError,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOutboxTableData &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.action == this.action &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.retryCount == this.retryCount &&
          other.lastError == this.lastError);
}

class SyncOutboxTableCompanion extends UpdateCompanion<SyncOutboxTableData> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> action;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<int> retryCount;
  final Value<String?> lastError;
  final Value<int> rowid;
  const SyncOutboxTableCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.action = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOutboxTableCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    required String action,
    required String payloadJson,
    this.createdAt = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.lastError = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       action = Value(action),
       payloadJson = Value(payloadJson);
  static Insertable<SyncOutboxTableData> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? action,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<int>? retryCount,
    Expression<String>? lastError,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (action != null) 'action': action,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (retryCount != null) 'retry_count': retryCount,
      if (lastError != null) 'last_error': lastError,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOutboxTableCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? action,
    Value<String>? payloadJson,
    Value<DateTime>? createdAt,
    Value<int>? retryCount,
    Value<String?>? lastError,
    Value<int>? rowid,
  }) {
    return SyncOutboxTableCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (lastError.present) {
      map['last_error'] = Variable<String>(lastError.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOutboxTableCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('action: $action, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('retryCount: $retryCount, ')
          ..write('lastError: $lastError, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalAppMetadataTableTable extends LocalAppMetadataTable
    with TableInfo<$LocalAppMetadataTableTable, LocalAppMetadataTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalAppMetadataTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_app_metadata_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalAppMetadataTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  LocalAppMetadataTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalAppMetadataTableData(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalAppMetadataTableTable createAlias(String alias) {
    return $LocalAppMetadataTableTable(attachedDatabase, alias);
  }
}

class LocalAppMetadataTableData extends DataClass
    implements Insertable<LocalAppMetadataTableData> {
  final String key;
  final String value;
  final DateTime updatedAt;
  const LocalAppMetadataTableData({
    required this.key,
    required this.value,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalAppMetadataTableCompanion toCompanion(bool nullToAbsent) {
    return LocalAppMetadataTableCompanion(
      key: Value(key),
      value: Value(value),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalAppMetadataTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalAppMetadataTableData(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalAppMetadataTableData copyWith({
    String? key,
    String? value,
    DateTime? updatedAt,
  }) => LocalAppMetadataTableData(
    key: key ?? this.key,
    value: value ?? this.value,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalAppMetadataTableData copyWithCompanion(
    LocalAppMetadataTableCompanion data,
  ) {
    return LocalAppMetadataTableData(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalAppMetadataTableData(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalAppMetadataTableData &&
          other.key == this.key &&
          other.value == this.value &&
          other.updatedAt == this.updatedAt);
}

class LocalAppMetadataTableCompanion
    extends UpdateCompanion<LocalAppMetadataTableData> {
  final Value<String> key;
  final Value<String> value;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalAppMetadataTableCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalAppMetadataTableCompanion.insert({
    required String key,
    required String value,
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<LocalAppMetadataTableData> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalAppMetadataTableCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalAppMetadataTableCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalAppMetadataTableCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMeasurementsTableTable extends LocalMeasurementsTable
    with TableInfo<$LocalMeasurementsTableTable, LocalMeasurementsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMeasurementsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _heartRateBpmMeta = const VerificationMeta(
    'heartRateBpm',
  );
  @override
  late final GeneratedColumn<double> heartRateBpm = GeneratedColumn<double>(
    'heart_rate_bpm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _systolicMmhgMeta = const VerificationMeta(
    'systolicMmhg',
  );
  @override
  late final GeneratedColumn<double> systolicMmhg = GeneratedColumn<double>(
    'systolic_mmhg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diastolicMmhgMeta = const VerificationMeta(
    'diastolicMmhg',
  );
  @override
  late final GeneratedColumn<double> diastolicMmhg = GeneratedColumn<double>(
    'diastolic_mmhg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _pulseBpmMeta = const VerificationMeta(
    'pulseBpm',
  );
  @override
  late final GeneratedColumn<double> pulseBpm = GeneratedColumn<double>(
    'pulse_bpm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperatureCelsiusMeta =
      const VerificationMeta('temperatureCelsius');
  @override
  late final GeneratedColumn<double> temperatureCelsius =
      GeneratedColumn<double>(
        'temperature_celsius',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _glucoseMmolLMeta = const VerificationMeta(
    'glucoseMmolL',
  );
  @override
  late final GeneratedColumn<double> glucoseMmolL = GeneratedColumn<double>(
    'glucose_mmol_l',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manual'),
  );
  static const VerificationMeta _provenanceMeta = const VerificationMeta(
    'provenance',
  );
  @override
  late final GeneratedColumn<String> provenance = GeneratedColumn<String>(
    'provenance',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('manually_entered'),
  );
  static const VerificationMeta _qualityJsonMeta = const VerificationMeta(
    'qualityJson',
  );
  @override
  late final GeneratedColumn<String> qualityJson = GeneratedColumn<String>(
    'quality_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _recordedUtcOffsetMeta = const VerificationMeta(
    'recordedUtcOffset',
  );
  @override
  late final GeneratedColumn<int> recordedUtcOffset = GeneratedColumn<int>(
    'recorded_utc_offset',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dailyCheckIdMeta = const VerificationMeta(
    'dailyCheckId',
  );
  @override
  late final GeneratedColumn<String> dailyCheckId = GeneratedColumn<String>(
    'daily_check_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    type,
    heartRateBpm,
    systolicMmhg,
    diastolicMmhg,
    pulseBpm,
    temperatureCelsius,
    weightKg,
    glucoseMmolL,
    source,
    provenance,
    qualityJson,
    recordedAt,
    recordedUtcOffset,
    notes,
    dailyCheckId,
    isDeleted,
    syncStatus,
    version,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_measurements_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMeasurementsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('heart_rate_bpm')) {
      context.handle(
        _heartRateBpmMeta,
        heartRateBpm.isAcceptableOrUnknown(
          data['heart_rate_bpm']!,
          _heartRateBpmMeta,
        ),
      );
    }
    if (data.containsKey('systolic_mmhg')) {
      context.handle(
        _systolicMmhgMeta,
        systolicMmhg.isAcceptableOrUnknown(
          data['systolic_mmhg']!,
          _systolicMmhgMeta,
        ),
      );
    }
    if (data.containsKey('diastolic_mmhg')) {
      context.handle(
        _diastolicMmhgMeta,
        diastolicMmhg.isAcceptableOrUnknown(
          data['diastolic_mmhg']!,
          _diastolicMmhgMeta,
        ),
      );
    }
    if (data.containsKey('pulse_bpm')) {
      context.handle(
        _pulseBpmMeta,
        pulseBpm.isAcceptableOrUnknown(data['pulse_bpm']!, _pulseBpmMeta),
      );
    }
    if (data.containsKey('temperature_celsius')) {
      context.handle(
        _temperatureCelsiusMeta,
        temperatureCelsius.isAcceptableOrUnknown(
          data['temperature_celsius']!,
          _temperatureCelsiusMeta,
        ),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('glucose_mmol_l')) {
      context.handle(
        _glucoseMmolLMeta,
        glucoseMmolL.isAcceptableOrUnknown(
          data['glucose_mmol_l']!,
          _glucoseMmolLMeta,
        ),
      );
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    }
    if (data.containsKey('provenance')) {
      context.handle(
        _provenanceMeta,
        provenance.isAcceptableOrUnknown(data['provenance']!, _provenanceMeta),
      );
    }
    if (data.containsKey('quality_json')) {
      context.handle(
        _qualityJsonMeta,
        qualityJson.isAcceptableOrUnknown(
          data['quality_json']!,
          _qualityJsonMeta,
        ),
      );
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('recorded_utc_offset')) {
      context.handle(
        _recordedUtcOffsetMeta,
        recordedUtcOffset.isAcceptableOrUnknown(
          data['recorded_utc_offset']!,
          _recordedUtcOffsetMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('daily_check_id')) {
      context.handle(
        _dailyCheckIdMeta,
        dailyCheckId.isAcceptableOrUnknown(
          data['daily_check_id']!,
          _dailyCheckIdMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMeasurementsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMeasurementsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      heartRateBpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heart_rate_bpm'],
      ),
      systolicMmhg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}systolic_mmhg'],
      ),
      diastolicMmhg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}diastolic_mmhg'],
      ),
      pulseBpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}pulse_bpm'],
      ),
      temperatureCelsius: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature_celsius'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      glucoseMmolL: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}glucose_mmol_l'],
      ),
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      provenance: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provenance'],
      )!,
      qualityJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}quality_json'],
      ),
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      )!,
      recordedUtcOffset: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}recorded_utc_offset'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      dailyCheckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}daily_check_id'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalMeasurementsTableTable createAlias(String alias) {
    return $LocalMeasurementsTableTable(attachedDatabase, alias);
  }
}

class LocalMeasurementsTableData extends DataClass
    implements Insertable<LocalMeasurementsTableData> {
  final String id;
  final String profileId;
  final String type;
  final double? heartRateBpm;
  final double? systolicMmhg;
  final double? diastolicMmhg;
  final double? pulseBpm;
  final double? temperatureCelsius;
  final double? weightKg;
  final double? glucoseMmolL;
  final String source;
  final String provenance;
  final String? qualityJson;
  final DateTime recordedAt;
  final int recordedUtcOffset;
  final String? notes;
  final String? dailyCheckId;
  final bool isDeleted;
  final String syncStatus;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalMeasurementsTableData({
    required this.id,
    required this.profileId,
    required this.type,
    this.heartRateBpm,
    this.systolicMmhg,
    this.diastolicMmhg,
    this.pulseBpm,
    this.temperatureCelsius,
    this.weightKg,
    this.glucoseMmolL,
    required this.source,
    required this.provenance,
    this.qualityJson,
    required this.recordedAt,
    required this.recordedUtcOffset,
    this.notes,
    this.dailyCheckId,
    required this.isDeleted,
    required this.syncStatus,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['type'] = Variable<String>(type);
    if (!nullToAbsent || heartRateBpm != null) {
      map['heart_rate_bpm'] = Variable<double>(heartRateBpm);
    }
    if (!nullToAbsent || systolicMmhg != null) {
      map['systolic_mmhg'] = Variable<double>(systolicMmhg);
    }
    if (!nullToAbsent || diastolicMmhg != null) {
      map['diastolic_mmhg'] = Variable<double>(diastolicMmhg);
    }
    if (!nullToAbsent || pulseBpm != null) {
      map['pulse_bpm'] = Variable<double>(pulseBpm);
    }
    if (!nullToAbsent || temperatureCelsius != null) {
      map['temperature_celsius'] = Variable<double>(temperatureCelsius);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || glucoseMmolL != null) {
      map['glucose_mmol_l'] = Variable<double>(glucoseMmolL);
    }
    map['source'] = Variable<String>(source);
    map['provenance'] = Variable<String>(provenance);
    if (!nullToAbsent || qualityJson != null) {
      map['quality_json'] = Variable<String>(qualityJson);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['recorded_utc_offset'] = Variable<int>(recordedUtcOffset);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || dailyCheckId != null) {
      map['daily_check_id'] = Variable<String>(dailyCheckId);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['sync_status'] = Variable<String>(syncStatus);
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalMeasurementsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalMeasurementsTableCompanion(
      id: Value(id),
      profileId: Value(profileId),
      type: Value(type),
      heartRateBpm: heartRateBpm == null && nullToAbsent
          ? const Value.absent()
          : Value(heartRateBpm),
      systolicMmhg: systolicMmhg == null && nullToAbsent
          ? const Value.absent()
          : Value(systolicMmhg),
      diastolicMmhg: diastolicMmhg == null && nullToAbsent
          ? const Value.absent()
          : Value(diastolicMmhg),
      pulseBpm: pulseBpm == null && nullToAbsent
          ? const Value.absent()
          : Value(pulseBpm),
      temperatureCelsius: temperatureCelsius == null && nullToAbsent
          ? const Value.absent()
          : Value(temperatureCelsius),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      glucoseMmolL: glucoseMmolL == null && nullToAbsent
          ? const Value.absent()
          : Value(glucoseMmolL),
      source: Value(source),
      provenance: Value(provenance),
      qualityJson: qualityJson == null && nullToAbsent
          ? const Value.absent()
          : Value(qualityJson),
      recordedAt: Value(recordedAt),
      recordedUtcOffset: Value(recordedUtcOffset),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      dailyCheckId: dailyCheckId == null && nullToAbsent
          ? const Value.absent()
          : Value(dailyCheckId),
      isDeleted: Value(isDeleted),
      syncStatus: Value(syncStatus),
      version: Value(version),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalMeasurementsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMeasurementsTableData(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      type: serializer.fromJson<String>(json['type']),
      heartRateBpm: serializer.fromJson<double?>(json['heartRateBpm']),
      systolicMmhg: serializer.fromJson<double?>(json['systolicMmhg']),
      diastolicMmhg: serializer.fromJson<double?>(json['diastolicMmhg']),
      pulseBpm: serializer.fromJson<double?>(json['pulseBpm']),
      temperatureCelsius: serializer.fromJson<double?>(
        json['temperatureCelsius'],
      ),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      glucoseMmolL: serializer.fromJson<double?>(json['glucoseMmolL']),
      source: serializer.fromJson<String>(json['source']),
      provenance: serializer.fromJson<String>(json['provenance']),
      qualityJson: serializer.fromJson<String?>(json['qualityJson']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      recordedUtcOffset: serializer.fromJson<int>(json['recordedUtcOffset']),
      notes: serializer.fromJson<String?>(json['notes']),
      dailyCheckId: serializer.fromJson<String?>(json['dailyCheckId']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'type': serializer.toJson<String>(type),
      'heartRateBpm': serializer.toJson<double?>(heartRateBpm),
      'systolicMmhg': serializer.toJson<double?>(systolicMmhg),
      'diastolicMmhg': serializer.toJson<double?>(diastolicMmhg),
      'pulseBpm': serializer.toJson<double?>(pulseBpm),
      'temperatureCelsius': serializer.toJson<double?>(temperatureCelsius),
      'weightKg': serializer.toJson<double?>(weightKg),
      'glucoseMmolL': serializer.toJson<double?>(glucoseMmolL),
      'source': serializer.toJson<String>(source),
      'provenance': serializer.toJson<String>(provenance),
      'qualityJson': serializer.toJson<String?>(qualityJson),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'recordedUtcOffset': serializer.toJson<int>(recordedUtcOffset),
      'notes': serializer.toJson<String?>(notes),
      'dailyCheckId': serializer.toJson<String?>(dailyCheckId),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalMeasurementsTableData copyWith({
    String? id,
    String? profileId,
    String? type,
    Value<double?> heartRateBpm = const Value.absent(),
    Value<double?> systolicMmhg = const Value.absent(),
    Value<double?> diastolicMmhg = const Value.absent(),
    Value<double?> pulseBpm = const Value.absent(),
    Value<double?> temperatureCelsius = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<double?> glucoseMmolL = const Value.absent(),
    String? source,
    String? provenance,
    Value<String?> qualityJson = const Value.absent(),
    DateTime? recordedAt,
    int? recordedUtcOffset,
    Value<String?> notes = const Value.absent(),
    Value<String?> dailyCheckId = const Value.absent(),
    bool? isDeleted,
    String? syncStatus,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalMeasurementsTableData(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    type: type ?? this.type,
    heartRateBpm: heartRateBpm.present ? heartRateBpm.value : this.heartRateBpm,
    systolicMmhg: systolicMmhg.present ? systolicMmhg.value : this.systolicMmhg,
    diastolicMmhg: diastolicMmhg.present
        ? diastolicMmhg.value
        : this.diastolicMmhg,
    pulseBpm: pulseBpm.present ? pulseBpm.value : this.pulseBpm,
    temperatureCelsius: temperatureCelsius.present
        ? temperatureCelsius.value
        : this.temperatureCelsius,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    glucoseMmolL: glucoseMmolL.present ? glucoseMmolL.value : this.glucoseMmolL,
    source: source ?? this.source,
    provenance: provenance ?? this.provenance,
    qualityJson: qualityJson.present ? qualityJson.value : this.qualityJson,
    recordedAt: recordedAt ?? this.recordedAt,
    recordedUtcOffset: recordedUtcOffset ?? this.recordedUtcOffset,
    notes: notes.present ? notes.value : this.notes,
    dailyCheckId: dailyCheckId.present ? dailyCheckId.value : this.dailyCheckId,
    isDeleted: isDeleted ?? this.isDeleted,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalMeasurementsTableData copyWithCompanion(
    LocalMeasurementsTableCompanion data,
  ) {
    return LocalMeasurementsTableData(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      type: data.type.present ? data.type.value : this.type,
      heartRateBpm: data.heartRateBpm.present
          ? data.heartRateBpm.value
          : this.heartRateBpm,
      systolicMmhg: data.systolicMmhg.present
          ? data.systolicMmhg.value
          : this.systolicMmhg,
      diastolicMmhg: data.diastolicMmhg.present
          ? data.diastolicMmhg.value
          : this.diastolicMmhg,
      pulseBpm: data.pulseBpm.present ? data.pulseBpm.value : this.pulseBpm,
      temperatureCelsius: data.temperatureCelsius.present
          ? data.temperatureCelsius.value
          : this.temperatureCelsius,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      glucoseMmolL: data.glucoseMmolL.present
          ? data.glucoseMmolL.value
          : this.glucoseMmolL,
      source: data.source.present ? data.source.value : this.source,
      provenance: data.provenance.present
          ? data.provenance.value
          : this.provenance,
      qualityJson: data.qualityJson.present
          ? data.qualityJson.value
          : this.qualityJson,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      recordedUtcOffset: data.recordedUtcOffset.present
          ? data.recordedUtcOffset.value
          : this.recordedUtcOffset,
      notes: data.notes.present ? data.notes.value : this.notes,
      dailyCheckId: data.dailyCheckId.present
          ? data.dailyCheckId.value
          : this.dailyCheckId,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMeasurementsTableData(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('type: $type, ')
          ..write('heartRateBpm: $heartRateBpm, ')
          ..write('systolicMmhg: $systolicMmhg, ')
          ..write('diastolicMmhg: $diastolicMmhg, ')
          ..write('pulseBpm: $pulseBpm, ')
          ..write('temperatureCelsius: $temperatureCelsius, ')
          ..write('weightKg: $weightKg, ')
          ..write('glucoseMmolL: $glucoseMmolL, ')
          ..write('source: $source, ')
          ..write('provenance: $provenance, ')
          ..write('qualityJson: $qualityJson, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('recordedUtcOffset: $recordedUtcOffset, ')
          ..write('notes: $notes, ')
          ..write('dailyCheckId: $dailyCheckId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    id,
    profileId,
    type,
    heartRateBpm,
    systolicMmhg,
    diastolicMmhg,
    pulseBpm,
    temperatureCelsius,
    weightKg,
    glucoseMmolL,
    source,
    provenance,
    qualityJson,
    recordedAt,
    recordedUtcOffset,
    notes,
    dailyCheckId,
    isDeleted,
    syncStatus,
    version,
    createdAt,
    updatedAt,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMeasurementsTableData &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.type == this.type &&
          other.heartRateBpm == this.heartRateBpm &&
          other.systolicMmhg == this.systolicMmhg &&
          other.diastolicMmhg == this.diastolicMmhg &&
          other.pulseBpm == this.pulseBpm &&
          other.temperatureCelsius == this.temperatureCelsius &&
          other.weightKg == this.weightKg &&
          other.glucoseMmolL == this.glucoseMmolL &&
          other.source == this.source &&
          other.provenance == this.provenance &&
          other.qualityJson == this.qualityJson &&
          other.recordedAt == this.recordedAt &&
          other.recordedUtcOffset == this.recordedUtcOffset &&
          other.notes == this.notes &&
          other.dailyCheckId == this.dailyCheckId &&
          other.isDeleted == this.isDeleted &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalMeasurementsTableCompanion
    extends UpdateCompanion<LocalMeasurementsTableData> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> type;
  final Value<double?> heartRateBpm;
  final Value<double?> systolicMmhg;
  final Value<double?> diastolicMmhg;
  final Value<double?> pulseBpm;
  final Value<double?> temperatureCelsius;
  final Value<double?> weightKg;
  final Value<double?> glucoseMmolL;
  final Value<String> source;
  final Value<String> provenance;
  final Value<String?> qualityJson;
  final Value<DateTime> recordedAt;
  final Value<int> recordedUtcOffset;
  final Value<String?> notes;
  final Value<String?> dailyCheckId;
  final Value<bool> isDeleted;
  final Value<String> syncStatus;
  final Value<int> version;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalMeasurementsTableCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.type = const Value.absent(),
    this.heartRateBpm = const Value.absent(),
    this.systolicMmhg = const Value.absent(),
    this.diastolicMmhg = const Value.absent(),
    this.pulseBpm = const Value.absent(),
    this.temperatureCelsius = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.glucoseMmolL = const Value.absent(),
    this.source = const Value.absent(),
    this.provenance = const Value.absent(),
    this.qualityJson = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.recordedUtcOffset = const Value.absent(),
    this.notes = const Value.absent(),
    this.dailyCheckId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMeasurementsTableCompanion.insert({
    required String id,
    required String profileId,
    required String type,
    this.heartRateBpm = const Value.absent(),
    this.systolicMmhg = const Value.absent(),
    this.diastolicMmhg = const Value.absent(),
    this.pulseBpm = const Value.absent(),
    this.temperatureCelsius = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.glucoseMmolL = const Value.absent(),
    this.source = const Value.absent(),
    this.provenance = const Value.absent(),
    this.qualityJson = const Value.absent(),
    required DateTime recordedAt,
    this.recordedUtcOffset = const Value.absent(),
    this.notes = const Value.absent(),
    this.dailyCheckId = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       type = Value(type),
       recordedAt = Value(recordedAt);
  static Insertable<LocalMeasurementsTableData> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? type,
    Expression<double>? heartRateBpm,
    Expression<double>? systolicMmhg,
    Expression<double>? diastolicMmhg,
    Expression<double>? pulseBpm,
    Expression<double>? temperatureCelsius,
    Expression<double>? weightKg,
    Expression<double>? glucoseMmolL,
    Expression<String>? source,
    Expression<String>? provenance,
    Expression<String>? qualityJson,
    Expression<DateTime>? recordedAt,
    Expression<int>? recordedUtcOffset,
    Expression<String>? notes,
    Expression<String>? dailyCheckId,
    Expression<bool>? isDeleted,
    Expression<String>? syncStatus,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (type != null) 'type': type,
      if (heartRateBpm != null) 'heart_rate_bpm': heartRateBpm,
      if (systolicMmhg != null) 'systolic_mmhg': systolicMmhg,
      if (diastolicMmhg != null) 'diastolic_mmhg': diastolicMmhg,
      if (pulseBpm != null) 'pulse_bpm': pulseBpm,
      if (temperatureCelsius != null) 'temperature_celsius': temperatureCelsius,
      if (weightKg != null) 'weight_kg': weightKg,
      if (glucoseMmolL != null) 'glucose_mmol_l': glucoseMmolL,
      if (source != null) 'source': source,
      if (provenance != null) 'provenance': provenance,
      if (qualityJson != null) 'quality_json': qualityJson,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (recordedUtcOffset != null) 'recorded_utc_offset': recordedUtcOffset,
      if (notes != null) 'notes': notes,
      if (dailyCheckId != null) 'daily_check_id': dailyCheckId,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMeasurementsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? type,
    Value<double?>? heartRateBpm,
    Value<double?>? systolicMmhg,
    Value<double?>? diastolicMmhg,
    Value<double?>? pulseBpm,
    Value<double?>? temperatureCelsius,
    Value<double?>? weightKg,
    Value<double?>? glucoseMmolL,
    Value<String>? source,
    Value<String>? provenance,
    Value<String?>? qualityJson,
    Value<DateTime>? recordedAt,
    Value<int>? recordedUtcOffset,
    Value<String?>? notes,
    Value<String?>? dailyCheckId,
    Value<bool>? isDeleted,
    Value<String>? syncStatus,
    Value<int>? version,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalMeasurementsTableCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      type: type ?? this.type,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      systolicMmhg: systolicMmhg ?? this.systolicMmhg,
      diastolicMmhg: diastolicMmhg ?? this.diastolicMmhg,
      pulseBpm: pulseBpm ?? this.pulseBpm,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      weightKg: weightKg ?? this.weightKg,
      glucoseMmolL: glucoseMmolL ?? this.glucoseMmolL,
      source: source ?? this.source,
      provenance: provenance ?? this.provenance,
      qualityJson: qualityJson ?? this.qualityJson,
      recordedAt: recordedAt ?? this.recordedAt,
      recordedUtcOffset: recordedUtcOffset ?? this.recordedUtcOffset,
      notes: notes ?? this.notes,
      dailyCheckId: dailyCheckId ?? this.dailyCheckId,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (heartRateBpm.present) {
      map['heart_rate_bpm'] = Variable<double>(heartRateBpm.value);
    }
    if (systolicMmhg.present) {
      map['systolic_mmhg'] = Variable<double>(systolicMmhg.value);
    }
    if (diastolicMmhg.present) {
      map['diastolic_mmhg'] = Variable<double>(diastolicMmhg.value);
    }
    if (pulseBpm.present) {
      map['pulse_bpm'] = Variable<double>(pulseBpm.value);
    }
    if (temperatureCelsius.present) {
      map['temperature_celsius'] = Variable<double>(temperatureCelsius.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (glucoseMmolL.present) {
      map['glucose_mmol_l'] = Variable<double>(glucoseMmolL.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (provenance.present) {
      map['provenance'] = Variable<String>(provenance.value);
    }
    if (qualityJson.present) {
      map['quality_json'] = Variable<String>(qualityJson.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (recordedUtcOffset.present) {
      map['recorded_utc_offset'] = Variable<int>(recordedUtcOffset.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (dailyCheckId.present) {
      map['daily_check_id'] = Variable<String>(dailyCheckId.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMeasurementsTableCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('type: $type, ')
          ..write('heartRateBpm: $heartRateBpm, ')
          ..write('systolicMmhg: $systolicMmhg, ')
          ..write('diastolicMmhg: $diastolicMmhg, ')
          ..write('pulseBpm: $pulseBpm, ')
          ..write('temperatureCelsius: $temperatureCelsius, ')
          ..write('weightKg: $weightKg, ')
          ..write('glucoseMmolL: $glucoseMmolL, ')
          ..write('source: $source, ')
          ..write('provenance: $provenance, ')
          ..write('qualityJson: $qualityJson, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('recordedUtcOffset: $recordedUtcOffset, ')
          ..write('notes: $notes, ')
          ..write('dailyCheckId: $dailyCheckId, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDailyChecksTableTable extends LocalDailyChecksTable
    with TableInfo<$LocalDailyChecksTableTable, LocalDailyChecksTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDailyChecksTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _checkDateMeta = const VerificationMeta(
    'checkDate',
  );
  @override
  late final GeneratedColumn<DateTime> checkDate = GeneratedColumn<DateTime>(
    'check_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _feelingMeta = const VerificationMeta(
    'feeling',
  );
  @override
  late final GeneratedColumn<String> feeling = GeneratedColumn<String>(
    'feeling',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationStatusMeta = const VerificationMeta(
    'medicationStatus',
  );
  @override
  late final GeneratedColumn<String> medicationStatus = GeneratedColumn<String>(
    'medication_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    checkDate,
    feeling,
    medicationStatus,
    notes,
    isDeleted,
    syncStatus,
    version,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_daily_checks_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDailyChecksTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('check_date')) {
      context.handle(
        _checkDateMeta,
        checkDate.isAcceptableOrUnknown(data['check_date']!, _checkDateMeta),
      );
    } else if (isInserting) {
      context.missing(_checkDateMeta);
    }
    if (data.containsKey('feeling')) {
      context.handle(
        _feelingMeta,
        feeling.isAcceptableOrUnknown(data['feeling']!, _feelingMeta),
      );
    } else if (isInserting) {
      context.missing(_feelingMeta);
    }
    if (data.containsKey('medication_status')) {
      context.handle(
        _medicationStatusMeta,
        medicationStatus.isAcceptableOrUnknown(
          data['medication_status']!,
          _medicationStatusMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationStatusMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDailyChecksTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDailyChecksTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      checkDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}check_date'],
      )!,
      feeling: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feeling'],
      )!,
      medicationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalDailyChecksTableTable createAlias(String alias) {
    return $LocalDailyChecksTableTable(attachedDatabase, alias);
  }
}

class LocalDailyChecksTableData extends DataClass
    implements Insertable<LocalDailyChecksTableData> {
  final String id;
  final String profileId;
  final DateTime checkDate;
  final String feeling;
  final String medicationStatus;
  final String? notes;
  final bool isDeleted;
  final String syncStatus;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalDailyChecksTableData({
    required this.id,
    required this.profileId,
    required this.checkDate,
    required this.feeling,
    required this.medicationStatus,
    this.notes,
    required this.isDeleted,
    required this.syncStatus,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['check_date'] = Variable<DateTime>(checkDate);
    map['feeling'] = Variable<String>(feeling);
    map['medication_status'] = Variable<String>(medicationStatus);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['sync_status'] = Variable<String>(syncStatus);
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalDailyChecksTableCompanion toCompanion(bool nullToAbsent) {
    return LocalDailyChecksTableCompanion(
      id: Value(id),
      profileId: Value(profileId),
      checkDate: Value(checkDate),
      feeling: Value(feeling),
      medicationStatus: Value(medicationStatus),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isDeleted: Value(isDeleted),
      syncStatus: Value(syncStatus),
      version: Value(version),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalDailyChecksTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDailyChecksTableData(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      checkDate: serializer.fromJson<DateTime>(json['checkDate']),
      feeling: serializer.fromJson<String>(json['feeling']),
      medicationStatus: serializer.fromJson<String>(json['medicationStatus']),
      notes: serializer.fromJson<String?>(json['notes']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'checkDate': serializer.toJson<DateTime>(checkDate),
      'feeling': serializer.toJson<String>(feeling),
      'medicationStatus': serializer.toJson<String>(medicationStatus),
      'notes': serializer.toJson<String?>(notes),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalDailyChecksTableData copyWith({
    String? id,
    String? profileId,
    DateTime? checkDate,
    String? feeling,
    String? medicationStatus,
    Value<String?> notes = const Value.absent(),
    bool? isDeleted,
    String? syncStatus,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalDailyChecksTableData(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    checkDate: checkDate ?? this.checkDate,
    feeling: feeling ?? this.feeling,
    medicationStatus: medicationStatus ?? this.medicationStatus,
    notes: notes.present ? notes.value : this.notes,
    isDeleted: isDeleted ?? this.isDeleted,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalDailyChecksTableData copyWithCompanion(
    LocalDailyChecksTableCompanion data,
  ) {
    return LocalDailyChecksTableData(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      checkDate: data.checkDate.present ? data.checkDate.value : this.checkDate,
      feeling: data.feeling.present ? data.feeling.value : this.feeling,
      medicationStatus: data.medicationStatus.present
          ? data.medicationStatus.value
          : this.medicationStatus,
      notes: data.notes.present ? data.notes.value : this.notes,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDailyChecksTableData(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('checkDate: $checkDate, ')
          ..write('feeling: $feeling, ')
          ..write('medicationStatus: $medicationStatus, ')
          ..write('notes: $notes, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    checkDate,
    feeling,
    medicationStatus,
    notes,
    isDeleted,
    syncStatus,
    version,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDailyChecksTableData &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.checkDate == this.checkDate &&
          other.feeling == this.feeling &&
          other.medicationStatus == this.medicationStatus &&
          other.notes == this.notes &&
          other.isDeleted == this.isDeleted &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalDailyChecksTableCompanion
    extends UpdateCompanion<LocalDailyChecksTableData> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<DateTime> checkDate;
  final Value<String> feeling;
  final Value<String> medicationStatus;
  final Value<String?> notes;
  final Value<bool> isDeleted;
  final Value<String> syncStatus;
  final Value<int> version;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalDailyChecksTableCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.checkDate = const Value.absent(),
    this.feeling = const Value.absent(),
    this.medicationStatus = const Value.absent(),
    this.notes = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDailyChecksTableCompanion.insert({
    required String id,
    required String profileId,
    required DateTime checkDate,
    required String feeling,
    required String medicationStatus,
    this.notes = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       checkDate = Value(checkDate),
       feeling = Value(feeling),
       medicationStatus = Value(medicationStatus);
  static Insertable<LocalDailyChecksTableData> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<DateTime>? checkDate,
    Expression<String>? feeling,
    Expression<String>? medicationStatus,
    Expression<String>? notes,
    Expression<bool>? isDeleted,
    Expression<String>? syncStatus,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (checkDate != null) 'check_date': checkDate,
      if (feeling != null) 'feeling': feeling,
      if (medicationStatus != null) 'medication_status': medicationStatus,
      if (notes != null) 'notes': notes,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDailyChecksTableCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<DateTime>? checkDate,
    Value<String>? feeling,
    Value<String>? medicationStatus,
    Value<String?>? notes,
    Value<bool>? isDeleted,
    Value<String>? syncStatus,
    Value<int>? version,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalDailyChecksTableCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      checkDate: checkDate ?? this.checkDate,
      feeling: feeling ?? this.feeling,
      medicationStatus: medicationStatus ?? this.medicationStatus,
      notes: notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (checkDate.present) {
      map['check_date'] = Variable<DateTime>(checkDate.value);
    }
    if (feeling.present) {
      map['feeling'] = Variable<String>(feeling.value);
    }
    if (medicationStatus.present) {
      map['medication_status'] = Variable<String>(medicationStatus.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDailyChecksTableCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('checkDate: $checkDate, ')
          ..write('feeling: $feeling, ')
          ..write('medicationStatus: $medicationStatus, ')
          ..write('notes: $notes, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDailyCheckSymptomsTableTable extends LocalDailyCheckSymptomsTable
    with
        TableInfo<
          $LocalDailyCheckSymptomsTableTable,
          LocalDailyCheckSymptomsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDailyCheckSymptomsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dailyCheckIdMeta = const VerificationMeta(
    'dailyCheckId',
  );
  @override
  late final GeneratedColumn<String> dailyCheckId = GeneratedColumn<String>(
    'daily_check_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _symptomCodeMeta = const VerificationMeta(
    'symptomCode',
  );
  @override
  late final GeneratedColumn<String> symptomCode = GeneratedColumn<String>(
    'symptom_code',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isUrgentMeta = const VerificationMeta(
    'isUrgent',
  );
  @override
  late final GeneratedColumn<bool> isUrgent = GeneratedColumn<bool>(
    'is_urgent',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_urgent" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _customDescriptionMeta = const VerificationMeta(
    'customDescription',
  );
  @override
  late final GeneratedColumn<String> customDescription =
      GeneratedColumn<String>(
        'custom_description',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dailyCheckId,
    symptomCode,
    isUrgent,
    customDescription,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_daily_check_symptoms_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDailyCheckSymptomsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('daily_check_id')) {
      context.handle(
        _dailyCheckIdMeta,
        dailyCheckId.isAcceptableOrUnknown(
          data['daily_check_id']!,
          _dailyCheckIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_dailyCheckIdMeta);
    }
    if (data.containsKey('symptom_code')) {
      context.handle(
        _symptomCodeMeta,
        symptomCode.isAcceptableOrUnknown(
          data['symptom_code']!,
          _symptomCodeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_symptomCodeMeta);
    }
    if (data.containsKey('is_urgent')) {
      context.handle(
        _isUrgentMeta,
        isUrgent.isAcceptableOrUnknown(data['is_urgent']!, _isUrgentMeta),
      );
    }
    if (data.containsKey('custom_description')) {
      context.handle(
        _customDescriptionMeta,
        customDescription.isAcceptableOrUnknown(
          data['custom_description']!,
          _customDescriptionMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalDailyCheckSymptomsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDailyCheckSymptomsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      dailyCheckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}daily_check_id'],
      )!,
      symptomCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symptom_code'],
      )!,
      isUrgent: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_urgent'],
      )!,
      customDescription: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}custom_description'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LocalDailyCheckSymptomsTableTable createAlias(String alias) {
    return $LocalDailyCheckSymptomsTableTable(attachedDatabase, alias);
  }
}

class LocalDailyCheckSymptomsTableData extends DataClass
    implements Insertable<LocalDailyCheckSymptomsTableData> {
  final String id;
  final String dailyCheckId;
  final String symptomCode;
  final bool isUrgent;
  final String? customDescription;
  final DateTime createdAt;
  const LocalDailyCheckSymptomsTableData({
    required this.id,
    required this.dailyCheckId,
    required this.symptomCode,
    required this.isUrgent,
    this.customDescription,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['daily_check_id'] = Variable<String>(dailyCheckId);
    map['symptom_code'] = Variable<String>(symptomCode);
    map['is_urgent'] = Variable<bool>(isUrgent);
    if (!nullToAbsent || customDescription != null) {
      map['custom_description'] = Variable<String>(customDescription);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LocalDailyCheckSymptomsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalDailyCheckSymptomsTableCompanion(
      id: Value(id),
      dailyCheckId: Value(dailyCheckId),
      symptomCode: Value(symptomCode),
      isUrgent: Value(isUrgent),
      customDescription: customDescription == null && nullToAbsent
          ? const Value.absent()
          : Value(customDescription),
      createdAt: Value(createdAt),
    );
  }

  factory LocalDailyCheckSymptomsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDailyCheckSymptomsTableData(
      id: serializer.fromJson<String>(json['id']),
      dailyCheckId: serializer.fromJson<String>(json['dailyCheckId']),
      symptomCode: serializer.fromJson<String>(json['symptomCode']),
      isUrgent: serializer.fromJson<bool>(json['isUrgent']),
      customDescription: serializer.fromJson<String?>(
        json['customDescription'],
      ),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'dailyCheckId': serializer.toJson<String>(dailyCheckId),
      'symptomCode': serializer.toJson<String>(symptomCode),
      'isUrgent': serializer.toJson<bool>(isUrgent),
      'customDescription': serializer.toJson<String?>(customDescription),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LocalDailyCheckSymptomsTableData copyWith({
    String? id,
    String? dailyCheckId,
    String? symptomCode,
    bool? isUrgent,
    Value<String?> customDescription = const Value.absent(),
    DateTime? createdAt,
  }) => LocalDailyCheckSymptomsTableData(
    id: id ?? this.id,
    dailyCheckId: dailyCheckId ?? this.dailyCheckId,
    symptomCode: symptomCode ?? this.symptomCode,
    isUrgent: isUrgent ?? this.isUrgent,
    customDescription: customDescription.present
        ? customDescription.value
        : this.customDescription,
    createdAt: createdAt ?? this.createdAt,
  );
  LocalDailyCheckSymptomsTableData copyWithCompanion(
    LocalDailyCheckSymptomsTableCompanion data,
  ) {
    return LocalDailyCheckSymptomsTableData(
      id: data.id.present ? data.id.value : this.id,
      dailyCheckId: data.dailyCheckId.present
          ? data.dailyCheckId.value
          : this.dailyCheckId,
      symptomCode: data.symptomCode.present
          ? data.symptomCode.value
          : this.symptomCode,
      isUrgent: data.isUrgent.present ? data.isUrgent.value : this.isUrgent,
      customDescription: data.customDescription.present
          ? data.customDescription.value
          : this.customDescription,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDailyCheckSymptomsTableData(')
          ..write('id: $id, ')
          ..write('dailyCheckId: $dailyCheckId, ')
          ..write('symptomCode: $symptomCode, ')
          ..write('isUrgent: $isUrgent, ')
          ..write('customDescription: $customDescription, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dailyCheckId,
    symptomCode,
    isUrgent,
    customDescription,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDailyCheckSymptomsTableData &&
          other.id == this.id &&
          other.dailyCheckId == this.dailyCheckId &&
          other.symptomCode == this.symptomCode &&
          other.isUrgent == this.isUrgent &&
          other.customDescription == this.customDescription &&
          other.createdAt == this.createdAt);
}

class LocalDailyCheckSymptomsTableCompanion
    extends UpdateCompanion<LocalDailyCheckSymptomsTableData> {
  final Value<String> id;
  final Value<String> dailyCheckId;
  final Value<String> symptomCode;
  final Value<bool> isUrgent;
  final Value<String?> customDescription;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LocalDailyCheckSymptomsTableCompanion({
    this.id = const Value.absent(),
    this.dailyCheckId = const Value.absent(),
    this.symptomCode = const Value.absent(),
    this.isUrgent = const Value.absent(),
    this.customDescription = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDailyCheckSymptomsTableCompanion.insert({
    required String id,
    required String dailyCheckId,
    required String symptomCode,
    this.isUrgent = const Value.absent(),
    this.customDescription = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       dailyCheckId = Value(dailyCheckId),
       symptomCode = Value(symptomCode);
  static Insertable<LocalDailyCheckSymptomsTableData> custom({
    Expression<String>? id,
    Expression<String>? dailyCheckId,
    Expression<String>? symptomCode,
    Expression<bool>? isUrgent,
    Expression<String>? customDescription,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dailyCheckId != null) 'daily_check_id': dailyCheckId,
      if (symptomCode != null) 'symptom_code': symptomCode,
      if (isUrgent != null) 'is_urgent': isUrgent,
      if (customDescription != null) 'custom_description': customDescription,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDailyCheckSymptomsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? dailyCheckId,
    Value<String>? symptomCode,
    Value<bool>? isUrgent,
    Value<String?>? customDescription,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LocalDailyCheckSymptomsTableCompanion(
      id: id ?? this.id,
      dailyCheckId: dailyCheckId ?? this.dailyCheckId,
      symptomCode: symptomCode ?? this.symptomCode,
      isUrgent: isUrgent ?? this.isUrgent,
      customDescription: customDescription ?? this.customDescription,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (dailyCheckId.present) {
      map['daily_check_id'] = Variable<String>(dailyCheckId.value);
    }
    if (symptomCode.present) {
      map['symptom_code'] = Variable<String>(symptomCode.value);
    }
    if (isUrgent.present) {
      map['is_urgent'] = Variable<bool>(isUrgent.value);
    }
    if (customDescription.present) {
      map['custom_description'] = Variable<String>(customDescription.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDailyCheckSymptomsTableCompanion(')
          ..write('id: $id, ')
          ..write('dailyCheckId: $dailyCheckId, ')
          ..write('symptomCode: $symptomCode, ')
          ..write('isUrgent: $isUrgent, ')
          ..write('customDescription: $customDescription, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalDailyCheckDraftsTableTable extends LocalDailyCheckDraftsTable
    with
        TableInfo<
          $LocalDailyCheckDraftsTableTable,
          LocalDailyCheckDraftsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalDailyCheckDraftsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _currentStepMeta = const VerificationMeta(
    'currentStep',
  );
  @override
  late final GeneratedColumn<int> currentStep = GeneratedColumn<int>(
    'current_step',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _feelingMeta = const VerificationMeta(
    'feeling',
  );
  @override
  late final GeneratedColumn<String> feeling = GeneratedColumn<String>(
    'feeling',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heartRateBpmMeta = const VerificationMeta(
    'heartRateBpm',
  );
  @override
  late final GeneratedColumn<double> heartRateBpm = GeneratedColumn<double>(
    'heart_rate_bpm',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _systolicMmhgMeta = const VerificationMeta(
    'systolicMmhg',
  );
  @override
  late final GeneratedColumn<double> systolicMmhg = GeneratedColumn<double>(
    'systolic_mmhg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _diastolicMmhgMeta = const VerificationMeta(
    'diastolicMmhg',
  );
  @override
  late final GeneratedColumn<double> diastolicMmhg = GeneratedColumn<double>(
    'diastolic_mmhg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _temperatureCelsiusMeta =
      const VerificationMeta('temperatureCelsius');
  @override
  late final GeneratedColumn<double> temperatureCelsius =
      GeneratedColumn<double>(
        'temperature_celsius',
        aliasedName,
        true,
        type: DriftSqlType.double,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _weightKgMeta = const VerificationMeta(
    'weightKg',
  );
  @override
  late final GeneratedColumn<double> weightKg = GeneratedColumn<double>(
    'weight_kg',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _glucoseMmolLMeta = const VerificationMeta(
    'glucoseMmolL',
  );
  @override
  late final GeneratedColumn<double> glucoseMmolL = GeneratedColumn<double>(
    'glucose_mmol_l',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _symptomsJsonMeta = const VerificationMeta(
    'symptomsJson',
  );
  @override
  late final GeneratedColumn<String> symptomsJson = GeneratedColumn<String>(
    'symptoms_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _medicationStatusMeta = const VerificationMeta(
    'medicationStatus',
  );
  @override
  late final GeneratedColumn<String> medicationStatus = GeneratedColumn<String>(
    'medication_status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    profileId,
    currentStep,
    feeling,
    heartRateBpm,
    systolicMmhg,
    diastolicMmhg,
    temperatureCelsius,
    weightKg,
    glucoseMmolL,
    symptomsJson,
    medicationStatus,
    notes,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_daily_check_drafts_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalDailyCheckDraftsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('current_step')) {
      context.handle(
        _currentStepMeta,
        currentStep.isAcceptableOrUnknown(
          data['current_step']!,
          _currentStepMeta,
        ),
      );
    }
    if (data.containsKey('feeling')) {
      context.handle(
        _feelingMeta,
        feeling.isAcceptableOrUnknown(data['feeling']!, _feelingMeta),
      );
    }
    if (data.containsKey('heart_rate_bpm')) {
      context.handle(
        _heartRateBpmMeta,
        heartRateBpm.isAcceptableOrUnknown(
          data['heart_rate_bpm']!,
          _heartRateBpmMeta,
        ),
      );
    }
    if (data.containsKey('systolic_mmhg')) {
      context.handle(
        _systolicMmhgMeta,
        systolicMmhg.isAcceptableOrUnknown(
          data['systolic_mmhg']!,
          _systolicMmhgMeta,
        ),
      );
    }
    if (data.containsKey('diastolic_mmhg')) {
      context.handle(
        _diastolicMmhgMeta,
        diastolicMmhg.isAcceptableOrUnknown(
          data['diastolic_mmhg']!,
          _diastolicMmhgMeta,
        ),
      );
    }
    if (data.containsKey('temperature_celsius')) {
      context.handle(
        _temperatureCelsiusMeta,
        temperatureCelsius.isAcceptableOrUnknown(
          data['temperature_celsius']!,
          _temperatureCelsiusMeta,
        ),
      );
    }
    if (data.containsKey('weight_kg')) {
      context.handle(
        _weightKgMeta,
        weightKg.isAcceptableOrUnknown(data['weight_kg']!, _weightKgMeta),
      );
    }
    if (data.containsKey('glucose_mmol_l')) {
      context.handle(
        _glucoseMmolLMeta,
        glucoseMmolL.isAcceptableOrUnknown(
          data['glucose_mmol_l']!,
          _glucoseMmolLMeta,
        ),
      );
    }
    if (data.containsKey('symptoms_json')) {
      context.handle(
        _symptomsJsonMeta,
        symptomsJson.isAcceptableOrUnknown(
          data['symptoms_json']!,
          _symptomsJsonMeta,
        ),
      );
    }
    if (data.containsKey('medication_status')) {
      context.handle(
        _medicationStatusMeta,
        medicationStatus.isAcceptableOrUnknown(
          data['medication_status']!,
          _medicationStatusMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {profileId};
  @override
  LocalDailyCheckDraftsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalDailyCheckDraftsTableData(
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      currentStep: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}current_step'],
      )!,
      feeling: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}feeling'],
      ),
      heartRateBpm: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}heart_rate_bpm'],
      ),
      systolicMmhg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}systolic_mmhg'],
      ),
      diastolicMmhg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}diastolic_mmhg'],
      ),
      temperatureCelsius: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}temperature_celsius'],
      ),
      weightKg: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}weight_kg'],
      ),
      glucoseMmolL: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}glucose_mmol_l'],
      ),
      symptomsJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}symptoms_json'],
      ),
      medicationStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_status'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalDailyCheckDraftsTableTable createAlias(String alias) {
    return $LocalDailyCheckDraftsTableTable(attachedDatabase, alias);
  }
}

class LocalDailyCheckDraftsTableData extends DataClass
    implements Insertable<LocalDailyCheckDraftsTableData> {
  final String profileId;
  final int currentStep;
  final String? feeling;
  final double? heartRateBpm;
  final double? systolicMmhg;
  final double? diastolicMmhg;
  final double? temperatureCelsius;
  final double? weightKg;
  final double? glucoseMmolL;
  final String? symptomsJson;
  final String? medicationStatus;
  final String? notes;
  final DateTime updatedAt;
  const LocalDailyCheckDraftsTableData({
    required this.profileId,
    required this.currentStep,
    this.feeling,
    this.heartRateBpm,
    this.systolicMmhg,
    this.diastolicMmhg,
    this.temperatureCelsius,
    this.weightKg,
    this.glucoseMmolL,
    this.symptomsJson,
    this.medicationStatus,
    this.notes,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['profile_id'] = Variable<String>(profileId);
    map['current_step'] = Variable<int>(currentStep);
    if (!nullToAbsent || feeling != null) {
      map['feeling'] = Variable<String>(feeling);
    }
    if (!nullToAbsent || heartRateBpm != null) {
      map['heart_rate_bpm'] = Variable<double>(heartRateBpm);
    }
    if (!nullToAbsent || systolicMmhg != null) {
      map['systolic_mmhg'] = Variable<double>(systolicMmhg);
    }
    if (!nullToAbsent || diastolicMmhg != null) {
      map['diastolic_mmhg'] = Variable<double>(diastolicMmhg);
    }
    if (!nullToAbsent || temperatureCelsius != null) {
      map['temperature_celsius'] = Variable<double>(temperatureCelsius);
    }
    if (!nullToAbsent || weightKg != null) {
      map['weight_kg'] = Variable<double>(weightKg);
    }
    if (!nullToAbsent || glucoseMmolL != null) {
      map['glucose_mmol_l'] = Variable<double>(glucoseMmolL);
    }
    if (!nullToAbsent || symptomsJson != null) {
      map['symptoms_json'] = Variable<String>(symptomsJson);
    }
    if (!nullToAbsent || medicationStatus != null) {
      map['medication_status'] = Variable<String>(medicationStatus);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalDailyCheckDraftsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalDailyCheckDraftsTableCompanion(
      profileId: Value(profileId),
      currentStep: Value(currentStep),
      feeling: feeling == null && nullToAbsent
          ? const Value.absent()
          : Value(feeling),
      heartRateBpm: heartRateBpm == null && nullToAbsent
          ? const Value.absent()
          : Value(heartRateBpm),
      systolicMmhg: systolicMmhg == null && nullToAbsent
          ? const Value.absent()
          : Value(systolicMmhg),
      diastolicMmhg: diastolicMmhg == null && nullToAbsent
          ? const Value.absent()
          : Value(diastolicMmhg),
      temperatureCelsius: temperatureCelsius == null && nullToAbsent
          ? const Value.absent()
          : Value(temperatureCelsius),
      weightKg: weightKg == null && nullToAbsent
          ? const Value.absent()
          : Value(weightKg),
      glucoseMmolL: glucoseMmolL == null && nullToAbsent
          ? const Value.absent()
          : Value(glucoseMmolL),
      symptomsJson: symptomsJson == null && nullToAbsent
          ? const Value.absent()
          : Value(symptomsJson),
      medicationStatus: medicationStatus == null && nullToAbsent
          ? const Value.absent()
          : Value(medicationStatus),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalDailyCheckDraftsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalDailyCheckDraftsTableData(
      profileId: serializer.fromJson<String>(json['profileId']),
      currentStep: serializer.fromJson<int>(json['currentStep']),
      feeling: serializer.fromJson<String?>(json['feeling']),
      heartRateBpm: serializer.fromJson<double?>(json['heartRateBpm']),
      systolicMmhg: serializer.fromJson<double?>(json['systolicMmhg']),
      diastolicMmhg: serializer.fromJson<double?>(json['diastolicMmhg']),
      temperatureCelsius: serializer.fromJson<double?>(
        json['temperatureCelsius'],
      ),
      weightKg: serializer.fromJson<double?>(json['weightKg']),
      glucoseMmolL: serializer.fromJson<double?>(json['glucoseMmolL']),
      symptomsJson: serializer.fromJson<String?>(json['symptomsJson']),
      medicationStatus: serializer.fromJson<String?>(json['medicationStatus']),
      notes: serializer.fromJson<String?>(json['notes']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'profileId': serializer.toJson<String>(profileId),
      'currentStep': serializer.toJson<int>(currentStep),
      'feeling': serializer.toJson<String?>(feeling),
      'heartRateBpm': serializer.toJson<double?>(heartRateBpm),
      'systolicMmhg': serializer.toJson<double?>(systolicMmhg),
      'diastolicMmhg': serializer.toJson<double?>(diastolicMmhg),
      'temperatureCelsius': serializer.toJson<double?>(temperatureCelsius),
      'weightKg': serializer.toJson<double?>(weightKg),
      'glucoseMmolL': serializer.toJson<double?>(glucoseMmolL),
      'symptomsJson': serializer.toJson<String?>(symptomsJson),
      'medicationStatus': serializer.toJson<String?>(medicationStatus),
      'notes': serializer.toJson<String?>(notes),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalDailyCheckDraftsTableData copyWith({
    String? profileId,
    int? currentStep,
    Value<String?> feeling = const Value.absent(),
    Value<double?> heartRateBpm = const Value.absent(),
    Value<double?> systolicMmhg = const Value.absent(),
    Value<double?> diastolicMmhg = const Value.absent(),
    Value<double?> temperatureCelsius = const Value.absent(),
    Value<double?> weightKg = const Value.absent(),
    Value<double?> glucoseMmolL = const Value.absent(),
    Value<String?> symptomsJson = const Value.absent(),
    Value<String?> medicationStatus = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    DateTime? updatedAt,
  }) => LocalDailyCheckDraftsTableData(
    profileId: profileId ?? this.profileId,
    currentStep: currentStep ?? this.currentStep,
    feeling: feeling.present ? feeling.value : this.feeling,
    heartRateBpm: heartRateBpm.present ? heartRateBpm.value : this.heartRateBpm,
    systolicMmhg: systolicMmhg.present ? systolicMmhg.value : this.systolicMmhg,
    diastolicMmhg: diastolicMmhg.present
        ? diastolicMmhg.value
        : this.diastolicMmhg,
    temperatureCelsius: temperatureCelsius.present
        ? temperatureCelsius.value
        : this.temperatureCelsius,
    weightKg: weightKg.present ? weightKg.value : this.weightKg,
    glucoseMmolL: glucoseMmolL.present ? glucoseMmolL.value : this.glucoseMmolL,
    symptomsJson: symptomsJson.present ? symptomsJson.value : this.symptomsJson,
    medicationStatus: medicationStatus.present
        ? medicationStatus.value
        : this.medicationStatus,
    notes: notes.present ? notes.value : this.notes,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalDailyCheckDraftsTableData copyWithCompanion(
    LocalDailyCheckDraftsTableCompanion data,
  ) {
    return LocalDailyCheckDraftsTableData(
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      currentStep: data.currentStep.present
          ? data.currentStep.value
          : this.currentStep,
      feeling: data.feeling.present ? data.feeling.value : this.feeling,
      heartRateBpm: data.heartRateBpm.present
          ? data.heartRateBpm.value
          : this.heartRateBpm,
      systolicMmhg: data.systolicMmhg.present
          ? data.systolicMmhg.value
          : this.systolicMmhg,
      diastolicMmhg: data.diastolicMmhg.present
          ? data.diastolicMmhg.value
          : this.diastolicMmhg,
      temperatureCelsius: data.temperatureCelsius.present
          ? data.temperatureCelsius.value
          : this.temperatureCelsius,
      weightKg: data.weightKg.present ? data.weightKg.value : this.weightKg,
      glucoseMmolL: data.glucoseMmolL.present
          ? data.glucoseMmolL.value
          : this.glucoseMmolL,
      symptomsJson: data.symptomsJson.present
          ? data.symptomsJson.value
          : this.symptomsJson,
      medicationStatus: data.medicationStatus.present
          ? data.medicationStatus.value
          : this.medicationStatus,
      notes: data.notes.present ? data.notes.value : this.notes,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalDailyCheckDraftsTableData(')
          ..write('profileId: $profileId, ')
          ..write('currentStep: $currentStep, ')
          ..write('feeling: $feeling, ')
          ..write('heartRateBpm: $heartRateBpm, ')
          ..write('systolicMmhg: $systolicMmhg, ')
          ..write('diastolicMmhg: $diastolicMmhg, ')
          ..write('temperatureCelsius: $temperatureCelsius, ')
          ..write('weightKg: $weightKg, ')
          ..write('glucoseMmolL: $glucoseMmolL, ')
          ..write('symptomsJson: $symptomsJson, ')
          ..write('medicationStatus: $medicationStatus, ')
          ..write('notes: $notes, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    profileId,
    currentStep,
    feeling,
    heartRateBpm,
    systolicMmhg,
    diastolicMmhg,
    temperatureCelsius,
    weightKg,
    glucoseMmolL,
    symptomsJson,
    medicationStatus,
    notes,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalDailyCheckDraftsTableData &&
          other.profileId == this.profileId &&
          other.currentStep == this.currentStep &&
          other.feeling == this.feeling &&
          other.heartRateBpm == this.heartRateBpm &&
          other.systolicMmhg == this.systolicMmhg &&
          other.diastolicMmhg == this.diastolicMmhg &&
          other.temperatureCelsius == this.temperatureCelsius &&
          other.weightKg == this.weightKg &&
          other.glucoseMmolL == this.glucoseMmolL &&
          other.symptomsJson == this.symptomsJson &&
          other.medicationStatus == this.medicationStatus &&
          other.notes == this.notes &&
          other.updatedAt == this.updatedAt);
}

class LocalDailyCheckDraftsTableCompanion
    extends UpdateCompanion<LocalDailyCheckDraftsTableData> {
  final Value<String> profileId;
  final Value<int> currentStep;
  final Value<String?> feeling;
  final Value<double?> heartRateBpm;
  final Value<double?> systolicMmhg;
  final Value<double?> diastolicMmhg;
  final Value<double?> temperatureCelsius;
  final Value<double?> weightKg;
  final Value<double?> glucoseMmolL;
  final Value<String?> symptomsJson;
  final Value<String?> medicationStatus;
  final Value<String?> notes;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalDailyCheckDraftsTableCompanion({
    this.profileId = const Value.absent(),
    this.currentStep = const Value.absent(),
    this.feeling = const Value.absent(),
    this.heartRateBpm = const Value.absent(),
    this.systolicMmhg = const Value.absent(),
    this.diastolicMmhg = const Value.absent(),
    this.temperatureCelsius = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.glucoseMmolL = const Value.absent(),
    this.symptomsJson = const Value.absent(),
    this.medicationStatus = const Value.absent(),
    this.notes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalDailyCheckDraftsTableCompanion.insert({
    required String profileId,
    this.currentStep = const Value.absent(),
    this.feeling = const Value.absent(),
    this.heartRateBpm = const Value.absent(),
    this.systolicMmhg = const Value.absent(),
    this.diastolicMmhg = const Value.absent(),
    this.temperatureCelsius = const Value.absent(),
    this.weightKg = const Value.absent(),
    this.glucoseMmolL = const Value.absent(),
    this.symptomsJson = const Value.absent(),
    this.medicationStatus = const Value.absent(),
    this.notes = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : profileId = Value(profileId);
  static Insertable<LocalDailyCheckDraftsTableData> custom({
    Expression<String>? profileId,
    Expression<int>? currentStep,
    Expression<String>? feeling,
    Expression<double>? heartRateBpm,
    Expression<double>? systolicMmhg,
    Expression<double>? diastolicMmhg,
    Expression<double>? temperatureCelsius,
    Expression<double>? weightKg,
    Expression<double>? glucoseMmolL,
    Expression<String>? symptomsJson,
    Expression<String>? medicationStatus,
    Expression<String>? notes,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (profileId != null) 'profile_id': profileId,
      if (currentStep != null) 'current_step': currentStep,
      if (feeling != null) 'feeling': feeling,
      if (heartRateBpm != null) 'heart_rate_bpm': heartRateBpm,
      if (systolicMmhg != null) 'systolic_mmhg': systolicMmhg,
      if (diastolicMmhg != null) 'diastolic_mmhg': diastolicMmhg,
      if (temperatureCelsius != null) 'temperature_celsius': temperatureCelsius,
      if (weightKg != null) 'weight_kg': weightKg,
      if (glucoseMmolL != null) 'glucose_mmol_l': glucoseMmolL,
      if (symptomsJson != null) 'symptoms_json': symptomsJson,
      if (medicationStatus != null) 'medication_status': medicationStatus,
      if (notes != null) 'notes': notes,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalDailyCheckDraftsTableCompanion copyWith({
    Value<String>? profileId,
    Value<int>? currentStep,
    Value<String?>? feeling,
    Value<double?>? heartRateBpm,
    Value<double?>? systolicMmhg,
    Value<double?>? diastolicMmhg,
    Value<double?>? temperatureCelsius,
    Value<double?>? weightKg,
    Value<double?>? glucoseMmolL,
    Value<String?>? symptomsJson,
    Value<String?>? medicationStatus,
    Value<String?>? notes,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalDailyCheckDraftsTableCompanion(
      profileId: profileId ?? this.profileId,
      currentStep: currentStep ?? this.currentStep,
      feeling: feeling ?? this.feeling,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      systolicMmhg: systolicMmhg ?? this.systolicMmhg,
      diastolicMmhg: diastolicMmhg ?? this.diastolicMmhg,
      temperatureCelsius: temperatureCelsius ?? this.temperatureCelsius,
      weightKg: weightKg ?? this.weightKg,
      glucoseMmolL: glucoseMmolL ?? this.glucoseMmolL,
      symptomsJson: symptomsJson ?? this.symptomsJson,
      medicationStatus: medicationStatus ?? this.medicationStatus,
      notes: notes ?? this.notes,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (currentStep.present) {
      map['current_step'] = Variable<int>(currentStep.value);
    }
    if (feeling.present) {
      map['feeling'] = Variable<String>(feeling.value);
    }
    if (heartRateBpm.present) {
      map['heart_rate_bpm'] = Variable<double>(heartRateBpm.value);
    }
    if (systolicMmhg.present) {
      map['systolic_mmhg'] = Variable<double>(systolicMmhg.value);
    }
    if (diastolicMmhg.present) {
      map['diastolic_mmhg'] = Variable<double>(diastolicMmhg.value);
    }
    if (temperatureCelsius.present) {
      map['temperature_celsius'] = Variable<double>(temperatureCelsius.value);
    }
    if (weightKg.present) {
      map['weight_kg'] = Variable<double>(weightKg.value);
    }
    if (glucoseMmolL.present) {
      map['glucose_mmol_l'] = Variable<double>(glucoseMmolL.value);
    }
    if (symptomsJson.present) {
      map['symptoms_json'] = Variable<String>(symptomsJson.value);
    }
    if (medicationStatus.present) {
      map['medication_status'] = Variable<String>(medicationStatus.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalDailyCheckDraftsTableCompanion(')
          ..write('profileId: $profileId, ')
          ..write('currentStep: $currentStep, ')
          ..write('feeling: $feeling, ')
          ..write('heartRateBpm: $heartRateBpm, ')
          ..write('systolicMmhg: $systolicMmhg, ')
          ..write('diastolicMmhg: $diastolicMmhg, ')
          ..write('temperatureCelsius: $temperatureCelsius, ')
          ..write('weightKg: $weightKg, ')
          ..write('glucoseMmolL: $glucoseMmolL, ')
          ..write('symptomsJson: $symptomsJson, ')
          ..write('medicationStatus: $medicationStatus, ')
          ..write('notes: $notes, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMedicationsTableTable extends LocalMedicationsTable
    with TableInfo<$LocalMedicationsTableTable, LocalMedicationsTableData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMedicationsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dosageMeta = const VerificationMeta('dosage');
  @override
  late final GeneratedColumn<String> dosage = GeneratedColumn<String>(
    'dosage',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _frequencyMeta = const VerificationMeta(
    'frequency',
  );
  @override
  late final GeneratedColumn<String> frequency = GeneratedColumn<String>(
    'frequency',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<DateTime> startDate = GeneratedColumn<DateTime>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<DateTime> endDate = GeneratedColumn<DateTime>(
    'end_date',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _reminderTimeMeta = const VerificationMeta(
    'reminderTime',
  );
  @override
  late final GeneratedColumn<String> reminderTime = GeneratedColumn<String>(
    'reminder_time',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isActiveMeta = const VerificationMeta(
    'isActive',
  );
  @override
  late final GeneratedColumn<bool> isActive = GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    name,
    dosage,
    frequency,
    startDate,
    endDate,
    reminderTime,
    notes,
    isActive,
    isDeleted,
    syncStatus,
    version,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_medications_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMedicationsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('dosage')) {
      context.handle(
        _dosageMeta,
        dosage.isAcceptableOrUnknown(data['dosage']!, _dosageMeta),
      );
    } else if (isInserting) {
      context.missing(_dosageMeta);
    }
    if (data.containsKey('frequency')) {
      context.handle(
        _frequencyMeta,
        frequency.isAcceptableOrUnknown(data['frequency']!, _frequencyMeta),
      );
    } else if (isInserting) {
      context.missing(_frequencyMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    }
    if (data.containsKey('reminder_time')) {
      context.handle(
        _reminderTimeMeta,
        reminderTime.isAcceptableOrUnknown(
          data['reminder_time']!,
          _reminderTimeMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMedicationsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMedicationsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      dosage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}dosage'],
      )!,
      frequency: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}frequency'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}end_date'],
      ),
      reminderTime: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}reminder_time'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalMedicationsTableTable createAlias(String alias) {
    return $LocalMedicationsTableTable(attachedDatabase, alias);
  }
}

class LocalMedicationsTableData extends DataClass
    implements Insertable<LocalMedicationsTableData> {
  final String id;
  final String profileId;
  final String name;
  final String dosage;
  final String frequency;
  final DateTime startDate;
  final DateTime? endDate;
  final String? reminderTime;
  final String? notes;
  final bool isActive;
  final bool isDeleted;
  final String syncStatus;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalMedicationsTableData({
    required this.id,
    required this.profileId,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.reminderTime,
    this.notes,
    required this.isActive,
    required this.isDeleted,
    required this.syncStatus,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['name'] = Variable<String>(name);
    map['dosage'] = Variable<String>(dosage);
    map['frequency'] = Variable<String>(frequency);
    map['start_date'] = Variable<DateTime>(startDate);
    if (!nullToAbsent || endDate != null) {
      map['end_date'] = Variable<DateTime>(endDate);
    }
    if (!nullToAbsent || reminderTime != null) {
      map['reminder_time'] = Variable<String>(reminderTime);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_active'] = Variable<bool>(isActive);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['sync_status'] = Variable<String>(syncStatus);
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalMedicationsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalMedicationsTableCompanion(
      id: Value(id),
      profileId: Value(profileId),
      name: Value(name),
      dosage: Value(dosage),
      frequency: Value(frequency),
      startDate: Value(startDate),
      endDate: endDate == null && nullToAbsent
          ? const Value.absent()
          : Value(endDate),
      reminderTime: reminderTime == null && nullToAbsent
          ? const Value.absent()
          : Value(reminderTime),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isActive: Value(isActive),
      isDeleted: Value(isDeleted),
      syncStatus: Value(syncStatus),
      version: Value(version),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalMedicationsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMedicationsTableData(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      name: serializer.fromJson<String>(json['name']),
      dosage: serializer.fromJson<String>(json['dosage']),
      frequency: serializer.fromJson<String>(json['frequency']),
      startDate: serializer.fromJson<DateTime>(json['startDate']),
      endDate: serializer.fromJson<DateTime?>(json['endDate']),
      reminderTime: serializer.fromJson<String?>(json['reminderTime']),
      notes: serializer.fromJson<String?>(json['notes']),
      isActive: serializer.fromJson<bool>(json['isActive']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'name': serializer.toJson<String>(name),
      'dosage': serializer.toJson<String>(dosage),
      'frequency': serializer.toJson<String>(frequency),
      'startDate': serializer.toJson<DateTime>(startDate),
      'endDate': serializer.toJson<DateTime?>(endDate),
      'reminderTime': serializer.toJson<String?>(reminderTime),
      'notes': serializer.toJson<String?>(notes),
      'isActive': serializer.toJson<bool>(isActive),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalMedicationsTableData copyWith({
    String? id,
    String? profileId,
    String? name,
    String? dosage,
    String? frequency,
    DateTime? startDate,
    Value<DateTime?> endDate = const Value.absent(),
    Value<String?> reminderTime = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    bool? isActive,
    bool? isDeleted,
    String? syncStatus,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalMedicationsTableData(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    name: name ?? this.name,
    dosage: dosage ?? this.dosage,
    frequency: frequency ?? this.frequency,
    startDate: startDate ?? this.startDate,
    endDate: endDate.present ? endDate.value : this.endDate,
    reminderTime: reminderTime.present ? reminderTime.value : this.reminderTime,
    notes: notes.present ? notes.value : this.notes,
    isActive: isActive ?? this.isActive,
    isDeleted: isDeleted ?? this.isDeleted,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalMedicationsTableData copyWithCompanion(
    LocalMedicationsTableCompanion data,
  ) {
    return LocalMedicationsTableData(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      name: data.name.present ? data.name.value : this.name,
      dosage: data.dosage.present ? data.dosage.value : this.dosage,
      frequency: data.frequency.present ? data.frequency.value : this.frequency,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      reminderTime: data.reminderTime.present
          ? data.reminderTime.value
          : this.reminderTime,
      notes: data.notes.present ? data.notes.value : this.notes,
      isActive: data.isActive.present ? data.isActive.value : this.isActive,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMedicationsTableData(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('dosage: $dosage, ')
          ..write('frequency: $frequency, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    name,
    dosage,
    frequency,
    startDate,
    endDate,
    reminderTime,
    notes,
    isActive,
    isDeleted,
    syncStatus,
    version,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMedicationsTableData &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.name == this.name &&
          other.dosage == this.dosage &&
          other.frequency == this.frequency &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.reminderTime == this.reminderTime &&
          other.notes == this.notes &&
          other.isActive == this.isActive &&
          other.isDeleted == this.isDeleted &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalMedicationsTableCompanion
    extends UpdateCompanion<LocalMedicationsTableData> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> name;
  final Value<String> dosage;
  final Value<String> frequency;
  final Value<DateTime> startDate;
  final Value<DateTime?> endDate;
  final Value<String?> reminderTime;
  final Value<String?> notes;
  final Value<bool> isActive;
  final Value<bool> isDeleted;
  final Value<String> syncStatus;
  final Value<int> version;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalMedicationsTableCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.name = const Value.absent(),
    this.dosage = const Value.absent(),
    this.frequency = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMedicationsTableCompanion.insert({
    required String id,
    required String profileId,
    required String name,
    required String dosage,
    required String frequency,
    required DateTime startDate,
    this.endDate = const Value.absent(),
    this.reminderTime = const Value.absent(),
    this.notes = const Value.absent(),
    this.isActive = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       name = Value(name),
       dosage = Value(dosage),
       frequency = Value(frequency),
       startDate = Value(startDate);
  static Insertable<LocalMedicationsTableData> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? name,
    Expression<String>? dosage,
    Expression<String>? frequency,
    Expression<DateTime>? startDate,
    Expression<DateTime>? endDate,
    Expression<String>? reminderTime,
    Expression<String>? notes,
    Expression<bool>? isActive,
    Expression<bool>? isDeleted,
    Expression<String>? syncStatus,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (name != null) 'name': name,
      if (dosage != null) 'dosage': dosage,
      if (frequency != null) 'frequency': frequency,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (reminderTime != null) 'reminder_time': reminderTime,
      if (notes != null) 'notes': notes,
      if (isActive != null) 'is_active': isActive,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMedicationsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? name,
    Value<String>? dosage,
    Value<String>? frequency,
    Value<DateTime>? startDate,
    Value<DateTime?>? endDate,
    Value<String?>? reminderTime,
    Value<String?>? notes,
    Value<bool>? isActive,
    Value<bool>? isDeleted,
    Value<String>? syncStatus,
    Value<int>? version,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalMedicationsTableCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      name: name ?? this.name,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      reminderTime: reminderTime ?? this.reminderTime,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (dosage.present) {
      map['dosage'] = Variable<String>(dosage.value);
    }
    if (frequency.present) {
      map['frequency'] = Variable<String>(frequency.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<DateTime>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<DateTime>(endDate.value);
    }
    if (reminderTime.present) {
      map['reminder_time'] = Variable<String>(reminderTime.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isActive.present) {
      map['is_active'] = Variable<bool>(isActive.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMedicationsTableCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('name: $name, ')
          ..write('dosage: $dosage, ')
          ..write('frequency: $frequency, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('reminderTime: $reminderTime, ')
          ..write('notes: $notes, ')
          ..write('isActive: $isActive, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMedicationEventsTableTable extends LocalMedicationEventsTable
    with
        TableInfo<
          $LocalMedicationEventsTableTable,
          LocalMedicationEventsTableData
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMedicationEventsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _profileIdMeta = const VerificationMeta(
    'profileId',
  );
  @override
  late final GeneratedColumn<String> profileId = GeneratedColumn<String>(
    'profile_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _medicationIdMeta = const VerificationMeta(
    'medicationId',
  );
  @override
  late final GeneratedColumn<String> medicationId = GeneratedColumn<String>(
    'medication_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledTimeMeta = const VerificationMeta(
    'scheduledTime',
  );
  @override
  late final GeneratedColumn<DateTime> scheduledTime =
      GeneratedColumn<DateTime>(
        'scheduled_time',
        aliasedName,
        false,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _recordedAtMeta = const VerificationMeta(
    'recordedAt',
  );
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
    'recorded_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _syncStatusMeta = const VerificationMeta(
    'syncStatus',
  );
  @override
  late final GeneratedColumn<String> syncStatus = GeneratedColumn<String>(
    'sync_status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('synced'),
  );
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    profileId,
    medicationId,
    scheduledTime,
    recordedAt,
    status,
    notes,
    isDeleted,
    syncStatus,
    version,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_medication_events_table';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMedicationEventsTableData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('profile_id')) {
      context.handle(
        _profileIdMeta,
        profileId.isAcceptableOrUnknown(data['profile_id']!, _profileIdMeta),
      );
    } else if (isInserting) {
      context.missing(_profileIdMeta);
    }
    if (data.containsKey('medication_id')) {
      context.handle(
        _medicationIdMeta,
        medicationId.isAcceptableOrUnknown(
          data['medication_id']!,
          _medicationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_medicationIdMeta);
    }
    if (data.containsKey('scheduled_time')) {
      context.handle(
        _scheduledTimeMeta,
        scheduledTime.isAcceptableOrUnknown(
          data['scheduled_time']!,
          _scheduledTimeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledTimeMeta);
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
        _recordedAtMeta,
        recordedAt.isAcceptableOrUnknown(data['recorded_at']!, _recordedAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('sync_status')) {
      context.handle(
        _syncStatusMeta,
        syncStatus.isAcceptableOrUnknown(data['sync_status']!, _syncStatusMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LocalMedicationEventsTableData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMedicationEventsTableData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      profileId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}profile_id'],
      )!,
      medicationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}medication_id'],
      )!,
      scheduledTime: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}scheduled_time'],
      )!,
      recordedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}recorded_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      syncStatus: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}sync_status'],
      )!,
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LocalMedicationEventsTableTable createAlias(String alias) {
    return $LocalMedicationEventsTableTable(attachedDatabase, alias);
  }
}

class LocalMedicationEventsTableData extends DataClass
    implements Insertable<LocalMedicationEventsTableData> {
  final String id;
  final String profileId;
  final String medicationId;
  final DateTime scheduledTime;
  final DateTime? recordedAt;
  final String status;
  final String? notes;
  final bool isDeleted;
  final String syncStatus;
  final int version;
  final DateTime createdAt;
  final DateTime updatedAt;
  const LocalMedicationEventsTableData({
    required this.id,
    required this.profileId,
    required this.medicationId,
    required this.scheduledTime,
    this.recordedAt,
    required this.status,
    this.notes,
    required this.isDeleted,
    required this.syncStatus,
    required this.version,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['profile_id'] = Variable<String>(profileId);
    map['medication_id'] = Variable<String>(medicationId);
    map['scheduled_time'] = Variable<DateTime>(scheduledTime);
    if (!nullToAbsent || recordedAt != null) {
      map['recorded_at'] = Variable<DateTime>(recordedAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['sync_status'] = Variable<String>(syncStatus);
    map['version'] = Variable<int>(version);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LocalMedicationEventsTableCompanion toCompanion(bool nullToAbsent) {
    return LocalMedicationEventsTableCompanion(
      id: Value(id),
      profileId: Value(profileId),
      medicationId: Value(medicationId),
      scheduledTime: Value(scheduledTime),
      recordedAt: recordedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(recordedAt),
      status: Value(status),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      isDeleted: Value(isDeleted),
      syncStatus: Value(syncStatus),
      version: Value(version),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory LocalMedicationEventsTableData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMedicationEventsTableData(
      id: serializer.fromJson<String>(json['id']),
      profileId: serializer.fromJson<String>(json['profileId']),
      medicationId: serializer.fromJson<String>(json['medicationId']),
      scheduledTime: serializer.fromJson<DateTime>(json['scheduledTime']),
      recordedAt: serializer.fromJson<DateTime?>(json['recordedAt']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      syncStatus: serializer.fromJson<String>(json['syncStatus']),
      version: serializer.fromJson<int>(json['version']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'profileId': serializer.toJson<String>(profileId),
      'medicationId': serializer.toJson<String>(medicationId),
      'scheduledTime': serializer.toJson<DateTime>(scheduledTime),
      'recordedAt': serializer.toJson<DateTime?>(recordedAt),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'syncStatus': serializer.toJson<String>(syncStatus),
      'version': serializer.toJson<int>(version),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LocalMedicationEventsTableData copyWith({
    String? id,
    String? profileId,
    String? medicationId,
    DateTime? scheduledTime,
    Value<DateTime?> recordedAt = const Value.absent(),
    String? status,
    Value<String?> notes = const Value.absent(),
    bool? isDeleted,
    String? syncStatus,
    int? version,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => LocalMedicationEventsTableData(
    id: id ?? this.id,
    profileId: profileId ?? this.profileId,
    medicationId: medicationId ?? this.medicationId,
    scheduledTime: scheduledTime ?? this.scheduledTime,
    recordedAt: recordedAt.present ? recordedAt.value : this.recordedAt,
    status: status ?? this.status,
    notes: notes.present ? notes.value : this.notes,
    isDeleted: isDeleted ?? this.isDeleted,
    syncStatus: syncStatus ?? this.syncStatus,
    version: version ?? this.version,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LocalMedicationEventsTableData copyWithCompanion(
    LocalMedicationEventsTableCompanion data,
  ) {
    return LocalMedicationEventsTableData(
      id: data.id.present ? data.id.value : this.id,
      profileId: data.profileId.present ? data.profileId.value : this.profileId,
      medicationId: data.medicationId.present
          ? data.medicationId.value
          : this.medicationId,
      scheduledTime: data.scheduledTime.present
          ? data.scheduledTime.value
          : this.scheduledTime,
      recordedAt: data.recordedAt.present
          ? data.recordedAt.value
          : this.recordedAt,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      syncStatus: data.syncStatus.present
          ? data.syncStatus.value
          : this.syncStatus,
      version: data.version.present ? data.version.value : this.version,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMedicationEventsTableData(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('medicationId: $medicationId, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    profileId,
    medicationId,
    scheduledTime,
    recordedAt,
    status,
    notes,
    isDeleted,
    syncStatus,
    version,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMedicationEventsTableData &&
          other.id == this.id &&
          other.profileId == this.profileId &&
          other.medicationId == this.medicationId &&
          other.scheduledTime == this.scheduledTime &&
          other.recordedAt == this.recordedAt &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.isDeleted == this.isDeleted &&
          other.syncStatus == this.syncStatus &&
          other.version == this.version &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LocalMedicationEventsTableCompanion
    extends UpdateCompanion<LocalMedicationEventsTableData> {
  final Value<String> id;
  final Value<String> profileId;
  final Value<String> medicationId;
  final Value<DateTime> scheduledTime;
  final Value<DateTime?> recordedAt;
  final Value<String> status;
  final Value<String?> notes;
  final Value<bool> isDeleted;
  final Value<String> syncStatus;
  final Value<int> version;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LocalMedicationEventsTableCompanion({
    this.id = const Value.absent(),
    this.profileId = const Value.absent(),
    this.medicationId = const Value.absent(),
    this.scheduledTime = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMedicationEventsTableCompanion.insert({
    required String id,
    required String profileId,
    required String medicationId,
    required DateTime scheduledTime,
    this.recordedAt = const Value.absent(),
    required String status,
    this.notes = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.syncStatus = const Value.absent(),
    this.version = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       profileId = Value(profileId),
       medicationId = Value(medicationId),
       scheduledTime = Value(scheduledTime),
       status = Value(status);
  static Insertable<LocalMedicationEventsTableData> custom({
    Expression<String>? id,
    Expression<String>? profileId,
    Expression<String>? medicationId,
    Expression<DateTime>? scheduledTime,
    Expression<DateTime>? recordedAt,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<bool>? isDeleted,
    Expression<String>? syncStatus,
    Expression<int>? version,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (profileId != null) 'profile_id': profileId,
      if (medicationId != null) 'medication_id': medicationId,
      if (scheduledTime != null) 'scheduled_time': scheduledTime,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (syncStatus != null) 'sync_status': syncStatus,
      if (version != null) 'version': version,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMedicationEventsTableCompanion copyWith({
    Value<String>? id,
    Value<String>? profileId,
    Value<String>? medicationId,
    Value<DateTime>? scheduledTime,
    Value<DateTime?>? recordedAt,
    Value<String>? status,
    Value<String?>? notes,
    Value<bool>? isDeleted,
    Value<String>? syncStatus,
    Value<int>? version,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LocalMedicationEventsTableCompanion(
      id: id ?? this.id,
      profileId: profileId ?? this.profileId,
      medicationId: medicationId ?? this.medicationId,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      recordedAt: recordedAt ?? this.recordedAt,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isDeleted: isDeleted ?? this.isDeleted,
      syncStatus: syncStatus ?? this.syncStatus,
      version: version ?? this.version,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (profileId.present) {
      map['profile_id'] = Variable<String>(profileId.value);
    }
    if (medicationId.present) {
      map['medication_id'] = Variable<String>(medicationId.value);
    }
    if (scheduledTime.present) {
      map['scheduled_time'] = Variable<DateTime>(scheduledTime.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (syncStatus.present) {
      map['sync_status'] = Variable<String>(syncStatus.value);
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMedicationEventsTableCompanion(')
          ..write('id: $id, ')
          ..write('profileId: $profileId, ')
          ..write('medicationId: $medicationId, ')
          ..write('scheduledTime: $scheduledTime, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('syncStatus: $syncStatus, ')
          ..write('version: $version, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $SyncOutboxTableTable syncOutboxTable = $SyncOutboxTableTable(
    this,
  );
  late final $LocalAppMetadataTableTable localAppMetadataTable =
      $LocalAppMetadataTableTable(this);
  late final $LocalMeasurementsTableTable localMeasurementsTable =
      $LocalMeasurementsTableTable(this);
  late final $LocalDailyChecksTableTable localDailyChecksTable =
      $LocalDailyChecksTableTable(this);
  late final $LocalDailyCheckSymptomsTableTable localDailyCheckSymptomsTable =
      $LocalDailyCheckSymptomsTableTable(this);
  late final $LocalDailyCheckDraftsTableTable localDailyCheckDraftsTable =
      $LocalDailyCheckDraftsTableTable(this);
  late final $LocalMedicationsTableTable localMedicationsTable =
      $LocalMedicationsTableTable(this);
  late final $LocalMedicationEventsTableTable localMedicationEventsTable =
      $LocalMedicationEventsTableTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    syncOutboxTable,
    localAppMetadataTable,
    localMeasurementsTable,
    localDailyChecksTable,
    localDailyCheckSymptomsTable,
    localDailyCheckDraftsTable,
    localMedicationsTable,
    localMedicationEventsTable,
  ];
}

typedef $$SyncOutboxTableTableCreateCompanionBuilder =
    SyncOutboxTableCompanion Function({
      required String id,
      required String entityType,
      required String entityId,
      required String action,
      required String payloadJson,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<int> rowid,
    });
typedef $$SyncOutboxTableTableUpdateCompanionBuilder =
    SyncOutboxTableCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> action,
      Value<String> payloadJson,
      Value<DateTime> createdAt,
      Value<int> retryCount,
      Value<String?> lastError,
      Value<int> rowid,
    });

class $$SyncOutboxTableTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOutboxTableTable> {
  $$SyncOutboxTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOutboxTableTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOutboxTableTable> {
  $$SyncOutboxTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get lastError => $composableBuilder(
    column: $table.lastError,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOutboxTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOutboxTableTable> {
  $$SyncOutboxTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
    column: $table.payloadJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get lastError =>
      $composableBuilder(column: $table.lastError, builder: (column) => column);
}

class $$SyncOutboxTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOutboxTableTable,
          SyncOutboxTableData,
          $$SyncOutboxTableTableFilterComposer,
          $$SyncOutboxTableTableOrderingComposer,
          $$SyncOutboxTableTableAnnotationComposer,
          $$SyncOutboxTableTableCreateCompanionBuilder,
          $$SyncOutboxTableTableUpdateCompanionBuilder,
          (
            SyncOutboxTableData,
            BaseReferences<
              _$AppDatabase,
              $SyncOutboxTableTable,
              SyncOutboxTableData
            >,
          ),
          SyncOutboxTableData,
          PrefetchHooks Function()
        > {
  $$SyncOutboxTableTableTableManager(
    _$AppDatabase db,
    $SyncOutboxTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOutboxTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOutboxTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOutboxTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<String> payloadJson = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxTableCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                action: action,
                payloadJson: payloadJson,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String entityId,
                required String action,
                required String payloadJson,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<String?> lastError = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOutboxTableCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                action: action,
                payloadJson: payloadJson,
                createdAt: createdAt,
                retryCount: retryCount,
                lastError: lastError,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOutboxTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOutboxTableTable,
      SyncOutboxTableData,
      $$SyncOutboxTableTableFilterComposer,
      $$SyncOutboxTableTableOrderingComposer,
      $$SyncOutboxTableTableAnnotationComposer,
      $$SyncOutboxTableTableCreateCompanionBuilder,
      $$SyncOutboxTableTableUpdateCompanionBuilder,
      (
        SyncOutboxTableData,
        BaseReferences<
          _$AppDatabase,
          $SyncOutboxTableTable,
          SyncOutboxTableData
        >,
      ),
      SyncOutboxTableData,
      PrefetchHooks Function()
    >;
typedef $$LocalAppMetadataTableTableCreateCompanionBuilder =
    LocalAppMetadataTableCompanion Function({
      required String key,
      required String value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalAppMetadataTableTableUpdateCompanionBuilder =
    LocalAppMetadataTableCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalAppMetadataTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalAppMetadataTableTable> {
  $$LocalAppMetadataTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalAppMetadataTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalAppMetadataTableTable> {
  $$LocalAppMetadataTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalAppMetadataTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalAppMetadataTableTable> {
  $$LocalAppMetadataTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalAppMetadataTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalAppMetadataTableTable,
          LocalAppMetadataTableData,
          $$LocalAppMetadataTableTableFilterComposer,
          $$LocalAppMetadataTableTableOrderingComposer,
          $$LocalAppMetadataTableTableAnnotationComposer,
          $$LocalAppMetadataTableTableCreateCompanionBuilder,
          $$LocalAppMetadataTableTableUpdateCompanionBuilder,
          (
            LocalAppMetadataTableData,
            BaseReferences<
              _$AppDatabase,
              $LocalAppMetadataTableTable,
              LocalAppMetadataTableData
            >,
          ),
          LocalAppMetadataTableData,
          PrefetchHooks Function()
        > {
  $$LocalAppMetadataTableTableTableManager(
    _$AppDatabase db,
    $LocalAppMetadataTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalAppMetadataTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalAppMetadataTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalAppMetadataTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAppMetadataTableCompanion(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalAppMetadataTableCompanion.insert(
                key: key,
                value: value,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalAppMetadataTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalAppMetadataTableTable,
      LocalAppMetadataTableData,
      $$LocalAppMetadataTableTableFilterComposer,
      $$LocalAppMetadataTableTableOrderingComposer,
      $$LocalAppMetadataTableTableAnnotationComposer,
      $$LocalAppMetadataTableTableCreateCompanionBuilder,
      $$LocalAppMetadataTableTableUpdateCompanionBuilder,
      (
        LocalAppMetadataTableData,
        BaseReferences<
          _$AppDatabase,
          $LocalAppMetadataTableTable,
          LocalAppMetadataTableData
        >,
      ),
      LocalAppMetadataTableData,
      PrefetchHooks Function()
    >;
typedef $$LocalMeasurementsTableTableCreateCompanionBuilder =
    LocalMeasurementsTableCompanion Function({
      required String id,
      required String profileId,
      required String type,
      Value<double?> heartRateBpm,
      Value<double?> systolicMmhg,
      Value<double?> diastolicMmhg,
      Value<double?> pulseBpm,
      Value<double?> temperatureCelsius,
      Value<double?> weightKg,
      Value<double?> glucoseMmolL,
      Value<String> source,
      Value<String> provenance,
      Value<String?> qualityJson,
      required DateTime recordedAt,
      Value<int> recordedUtcOffset,
      Value<String?> notes,
      Value<String?> dailyCheckId,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<int> version,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalMeasurementsTableTableUpdateCompanionBuilder =
    LocalMeasurementsTableCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> type,
      Value<double?> heartRateBpm,
      Value<double?> systolicMmhg,
      Value<double?> diastolicMmhg,
      Value<double?> pulseBpm,
      Value<double?> temperatureCelsius,
      Value<double?> weightKg,
      Value<double?> glucoseMmolL,
      Value<String> source,
      Value<String> provenance,
      Value<String?> qualityJson,
      Value<DateTime> recordedAt,
      Value<int> recordedUtcOffset,
      Value<String?> notes,
      Value<String?> dailyCheckId,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<int> version,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalMeasurementsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMeasurementsTableTable> {
  $$LocalMeasurementsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heartRateBpm => $composableBuilder(
    column: $table.heartRateBpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get systolicMmhg => $composableBuilder(
    column: $table.systolicMmhg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get diastolicMmhg => $composableBuilder(
    column: $table.diastolicMmhg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get pulseBpm => $composableBuilder(
    column: $table.pulseBpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperatureCelsius => $composableBuilder(
    column: $table.temperatureCelsius,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get glucoseMmolL => $composableBuilder(
    column: $table.glucoseMmolL,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get qualityJson => $composableBuilder(
    column: $table.qualityJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get recordedUtcOffset => $composableBuilder(
    column: $table.recordedUtcOffset,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dailyCheckId => $composableBuilder(
    column: $table.dailyCheckId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMeasurementsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMeasurementsTableTable> {
  $$LocalMeasurementsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heartRateBpm => $composableBuilder(
    column: $table.heartRateBpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get systolicMmhg => $composableBuilder(
    column: $table.systolicMmhg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get diastolicMmhg => $composableBuilder(
    column: $table.diastolicMmhg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get pulseBpm => $composableBuilder(
    column: $table.pulseBpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperatureCelsius => $composableBuilder(
    column: $table.temperatureCelsius,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get glucoseMmolL => $composableBuilder(
    column: $table.glucoseMmolL,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get qualityJson => $composableBuilder(
    column: $table.qualityJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get recordedUtcOffset => $composableBuilder(
    column: $table.recordedUtcOffset,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dailyCheckId => $composableBuilder(
    column: $table.dailyCheckId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMeasurementsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMeasurementsTableTable> {
  $$LocalMeasurementsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<double> get heartRateBpm => $composableBuilder(
    column: $table.heartRateBpm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get systolicMmhg => $composableBuilder(
    column: $table.systolicMmhg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get diastolicMmhg => $composableBuilder(
    column: $table.diastolicMmhg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get pulseBpm =>
      $composableBuilder(column: $table.pulseBpm, builder: (column) => column);

  GeneratedColumn<double> get temperatureCelsius => $composableBuilder(
    column: $table.temperatureCelsius,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get glucoseMmolL => $composableBuilder(
    column: $table.glucoseMmolL,
    builder: (column) => column,
  );

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<String> get provenance => $composableBuilder(
    column: $table.provenance,
    builder: (column) => column,
  );

  GeneratedColumn<String> get qualityJson => $composableBuilder(
    column: $table.qualityJson,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get recordedUtcOffset => $composableBuilder(
    column: $table.recordedUtcOffset,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get dailyCheckId => $composableBuilder(
    column: $table.dailyCheckId,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalMeasurementsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMeasurementsTableTable,
          LocalMeasurementsTableData,
          $$LocalMeasurementsTableTableFilterComposer,
          $$LocalMeasurementsTableTableOrderingComposer,
          $$LocalMeasurementsTableTableAnnotationComposer,
          $$LocalMeasurementsTableTableCreateCompanionBuilder,
          $$LocalMeasurementsTableTableUpdateCompanionBuilder,
          (
            LocalMeasurementsTableData,
            BaseReferences<
              _$AppDatabase,
              $LocalMeasurementsTableTable,
              LocalMeasurementsTableData
            >,
          ),
          LocalMeasurementsTableData,
          PrefetchHooks Function()
        > {
  $$LocalMeasurementsTableTableTableManager(
    _$AppDatabase db,
    $LocalMeasurementsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMeasurementsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalMeasurementsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalMeasurementsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<double?> heartRateBpm = const Value.absent(),
                Value<double?> systolicMmhg = const Value.absent(),
                Value<double?> diastolicMmhg = const Value.absent(),
                Value<double?> pulseBpm = const Value.absent(),
                Value<double?> temperatureCelsius = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> glucoseMmolL = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> provenance = const Value.absent(),
                Value<String?> qualityJson = const Value.absent(),
                Value<DateTime> recordedAt = const Value.absent(),
                Value<int> recordedUtcOffset = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> dailyCheckId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMeasurementsTableCompanion(
                id: id,
                profileId: profileId,
                type: type,
                heartRateBpm: heartRateBpm,
                systolicMmhg: systolicMmhg,
                diastolicMmhg: diastolicMmhg,
                pulseBpm: pulseBpm,
                temperatureCelsius: temperatureCelsius,
                weightKg: weightKg,
                glucoseMmolL: glucoseMmolL,
                source: source,
                provenance: provenance,
                qualityJson: qualityJson,
                recordedAt: recordedAt,
                recordedUtcOffset: recordedUtcOffset,
                notes: notes,
                dailyCheckId: dailyCheckId,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String type,
                Value<double?> heartRateBpm = const Value.absent(),
                Value<double?> systolicMmhg = const Value.absent(),
                Value<double?> diastolicMmhg = const Value.absent(),
                Value<double?> pulseBpm = const Value.absent(),
                Value<double?> temperatureCelsius = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> glucoseMmolL = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<String> provenance = const Value.absent(),
                Value<String?> qualityJson = const Value.absent(),
                required DateTime recordedAt,
                Value<int> recordedUtcOffset = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> dailyCheckId = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMeasurementsTableCompanion.insert(
                id: id,
                profileId: profileId,
                type: type,
                heartRateBpm: heartRateBpm,
                systolicMmhg: systolicMmhg,
                diastolicMmhg: diastolicMmhg,
                pulseBpm: pulseBpm,
                temperatureCelsius: temperatureCelsius,
                weightKg: weightKg,
                glucoseMmolL: glucoseMmolL,
                source: source,
                provenance: provenance,
                qualityJson: qualityJson,
                recordedAt: recordedAt,
                recordedUtcOffset: recordedUtcOffset,
                notes: notes,
                dailyCheckId: dailyCheckId,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMeasurementsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMeasurementsTableTable,
      LocalMeasurementsTableData,
      $$LocalMeasurementsTableTableFilterComposer,
      $$LocalMeasurementsTableTableOrderingComposer,
      $$LocalMeasurementsTableTableAnnotationComposer,
      $$LocalMeasurementsTableTableCreateCompanionBuilder,
      $$LocalMeasurementsTableTableUpdateCompanionBuilder,
      (
        LocalMeasurementsTableData,
        BaseReferences<
          _$AppDatabase,
          $LocalMeasurementsTableTable,
          LocalMeasurementsTableData
        >,
      ),
      LocalMeasurementsTableData,
      PrefetchHooks Function()
    >;
typedef $$LocalDailyChecksTableTableCreateCompanionBuilder =
    LocalDailyChecksTableCompanion Function({
      required String id,
      required String profileId,
      required DateTime checkDate,
      required String feeling,
      required String medicationStatus,
      Value<String?> notes,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<int> version,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalDailyChecksTableTableUpdateCompanionBuilder =
    LocalDailyChecksTableCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<DateTime> checkDate,
      Value<String> feeling,
      Value<String> medicationStatus,
      Value<String?> notes,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<int> version,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalDailyChecksTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDailyChecksTableTable> {
  $$LocalDailyChecksTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get checkDate => $composableBuilder(
    column: $table.checkDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feeling => $composableBuilder(
    column: $table.feeling,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationStatus => $composableBuilder(
    column: $table.medicationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDailyChecksTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDailyChecksTableTable> {
  $$LocalDailyChecksTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get checkDate => $composableBuilder(
    column: $table.checkDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feeling => $composableBuilder(
    column: $table.feeling,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationStatus => $composableBuilder(
    column: $table.medicationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDailyChecksTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDailyChecksTableTable> {
  $$LocalDailyChecksTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<DateTime> get checkDate =>
      $composableBuilder(column: $table.checkDate, builder: (column) => column);

  GeneratedColumn<String> get feeling =>
      $composableBuilder(column: $table.feeling, builder: (column) => column);

  GeneratedColumn<String> get medicationStatus => $composableBuilder(
    column: $table.medicationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalDailyChecksTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDailyChecksTableTable,
          LocalDailyChecksTableData,
          $$LocalDailyChecksTableTableFilterComposer,
          $$LocalDailyChecksTableTableOrderingComposer,
          $$LocalDailyChecksTableTableAnnotationComposer,
          $$LocalDailyChecksTableTableCreateCompanionBuilder,
          $$LocalDailyChecksTableTableUpdateCompanionBuilder,
          (
            LocalDailyChecksTableData,
            BaseReferences<
              _$AppDatabase,
              $LocalDailyChecksTableTable,
              LocalDailyChecksTableData
            >,
          ),
          LocalDailyChecksTableData,
          PrefetchHooks Function()
        > {
  $$LocalDailyChecksTableTableTableManager(
    _$AppDatabase db,
    $LocalDailyChecksTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDailyChecksTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalDailyChecksTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalDailyChecksTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<DateTime> checkDate = const Value.absent(),
                Value<String> feeling = const Value.absent(),
                Value<String> medicationStatus = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDailyChecksTableCompanion(
                id: id,
                profileId: profileId,
                checkDate: checkDate,
                feeling: feeling,
                medicationStatus: medicationStatus,
                notes: notes,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required DateTime checkDate,
                required String feeling,
                required String medicationStatus,
                Value<String?> notes = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDailyChecksTableCompanion.insert(
                id: id,
                profileId: profileId,
                checkDate: checkDate,
                feeling: feeling,
                medicationStatus: medicationStatus,
                notes: notes,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDailyChecksTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDailyChecksTableTable,
      LocalDailyChecksTableData,
      $$LocalDailyChecksTableTableFilterComposer,
      $$LocalDailyChecksTableTableOrderingComposer,
      $$LocalDailyChecksTableTableAnnotationComposer,
      $$LocalDailyChecksTableTableCreateCompanionBuilder,
      $$LocalDailyChecksTableTableUpdateCompanionBuilder,
      (
        LocalDailyChecksTableData,
        BaseReferences<
          _$AppDatabase,
          $LocalDailyChecksTableTable,
          LocalDailyChecksTableData
        >,
      ),
      LocalDailyChecksTableData,
      PrefetchHooks Function()
    >;
typedef $$LocalDailyCheckSymptomsTableTableCreateCompanionBuilder =
    LocalDailyCheckSymptomsTableCompanion Function({
      required String id,
      required String dailyCheckId,
      required String symptomCode,
      Value<bool> isUrgent,
      Value<String?> customDescription,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$LocalDailyCheckSymptomsTableTableUpdateCompanionBuilder =
    LocalDailyCheckSymptomsTableCompanion Function({
      Value<String> id,
      Value<String> dailyCheckId,
      Value<String> symptomCode,
      Value<bool> isUrgent,
      Value<String?> customDescription,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$LocalDailyCheckSymptomsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDailyCheckSymptomsTableTable> {
  $$LocalDailyCheckSymptomsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dailyCheckId => $composableBuilder(
    column: $table.dailyCheckId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symptomCode => $composableBuilder(
    column: $table.symptomCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isUrgent => $composableBuilder(
    column: $table.isUrgent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get customDescription => $composableBuilder(
    column: $table.customDescription,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDailyCheckSymptomsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDailyCheckSymptomsTableTable> {
  $$LocalDailyCheckSymptomsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dailyCheckId => $composableBuilder(
    column: $table.dailyCheckId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symptomCode => $composableBuilder(
    column: $table.symptomCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isUrgent => $composableBuilder(
    column: $table.isUrgent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get customDescription => $composableBuilder(
    column: $table.customDescription,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDailyCheckSymptomsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDailyCheckSymptomsTableTable> {
  $$LocalDailyCheckSymptomsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get dailyCheckId => $composableBuilder(
    column: $table.dailyCheckId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get symptomCode => $composableBuilder(
    column: $table.symptomCode,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isUrgent =>
      $composableBuilder(column: $table.isUrgent, builder: (column) => column);

  GeneratedColumn<String> get customDescription => $composableBuilder(
    column: $table.customDescription,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LocalDailyCheckSymptomsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDailyCheckSymptomsTableTable,
          LocalDailyCheckSymptomsTableData,
          $$LocalDailyCheckSymptomsTableTableFilterComposer,
          $$LocalDailyCheckSymptomsTableTableOrderingComposer,
          $$LocalDailyCheckSymptomsTableTableAnnotationComposer,
          $$LocalDailyCheckSymptomsTableTableCreateCompanionBuilder,
          $$LocalDailyCheckSymptomsTableTableUpdateCompanionBuilder,
          (
            LocalDailyCheckSymptomsTableData,
            BaseReferences<
              _$AppDatabase,
              $LocalDailyCheckSymptomsTableTable,
              LocalDailyCheckSymptomsTableData
            >,
          ),
          LocalDailyCheckSymptomsTableData,
          PrefetchHooks Function()
        > {
  $$LocalDailyCheckSymptomsTableTableTableManager(
    _$AppDatabase db,
    $LocalDailyCheckSymptomsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDailyCheckSymptomsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalDailyCheckSymptomsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalDailyCheckSymptomsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> dailyCheckId = const Value.absent(),
                Value<String> symptomCode = const Value.absent(),
                Value<bool> isUrgent = const Value.absent(),
                Value<String?> customDescription = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDailyCheckSymptomsTableCompanion(
                id: id,
                dailyCheckId: dailyCheckId,
                symptomCode: symptomCode,
                isUrgent: isUrgent,
                customDescription: customDescription,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String dailyCheckId,
                required String symptomCode,
                Value<bool> isUrgent = const Value.absent(),
                Value<String?> customDescription = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDailyCheckSymptomsTableCompanion.insert(
                id: id,
                dailyCheckId: dailyCheckId,
                symptomCode: symptomCode,
                isUrgent: isUrgent,
                customDescription: customDescription,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDailyCheckSymptomsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDailyCheckSymptomsTableTable,
      LocalDailyCheckSymptomsTableData,
      $$LocalDailyCheckSymptomsTableTableFilterComposer,
      $$LocalDailyCheckSymptomsTableTableOrderingComposer,
      $$LocalDailyCheckSymptomsTableTableAnnotationComposer,
      $$LocalDailyCheckSymptomsTableTableCreateCompanionBuilder,
      $$LocalDailyCheckSymptomsTableTableUpdateCompanionBuilder,
      (
        LocalDailyCheckSymptomsTableData,
        BaseReferences<
          _$AppDatabase,
          $LocalDailyCheckSymptomsTableTable,
          LocalDailyCheckSymptomsTableData
        >,
      ),
      LocalDailyCheckSymptomsTableData,
      PrefetchHooks Function()
    >;
typedef $$LocalDailyCheckDraftsTableTableCreateCompanionBuilder =
    LocalDailyCheckDraftsTableCompanion Function({
      required String profileId,
      Value<int> currentStep,
      Value<String?> feeling,
      Value<double?> heartRateBpm,
      Value<double?> systolicMmhg,
      Value<double?> diastolicMmhg,
      Value<double?> temperatureCelsius,
      Value<double?> weightKg,
      Value<double?> glucoseMmolL,
      Value<String?> symptomsJson,
      Value<String?> medicationStatus,
      Value<String?> notes,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalDailyCheckDraftsTableTableUpdateCompanionBuilder =
    LocalDailyCheckDraftsTableCompanion Function({
      Value<String> profileId,
      Value<int> currentStep,
      Value<String?> feeling,
      Value<double?> heartRateBpm,
      Value<double?> systolicMmhg,
      Value<double?> diastolicMmhg,
      Value<double?> temperatureCelsius,
      Value<double?> weightKg,
      Value<double?> glucoseMmolL,
      Value<String?> symptomsJson,
      Value<String?> medicationStatus,
      Value<String?> notes,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalDailyCheckDraftsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalDailyCheckDraftsTableTable> {
  $$LocalDailyCheckDraftsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get currentStep => $composableBuilder(
    column: $table.currentStep,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get feeling => $composableBuilder(
    column: $table.feeling,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get heartRateBpm => $composableBuilder(
    column: $table.heartRateBpm,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get systolicMmhg => $composableBuilder(
    column: $table.systolicMmhg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get diastolicMmhg => $composableBuilder(
    column: $table.diastolicMmhg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get temperatureCelsius => $composableBuilder(
    column: $table.temperatureCelsius,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get glucoseMmolL => $composableBuilder(
    column: $table.glucoseMmolL,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get symptomsJson => $composableBuilder(
    column: $table.symptomsJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationStatus => $composableBuilder(
    column: $table.medicationStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalDailyCheckDraftsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalDailyCheckDraftsTableTable> {
  $$LocalDailyCheckDraftsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get currentStep => $composableBuilder(
    column: $table.currentStep,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get feeling => $composableBuilder(
    column: $table.feeling,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get heartRateBpm => $composableBuilder(
    column: $table.heartRateBpm,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get systolicMmhg => $composableBuilder(
    column: $table.systolicMmhg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get diastolicMmhg => $composableBuilder(
    column: $table.diastolicMmhg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get temperatureCelsius => $composableBuilder(
    column: $table.temperatureCelsius,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get weightKg => $composableBuilder(
    column: $table.weightKg,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get glucoseMmolL => $composableBuilder(
    column: $table.glucoseMmolL,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get symptomsJson => $composableBuilder(
    column: $table.symptomsJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationStatus => $composableBuilder(
    column: $table.medicationStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalDailyCheckDraftsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalDailyCheckDraftsTableTable> {
  $$LocalDailyCheckDraftsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<int> get currentStep => $composableBuilder(
    column: $table.currentStep,
    builder: (column) => column,
  );

  GeneratedColumn<String> get feeling =>
      $composableBuilder(column: $table.feeling, builder: (column) => column);

  GeneratedColumn<double> get heartRateBpm => $composableBuilder(
    column: $table.heartRateBpm,
    builder: (column) => column,
  );

  GeneratedColumn<double> get systolicMmhg => $composableBuilder(
    column: $table.systolicMmhg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get diastolicMmhg => $composableBuilder(
    column: $table.diastolicMmhg,
    builder: (column) => column,
  );

  GeneratedColumn<double> get temperatureCelsius => $composableBuilder(
    column: $table.temperatureCelsius,
    builder: (column) => column,
  );

  GeneratedColumn<double> get weightKg =>
      $composableBuilder(column: $table.weightKg, builder: (column) => column);

  GeneratedColumn<double> get glucoseMmolL => $composableBuilder(
    column: $table.glucoseMmolL,
    builder: (column) => column,
  );

  GeneratedColumn<String> get symptomsJson => $composableBuilder(
    column: $table.symptomsJson,
    builder: (column) => column,
  );

  GeneratedColumn<String> get medicationStatus => $composableBuilder(
    column: $table.medicationStatus,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalDailyCheckDraftsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalDailyCheckDraftsTableTable,
          LocalDailyCheckDraftsTableData,
          $$LocalDailyCheckDraftsTableTableFilterComposer,
          $$LocalDailyCheckDraftsTableTableOrderingComposer,
          $$LocalDailyCheckDraftsTableTableAnnotationComposer,
          $$LocalDailyCheckDraftsTableTableCreateCompanionBuilder,
          $$LocalDailyCheckDraftsTableTableUpdateCompanionBuilder,
          (
            LocalDailyCheckDraftsTableData,
            BaseReferences<
              _$AppDatabase,
              $LocalDailyCheckDraftsTableTable,
              LocalDailyCheckDraftsTableData
            >,
          ),
          LocalDailyCheckDraftsTableData,
          PrefetchHooks Function()
        > {
  $$LocalDailyCheckDraftsTableTableTableManager(
    _$AppDatabase db,
    $LocalDailyCheckDraftsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalDailyCheckDraftsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalDailyCheckDraftsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalDailyCheckDraftsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> profileId = const Value.absent(),
                Value<int> currentStep = const Value.absent(),
                Value<String?> feeling = const Value.absent(),
                Value<double?> heartRateBpm = const Value.absent(),
                Value<double?> systolicMmhg = const Value.absent(),
                Value<double?> diastolicMmhg = const Value.absent(),
                Value<double?> temperatureCelsius = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> glucoseMmolL = const Value.absent(),
                Value<String?> symptomsJson = const Value.absent(),
                Value<String?> medicationStatus = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDailyCheckDraftsTableCompanion(
                profileId: profileId,
                currentStep: currentStep,
                feeling: feeling,
                heartRateBpm: heartRateBpm,
                systolicMmhg: systolicMmhg,
                diastolicMmhg: diastolicMmhg,
                temperatureCelsius: temperatureCelsius,
                weightKg: weightKg,
                glucoseMmolL: glucoseMmolL,
                symptomsJson: symptomsJson,
                medicationStatus: medicationStatus,
                notes: notes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String profileId,
                Value<int> currentStep = const Value.absent(),
                Value<String?> feeling = const Value.absent(),
                Value<double?> heartRateBpm = const Value.absent(),
                Value<double?> systolicMmhg = const Value.absent(),
                Value<double?> diastolicMmhg = const Value.absent(),
                Value<double?> temperatureCelsius = const Value.absent(),
                Value<double?> weightKg = const Value.absent(),
                Value<double?> glucoseMmolL = const Value.absent(),
                Value<String?> symptomsJson = const Value.absent(),
                Value<String?> medicationStatus = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalDailyCheckDraftsTableCompanion.insert(
                profileId: profileId,
                currentStep: currentStep,
                feeling: feeling,
                heartRateBpm: heartRateBpm,
                systolicMmhg: systolicMmhg,
                diastolicMmhg: diastolicMmhg,
                temperatureCelsius: temperatureCelsius,
                weightKg: weightKg,
                glucoseMmolL: glucoseMmolL,
                symptomsJson: symptomsJson,
                medicationStatus: medicationStatus,
                notes: notes,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalDailyCheckDraftsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalDailyCheckDraftsTableTable,
      LocalDailyCheckDraftsTableData,
      $$LocalDailyCheckDraftsTableTableFilterComposer,
      $$LocalDailyCheckDraftsTableTableOrderingComposer,
      $$LocalDailyCheckDraftsTableTableAnnotationComposer,
      $$LocalDailyCheckDraftsTableTableCreateCompanionBuilder,
      $$LocalDailyCheckDraftsTableTableUpdateCompanionBuilder,
      (
        LocalDailyCheckDraftsTableData,
        BaseReferences<
          _$AppDatabase,
          $LocalDailyCheckDraftsTableTable,
          LocalDailyCheckDraftsTableData
        >,
      ),
      LocalDailyCheckDraftsTableData,
      PrefetchHooks Function()
    >;
typedef $$LocalMedicationsTableTableCreateCompanionBuilder =
    LocalMedicationsTableCompanion Function({
      required String id,
      required String profileId,
      required String name,
      required String dosage,
      required String frequency,
      required DateTime startDate,
      Value<DateTime?> endDate,
      Value<String?> reminderTime,
      Value<String?> notes,
      Value<bool> isActive,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<int> version,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalMedicationsTableTableUpdateCompanionBuilder =
    LocalMedicationsTableCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> name,
      Value<String> dosage,
      Value<String> frequency,
      Value<DateTime> startDate,
      Value<DateTime?> endDate,
      Value<String?> reminderTime,
      Value<String?> notes,
      Value<bool> isActive,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<int> version,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalMedicationsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMedicationsTableTable> {
  $$LocalMedicationsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dosage => $composableBuilder(
    column: $table.dosage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMedicationsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMedicationsTableTable> {
  $$LocalMedicationsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dosage => $composableBuilder(
    column: $table.dosage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get frequency => $composableBuilder(
    column: $table.frequency,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMedicationsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMedicationsTableTable> {
  $$LocalMedicationsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get dosage =>
      $composableBuilder(column: $table.dosage, builder: (column) => column);

  GeneratedColumn<String> get frequency =>
      $composableBuilder(column: $table.frequency, builder: (column) => column);

  GeneratedColumn<DateTime> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<DateTime> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<String> get reminderTime => $composableBuilder(
    column: $table.reminderTime,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalMedicationsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMedicationsTableTable,
          LocalMedicationsTableData,
          $$LocalMedicationsTableTableFilterComposer,
          $$LocalMedicationsTableTableOrderingComposer,
          $$LocalMedicationsTableTableAnnotationComposer,
          $$LocalMedicationsTableTableCreateCompanionBuilder,
          $$LocalMedicationsTableTableUpdateCompanionBuilder,
          (
            LocalMedicationsTableData,
            BaseReferences<
              _$AppDatabase,
              $LocalMedicationsTableTable,
              LocalMedicationsTableData
            >,
          ),
          LocalMedicationsTableData,
          PrefetchHooks Function()
        > {
  $$LocalMedicationsTableTableTableManager(
    _$AppDatabase db,
    $LocalMedicationsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMedicationsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalMedicationsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalMedicationsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> dosage = const Value.absent(),
                Value<String> frequency = const Value.absent(),
                Value<DateTime> startDate = const Value.absent(),
                Value<DateTime?> endDate = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMedicationsTableCompanion(
                id: id,
                profileId: profileId,
                name: name,
                dosage: dosage,
                frequency: frequency,
                startDate: startDate,
                endDate: endDate,
                reminderTime: reminderTime,
                notes: notes,
                isActive: isActive,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String name,
                required String dosage,
                required String frequency,
                required DateTime startDate,
                Value<DateTime?> endDate = const Value.absent(),
                Value<String?> reminderTime = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isActive = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMedicationsTableCompanion.insert(
                id: id,
                profileId: profileId,
                name: name,
                dosage: dosage,
                frequency: frequency,
                startDate: startDate,
                endDate: endDate,
                reminderTime: reminderTime,
                notes: notes,
                isActive: isActive,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMedicationsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMedicationsTableTable,
      LocalMedicationsTableData,
      $$LocalMedicationsTableTableFilterComposer,
      $$LocalMedicationsTableTableOrderingComposer,
      $$LocalMedicationsTableTableAnnotationComposer,
      $$LocalMedicationsTableTableCreateCompanionBuilder,
      $$LocalMedicationsTableTableUpdateCompanionBuilder,
      (
        LocalMedicationsTableData,
        BaseReferences<
          _$AppDatabase,
          $LocalMedicationsTableTable,
          LocalMedicationsTableData
        >,
      ),
      LocalMedicationsTableData,
      PrefetchHooks Function()
    >;
typedef $$LocalMedicationEventsTableTableCreateCompanionBuilder =
    LocalMedicationEventsTableCompanion Function({
      required String id,
      required String profileId,
      required String medicationId,
      required DateTime scheduledTime,
      Value<DateTime?> recordedAt,
      required String status,
      Value<String?> notes,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<int> version,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LocalMedicationEventsTableTableUpdateCompanionBuilder =
    LocalMedicationEventsTableCompanion Function({
      Value<String> id,
      Value<String> profileId,
      Value<String> medicationId,
      Value<DateTime> scheduledTime,
      Value<DateTime?> recordedAt,
      Value<String> status,
      Value<String?> notes,
      Value<bool> isDeleted,
      Value<String> syncStatus,
      Value<int> version,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LocalMedicationEventsTableTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMedicationEventsTableTable> {
  $$LocalMedicationEventsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMedicationEventsTableTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMedicationEventsTableTable> {
  $$LocalMedicationEventsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get profileId => $composableBuilder(
    column: $table.profileId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMedicationEventsTableTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMedicationEventsTableTable> {
  $$LocalMedicationEventsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get profileId =>
      $composableBuilder(column: $table.profileId, builder: (column) => column);

  GeneratedColumn<String> get medicationId => $composableBuilder(
    column: $table.medicationId,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get scheduledTime => $composableBuilder(
    column: $table.scheduledTime,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
    column: $table.recordedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get syncStatus => $composableBuilder(
    column: $table.syncStatus,
    builder: (column) => column,
  );

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LocalMedicationEventsTableTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMedicationEventsTableTable,
          LocalMedicationEventsTableData,
          $$LocalMedicationEventsTableTableFilterComposer,
          $$LocalMedicationEventsTableTableOrderingComposer,
          $$LocalMedicationEventsTableTableAnnotationComposer,
          $$LocalMedicationEventsTableTableCreateCompanionBuilder,
          $$LocalMedicationEventsTableTableUpdateCompanionBuilder,
          (
            LocalMedicationEventsTableData,
            BaseReferences<
              _$AppDatabase,
              $LocalMedicationEventsTableTable,
              LocalMedicationEventsTableData
            >,
          ),
          LocalMedicationEventsTableData,
          PrefetchHooks Function()
        > {
  $$LocalMedicationEventsTableTableTableManager(
    _$AppDatabase db,
    $LocalMedicationEventsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMedicationEventsTableTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalMedicationEventsTableTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalMedicationEventsTableTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> profileId = const Value.absent(),
                Value<String> medicationId = const Value.absent(),
                Value<DateTime> scheduledTime = const Value.absent(),
                Value<DateTime?> recordedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMedicationEventsTableCompanion(
                id: id,
                profileId: profileId,
                medicationId: medicationId,
                scheduledTime: scheduledTime,
                recordedAt: recordedAt,
                status: status,
                notes: notes,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String profileId,
                required String medicationId,
                required DateTime scheduledTime,
                Value<DateTime?> recordedAt = const Value.absent(),
                required String status,
                Value<String?> notes = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String> syncStatus = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMedicationEventsTableCompanion.insert(
                id: id,
                profileId: profileId,
                medicationId: medicationId,
                scheduledTime: scheduledTime,
                recordedAt: recordedAt,
                status: status,
                notes: notes,
                isDeleted: isDeleted,
                syncStatus: syncStatus,
                version: version,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMedicationEventsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMedicationEventsTableTable,
      LocalMedicationEventsTableData,
      $$LocalMedicationEventsTableTableFilterComposer,
      $$LocalMedicationEventsTableTableOrderingComposer,
      $$LocalMedicationEventsTableTableAnnotationComposer,
      $$LocalMedicationEventsTableTableCreateCompanionBuilder,
      $$LocalMedicationEventsTableTableUpdateCompanionBuilder,
      (
        LocalMedicationEventsTableData,
        BaseReferences<
          _$AppDatabase,
          $LocalMedicationEventsTableTable,
          LocalMedicationEventsTableData
        >,
      ),
      LocalMedicationEventsTableData,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$SyncOutboxTableTableTableManager get syncOutboxTable =>
      $$SyncOutboxTableTableTableManager(_db, _db.syncOutboxTable);
  $$LocalAppMetadataTableTableTableManager get localAppMetadataTable =>
      $$LocalAppMetadataTableTableTableManager(_db, _db.localAppMetadataTable);
  $$LocalMeasurementsTableTableTableManager get localMeasurementsTable =>
      $$LocalMeasurementsTableTableTableManager(
        _db,
        _db.localMeasurementsTable,
      );
  $$LocalDailyChecksTableTableTableManager get localDailyChecksTable =>
      $$LocalDailyChecksTableTableTableManager(_db, _db.localDailyChecksTable);
  $$LocalDailyCheckSymptomsTableTableTableManager
  get localDailyCheckSymptomsTable =>
      $$LocalDailyCheckSymptomsTableTableTableManager(
        _db,
        _db.localDailyCheckSymptomsTable,
      );
  $$LocalDailyCheckDraftsTableTableTableManager
  get localDailyCheckDraftsTable =>
      $$LocalDailyCheckDraftsTableTableTableManager(
        _db,
        _db.localDailyCheckDraftsTable,
      );
  $$LocalMedicationsTableTableTableManager get localMedicationsTable =>
      $$LocalMedicationsTableTableTableManager(_db, _db.localMedicationsTable);
  $$LocalMedicationEventsTableTableTableManager
  get localMedicationEventsTable =>
      $$LocalMedicationEventsTableTableTableManager(
        _db,
        _db.localMedicationEventsTable,
      );
}
