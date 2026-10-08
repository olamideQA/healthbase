import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/errors/failures.dart';
import 'package:healthbase/features/auth/data/auth_repository.dart';
import 'package:healthbase/features/auth/domain/models/auth_user.dart';
import 'package:healthbase/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockRepo;
  late AuthController controller;

  setUp(() {
    mockRepo = MockAuthRepository();
    when(() => mockRepo.currentUser).thenReturn(null);
    controller = AuthController(mockRepo);
  });

  group('AuthController Unit Tests', () {
    test('initial state reflects currentUser', () {
      expect(controller.state.value, isNull);
    });

    test('signIn updates state to data on success', () async {
      const user = AuthUser(id: 'u1', email: 'test@example.com');
      when(() => mockRepo.signInWithPassword(
            email: 'test@example.com',
            password: 'Password123',
          )).thenAnswer((_) async => user);

      final success = await controller.signIn(
        email: 'test@example.com',
        password: 'Password123',
      );

      expect(success, isTrue);
      expect(controller.state.value, user);
    });

    test('signIn updates state to error on failure', () async {
      when(() => mockRepo.signInWithPassword(
            email: 'test@example.com',
            password: 'wrong',
          )).thenThrow(const AuthFailure(message: 'Invalid credentials'));

      final success = await controller.signIn(
        email: 'test@example.com',
        password: 'wrong',
      );

      expect(success, isFalse);
      expect(controller.state.hasError, isTrue);
      expect(controller.state.error, isA<AuthFailure>());
    });

    test('signOut clears user state to null', () async {
      when(() => mockRepo.signOut()).thenAnswer((_) async {});

      await controller.signOut();

      expect(controller.state.value, isNull);
      verify(() => mockRepo.signOut()).called(1);
    });

    test('deleteAccount calls repo and resets state', () async {
      when(() => mockRepo.deleteAccount()).thenAnswer((_) async {});

      final success = await controller.deleteAccount();

      expect(success, isTrue);
      expect(controller.state.value, isNull);
      verify(() => mockRepo.deleteAccount()).called(1);
    });
  });
}
