import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/db/app_database.dart';
import 'package:healthbase/core/errors/failures.dart';
import 'package:healthbase/features/family/data/family_repository.dart';
import 'package:healthbase/features/family/domain/models/family_profile.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class MockSupabaseClient extends Mock implements sb.SupabaseClient {}
class MockGoTrueClient extends Mock implements sb.GoTrueClient {}
class MockUser extends Mock implements sb.User {}

void main() {
  late AppDatabase db;
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late FamilyRepository repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();

    when(() => mockUser.id).thenReturn('user_1');
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockClient.auth).thenReturn(mockAuth);

    repository = FamilyRepository(db: db, client: mockClient);
  });

  tearDown(() async {
    await db.close();
  });

  group('FamilyRepository Database Tests', () {
    test('createFamilyMember persists locally and queues sync outbox action', () async {
      // Act
      final id = await repository.createFamilyMember(
        displayName: 'Mum',
        relationshipLabel: 'Mum',
        dateOfBirth: DateTime(1965, 5, 20),
        heightCm: 165.0,
        weightKg: 68.0,
      );

      expect(id, isNotEmpty);

      // Verify persisted in SQLite
      final profiles = await repository.getFamilyProfiles();
      expect(profiles.length, 1);
      final mum = profiles.first;
      expect(mum.displayName, 'Mum');
      expect(mum.relationshipLabel, 'Mum');
      expect(mum.relationshipDisplay, 'Mum');
      expect(mum.isSelf, isFalse);
      expect(mum.isOwner, isTrue);

      // Verify sync outbox record
      final outboxEntries = await db.select(db.syncOutboxTable).get();
      expect(outboxEntries.length, 1);
      expect(outboxEntries.first.entityType, 'health_profile');
      expect(outboxEntries.first.entityId, id);
      expect(outboxEntries.first.action, 'create');
    });

    test('watchFamilyProfiles streams updated list when family member is added', () async {
      final streamFuture = repository.watchFamilyProfiles().firstWhere((list) => list.isNotEmpty);

      await repository.createFamilyMember(
        displayName: 'Papa Joe',
        relationshipLabel: 'Grandparent',
      );

      final list = await streamFuture;
      expect(list.length, 1);
      expect(list.first.displayName, 'Papa Joe');
    });

    test('removeFamilyMember soft-deletes profile and removes from active list', () async {
      final id = await repository.createFamilyMember(
        displayName: 'Spouse',
        relationshipLabel: 'Spouse',
      );

      var profiles = await repository.getFamilyProfiles();
      expect(profiles.length, 1);

      await repository.removeFamilyMember(id);

      profiles = await repository.getFamilyProfiles();
      expect(profiles, isEmpty);

      // Verify sync outbox has delete action
      final outbox = await db.select(db.syncOutboxTable).get();
      expect(outbox.any((entry) => entry.action == 'delete' && entry.entityId == id), isTrue);
    });

    test('createInvite requires connectivity (never fabricates codes)',
        () async {
      // The RPC mock is unstubbed, simulating offline: no fake code may
      // ever be returned, since fabricated codes are always rejected.
      expect(
        () => repository.createInvite(
          profileId: 'prof-123',
          role: AccessRole.view,
        ),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('acceptInvite accepts 8 or 32 char codes, rejects the rest',
        () async {
      expect(
        () => repository.acceptInvite('ABC123'),
        throwsA(isA<ValidationFailure>()),
      );
      // 32-char codes pass validation and reach the network layer
      // (unstubbed RPC mock throws UnexpectedFailure here).
      expect(
        () => repository.acceptInvite('A' * 32),
        throwsA(isA<UnexpectedFailure>()),
      );
    });
  });
}
