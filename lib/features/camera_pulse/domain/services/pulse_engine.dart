import 'dart:math' as math;
import '../models/ppg_sample.dart';

/// Pure functional, deterministic signal processing engine for camera Photoplethysmography (PPG).
///
/// Implements:
/// - In-memory optical signal extraction (Zero raw frame retention).
/// - Baseline detrending & physiological bandpass filtering (0.7 Hz to 3.5 Hz).
/// - Dual independent estimation: Time-Domain Peak Intervals (IBI) + Autocorrelation Spectral Peak.
/// - Strict clinical rejection gates: never fabricates or displays low-confidence pulse estimates.
class PulseEngine {
  const PulseEngine();

  // Physiological limits
  static const double minBpm = 42.0; // ~0.7 Hz
  static const double maxBpm = 210.0; // ~3.5 Hz
  static const double minDurationSeconds = 10.0;
  static const double maxMethodAgreementDeltaBpm = 6.0;
  static const double minQualityThreshold = 0.60;

  /// Check whether an optical frame average represents a fingertip covering the camera + flash.
  static bool isFingerDetected({
    required double red,
    required double green,
    required double blue,
  }) {
    // Hemoglobin absorbs green and blue strongly when back-illuminated by torch.
    // Fingertip creates a strong diffuse red dominance.
    return red >= 55.0 &&
        red > green * 1.30 &&
        red > blue * 1.45 &&
        (green + blue) < red * 1.20;
  }

  /// Process recorded PPG samples and produce a deterministic [PulseEngineResult].
  PulseEngineResult processSamples(List<PpgSample> samples) {
    if (samples.length < 30) {
      return const PulseEngineResult(
        estimatedBpm: null,
        qualityScore: 0.0,
        isConfident: false,
        rejectionReason: 'Insufficient data collected. Please hold finger steadily on camera.',
        durationSeconds: 0.0,
        samplesProcessed: 0,
      );
    }

    final totalSamples = samples.length;
    final startMs = samples.first.timestampMs;
    final endMs = samples.last.timestampMs;
    final durationSeconds = (endMs - startMs) / 1000.0;

    if (durationSeconds < minDurationSeconds) {
      return PulseEngineResult(
        estimatedBpm: null,
        qualityScore: 0.1,
        isConfident: false,
        rejectionReason: 'Duration too short (${durationSeconds.toStringAsFixed(1)}s). Minimum 15s recommended.',
        durationSeconds: durationSeconds,
        samplesProcessed: totalSamples,
      );
    }

    final samplingRate = totalSamples / durationSeconds;
    if (samplingRate < 10.0) {
      return PulseEngineResult(
        estimatedBpm: null,
        qualityScore: 0.0,
        isConfident: false,
        rejectionReason: 'Camera frame rate too low (${samplingRate.toStringAsFixed(1)} FPS).',
        durationSeconds: durationSeconds,
        samplesProcessed: totalSamples,
      );
    }

    // 1. Verify finger coverage consistency
    final coveredCount = samples.where((s) => s.isFingerCovering).length;
    final coverageRatio = coveredCount / totalSamples;
    if (coverageRatio < 0.80) {
      return PulseEngineResult(
        estimatedBpm: null,
        qualityScore: coverageRatio * 0.5,
        isConfident: false,
        rejectionReason: 'Fingertip was not consistently covering camera lens.',
        durationSeconds: durationSeconds,
        samplesProcessed: totalSamples,
      );
    }

    // 2. Extract signal (using red channel as primary PPG signal)
    final rawSignal = samples.map((s) => s.red).toList();

    // 3. Preprocessing: Detrend & Band-pass filter
    final filteredSignal = _filterSignal(rawSignal, samplingRate);

    // Check for flatline or zero variation
    final signalVariance = _computeVariance(filteredSignal);
    if (signalVariance < 0.001) {
      return PulseEngineResult(
        estimatedBpm: null,
        qualityScore: 0.0,
        isConfident: false,
        rejectionReason: 'No pulse signal detected. Ensure flash is on and finger is gently placed.',
        durationSeconds: durationSeconds,
        samplesProcessed: totalSamples,
      );
    }

    // 4. Method 1: Time-Domain Peak Intervals (IBI)
    final peakEstimate = _estimateBpmPeakMethod(filteredSignal, samplingRate);

    // 5. Method 2: Frequency-Domain Autocorrelation
    final spectralEstimate = _estimateBpmAutocorrelation(filteredSignal, samplingRate);

    final peakBpm = peakEstimate.bpm;
    final spectralBpm = spectralEstimate.bpm;

    // Both methods must succeed
    if (peakBpm == null || spectralBpm == null) {
      return PulseEngineResult(
        estimatedBpm: null,
        qualityScore: 0.25,
        isConfident: false,
        peakMethodBpm: peakBpm,
        spectralMethodBpm: spectralBpm,
        rejectionReason: 'Could not extract a rhythmic pulse waveform.',
        durationSeconds: durationSeconds,
        samplesProcessed: totalSamples,
      );
    }

    // 6. Evaluate inter-method agreement
    final delta = (peakBpm - spectralBpm).abs();
    final agreementScore = math.max(0.0, 1.0 - (delta / 12.0));

    // 7. Calculate composite quality score
    final compositeQuality = (
      peakEstimate.regularityScore * 0.35 +
      spectralEstimate.prominenceScore * 0.40 +
      agreementScore * 0.25
    ).clamp(0.0, 1.0);

    // 8. Gate check: Must agree within tolerance and exceed quality threshold
    final hasAgreement = delta <= maxMethodAgreementDeltaBpm;
    final isQualitySufficient = compositeQuality >= minQualityThreshold;

    if (!hasAgreement) {
      return PulseEngineResult(
        estimatedBpm: null,
        qualityScore: compositeQuality,
        isConfident: false,
        peakMethodBpm: peakBpm,
        spectralMethodBpm: spectralBpm,
        methodAgreementDelta: delta,
        rejectionReason: 'Motion or irregular pulse detected between analysis methods.',
        durationSeconds: durationSeconds,
        samplesProcessed: totalSamples,
      );
    }

    if (!isQualitySufficient) {
      return PulseEngineResult(
        estimatedBpm: null,
        qualityScore: compositeQuality,
        isConfident: false,
        peakMethodBpm: peakBpm,
        spectralMethodBpm: spectralBpm,
        methodAgreementDelta: delta,
        rejectionReason: 'Signal quality too low for a reliable estimate. Keep still and try again.',
        durationSeconds: durationSeconds,
        samplesProcessed: totalSamples,
      );
    }

    // Both methods agreed and quality is sufficient: average the estimates
    final finalEstimatedBpm = double.parse(((peakBpm + spectralBpm) / 2.0).toStringAsFixed(1));

    return PulseEngineResult(
      estimatedBpm: finalEstimatedBpm,
      qualityScore: double.parse(compositeQuality.toStringAsFixed(2)),
      isConfident: true,
      peakMethodBpm: double.parse(peakBpm.toStringAsFixed(1)),
      spectralMethodBpm: double.parse(spectralBpm.toStringAsFixed(1)),
      methodAgreementDelta: double.parse(delta.toStringAsFixed(1)),
      durationSeconds: double.parse(durationSeconds.toStringAsFixed(1)),
      samplesProcessed: totalSamples,
    );
  }

