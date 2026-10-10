import 'dart:convert';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'security_service.dart';

/// Supabase session storage backed by [SecurityService] (Keystore /
/// Keychain on phones) instead of the default plaintext SharedPreferences.
///
/// Sessions are created on login, refreshed automatically, and destroyed
/// by [SecurityService.deleteAll] on logout — so signing out always
/// removes every credential from the device.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage(this._security);

  final SecurityService _security;

  /// Storage key for the serialized Supabase session (tokens included).
  static const String sessionStorageKey = 'hb_supabase_session';

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    final raw = await _security.read(sessionStorageKey);
    return raw != null && raw.isNotEmpty;
  }

  @override
  Future<String?> accessToken() async {
    final raw = await _security.read(sessionStorageKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      if (map is Map) return map['access_token'] as String?;
    } catch (_) {
      // Corrupt entry: treat as signed out; refresh will replace it.
    }
    return null;
  }

  @override
  Future<void> persistSession(String persistSessionString) {
    return _security.write(sessionStorageKey, persistSessionString);
  }

  @override
  Future<void> removePersistedSession() {
    return _security.delete(sessionStorageKey);
  }
}
