import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3lib;

import '../security/security_service.dart';
import 'app_database.dart';

/// Name of the local SQLite file (native) / database (web).
const String kLocalDbName = 'healthbase_local_db';

/// Storage key for the SQLCipher passphrase (hex) in secure storage.
const String kDbKeyStorageKey = 'hb_db_encryption_key';

/// Opens the app database, encrypted at rest on phones.
///
/// - Web: WASM SQLite (browser storage cannot use SQLCipher). Data is
///   cleared at logout; see [wipeLocalData].
/// - Android/iOS/desktop: SQLCipher-encrypted file. The passphrase is a
///   256-bit random value held in [SecurityService] (Keystore/Keychain).
///   Legacy plaintext installs are upgraded in place (exported into a fresh
///   encrypted file, original removed).
///
/// If the file is corrupt (neither the stored key nor a plaintext upgrade
/// works), it is moved aside with a `.corrupt-<timestamp>` suffix and a
/// fresh encrypted database is created, so the app never bricks. Synced
/// data is recovered from Supabase on next login; unsynced rows are lost.
Future<AppDatabase> openEncryptedAppDatabase(SecurityService security) async {
  if (kIsWeb) {
    return AppDatabase(
      driftDatabase(
        name: kLocalDbName,
        web: DriftWebOptions(
          sqlite3Wasm: Uri.parse('sqlite3.wasm'),
          driftWorker: Uri.parse('drift_worker.js'),
        ),
      ),
    );
  }

  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  } else if (Platform.isIOS) {
    open.overrideFor(OperatingSystem.iOS, () => DynamicLibrary.process());
  }

  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, '$kLocalDbName.sqlite');
  final hexKey = await security.getOrCreateDatabaseKey();
  final raw = _openNativeWithUpgrade(dbPath, hexKey);
  return AppDatabase(NativeDatabase.opened(raw));
}

/// Opens [dbPath] with SQLCipher key [hexKey], upgrading a legacy
/// plaintext database on first run after this change ships.
sqlite3lib.Database _openNativeWithUpgrade(String dbPath, String hexKey) {
  final keyPragma = 'PRAGMA key = "x\'$hexKey\'"';

  // 1. Fresh install (no file yet) or already-encrypted database.
  try {
    final db = sqlite3lib.sqlite3.open(dbPath);
    try {
      db.execute(keyPragma);
      db.select('SELECT count(*) FROM sqlite_master;');
      return db;
    } catch (_) {
      db.dispose();
      rethrow;
    }
  } on sqlite3lib.SqliteException catch (_) {
    // Wrong key or legacy plaintext file — fall through to upgrade path.
    // (A brand-new empty file never reaches here: PRAGMA key + SELECT
    // succeed on it.)
  }

  // 2. Legacy plaintext database: verify, then export into encrypted file.
  final plain = sqlite3lib.sqlite3.open(dbPath);
  try {
    plain.select('SELECT count(*) FROM sqlite_master;');
  } catch (_) {
    plain.dispose();
    _quarantineCorruptFile(dbPath);
    final fresh = sqlite3lib.sqlite3.open(dbPath);
    fresh.execute(keyPragma);
    return fresh;
  }

  final tmpPath = '$dbPath.migrating';
  _deleteIfExists(tmpPath);
  final safeTmp = tmpPath.replaceAll("'", "''");
  plain.execute('ATTACH DATABASE \'$safeTmp\' AS encrypted KEY "$keyPragma"');
  plain.execute('SELECT sqlcipher_export(\'encrypted\');');
  plain.execute('DETACH DATABASE encrypted;');
  plain.dispose();

  _deleteIfExists(dbPath);
  File(tmpPath).renameSync(dbPath);

  final db = sqlite3lib.sqlite3.open(dbPath);
  db.execute(keyPragma);
  db.select('SELECT count(*) FROM sqlite_master;');
  return db;
}

void _deleteIfExists(String path) {
  try {
    File(path).deleteSync();
  } catch (_) {
    // Missing file is the expected case; anything else is retried by caller.
  }
}

void _quarantineCorruptFile(String dbPath) {
  try {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    File(dbPath).renameSync('$dbPath.corrupt-$stamp');
  } catch (_) {
    _deleteIfExists(dbPath);
  }
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
  total += await _countUnsynced(db.localMedicationEventsTable,
      db.localMedicationEventsTable.syncStatus);
  total += await _countUnsynced(db.localFamilyProfilesTable,
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
