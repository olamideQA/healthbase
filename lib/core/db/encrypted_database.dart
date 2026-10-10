import 'package:drift/drift.dart';

import '../security/security_service.dart';
import 'app_database.dart';
import 'connection/local_connection_stub.dart'
    if (dart.library.ffi) 'connection/local_connection_native.dart'
    if (dart.library.js_interop) 'connection/local_connection_web.dart'
    as platform_conn;

/// Opens the app database, encrypted at rest on phones.
///
/// - Android/iOS: SQLCipher-encrypted file; the 256-bit passphrase lives in
///   [SecurityService] (Keystore/Keychain). Legacy plaintext installs are
///   upgraded in place; corrupt files are quarantined, never fatal.
/// - Web: WASM SQLite (browsers cannot use SQLCipher); data is cleared at
///   logout via [wipeLocalData].
Future<AppDatabase> openEncryptedAppDatabase(SecurityService security) {
  return platform_conn
      .openPlatformExecutor(security.getOrCreateDatabaseKey)
      .then(AppDatabase.new);
}

/// Deletes every local health row plus all sync metadata, vacuums the file,
/// and destroys the encryption key in secure storage.
///
/// Safe to call on any platform (keeps the connection open, so providers
/// and repositories keep working). Call BEFORE signing out / deleting the
/// account so no health data survives the session.
Future<void> wipeLocalData({
  required AppDatabase db,
  required SecurityService security,
}) async {
  await db.transaction(() async {
    for (final TableInfo<Table, Object?> table in db.allTables) {
      await db.delete(table).go();
    }
  });
  try {
    await db.customStatement('VACUUM;');
  } catch (_) {
    // VACUUM is best-effort (some web backends reject it); rows are
    // already deleted above, which is what matters.
  }
  await security.deleteAll();
}

/// Counts local rows still awaiting upload (pending or failed), across all
/// synced tables. Used for the "unsynced data" logout warning.
Future<int> countPendingLocalChanges(AppDatabase db) async {
  var total = 0;
  total += await _countUnsynced(
      db, db.localMeasurementsTable, db.localMeasurementsTable.syncStatus);
  total += await _countUnsynced(
      db, db.localDailyChecksTable, db.localDailyChecksTable.syncStatus);
  total += await _countUnsynced(
      db, db.localMedicationsTable, db.localMedicationsTable.syncStatus);
  total += await _countUnsynced(db, db.localMedicationEventsTable,
      db.localMedicationEventsTable.syncStatus);
  total += await _countUnsynced(db, db.localFamilyProfilesTable,
      db.localFamilyProfilesTable.syncStatus);
  total += await _countUnsynced(
      db, db.localProfileAccessTable, db.localProfileAccessTable.syncStatus);
  return total;
}

Future<int> _countUnsynced(
  GeneratedDatabase db,
  TableInfo<Table, Object?> table,
  GeneratedColumn<String> statusColumn,
) async {
  final count = countAll(filter: statusColumn.equals('synced').not());
  final query = db.selectOnly(table)..addColumns([count]);
  final row = await query.getSingleOrNull();
  return row?.read(count) ?? 0;
}
