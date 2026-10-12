import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

/// Opens the WASM SQLite database on web (browsers cannot use SQLCipher).
/// Served from `web/sqlite3.wasm` + `web/drift_worker.js`. The [keyProvider]
/// is unused on web; browser data is cleared at logout instead.
Future<QueryExecutor> openPlatformExecutor(
  Future<String> Function() keyProvider,
) async {
  final result = await WasmDatabase.open(
    databaseName: 'healthbase_local_db',
    sqlite3Uri: Uri.parse('sqlite3.wasm'),
    driftWorkerUri: Uri.parse('drift_worker.js'),
  );
  return result.resolvedExecutor;
}
