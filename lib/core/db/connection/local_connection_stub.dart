import 'package:drift/drift.dart';

/// Fallback when neither `dart:ffi` nor web JS interop is available.
/// Real platforms use the native (SQLCipher) or web (WASM) file instead.
Future<QueryExecutor> openPlatformExecutor(
  Future<String> Function() keyProvider,
) {
  throw UnimplementedError(
    'No local database implementation for this platform.',
  );
}
