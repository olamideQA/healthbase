import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';

void main() {
  group('HealthProfile & UnitSystem Model Tests', () {
    test('parses full database json into HealthProfile correctly', () {
      final json = <String, dynamic>{
        'id': 'profile-001',
        'owner_account_id': 'account-001',
        'is_self': true,
        'display_name': 'Sarah Connor',
        'date_of_birth': '1984-05-12',
        'sex': 'female',
        'height_cm': 165.5,
        'weight_kg': 60.2,
        'onboarding_completed_at': '2026-10-07T12:00:00Z',
        'created_at': '2026-10-07T10:00:00Z',
        'updated_at': '2026-10-07T11:00:00Z',
      };

      final profile = HealthProfile.fromJson(
        json,
        preferredUnits: UnitSystem.metric,
      );

      expect(profile.id, 'profile-001');
      expect(profile.ownerAccountId, 'account-001');
      expect(profile.isSelf, isTrue);
      expect(profile.displayName, 'Sarah Connor');
      expect(profile.sex, SexType.female);
      expect(profile.heightCm, 165.5);
      expect(profile.weightKg, 60.2);
      expect(profile.isOnboardingCompleted, isTrue);
      expect(profile.preferredUnits, UnitSystem.metric);
    });

    test('toUpdateJson serializes only modified/present fields', () {
      final profile = HealthProfile(
        id: 'p1',
        ownerAccountId: 'a1',
        isSelf: true,
        displayName: 'John',
        heightCm: 180.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final updateMap = profile.toUpdateJson();

      expect(updateMap['display_name'], 'John');
      expect(updateMap['height_cm'], 180.0);
      expect(updateMap.containsKey('owner_account_id'), isFalse);
      expect(updateMap.containsKey('is_self'), isFalse);
    });

    test('SexType converts to and from DB enum values accurately', () {
      expect(SexType.fromDbValue('female'), SexType.female);
      expect(SexType.fromDbValue('male'), SexType.male);
      expect(SexType.fromDbValue('intersex'), SexType.intersex);
      expect(SexType.fromDbValue('prefer_not_to_say'), SexType.preferNotToSay);
      expect(SexType.fromDbValue('invalid'), isNull);

      expect(SexType.female.toDbValue(), 'female');
      expect(SexType.preferNotToSay.toDbValue(), 'prefer_not_to_say');
    });

    test('UnitSystem handles conversions properly', () {
      expect(UnitSystem.fromDbValue('metric'), UnitSystem.metric);
      expect(UnitSystem.fromDbValue('imperial'), UnitSystem.imperial);
      expect(UnitSystem.fromDbValue(null), UnitSystem.metric);
      expect(UnitSystem.metric.toDbValue(), 'metric');
      expect(UnitSystem.imperial.toDbValue(), 'imperial');
    });
  });
}