  /// Digital band-pass filtering tailored for human pulse range (0.7 Hz to 3.5 Hz).
  List<double> _filterSignal(List<double> signal, double samplingRate) {
    final n = signal.length;
    if (n < 5) return List.from(signal);

    // Step A: Baseline removal (high-pass detrending)
    // Moving average window of ~0.75 seconds to capture respiratory/thermal drift
    final windowSize = math.max(3, (samplingRate * 0.75).round());
    final detrended = List<double>.filled(n, 0.0);

    double sum = 0.0;
    for (int i = 0; i < n; i++) {
      sum += signal[i];
      if (i >= windowSize) {
        sum -= signal[i - windowSize];
        detrended[i - (windowSize ~/ 2)] = signal[i - (windowSize ~/ 2)] - (sum / windowSize);
      }
    }

    // Fill boundaries
    for (int i = 0; i < windowSize ~/ 2; i++) {
      detrended[i] = signal[i] - (sum / windowSize);
    }
    for (int i = n - (windowSize ~/ 2); i < n; i++) {
      detrended[i] = signal[i] - (sum / windowSize);
    }

    // Step B: Low-pass smoothing to suppress high-frequency camera sensor noise (>3.5 Hz)
    // Moving average window of ~0.12 seconds (~4 samples at 30 FPS)
    final smoothWindow = math.max(2, (samplingRate * 0.12).round());
    final filtered = List<double>.filled(n, 0.0);

    double smoothSum = 0.0;
    for (int i = 0; i < n; i++) {
      smoothSum += detrended[i];
      if (i >= smoothWindow) {
        smoothSum -= detrended[i - smoothWindow];
        filtered[i - (smoothWindow ~/ 2)] = smoothSum / smoothWindow;
      }
    }

    return filtered;
  }

