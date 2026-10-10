import 'package:flutter/foundation.dart';

/// Represents a single in-memory optical sensor sample extracted from a camera frame.
///
/// NOTE: Raw camera frames or images are NEVER saved to disk or uploaded.
/// Only aggregated RGB channel brightness means are extracted in-memory.
@immutable
class PpgSample {
  const PpgSample({
    required this.timestampMs,
    required this.red,
    required this.green,
    required this.blue,
    required this.isFingerCovering,
  });

  /// Timestamp in milliseconds from recording start.
  final int timestampMs;

  /// Normalized average red channel value (0.0 to 255.0).
  final double red;

  /// Normalized average green channel value (0.0 to 255.0).
  final double green;

  /// Normalized average blue channel value (0.0 to 255.0).
  final double blue;

  /// Whether the sample meets finger coverage and red saturation criteria.
  final bool isFingerCovering;
}

/// Result of pulse engine signal processing and estimation.
@immutable
class PulseEngineResult {
  const PulseEngineResult({
    required this.estimatedBpm,
    required this.qualityScore,
    required this.isConfident,
    this.peakMethodBpm,
    this.spectralMethodBpm,
    this.methodAgreementDelta,
    this.rejectionReason,
    required this.durationSeconds,
    required this.samplesProcessed,
  });

  /// Estimated heart rate in BPM.
  /// STRICT CLINICAL RULE: Will be null if quality < threshold or confidence is low.
  final double? estimatedBpm;

  /// Computed signal quality metric from 0.0 (no signal) to 1.0 (ideal signal).
  final double qualityScore;

  /// Whether both independent methods agreed and quality exceeded threshold.
  final bool isConfident;

  /// BPM estimated via time-domain Inter-Beat Interval (IBI) peak detection.
  final double? peakMethodBpm;

  /// BPM estimated via frequency-domain spectral analysis / autocorrelation.
  final double? spectralMethodBpm;

  /// Absolute difference between the two independent estimation methods.
  final double? methodAgreementDelta;

  /// Explicit rationale if the measurement was rejected or deemed low quality.
  final String? rejectionReason;

  /// Duration of the analyzed signal in seconds.
  final double durationSeconds;

  /// Total number of valid optical samples processed.
  final int samplesProcessed;

  static const String disclaimer =
      'HealthBase Camera Pulse is an experimental monitoring estimate. '
      'It is not a medical diagnostic device or FDA-cleared pulse oximeter. '
      'Do not rely on this estimate for acute medical decisions.';
}
