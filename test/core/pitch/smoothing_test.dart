import 'package:brass_tunner/core/pitch/smoothing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('first value passes straight through', () {
    expect(PitchSmoother().add(1000), 1000);
  });

  test('a single octave-jump outlier is rejected by the median', () {
    final s = PitchSmoother();
    for (var i = 0; i < 4; i++) {
      s.add(1000);
    }
    final afterOutlier = s.add(1000 + 1200); // one frame an octave up
    expect(afterOutlier, closeTo(1000, 1e-9));
  });

  test('EMA reduces jitter', () {
    final s = PitchSmoother(medianSize: 1, emaAlpha: 0.3);
    s.add(0);
    final out = s.add(10);
    expect(out, closeTo(3, 1e-9));
  });

  test('a note change (> threshold) jumps instead of gliding', () {
    final s = PitchSmoother(medianSize: 3);
    for (var i = 0; i < 5; i++) {
      s.add(1000);
    }
    s.add(1200); // median still 1000
    final out = s.add(1200); // median now 1200 → reset
    expect(out, 1200);
  });

  test('short dropouts hold the last value, long ones reset', () {
    final s = PitchSmoother(holdFrames: 2);
    s.add(500);
    expect(s.add(null), 500);
    expect(s.add(null), 500);
    expect(s.add(null), isNull);
    expect(s.value, isNull);
    expect(s.add(800), 800, reason: 'fresh start after reset');
  });

  test('converges to a steady input', () {
    final s = PitchSmoother();
    s.add(0);
    double? out;
    for (var i = 0; i < 40; i++) {
      out = s.add(20);
    }
    expect(out, closeTo(20, 0.01));
  });

  test('rejects invalid parameters', () {
    expect(() => PitchSmoother(medianSize: 0), throwsArgumentError);
    expect(() => PitchSmoother(emaAlpha: 0), throwsArgumentError);
    expect(() => PitchSmoother(emaAlpha: 1.5), throwsArgumentError);
  });
}
