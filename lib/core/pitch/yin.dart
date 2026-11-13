import 'dart:typed_data';

import 'autocorrelation.dart';
import 'pitch_result.dart';

/// YIN (de Cheveigné & Kawahara, 2002), used as a fallback when MPM is not
/// confident.
///
/// The difference function `d(τ) = m(τ) - 2r(τ)` reuses the sums already
/// computed for MPM, so running it costs only one pass over the lags.
class Yin {
  Yin({this.threshold = 0.15});

  /// Maximum cumulative-mean-normalized difference accepted as periodic.
  final double threshold;

  Float64List _d = Float64List(0);
  Float64List _cmnd = Float64List(0);

  PitchEstimate? estimate(
    AutocorrelationEngine ac, {
    required double sampleRate,
    required int minLag,
  }) {
    final maxLag = ac.maxLag;
    if (_d.length != maxLag + 1) {
      _d = Float64List(maxLag + 1);
      _cmnd = Float64List(maxLag + 1);
    }
    final d = _d;
    final cmnd = _cmnd;

    d[0] = 0;
    cmnd[0] = 1;
    var runningSum = 0.0;
    for (var tau = 1; tau <= maxLag; tau++) {
      final value = ac.m[tau] - 2 * ac.r[tau];
      d[tau] = value < 0 ? 0 : value;
      runningSum += d[tau];
      cmnd[tau] = runningSum > 0 ? d[tau] * tau / runningSum : 1;
    }

    var tau = minLag < 2 ? 2 : minLag;
    var found = -1;
    for (; tau < maxLag; tau++) {
      if (cmnd[tau] < threshold) {
        while (tau + 1 < maxLag && cmnd[tau + 1] < cmnd[tau]) {
          tau++;
        }
        found = tau;
        break;
      }
    }
    if (found < 0) return null;

    // Interpolate on the raw difference, which is locally quadratic around
    // the true period; the normalized curve is skewed.
    final offset = parabolicOffset(d[found - 1], d[found], d[found + 1]);
    return PitchEstimate(
      frequency: sampleRate / (found + offset),
      clarity: (1 - cmnd[found]).clamp(0.0, 1.0),
      algorithm: PitchAlgorithm.yin,
    );
  }
}
