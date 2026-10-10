import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlcipher_flutter_libs/sqlcipher_flutter_libs.dart';
import 'package:sqlite3/open.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3lib;

/// Opens the SQLCipher-encrypted app database on Android/iOS/desktop.
///
/// The passphrase ([hexKey] via [keyProvider]) is a 256-bit random value
/// held in secure storage. Legacy plaintext installs are exported into a
/// fresh encrypted file on first run; corrupt files are quarantined aside
/// so the app never bricks (synced data is re-pulled after login).
Future<QueryExecutor> openPlatformExecutor(
  Future<String> Function() keyProvider,
) async {
  if (Platform.isAndroid) {
    await applyWorkaroundToOpenSqlCipherOnOldAndroidVersions();
    open.overrideFor(OperatingSystem.android, openCipherOnAndroid);
  } else if (Platform.isIOS) {
    // SQLCipher is statically linked on iOS: use the process library.
    open.overrideFor(OperatingSystem.iOS, () => DynamicLibrary.process());
  }
  // Desktop/dev builds use the default sqlite3 library (no cipher).

  final dir = await getApplicationDocumentsDirectory();
  final dbPath = p.join(dir.path, 'healthbase_local_db.sqlite');
  final hexKey = await keyProvider();
  final raw = _openWithUpgrade(dbPath, hexKey);
  return NativeDatabase.opened(raw);
}

sqlite3lib.Database _openWithUpgrade(String dbPath, String hexKey) {
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
    // Missing file is the expected case.
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
