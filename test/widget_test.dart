import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/auth/data/auth_repository.dart';
import 'package:healthbase/main.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('HealthBaseApp root smoke test mounts and redirects to Login when unauthenticated', (WidgetTester tester) async {
    final mockAuthRepo = MockAuthRepository();
    when(() => mockAuthRepo.currentUser).thenReturn(null);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(mockAuthRepo),
        ],
        child: const HealthBaseApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify unauthenticated user lands on Welcome screen
    expect(find.text('Welcome to HealthBase'), findsOneWidget);
  });
}
