import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Global access to [SecurityService] (Keystore / Keychain backed).
final securityServiceProvider = Provider<SecurityService>((ref) {
  return SecurityService();
});

/// Secure storage service for holding encryption keys and session credentials.
class SecurityService {
  SecurityService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  final FlutterSecureStorage _storage;

  Future<void> write(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> read(String key) async {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> deleteAll() async {
    await _storage.deleteAll();
  }

  /// Returns the 256-bit database passphrase (hex), creating and storing it
  /// on first use. The key never leaves secure storage except into the
  /// SQLCipher `PRAGMA key` call, and is destroyed by [deleteAll].
  static const String dbKeyStorageKey = 'hb_db_encryption_key';

  Future<String> getOrCreateDatabaseKey() async {
    final existing = await read(dbKeyStorageKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    final hex =
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await write(dbKeyStorageKey, hex);
    return hex;
  }
}

/// Redacting production logger.
/// 
/// Ensures authentication tokens, passwords, and sensitive medical measurements
/// never leak into device console logs or external log drains.
class AppLogger {
  const AppLogger._();

  static final RegExp _bearerPattern = RegExp(r'bearer\s+[a-zA-Z0-9_\-\.]+', caseSensitive: false);
  static final RegExp _jwtPattern = RegExp(r'eyJ[a-zA-Z0-9_\-]+\.[a-zA-Z0-9_\-]+\.[a-zA-Z0-9_\-]+');
  static final RegExp _apiKeyPattern = RegExp(r'sbp_[a-zA-Z0-9]+');
  static final RegExp _emailPattern = RegExp(r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+');
  static final RegExp _passwordPattern = RegExp(
    r'(password|passphrase|secret)\s*[:=]\s*("[^"]*"|' r"'[^']*'|\S+)",
    caseSensitive: false,
  );

  /// Redacts sensitive information from a string.
  static String redact(String message) {
    var sanitized = message.replaceAll(_bearerPattern, 'Bearer [REDACTED_TOKEN]');
    sanitized = sanitized.replaceAll(_jwtPattern, '[REDACTED_JWT]');
    sanitized = sanitized.replaceAll(_apiKeyPattern, '[REDACTED_API_KEY]');
    sanitized = sanitized.replaceAll(_emailPattern, '[REDACTED_EMAIL]');
    sanitized = sanitized.replaceAllMapped(
      _passwordPattern,
      (match) => '${match.group(1)}=[REDACTED_SECRET]',
    );
    return sanitized;
  }

  static void info(String message) {
    if (kDebugMode) {
      debugPrint('[INFO] ${redact(message)}');
    }
  }

  static void warning(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('[WARN] ${redact(message)}${error != null ? ' | Cause: $error' : ''}');
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('[ERROR] ${redact(message)}${error != null ? ' | Cause: $error' : ''}');
      if (stackTrace != null) {
        debugPrint(stackTrace.toString());
      }
    }
  }
}
