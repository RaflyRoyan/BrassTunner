import 'dart:typed_data';

import 'autocorrelation.dart';
import 'pitch_result.dart';

/// McLeod Pitch Method (McLeod & Wyvill, 2005).
///
/// Uses the normalized square difference function `n(τ) = 2r(τ)/m(τ)`, which
/// is bounded by 1 and reaches exactly 1 at the period of a periodic signal.
/// The first "key maximum" above `cutoff × highest key maximum` is taken as
/// the period, which avoids picking a multiple of the period (octave-down
/// errors).
class Mpm {
  Mpm({this.cutoff = 0.9, this.smallCutoff = 0.5});

  /// Fraction of the highest key maximum a peak must reach to be chosen.
  final double cutoff;

  /// Below this highest key maximum the frame is treated as unpitched.
  final double smallCutoff;

  Float64List _nsdf = Float64List(0);
  final List<int> _keyMaxima = <int>[];

  PitchEstimate? estimate(
    AutocorrelationEngine ac, {
    required double sampleRate,
    required int minLag,
  }) {
    final maxLag = ac.maxLag;
    if (_nsdf.length != maxLag + 1) _nsdf = Float64List(maxLag + 1);
    final n = _nsdf;
    for (var tau = 0; tau <= maxLag; tau++) {
      final m = ac.m[tau];
      n[tau] = m > 1e-12 ? 2 * ac.r[tau] / m : 0;
    }

    _keyMaxima.clear();
    var tau = 1;
    // Skip the lobe around τ = 0; it is not a period.
    while (tau < maxLag && n[tau] > 0) {
      tau++;
    }
    var inRegion = false;
    var best = -1;
    for (; tau < maxLag; tau++) {
      final v = n[tau];
      if (v > 0) {
        if (!inRegion) {
          inRegion = true;
          best = tau;
        } else if (v > n[best]) {
          best = tau;
        }
      } else if (inRegion) {
        inRegion = false;
        if (best >= minLag) _keyMaxima.add(best);
      }
    }
    // A region still open at maxLag counts only if its peak is a real local
    // maximum, not the edge of the search range.
    if (inRegion && best >= minLag && n[best] > n[best + 1]) {
      _keyMaxima.add(best);
    }
    if (_keyMaxima.isEmpty) return null;

    var highest = 0.0;
    for (final k in _keyMaxima) {
      if (n[k] > highest) highest = n[k];
    }
    if (highest < smallCutoff) return null;

    final threshold = cutoff * highest;
    final chosen = _keyMaxima.firstWhere((k) => n[k] >= threshold);
    final left = n[chosen - 1];
    final center = n[chosen];
    final right = n[chosen + 1];
    final offset = parabolicOffset(left, center, right);
    final peak = center - 0.25 * (left - right) * offset;
    final period = chosen + offset;

    return PitchEstimate(
      frequency: sampleRate / period,
      clarity: peak.clamp(0.0, 1.0),
      algorithm: PitchAlgorithm.mpm,
    );
  }
}
