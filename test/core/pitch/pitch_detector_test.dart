import 'dart:typed_data';

import 'package:brass_tunner/core/pitch/autocorrelation.dart';
import 'package:brass_tunner/core/pitch/mpm.dart';
import 'package:brass_tunner/core/pitch/pitch_detector.dart';
import 'package:brass_tunner/core/pitch/pitch_result.dart';
import 'package:brass_tunner/core/pitch/yin.dart';
import 'package:flutter_test/flutter_test.dart';

import 'signals.dart';

/// Frequencies from the phase 1 spec: tuba low range up to trumpet high B♭.
const targets = {
  '40 Hz': 40.0,
  'B♭1': 58.27,
  'B♭3': 233.08,
  'B♭4': 466.16,
  'B♭5': 932.33,
};

const maxCentsError = 2.0;

void main() {
  group('PitchDetector (MPM + YIN fallback)', () {
    final detector = PitchDetector();

    for (final MapEntry(key: name, value: f) in targets.entries) {
      for (final phase in [0.0, 1.3, 2.9]) {
        test('sine $name, phase $phase', () {
          final result = detector.detect(sine(f, phase: phase));
          _expectPitch(result, f);
        });
      }
      for (final seed in [1, 2, 3]) {
        test('brass harmonics $name, seed $seed', () {
          final result = detector.detect(harmonic(f, seed: seed));
          _expectPitch(result, f);
        });
      }
      test('weak fundamental $name', () {
        final result = detector.detect(
          harmonic(f, amplitudes: weakFundamentalHarmonics),
        );
        _expectPitch(result, f);
      });
      test('harmonics + noise (~26 dB SNR) $name', () {
        final result = detector.detect(withNoise(harmonic(f), 0.03));
        _expectPitch(result, f);
      });
    }

    test('extremes of the brass range: 30 Hz and 1500 Hz', () {
      _expectPitch(detector.detect(harmonic(30)), 30);
      _expectPitch(detector.detect(harmonic(1500)), 1500);
    });

    test('rejects white noise', () {
      expect(detector.detect(whiteNoise(0.5)), isNull);
    });

    test('rejects silence', () {
      expect(detector.detect(Float32List(4096)), isNull);
    });

    test('ignores DC offset', () {
      final shifted = Float32List.fromList([
        for (final s in sine(233.08)) s + 0.3,
      ]);
      _expectPitch(detector.detect(shifted), 233.08);
    });

    test('works at 48 kHz', () {
      final detector48 = PitchDetector(sampleRate: 48000);
      // Signal generated at 44.1 kHz read as 48 kHz is scaled by 48/44.1.
      const f = 233.08;
      _expectPitch(detector48.detect(sine(f)), f * 48000 / 44100);
    });

    test('rejects a window too short for the minimum frequency', () {
      expect(() => PitchDetector(windowSize: 2048), throwsArgumentError);
    });

    test('rejects a frame of the wrong size', () {
      expect(() => detector.detect(Float32List(1024)), throwsArgumentError);
    });
  });

  group('YIN alone', () {
    final ac = AutocorrelationEngine(windowSize: 4096, maxLag: 1636);
    final yin = Yin();

    PitchEstimate? run(Float32List signal) {
      ac.compute(Float64List.fromList(signal));
      return yin.estimate(ac, sampleRate: sampleRate, minLag: 27);
    }

    for (final MapEntry(key: name, value: f) in targets.entries) {
      test('sine $name', () => _expectPitch(run(sine(f)), f));
      test('brass harmonics $name', () => _expectPitch(run(harmonic(f)), f));
    }
  });

  group('MPM alone', () {
    final ac = AutocorrelationEngine(windowSize: 4096, maxLag: 1636);
    final mpm = Mpm();

    test('reports clarity close to 1 for a clean tone', () {
      ac.compute(Float64List.fromList(harmonic(233.08)));
      final result = mpm.estimate(ac, sampleRate: sampleRate, minLag: 27);
      expect(result!.algorithm, PitchAlgorithm.mpm);
      expect(result.clarity, greaterThan(0.99));
    });
  });

  group('AutocorrelationEngine', () {
    test('FFT result matches the direct sums', () {
      const window = 512;
      const maxLag = 200;
      final x = Float64List.fromList(
        withNoise(harmonic(440, length: window), 0.1),
      );
      final ac = AutocorrelationEngine(windowSize: window, maxLag: maxLag)
        ..compute(x);
      for (var tau = 0; tau <= maxLag; tau++) {
        var r = 0.0;
        var m = 0.0;
        for (var j = 0; j < window - tau; j++) {
          r += x[j] * x[j + tau];
          m += x[j] * x[j] + x[j + tau] * x[j + tau];
        }
        expect(ac.r[tau], closeTo(r, 1e-9), reason: 'r at lag $tau');
        expect(ac.m[tau], closeTo(m, 1e-9), reason: 'm at lag $tau');
      }
    });
  });

  test('performance: one 4096-sample frame is well under the 23 ms hop', () {
    final detector = PitchDetector();
    final frame = harmonic(58.27);
    for (var i = 0; i < 20; i++) {
      detector.detect(frame); // warm up the JIT
    }
    const runs = 200;
    final sw = Stopwatch()..start();
    for (var i = 0; i < runs; i++) {
      detector.detect(frame);
    }
    final perFrameMs = sw.elapsedMicroseconds / runs / 1000;
    // ignore: avoid_print
    print('PitchDetector: ${perFrameMs.toStringAsFixed(2)} ms per frame');
    expect(perFrameMs, lessThan(10));
  });
}

void _expectPitch(PitchEstimate? result, double expected) {
  expect(result, isNotNull, reason: 'no pitch detected for $expected Hz');
  final error = centsError(result!.frequency, expected);
  expect(
    error.abs(),
    lessThan(maxCentsError),
    reason: 'expected $expected Hz, got $result (${error.toStringAsFixed(3)}¢)',
  );
}
