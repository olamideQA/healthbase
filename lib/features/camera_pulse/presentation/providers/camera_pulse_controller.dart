import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:healthbase/features/measurements/data/measurement_repository.dart';
import 'package:healthbase/features/measurements/domain/models/measurement.dart';
import '../../domain/models/ppg_sample.dart';
import '../../domain/services/pulse_engine.dart';

enum CameraPulseStatus {
  initial,
  unsupported,
  calibrating,
  measuring,
  completed,
  error,
}

@immutable
class CameraPulseState {
  const CameraPulseState({
    required this.status,
    this.isFingerDetected = false,
    this.progress = 0.0,
    this.secondsRemaining = 20,
    this.waveformPoints = const [],
    this.result,
    this.errorMessage,
  });

  final CameraPulseStatus status;
  final bool isFingerDetected;
  final double progress;
  final int secondsRemaining;
  final List<double> waveformPoints;
  final PulseEngineResult? result;
  final String? errorMessage;

  CameraPulseState copyWith({
    CameraPulseStatus? status,
    bool? isFingerDetected,
    double? progress,
    int? secondsRemaining,
    List<double>? waveformPoints,
    PulseEngineResult? result,
    String? errorMessage,
  }) {
    return CameraPulseState(
      status: status ?? this.status,
      isFingerDetected: isFingerDetected ?? this.isFingerDetected,
      progress: progress ?? this.progress,
      secondsRemaining: secondsRemaining ?? this.secondsRemaining,
      waveformPoints: waveformPoints ?? this.waveformPoints,
      result: result ?? this.result,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final pulseEngineProvider = Provider<PulseEngine>((ref) {
  return const PulseEngine();
});

final cameraPulseControllerProvider =
    StateNotifierProvider.autoDispose<CameraPulseController, CameraPulseState>((ref) {
  final engine = ref.watch(pulseEngineProvider);
  final measRepo = ref.watch(measurementRepositoryProvider);
  return CameraPulseController(engine: engine, measurementRepository: measRepo);
});

class CameraPulseController extends StateNotifier<CameraPulseState> {
  CameraPulseController({
    required this.engine,
    required this.measurementRepository,
    CameraPulseState? initialState,
  }) : super(initialState ?? const CameraPulseState(status: CameraPulseStatus.initial));

  final PulseEngine engine;
  final MeasurementRepository measurementRepository;
  final _uuid = const Uuid();

  final List<PpgSample> _recordedSamples = [];
  Timer? _countdownTimer;
  static const int totalMeasurementSeconds = 20;

  /// Check hardware support and prepare sensor pipeline.
  void checkSupport() {
    if (state.status != CameraPulseStatus.initial) return;
    // Web browsers and desktop environments lack torch control and low-latency camera stream
    if (kIsWeb) {
      state = state.copyWith(
        status: CameraPulseStatus.unsupported,
        errorMessage: 'Camera Pulse requires a mobile device with a rear camera and flash. Web browsers do not support direct camera torch control.',
      );
    }
  }

  /// Start pulse capture session.
  void startMeasuring() {
    if (kIsWeb) {
      checkSupport();
      return;
    }

    _recordedSamples.clear();
    state = state.copyWith(
      status: CameraPulseStatus.measuring,
      progress: 0.0,
      secondsRemaining: totalMeasurementSeconds,
      waveformPoints: [],
      errorMessage: null,
      result: null,
    );

    int elapsedSeconds = 0;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      elapsedSeconds++;
      final remaining = totalMeasurementSeconds - elapsedSeconds;
      final progress = elapsedSeconds / totalMeasurementSeconds;

      if (remaining <= 0) {
        timer.cancel();
        finishMeasuring();
      } else {
        state = state.copyWith(
          secondsRemaining: remaining,
          progress: progress,
        );
      }
    });
  }

  /// Add in-memory optical RGB average sample.
  /// ZERO FRAME RETENTION: Raw frames are never retained or saved.
  void addOpticalSample({
    required int timestampMs,
    required double red,
    required double green,
    required double blue,
  }) {
    if (state.status != CameraPulseStatus.measuring) return;

    final isCovering = PulseEngine.isFingerDetected(
      red: red,
      green: green,
      blue: blue,
    );

    final sample = PpgSample(
      timestampMs: timestampMs,
      red: red,
      green: green,
      blue: blue,
      isFingerCovering: isCovering,
    );

    _recordedSamples.add(sample);

    // Maintain recent waveform points (last 60 samples for real-time visualization)
    final points = List<double>.from(state.waveformPoints)..add(red);
    if (points.length > 60) {
      points.removeAt(0);
    }

    state = state.copyWith(
      isFingerDetected: isCovering,
      waveformPoints: points,
    );
  }

  /// Conclude measurement, invoke DSP pulse engine, and produce result.
  void finishMeasuring() {
    _countdownTimer?.cancel();

    final result = engine.processSamples(_recordedSamples);

    state = state.copyWith(
      status: CameraPulseStatus.completed,
      progress: 1.0,
      secondsRemaining: 0,
      result: result,
    );
  }

  /// Save estimated BPM to HealthBase database with camera provenance.
  Future<bool> saveResult(String profileId) async {
    final result = state.result;
    if (result == null || !result.isConfident || result.estimatedBpm == null) {
      return false;
    }

    final now = DateTime.now();
    final measurement = Measurement(
      id: _uuid.v4(),
      profileId: profileId,
      type: MeasurementType.heartRate,
      heartRateBpm: result.estimatedBpm,
      source: MeasurementSource.camera,
      provenance: MeasurementProvenance.estimated,
      recordedAt: now,
      recordedUtcOffset: now.timeZoneOffset.inMinutes,
      notes: 'Camera Pulse estimate (Quality: ${(result.qualityScore * 100).toStringAsFixed(0)}%)',
      isDeleted: false,
      syncStatus: SyncStatus.pendingInsert,
      createdAt: now,
      updatedAt: now,
    );

    await measurementRepository.createMeasurement(measurement);
    return true;
  }

  /// Reset to initial state for a new measurement.
  void reset() {
    _countdownTimer?.cancel();
    _recordedSamples.clear();
    state = const CameraPulseState(status: CameraPulseStatus.initial);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }
}
