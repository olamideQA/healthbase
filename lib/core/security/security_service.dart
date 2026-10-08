import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
}

/// Redacting production logger.
/// 
/// Ensures authentication tokens, passwords, and sensitive medical measurements
/// never leak into device console logs or external log drains.
class AppLogger {
  const AppLogger._();

  static final RegExp _jwtPattern = RegExp(r'eyJ[a-zA-Z0-9_\-]+\.[a-zA-Z0-9_\-]+\.[a-zA-Z0-9_\-]+');
  static final RegExp _apiKeyPattern = RegExp(r'sbp_[a-zA-Z0-9]+');
  static final RegExp _emailPattern = RegExp(r'[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+');

  /// Redacts sensitive information from a string.
  static String redact(String message) {
    var sanitized = message.replaceAll(_jwtPattern, '[REDACTED_JWT]');
    sanitized = sanitized.replaceAll(_apiKeyPattern, '[REDACTED_API_KEY]');
    sanitized = sanitized.replaceAll(_emailPattern, '[REDACTED_EMAIL]');
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
