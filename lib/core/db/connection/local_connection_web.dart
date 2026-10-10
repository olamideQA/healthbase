import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

/// Opens the WASM SQLite database on web (browsers cannot use SQLCipher).
/// Served from `web/sqlite3.wasm` + `web/drift_worker.js`. The [keyProvider]
/// is unused on web; browser data is cleared at logout instead.
Future<QueryExecutor> openPlatformExecutor(
  Future<String> Function() keyProvider,
) async {
  return driftDatabase(
    name: 'healthbase_local_db',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  );
}
