import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:healthbase/features/camera_pulse/domain/models/ppg_sample.dart';
import 'package:healthbase/features/camera_pulse/domain/services/pulse_engine.dart';

void main() {
  const engine = PulseEngine();

  List<PpgSample> generateSyntheticPpg({
    required double targetBpm,
    required double durationSeconds,
    double samplingRate = 30.0,
    double noiseAmplitude = 0.0,
    bool isFingerCovering = true,
    double redBaseline = 180.0,
    double pulseAmplitude = 8.0,
  }) {
    final totalSamples = (durationSeconds * samplingRate).round();
    final freqHz = targetBpm / 60.0;
    final samples = <PpgSample>[];
    final random = math.Random(42);

    for (int i = 0; i < totalSamples; i++) {
      final t = i / samplingRate;
      final timestampMs = (t * 1000).round();

      // Fundamental harmonic + second harmonic (dicrotic notch simulation)
      final pulse = pulseAmplitude * math.sin(2 * math.pi * freqHz * t) +
          (pulseAmplitude * 0.3) * math.sin(4 * math.pi * freqHz * t);

      // Low frequency baseline drift (respiration ~0.25 Hz)
      final drift = 2.0 * math.sin(2 * math.pi * 0.25 * t);

      final noise = (noiseAmplitude > 0)
          ? (random.nextDouble() - 0.5) * 2.0 * noiseAmplitude
          : 0.0;

      final red = redBaseline + pulse + drift + noise;

      samples.add(PpgSample(
        timestampMs: timestampMs,
        red: red,
        green: 35.0,
        blue: 25.0,
        isFingerCovering: isFingerCovering,
      ));
    }

    return samples;
  }

  group('PulseEngine - Synthetic Signal DSP Tests', () {
    test('accurately estimates known 72 BPM clean synthetic signal', () {
      final samples = generateSyntheticPpg(
        targetBpm: 72.0,
        durationSeconds: 20.0,
        samplingRate: 30.0,
      );

      final result = engine.processSamples(samples);

      expect(result.isConfident, isTrue);
      expect(result.estimatedBpm, isNotNull);
      expect(result.estimatedBpm!, closeTo(72.0, 1.5));
      expect(result.qualityScore, greaterThanOrEqualTo(0.60));
      expect(result.methodAgreementDelta, lessThanOrEqualTo(4.0));
      expect(result.peakMethodBpm, closeTo(72.0, 2.0));
      expect(result.spectralMethodBpm, closeTo(72.0, 2.0));
    });

    test('accurately estimates known 60 BPM and 100 BPM synthetic signals', () {
      final samples60 = generateSyntheticPpg(
        targetBpm: 60.0,
        durationSeconds: 20.0,
      );
      final result60 = engine.processSamples(samples60);
      expect(result60.isConfident, isTrue);
      expect(result60.estimatedBpm!, closeTo(60.0, 1.5));

      final samples100 = generateSyntheticPpg(
        targetBpm: 100.0,
        durationSeconds: 20.0,
      );
      final result100 = engine.processSamples(samples100);
      expect(result100.isConfident, isTrue);
      expect(result100.estimatedBpm!, closeTo(100.0, 2.0));
    });

    test('rejects flatline / static signal without fabricating numbers', () {
      final totalSamples = 600; // 20 seconds at 30 fps
      final samples = List.generate(
        totalSamples,
        (i) => PpgSample(
          timestampMs: (i * (1000 / 30)).round(),
          red: 180.0,
          green: 30.0,
          blue: 20.0,
          isFingerCovering: true,
        ),
      );

      final result = engine.processSamples(samples);

      expect(result.isConfident, isFalse);
      expect(result.estimatedBpm, isNull);
      expect(result.rejectionReason, contains('No pulse signal detected'));
    });

    test('rejects pure white noise signal', () {
      final random = math.Random(99);
      final samples = List.generate(
        600,
        (i) => PpgSample(
          timestampMs: (i * (1000 / 30)).round(),
          red: 180.0 + (random.nextDouble() - 0.5) * 40.0,
          green: 30.0,
          blue: 20.0,
          isFingerCovering: true,
        ),
      );

      final result = engine.processSamples(samples);

      expect(result.isConfident, isFalse);
      expect(result.estimatedBpm, isNull);
    });

    test('rejects signal with duration shorter than 10 seconds', () {
      final samples = generateSyntheticPpg(
        targetBpm: 72.0,
        durationSeconds: 6.0,
      );

      final result = engine.processSamples(samples);

      expect(result.isConfident, isFalse);
      expect(result.estimatedBpm, isNull);
      expect(result.rejectionReason, contains('Duration too short'));
    });

    test('rejects signal when finger coverage is inconsistent (< 80%)', () {
      final samples = generateSyntheticPpg(
        targetBpm: 72.0,
        durationSeconds: 20.0,
      );

      // Invalidate coverage for 40% of the duration
      final corrupted = samples.map((s) {
        if (s.timestampMs < 8000) {
          return PpgSample(
            timestampMs: s.timestampMs,
            red: s.red,
            green: s.green,
            blue: s.blue,
            isFingerCovering: false,
          );
        }
        return s;
      }).toList();

      final result = engine.processSamples(corrupted);

      expect(result.isConfident, isFalse);
      expect(result.estimatedBpm, isNull);
      expect(result.rejectionReason, contains('Fingertip was not consistently covering'));
    });
  });

  group('PulseEngine - Optical Finger Detection Heuristics', () {
    test('correctly identifies fingertip with red saturation and low green/blue', () {
      expect(
        PulseEngine.isFingerDetected(red: 195.0, green: 40.0, blue: 30.0),
        isTrue,
      );
    });

    test('correctly rejects ambient non-finger scenes (grey, bright white, yellow, low red)', () {
      // Grey / dim room
      expect(
        PulseEngine.isFingerDetected(red: 50.0, green: 50.0, blue: 50.0),
        isFalse,
      );
      // Bright white light
      expect(
        PulseEngine.isFingerDetected(red: 250.0, green: 250.0, blue: 250.0),
        isFalse,
      );
      // Yellow surface
      expect(
        PulseEngine.isFingerDetected(red: 200.0, green: 190.0, blue: 40.0),
        isFalse,
      );
    });
  });
}