  /// Method 1: Inter-Beat Interval (IBI) Peak Detection.
  ({double? bpm, double regularityScore}) _estimateBpmPeakMethod(
    List<double> signal,
    double samplingRate,
  ) {
    final n = signal.length;
    final minDistance = math.max(2, (samplingRate * 60.0 / maxBpm).round()); // Refractory limit
    final stdDev = math.sqrt(_computeVariance(signal));
    final threshold = stdDev * 0.30;

    final peakIndices = <int>[];
    int lastPeak = -minDistance;

    for (int i = 1; i < n - 1; i++) {
      if (signal[i] > signal[i - 1] &&
          signal[i] > signal[i + 1] &&
          signal[i] > threshold &&
          (i - lastPeak) >= minDistance) {
        peakIndices.add(i);
        lastPeak = i;
      }
    }

    if (peakIndices.length < 4) {
      return (bpm: null, regularityScore: 0.0);
    }

    // Calculate inter-beat intervals (in seconds)
    final ibis = <double>[];
    for (int i = 1; i < peakIndices.length; i++) {
      final intervalSec = (peakIndices[i] - peakIndices[i - 1]) / samplingRate;
      // Filter out intervals outside physiological bounds (42 to 210 BPM)
      if (intervalSec >= (60.0 / maxBpm) && intervalSec <= (60.0 / minBpm)) {
        ibis.add(intervalSec);
      }
    }

    if (ibis.length < 3) {
      return (bpm: null, regularityScore: 0.0);
    }

    ibis.sort();
    final medianIbi = ibis[ibis.length ~/ 2];
    final meanIbi = ibis.reduce((a, b) => a + b) / ibis.length;

    // Regularity metric: coefficient of variation (lower is more rhythmic)
    double variance = 0.0;
    for (final ibi in ibis) {
      variance += math.pow(ibi - meanIbi, 2);
    }
    final ibiStdDev = math.sqrt(variance / ibis.length);
    final cv = ibiStdDev / meanIbi;
    final regularityScore = (1.0 - (cv * 2.5)).clamp(0.0, 1.0);

    final bpm = 60.0 / medianIbi;
    return (bpm: bpm, regularityScore: regularityScore);
  }

  /// Method 2: Autocorrelation Spectral Peak Estimation.
  ({double? bpm, double prominenceScore}) _estimateBpmAutocorrelation(
    List<double> signal,
    double samplingRate,
  ) {
    final n = signal.length;
    final minLag = math.max(2, (samplingRate * 60.0 / maxBpm).round()); // 210 BPM lag
    final maxLag = math.min(n ~/ 2, (samplingRate * 60.0 / minBpm).round()); // 42 BPM lag

    if (maxLag <= minLag) {
      return (bpm: null, prominenceScore: 0.0);
    }

    // Compute energy at lag 0: R(0)
    double r0 = 0.0;
    for (int i = 0; i < n; i++) {
      r0 += signal[i] * signal[i];
    }
    if (r0 <= 0.0) return (bpm: null, prominenceScore: 0.0);

    double bestAutocorr = -1.0;
    int bestLag = -1;

    for (int lag = minLag; lag <= maxLag; lag++) {
      double r = 0.0;
      for (int i = 0; i < n - lag; i++) {
        r += signal[i] * signal[i + lag];
      }
      final normalizedR = r / r0;

      if (normalizedR > bestAutocorr) {
        bestAutocorr = normalizedR;
        bestLag = lag;
      }
    }

    if (bestLag < 0 || bestAutocorr < 0.15) {
      return (bpm: null, prominenceScore: 0.0);
    }

    final bpm = 60.0 * samplingRate / bestLag;
    final prominenceScore = bestAutocorr.clamp(0.0, 1.0);

    return (bpm: bpm, prominenceScore: prominenceScore);
  }

  double _computeVariance(List<double> list) {
    if (list.isEmpty) return 0.0;
    final mean = list.reduce((a, b) => a + b) / list.length;
    double sum = 0.0;
    for (final v in list) {
      sum += math.pow(v - mean, 2);
    }
    return sum / list.length;
  }
}
