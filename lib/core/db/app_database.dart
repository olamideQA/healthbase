import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Sync outbox table to track locally recorded actions awaiting Supabase upload.
class SyncOutboxTable extends Table {
  TextColumn get id => text()();
  TextColumn get entityType => text()(); // 'measurement', 'profile', 'daily_check', etc.
  TextColumn get entityId => text()();
  TextColumn get action => text()(); // 'create', 'update', 'delete'
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local cached key-value store for app state and offline metadata.
class LocalAppMetadataTable extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {key};
}

/// Offline-first cache for measurements.
class LocalMeasurementsTable extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get type => text()(); // 'heart_rate', 'blood_pressure', 'temperature', 'weight', 'blood_glucose'

  // Metric columns in canonical scientific units
  RealColumn get heartRateBpm => real().nullable()();
  RealColumn get systolicMmhg => real().nullable()();
  RealColumn get diastolicMmhg => real().nullable()();
  RealColumn get pulseBpm => real().nullable()();
  RealColumn get temperatureCelsius => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get glucoseMmolL => real().nullable()();

  // Provenance & context
  TextColumn get source => text().withDefault(const Constant('manual'))();
  TextColumn get provenance => text().withDefault(const Constant('manually_entered'))();
  TextColumn get qualityJson => text().nullable()();
  DateTimeColumn get recordedAt => dateTime()();
  IntColumn get recordedUtcOffset => integer().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
  TextColumn get dailyCheckId => text().nullable()();

  // Sync tracking
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))(); // 'synced', 'pending_insert', 'pending_update', 'pending_delete', 'sync_error'
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local table for daily health checks.
class LocalDailyChecksTable extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  DateTimeColumn get checkDate => dateTime()(); // calendar date
  TextColumn get feeling => text()(); // 'good', 'okay', 'not_great', 'unwell'
  TextColumn get medicationStatus => text()(); // 'yes', 'no', 'some', 'none_scheduled'
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local table for daily check symptoms.
class LocalDailyCheckSymptomsTable extends Table {
  TextColumn get id => text()();
  TextColumn get dailyCheckId => text()();
  TextColumn get symptomCode => text()();
  BoolColumn get isUrgent => boolean().withDefault(const Constant(false))();
  TextColumn get customDescription => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local table for auto-saving daily check draft progress.
class LocalDailyCheckDraftsTable extends Table {
  TextColumn get profileId => text()();
  IntColumn get currentStep => integer().withDefault(const Constant(0))();
  TextColumn get feeling => text().nullable()();
  RealColumn get heartRateBpm => real().nullable()();
  RealColumn get systolicMmhg => real().nullable()();
  RealColumn get diastolicMmhg => real().nullable()();
  RealColumn get temperatureCelsius => real().nullable()();
  RealColumn get weightKg => real().nullable()();
  RealColumn get glucoseMmolL => real().nullable()();
  TextColumn get symptomsJson => text().nullable()();
  TextColumn get medicationStatus => text().nullable()();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {profileId};
}

/// Local offline-first table for user medications.
class LocalMedicationsTable extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get name => text()();
  TextColumn get dosage => text()(); // User-entered free text, never calculated
  TextColumn get frequency => text()(); // 'daily', 'twice_daily', 'three_times_daily', 'as_needed', 'weekly'
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get endDate => dateTime().nullable()();
  TextColumn get reminderTime => text().nullable()(); // e.g. "08:00"
  TextColumn get notes => text().nullable()();
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Local offline-first table for medication adherence events.
class LocalMedicationEventsTable extends Table {
  TextColumn get id => text()();
  TextColumn get profileId => text()();
  TextColumn get medicationId => text()();
  DateTimeColumn get scheduledTime => dateTime()();
  DateTimeColumn get recordedAt => dateTime().nullable()();
  TextColumn get status => text()(); // 'taken', 'missed', 'not_recorded'
  TextColumn get notes => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  TextColumn get syncStatus => text().withDefault(const Constant('synced'))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [
  SyncOutboxTable,
  LocalAppMetadataTable,
  LocalMeasurementsTable,
  LocalDailyChecksTable,
  LocalDailyCheckSymptomsTable,
  LocalDailyCheckDraftsTable,
  LocalMedicationsTable,
  LocalMedicationEventsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'healthbase_local_db'));

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(localMedicationsTable);
            await m.createTable(localMedicationEventsTable);
          }
        },
      );
}
