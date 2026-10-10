import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/security/secure_session_storage.dart';
import 'package:healthbase/core/security/security_service.dart';
import 'package:mocktail/mocktail.dart';

class MapBackedStorage extends Mock implements FlutterSecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      values.remove(key);
    } else {
      values[key] = value;
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return values[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.remove(key);
  }

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    values.clear();
  }
}

void main() {
  late MapBackedStorage storage;
  late SecureSessionStorage sessions;

  setUp(() {
    storage = MapBackedStorage();
    sessions = SecureSessionStorage(SecurityService(storage: storage));
  });

  test('session round-trips through secure storage (never plaintext prefs)',
      () async {
    expect(await sessions.hasAccessToken(), isFalse);

    final payload = jsonEncode({
      'access_token': 'header.payload.signature',
      'refresh_token': 'refresh-123',
    });
    await sessions.persistSession(payload);

    expect(await sessions.hasAccessToken(), isTrue);
    expect(await sessions.accessToken(), 'header.payload.signature');
    expect(
      storage.values[SecureSessionStorage.sessionStorageKey],
      payload,
    );
  });

  test('logout removes the session decisively', () async {
    await sessions.persistSession(jsonEncode({'access_token': 'abc'}));
    await sessions.removePersistedSession();

    expect(await sessions.hasAccessToken(), isFalse);
    expect(await sessions.accessToken(), isNull);
  });

  test('corrupt session reads as signed out', () async {
    await sessions.persistSession('not-json{{');
    expect(await sessions.hasAccessToken(), isTrue);
    expect(await sessions.accessToken(), isNull);
  });
}
