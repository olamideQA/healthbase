import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/family/domain/models/family_profile.dart';

void main() {
  group('Loop 11 Family Health Domain & Permission Tests', () {
    test('Non-biological relationships: supports customizable labels without biological assumptions', () {
      expect(RelationshipCategory.commonOptions, containsAll(['Mum', 'Dad', 'Spouse', 'Partner', 'Grandparent', 'Child', 'Dependent']));
      expect(
        RelationshipCategory.clinicalDisclaimer,
        contains('does not assume biological relationships'),
      );
    });

    test('AccessRole hierarchy and satisfies check', () {
      expect(AccessRole.view.satisfies(AccessRole.view), isTrue);
      expect(AccessRole.view.satisfies(AccessRole.contribute), isFalse);
      expect(AccessRole.view.satisfies(AccessRole.manage), isFalse);

      expect(AccessRole.contribute.satisfies(AccessRole.view), isTrue);
      expect(AccessRole.contribute.satisfies(AccessRole.contribute), isTrue);
      expect(AccessRole.contribute.satisfies(AccessRole.manage), isFalse);

      expect(AccessRole.manage.satisfies(AccessRole.view), isTrue);
      expect(AccessRole.manage.satisfies(AccessRole.contribute), isTrue);
      expect(AccessRole.manage.satisfies(AccessRole.manage), isTrue);
    });

    test('FamilyProfile permission scoping: owner has full access regardless of granted role', () {
      final ownerProfile = FamilyProfile(
        id: 'prof-owner',
        ownerAccountId: 'user-1',
        isSelf: false,
        displayName: 'Mum',
        relationshipLabel: 'Mum',
        effectiveRole: AccessRole.view, // Even if set to view, owner flag grants full access
        isOwner: true,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(ownerProfile.canView, isTrue);
      expect(ownerProfile.canContribute, isTrue);
      expect(ownerProfile.canManage, isTrue);
      expect(ownerProfile.relationshipDisplay, 'Mum');
    });

    test('FamilyProfile permission scoping: non-owner with view-only cannot contribute or manage', () {
      final viewOnlyProfile = FamilyProfile(
        id: 'prof-shared',
        ownerAccountId: 'user-other',
        isSelf: false,
        displayName: 'Dad',
        relationshipLabel: 'Dad',
        effectiveRole: AccessRole.view,
        isOwner: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(viewOnlyProfile.canView, isTrue);
      expect(viewOnlyProfile.canContribute, isFalse);
      expect(viewOnlyProfile.canManage, isFalse);
    });

    test('FamilyProfile permission scoping: non-owner with contribute role can view and contribute but not manage', () {
      final contributorProfile = FamilyProfile(
        id: 'prof-shared',
        ownerAccountId: 'user-other',
        isSelf: false,
        displayName: 'Grandparent',
        relationshipLabel: 'Grandparent',
        effectiveRole: AccessRole.contribute,
        isOwner: false,
        createdAt: DateTime(2026, 1, 1),
        updatedAt: DateTime(2026, 1, 1),
      );

      expect(contributorProfile.canView, isTrue);
      expect(contributorProfile.canContribute, isTrue);
      expect(contributorProfile.canManage, isFalse);
    });

    test('ProfileInvite lifecycle: valid, expired, and used status check', () {
      final validInvite = ProfileInvite(
        id: 'inv-1',
        profileId: 'prof-1',
        role: AccessRole.contribute,
        inviteCode: 'A1B2C3D4',
        createdBy: 'user-1',
        expiresAt: DateTime.now().add(const Duration(days: 3)),
        isUsed: false,
        createdAt: DateTime.now(),
      );

      expect(validInvite.isExpired, isFalse);
      expect(validInvite.isValid, isTrue);

      final expiredInvite = ProfileInvite(
        id: 'inv-2',
        profileId: 'prof-1',
        role: AccessRole.view,
        inviteCode: 'EXPIRED1',
        createdBy: 'user-1',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
        isUsed: false,
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
      );

      expect(expiredInvite.isExpired, isTrue);
      expect(expiredInvite.isValid, isFalse);

      final usedInvite = ProfileInvite(
        id: 'inv-3',
        profileId: 'prof-1',
        role: AccessRole.manage,
        inviteCode: 'USED1234',
        createdBy: 'user-1',
        expiresAt: DateTime.now().add(const Duration(days: 3)),
        isUsed: true,
        createdAt: DateTime.now(),
      );

      expect(usedInvite.isUsed, isTrue);
      expect(usedInvite.isValid, isFalse);
    });
  });
}
