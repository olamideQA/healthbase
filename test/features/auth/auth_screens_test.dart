import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/theme/app_theme.dart';
import 'package:healthbase/core/theme/components/app_button.dart';
import 'package:healthbase/features/auth/data/auth_repository.dart';
import 'package:healthbase/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:healthbase/features/auth/presentation/screens/login_screen.dart';
import 'package:healthbase/features/auth/presentation/screens/register_screen.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository mockAuthRepo;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    when(() => mockAuthRepo.currentUser).thenReturn(null);
  });

  Widget createAuthWidget(Widget screen) {
    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockAuthRepo),
      ],
      child: MaterialApp(
        theme: AppTheme.lightTheme,
        home: screen,
      ),
    );
  }

  group('LoginScreen Widget Tests', () {
    testWidgets('renders brand title, email/password inputs, and disclaimer', (tester) async {
      await tester.pumpWidget(createAuthWidget(const LoginScreen()));
      await tester.pump();

      expect(find.text('Welcome to HealthBase'), findsOneWidget);
      expect(find.text('Email Address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.textContaining('does not diagnose'), findsOneWidget);
    });

    testWidgets('validates empty email and password on submit', (tester) async {
      await tester.pumpWidget(createAuthWidget(const LoginScreen()));
      await tester.pump();

      await tester.tap(find.text('Sign In'));
      await tester.pump();

      expect(find.text('Please enter your email address.'), findsOneWidget);
      expect(find.text('Please enter your password.'), findsOneWidget);
    });
  });

  group('RegisterScreen Widget Tests', () {
    testWidgets('validates password complexity (requires 8+ chars and digits)', (tester) async {
      await tester.pumpWidget(createAuthWidget(const RegisterScreen()));
      await tester.pump();

      // Enter weak password
      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(1), 'test@example.com'); // email
      await tester.enterText(passwordFields.at(2), 'short'); // password
      await tester.enterText(passwordFields.at(3), 'short'); // confirm password

      final submitButton = find.widgetWithText(AppButton, 'Create Account');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(find.text('Password must be at least 8 characters long.'), findsOneWidget);
    });

    testWidgets('validates password mismatch', (tester) async {
      await tester.pumpWidget(createAuthWidget(const RegisterScreen()));
      await tester.pump();

      final passwordFields = find.byType(TextFormField);
      await tester.enterText(passwordFields.at(1), 'valid@example.com'); // email
      await tester.enterText(passwordFields.at(2), 'Password123'); // password
      await tester.enterText(passwordFields.at(3), 'Mismatch999'); // confirm password

      final submitButton = find.widgetWithText(AppButton, 'Create Account');
      await tester.ensureVisible(submitButton);
      await tester.tap(submitButton);
      await tester.pump();

      expect(find.text('Passwords do not match.'), findsOneWidget);
    });
  });

  group('ForgotPasswordScreen Widget Tests', () {
    testWidgets('transitions to success confirmation upon reset email dispatch', (tester) async {
      when(() => mockAuthRepo.sendPasswordResetEmail('patient@example.com'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(createAuthWidget(const ForgotPasswordScreen()));
      await tester.pump();

      final emailField = find.byType(TextFormField);
      await tester.enterText(emailField, 'patient@example.com');

      await tester.tap(find.text('Send Recovery Link'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Check Your Inbox'), findsOneWidget);
    });
  });
}
