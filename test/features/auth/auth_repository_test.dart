import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/errors/failures.dart';
import 'package:healthbase/features/auth/data/auth_repository.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class MockSupabaseClient extends Mock implements sb.SupabaseClient {}
class MockGoTrueClient extends Mock implements sb.GoTrueClient {}
class MockUser extends Mock implements sb.User {}
class MockAuthResponse extends Mock implements sb.AuthResponse {}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late AuthRepository repository;

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    repository = AuthRepository(mockClient);
  });

  group('AuthRepository Unit Tests', () {
    test('currentUser returns mapped AuthUser when user is present', () {
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-123');
      when(() => mockUser.email).thenReturn('patient@example.com');
      when(() => mockUser.emailConfirmedAt).thenReturn('2026-10-07T12:00:00Z');
      when(() => mockUser.userMetadata).thenReturn({'display_name': 'Jane Doe'});
      when(() => mockAuth.currentUser).thenReturn(mockUser);

      final user = repository.currentUser;

      expect(user, isNotNull);
      expect(user!.id, 'user-123');
      expect(user.email, 'patient@example.com');
      expect(user.isEmailConfirmed, isTrue);
      expect(user.displayName, 'Jane Doe');
    });

    test('currentUser returns null when no session exists', () {
      when(() => mockAuth.currentUser).thenReturn(null);
      expect(repository.currentUser, isNull);
    });

    test('signInWithPassword succeeds on valid credentials', () async {
      final mockUser = MockUser();
      when(() => mockUser.id).thenReturn('user-456');
      when(() => mockUser.email).thenReturn('user@test.com');
      when(() => mockUser.emailConfirmedAt).thenReturn(null);
      when(() => mockUser.userMetadata).thenReturn({});

      final mockResponse = MockAuthResponse();
      when(() => mockResponse.user).thenReturn(mockUser);

      when(() => mockAuth.signInWithPassword(
            email: 'user@test.com',
            password: 'Password123!',
          )).thenAnswer((_) async => mockResponse);

      final result = await repository.signInWithPassword(
        email: 'user@test.com',
        password: 'Password123!',
      );

      expect(result.id, 'user-456');
      expect(result.email, 'user@test.com');
    });

    test('signInWithPassword maps invalid credentials AuthException to AuthFailure', () async {
      when(() => mockAuth.signInWithPassword(
            email: 'user@test.com',
            password: 'wrong-password',
          )).thenThrow(const sb.AuthException('Invalid login credentials'));

      expect(
        () => repository.signInWithPassword(
          email: 'user@test.com',
          password: 'wrong-password',
        ),
        throwsA(isA<AuthFailure>().having(
          (f) => f.message,
          'message',
          contains('Incorrect email or password'),
        )),
      );
    });

    test('signUp maps weak password error to friendly AuthFailure', () async {
      when(() => mockAuth.signUp(
            email: 'new@test.com',
            password: 'short',
            data: any(named: 'data'),
          )).thenThrow(const sb.AuthException('Password should be at least 8 characters'));

      expect(
        () => repository.signUp(
          email: 'new@test.com',
          password: 'short',
        ),
        throwsA(isA<AuthFailure>().having(
          (f) => f.message,
          'message',
          contains('Password must be at least 8 characters'),
        )),
      );
    });

    test('signOut terminates session successfully', () async {
      when(() => mockAuth.signOut()).thenAnswer((_) async {});
      await expectLater(repository.signOut(), completes);
      verify(() => mockAuth.signOut()).called(1);
    });
  });
}
