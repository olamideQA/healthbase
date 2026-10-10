import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/config/app_config.dart';
import 'package:healthbase/core/security/security_service.dart';

void main() {
  group('Security & Privacy Audit - Credential & PHI Leak Guards', () {
    test('AppConfig does NOT expose or bundle Supabase service_role key', () {
      expect(AppConfig.supabaseAnonKey, isNotEmpty);
      expect(AppConfig.supabaseAnonKey.toLowerCase(), isNot(contains('service_role')));
      expect(AppConfig.supabaseAnonKey.toLowerCase(), isNot(contains('secret')));
    });

    test('AppLogger automatically sanitizes Bearer auth headers', () {
      const raw = 'Request sent with Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.token.signature';
      final sanitized = AppLogger.redact(raw);
      expect(sanitized, isNot(contains('Bearer eyJ')));
      expect(sanitized, contains('Bearer [REDACTED_TOKEN]'));
    });

    test('AppLogger automatically redacts passwords and secrets', () {
      const raw = 'User login payload: password="SuperSecretPassword123!"';
      final sanitized = AppLogger.redact(raw);
      expect(sanitized, isNot(contains('SuperSecretPassword123!')));
      expect(sanitized, contains('[REDACTED_SECRET]'));
    });

    test('AppLogger automatically sanitizes patient emails', () {
      const raw = 'Dispatching confidential clinical report to patient@example.com';
      final sanitized = AppLogger.redact(raw);
      expect(sanitized, isNot(contains('patient@example.com')));
      expect(sanitized, contains('[REDACTED_EMAIL]'));
    });

    test('AppLogger automatically sanitizes Supabase management keys', () {
      const raw = 'Configuring gateway via token: sbp_999888777abcdef';
      final sanitized = AppLogger.redact(raw);
      expect(sanitized, isNot(contains('sbp_999888777abcdef')));
      expect(sanitized, contains('[REDACTED_API_KEY]'));
    });
  });
}
