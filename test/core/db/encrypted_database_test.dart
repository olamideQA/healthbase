import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/db/app_database.dart';
import 'package:healthbase/core/db/encrypted_database.dart';
import 'package:healthbase/core/security/security_service.dart';
import 'package:mocktail/mocktail.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

/// In-memory stand-in for platform secure storage.
class MapBackedStorage extends Mock implements FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> write(
      {required String key,
      required String? value,
      IOSOptions? iOptions,
      AndroidOptions? aOptions,
      LinuxOptions? lOptions,
      WebOptions? webOptions,
      MacOsOptions? mOptions,
      WindowsOptions? wOptions}) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<String?> read(
      {required String key,
      IOSOptions? iOptions,
      AndroidOptions? aOptions,
      LinuxOptions? lOptions,
      WebOptions? webOptions,
      MacOsOptions? mOptions,
      WindowsOptions? wOptions}) async {
    return values[key];
  }

  @override
  Future<void> delete(
      {required String key,
      IOSOptions? iOptions,
      AndroidOptions? aOptions,
      LinuxOptions? lOptions,
      WebOptions? webOptions,
      MacOsOptions? mOptions,
      WindowsOptions? wOptions}) async {
    values.remove(key);
  }

  @override
  Future<void> deleteAll(
      {IOSOptions? iOptions,
      AndroidOptions? aOptions,
      LinuxOptions? lOptions,
      WebOptions? webOptions,
      MacOsOptions? mOptions,
      WindowsOptions? wOptions}) async {
    values.clear();
  }
}

void main() {
  group('Database encryption key', () {
    test('same key is returned on repeat calls (created once)', () async {
      final security = SecurityService(storage: MapBackedStorage());

      final first = await security.getOrCreateDatabaseKey();
      final second = await security.getOrCreateDatabaseKey();

      expect(first, isNotEmpty);
      expect(second, first);
      // 256-bit key as 64 hex chars.
      expect(RegExp(r'^[0-9a-f]{64}$').hasMatch(first), isTrue);
    });

    test('key is stored under the documented storage key', () async {
      final storage = MapBackedStorage();
      final security = SecurityService(storage: storage);

      final key = await security.getOrCreateDatabaseKey();
      expect(storage.values[SecurityService.dbKeyStorageKey], key);
    });
  });

  group('wipeLocalData', () {
    late AppDatabase db;
    late MapBackedStorage storage;
    late SecurityService security;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      storage = MapBackedStorage();
      security = SecurityService(storage: storage);
    });

    tearDown(() async {
      await db.close();
    });

    test('deletes all health rows and destroys the key', () async {
      final now = DateTime.now();
      await db.into(db.localMeasurementsTable).insert(
            LocalMeasurementsTableCompanion.insert(
              id: 'm-1',
              profileId: 'p-1',
              type: 'heart_rate',
              heartRateBpm: const Value(72.0),
              recordedAt: now,
              syncStatus: const Value('pending_insert'),
            ),
          );
      await db.into(db.localDailyChecksTable).insert(
            LocalDailyChecksTableCompanion.insert(
              id: 'c-1',
              profileId: 'p-1',
              checkDate: now,
              feeling: 'good',
              medicationStatus: 'yes',
            ),
          );
      await security.getOrCreateDatabaseKey();
      expect(storage.values, isNotEmpty);

      await wipeLocalData(db: db, security: security);

      final measurements = await db.select(db.localMeasurementsTable).get();
      final checks = await db.select(db.localDailyChecksTable).get();
      expect(measurements, isEmpty);
      expect(checks, isEmpty);
      // Encryption key destroyed: a fresh key is created afterwards.
      expect(storage.values, isEmpty);
    });

    test('countPendingLocalChanges counts only unsynced rows', () async {
      final now = DateTime.now();
      Future<void> addMeasurement(String id, String status) =>
          db.into(db.localMeasurementsTable).insert(
                LocalMeasurementsTableCompanion.insert(
                  id: id,
                  profileId: 'p-1',
                  type: 'heart_rate',
                  heartRateBpm: const Value(70.0),
                  recordedAt: now,
                  syncStatus: Value(status),
                ),
              );

      expect(await countPendingLocalChanges(db), 0);

      await addMeasurement('m-synced', 'synced');
      await addMeasurement('m-pending', 'pending_insert');
      await addMeasurement('m-error', 'sync_error');
      expect(await countPendingLocalChanges(db), 2);

      await wipeLocalData(db: db, security: security);
      expect(await countPendingLocalChanges(db), 0);
    });
  });
}
