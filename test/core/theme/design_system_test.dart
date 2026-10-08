import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/core/theme/app_theme.dart';
import 'package:healthbase/core/theme/components/app_button.dart';
import 'package:healthbase/core/theme/components/app_card.dart';
import 'package:healthbase/core/theme/components/app_empty_state.dart';
import 'package:healthbase/core/theme/components/app_error_state.dart';
import 'package:healthbase/core/theme/components/app_loading_state.dart';
import 'package:healthbase/core/theme/components/app_status_chip.dart';
import 'package:healthbase/core/theme/components/app_text_field.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: Scaffold(body: Center(child: child)),
    );
  }

  group('AppButton Widget Tests', () {
    testWidgets('renders button label and fires onPressed callback', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        createTestWidget(
          AppButton(
            label: 'Record Check',
            onPressed: () => pressed = true,
          ),
        ),
      );

      expect(find.text('Record Check'), findsOneWidget);
      await tester.tap(find.text('Record Check'));
      expect(pressed, isTrue);
    });

    testWidgets('displays loading spinner and disables clicks when isLoading is true', (tester) async {
      var pressed = false;

      await tester.pumpWidget(
        createTestWidget(
          AppButton(
            label: 'Save Measurement',
            isLoading: true,
            onPressed: () => pressed = true,
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Save Measurement'));
      expect(pressed, isFalse);
    });
  });

  group('AppStatusChip Widget Tests', () {
    testWidgets('displays correct text and icons for trend states', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          Column(
            children: [
              AppStatusChip.trend(HealthTrendStatus.stable),
              AppStatusChip.trend(HealthTrendStatus.increased),
              AppStatusChip.trend(HealthTrendStatus.decreased),
              AppStatusChip.trend(HealthTrendStatus.insufficientData),
            ],
          ),
        ),
      );

      expect(find.text('Stable'), findsOneWidget);
      expect(find.text('Increased'), findsOneWidget);
      expect(find.text('Decreased'), findsOneWidget);
      expect(find.text('Not enough history yet'), findsOneWidget);
    });

    testWidgets('displays correct text for sync states', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          Column(
            children: [
              AppStatusChip.sync(SyncStatus.savedLocally),
              AppStatusChip.sync(SyncStatus.syncing),
              AppStatusChip.sync(SyncStatus.synced),
              AppStatusChip.sync(SyncStatus.syncFailed),
            ],
          ),
        ),
      );

      expect(find.text('Saved locally'), findsOneWidget);
      expect(find.text('Syncing...'), findsOneWidget);
      expect(find.text('Synced'), findsOneWidget);
      expect(find.text('Sync failed (offline)'), findsOneWidget);
    });
  });

  group('AppCard & AppTextField Widget Tests', () {
    testWidgets('renders card with title and content', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AppCard(
            title: 'Heart Rate',
            child: Text('72 BPM'),
          ),
        ),
      );

      expect(find.text('Heart Rate'), findsOneWidget);
      expect(find.text('72 BPM'), findsOneWidget);
    });

    testWidgets('renders AppTextField with label and error text', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AppTextField(
            label: 'Systolic Blood Pressure',
            errorText: 'Value is out of plausible range',
          ),
        ),
      );

      expect(find.text('Systolic Blood Pressure'), findsOneWidget);
      expect(find.text('Value is out of plausible range'), findsOneWidget);
    });
  });

  group('Feedback State Widgets', () {
    testWidgets('renders AppLoadingState with message', (tester) async {
      await tester.pumpWidget(
        createTestWidget(
          const AppLoadingState(message: 'Fetching medical baseline...'),
        ),
      );

      expect(find.text('Fetching medical baseline...'), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders AppEmptyState with title and action button', (tester) async {
      var actionTriggered = false;

      await tester.pumpWidget(
        createTestWidget(
          AppEmptyState(
            title: 'No Records Found',
            message: 'Your health history is currently empty.',
            actionLabel: 'Add First Record',
            onAction: () => actionTriggered = true,
          ),
        ),
      );

      expect(find.text('No Records Found'), findsOneWidget);
      expect(find.text('Your health history is currently empty.'), findsOneWidget);
      expect(find.text('Add First Record'), findsOneWidget);

      await tester.tap(find.text('Add First Record'));
      expect(actionTriggered, isTrue);
    });

    testWidgets('renders AppErrorState with retry action', (tester) async {
      var retryTriggered = false;

      await tester.pumpWidget(
        createTestWidget(
          AppErrorState(
            message: 'Network connection lost.',
            onRetry: () => retryTriggered = true,
          ),
        ),
      );

      expect(find.text('Network connection lost.'), findsOneWidget);
      expect(find.text('Try Again'), findsOneWidget);

      await tester.tap(find.text('Try Again'));
      expect(retryTriggered, isTrue);
    });
  });
}
