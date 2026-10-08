import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/security/security_service.dart';

void main() {
  group('AppLogger Security & Redaction', () {
    test('redacts JWT tokens from log messages', () {
      const jwt =
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJueWlyaWh4c2hnd3NhaG1vdGpoIn0.Ux3uwXkaNHxca5YpfBRi6L1I8YVFxeXPi6P_l2kVYP4';
      final logMessage = 'User authenticated with session token: $jwt';

      final sanitized = AppLogger.redact(logMessage);

      expect(sanitized, isNot(contains(jwt)));
      expect(sanitized, contains('[REDACTED_JWT]'));
    });

    test('redacts Supabase management API keys from logs', () {
      const apiKey = 'sbp_mock_sample_key_123';
      final logMessage = 'Connecting using management token: $apiKey';

      final sanitized = AppLogger.redact(logMessage);

      expect(sanitized, isNot(contains(apiKey)));
      expect(sanitized, contains('[REDACTED_API_KEY]'));
    });

    test('redacts email addresses from logs', () {
      const email = 'patient.john@example.com';
      final logMessage = 'Password reset requested for $email';

      final sanitized = AppLogger.redact(logMessage);

      expect(sanitized, isNot(contains(email)));
      expect(sanitized, contains('[REDACTED_EMAIL]'));
    });
  });
}
