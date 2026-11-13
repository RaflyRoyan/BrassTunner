import 'dart:typed_data';

import 'fft.dart';

/// Computes, for lags 0..[maxLag], the two sums both MPM and YIN need:
///
/// * `r[τ] = Σ x[j]·x[j+τ]` (linear autocorrelation, via FFT)
/// * `m[τ] = Σ (x[j]² + x[j+τ]²)` (energy of the overlapping parts)
///
/// with `j` running over `0 .. windowSize-1-τ`.
///
/// MPM's NSDF is `2r/m`; YIN's difference function is `m - 2r`. Sharing them
/// makes the YIN fallback almost free.
class AutocorrelationEngine {
  AutocorrelationEngine({required this.windowSize, required this.maxLag})
    : fftSize = _nextPowerOfTwo(windowSize + maxLag),
      r = Float64List(maxLag + 1),
      m = Float64List(maxLag + 1) {
    if (maxLag < 2 || maxLag >= windowSize) {
      throw ArgumentError.value(maxLag, 'maxLag', 'must be in 2..windowSize-1');
    }
    _fft = Fft(fftSize);
    _re = Float64List(fftSize);
    _im = Float64List(fftSize);
  }

  final int windowSize;
  final int maxLag;

  /// Zero-padded so the circular correlation equals the linear one for every
  /// lag up to [maxLag].
  final int fftSize;

  final Float64List r;
  final Float64List m;

  late final Fft _fft;
  late final Float64List _re;
  late final Float64List _im;

  void compute(Float64List x) {
    if (x.length != windowSize) {
      throw ArgumentError('Expected $windowSize samples, got ${x.length}');
    }
    _re.setRange(0, windowSize, x);
    _re.fillRange(windowSize, fftSize, 0);
    _im.fillRange(0, fftSize, 0);

    _fft.transform(_re, _im);
    for (var i = 0; i < fftSize; i++) {
      _re[i] = _re[i] * _re[i] + _im[i] * _im[i];
      _im[i] = 0;
    }
    // The power spectrum is real and even, so a forward FFT equals the
    // inverse up to the 1/N scale.
    _fft.transform(_re, _im);
    final scale = 1.0 / fftSize;
    for (var tau = 0; tau <= maxLag; tau++) {
      r[tau] = _re[tau] * scale;
    }

    var energy = 0.0;
    for (var i = 0; i < windowSize; i++) {
      energy += x[i] * x[i];
    }
    m[0] = 2 * energy;
    for (var tau = 1; tau <= maxLag; tau++) {
      final a = x[tau - 1];
      final b = x[windowSize - tau];
      m[tau] = m[tau - 1] - a * a - b * b;
    }
  }

  static int _nextPowerOfTwo(int n) {
    var p = 1;
    while (p < n) {
      p <<= 1;
    }
    return p;
  }
}
