import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/camera_pulse/domain/models/ppg_sample.dart';
import 'package:healthbase/features/camera_pulse/presentation/providers/camera_pulse_controller.dart';
import 'package:healthbase/features/camera_pulse/presentation/screens/camera_pulse_screen.dart';
import 'package:healthbase/features/measurements/data/measurement_repository.dart';
import 'package:healthbase/features/profile/data/profile_repository.dart';
import 'package:healthbase/features/profile/domain/models/health_profile.dart';
import 'package:mocktail/mocktail.dart';

class MockMeasurementRepository extends Mock implements MeasurementRepository {}

void main() {
  final now = DateTime(2026, 10, 10, 12, 0);

  final sampleProfile = HealthProfile(
    id: 'user_1',
    ownerAccountId: 'user_1',
    isSelf: true,
    displayName: 'Test User',
    preferredUnits: UnitSystem.metric,
    createdAt: now.subtract(const Duration(days: 30)),
    updatedAt: now,
  );

  Widget createWidgetUnderTest({
    CameraPulseState? initialState,
  }) {
    final mockRepo = MockMeasurementRepository();
    return ProviderScope(
      overrides: [
        myProfileProvider.overrideWith((ref) => sampleProfile),
        measurementRepositoryProvider.overrideWithValue(mockRepo),
        if (initialState != null)
          cameraPulseControllerProvider.overrideWith((ref) {
            final engine = ref.watch(pulseEngineProvider);
            return CameraPulseController(
              engine: engine,
              measurementRepository: mockRepo,
              initialState: initialState,
            );
          }),
      ],
      child: const MaterialApp(
        home: CameraPulseScreen(),
      ),
    );
  }

  group('CameraPulseScreen Widget Tests', () {
    testWidgets('renders screen header and mandatory clinical disclaimer banner', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const CameraPulseState(status: CameraPulseStatus.initial),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Camera Pulse (PPG)'), findsOneWidget);
      expect(
        find.textContaining('Camera Pulse is an experimental monitoring estimate. It is not a medical diagnostic device or FDA-cleared pulse oximeter.'),
        findsOneWidget,
      );
    });

    testWidgets('renders step-by-step instructions on initial load', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const CameraPulseState(status: CameraPulseStatus.initial),
      ));
      await tester.pumpAndSettle();

      expect(find.text('How Camera Pulse Works'), findsOneWidget);
      expect(find.text('Place your fingertip'), findsOneWidget);
      expect(find.text('Do not press too firmly'), findsOneWidget);
      expect(find.text('Remain seated and still'), findsOneWidget);
      expect(find.text('Start Pulse Measurement'), findsOneWidget);
    });

    testWidgets('renders live contact status, waveform and timer when measuring', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const CameraPulseState(
          status: CameraPulseStatus.measuring,
          isFingerDetected: true,
          progress: 0.45,
          secondsRemaining: 11,
          waveformPoints: [180.0, 185.0, 192.0, 187.0, 179.0],
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Good Contact · Measuring...'), findsOneWidget);
      expect(find.text('11'), findsOneWidget);
      expect(find.text('seconds left'), findsOneWidget);
      expect(find.text('LIVE OPTICAL SIGNAL'), findsOneWidget);
      expect(find.text('Cancel Recording'), findsOneWidget);
    });

    testWidgets('renders confident result with estimated BPM and save button', (tester) async {
      const confidentResult = PulseEngineResult(
        estimatedBpm: 72.0,
        qualityScore: 0.88,
        isConfident: true,
        peakMethodBpm: 72.0,
        spectralMethodBpm: 71.5,
        methodAgreementDelta: 0.5,
        durationSeconds: 20.0,
        samplesProcessed: 600,
      );

      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const CameraPulseState(
          status: CameraPulseStatus.completed,
          result: confidentResult,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('72'), findsOneWidget);
      expect(find.text('Beats Per Minute (Estimated)'), findsOneWidget);
      expect(find.text('88%'), findsOneWidget);
      expect(find.text('Save Measurement'), findsOneWidget);
      expect(find.text('Retake'), findsOneWidget);
    });

    testWidgets('renders rejected state with explanation when reading is unclear', (tester) async {
      const rejectedResult = PulseEngineResult(
        estimatedBpm: null,
        qualityScore: 0.35,
        isConfident: false,
        rejectionReason: 'Motion or irregular pulse detected between analysis methods.',
        durationSeconds: 20.0,
        samplesProcessed: 600,
      );

      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const CameraPulseState(
          status: CameraPulseStatus.completed,
          result: rejectedResult,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Could Not Get a Clear Reading'), findsOneWidget);
      expect(
        find.textContaining('Motion or irregular pulse detected between analysis methods.'),
        findsOneWidget,
      );
      expect(find.text('Try Again'), findsOneWidget);
    });

    testWidgets('renders hardware unsupported view with explanation', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest(
        initialState: const CameraPulseState(
          status: CameraPulseStatus.unsupported,
          errorMessage: 'Camera Pulse requires a mobile device with a rear camera and flash.',
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hardware Not Supported'), findsOneWidget);
      expect(
        find.textContaining('Camera Pulse requires a mobile device with a rear camera and flash.'),
        findsOneWidget,
      );
      expect(find.text('Back to Dashboard'), findsOneWidget);
    });
  });
}
