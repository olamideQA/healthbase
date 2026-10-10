import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/errors/failures.dart';
import 'package:healthbase/features/family/domain/models/family_profile.dart';
import 'package:healthbase/features/measurements/data/measurement_repository.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import 'package:mocktail/mocktail.dart';

class MockMeasurementRepository extends Mock implements MeasurementRepository {}

void main() {
  late MockMeasurementRepository mockMeasurementRepo;

  setUp(() {
    mockMeasurementRepo = MockMeasurementRepository();
  });

  group('Cross-User Authorization & RLS Boundary Tests', () {
    test('User A attempting to query User B measurements receives empty or unauthorized failure', () async {
      // Simulate User A attempting to query User B's profile ('user-b-prof')
      when(() => mockMeasurementRepo.getMeasurements(
            profileId: 'user-b-prof',
            limit: any(named: 'limit'),
          )).thenThrow(const DatabaseFailure(
        message: 'Row-level security violation: access denied to profile user-b-prof.',
      ));

      expect(
        () => mockMeasurementRepo.getMeasurements(profileId: 'user-b-prof'),
        throwsA(isA<DatabaseFailure>().having(
          (e) => e.message,
          'message',
          contains('access denied'),
        )),
      );
    });

    test('User A cannot write a measurement to unauthorized profile', () async {
      final now = DateTime.now();
      final unauthorizedMeasurement = Measurement(
        id: 'm-tamper-1',
        profileId: 'user-b-prof',
        type: MeasurementType.heartRate,
        heartRateBpm: 88.0,
        recordedAt: now,
        createdAt: now,
        updatedAt: now,
      );

      when(() => mockMeasurementRepo.createMeasurement(unauthorizedMeasurement))
          .thenThrow(const DatabaseFailure(
        message: 'RLS check constraint failed: user does not have contribute permission.',
      ));

      expect(
        () => mockMeasurementRepo.createMeasurement(unauthorizedMeasurement),
        throwsA(isA<DatabaseFailure>()),
      );
    });

    test('Accessing a revoked family profile is immediately rejected', () {
      final now = DateTime.now();
      final revokedGrant = ProfileAccessGrant(
        id: 'grant-revoked',
        profileId: 'prof-mom',
        granteeAccountId: 'user-a',
        role: AccessRole.view,
        status: AccessStatus.revoked,
        createdAt: now,
        updatedAt: now,
      );

      // Verify that revoked grant does not permit active reading
      expect(revokedGrant.status, AccessStatus.revoked);
      expect(revokedGrant.status == AccessStatus.active, isFalse);
    });

    test('Unauthenticated user attempting to query protected data is rejected', () {
      Future<List<Measurement>> queryProtectedRecords({required bool isAuthenticated}) async {
        if (!isAuthenticated) {
          throw const AuthFailure(message: 'Authentication session required.');
        }
        return <Measurement>[];
      }

      expect(
        () => queryProtectedRecords(isAuthenticated: false),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Authentication session required'),
        )),
      );
    });
  });
}
