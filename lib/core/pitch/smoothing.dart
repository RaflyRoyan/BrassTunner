import 'dart:typed_data';

/// Stabilizes a stream of pitch values (in cents, any reference) for the
/// tuner needle.
///
/// 1. A median over the last [medianSize] frames rejects single-frame
///    outliers such as octave jumps.
/// 2. An EMA with [emaAlpha] smooths the remaining jitter.
/// 3. If the median moves more than [resetThresholdCents] away from the EMA
///    (a new note), the EMA jumps straight to it instead of gliding.
/// 4. Up to [holdFrames] missing frames keep the last value; after that the
///    smoother resets and reports no pitch.
class PitchSmoother {
  PitchSmoother({
    this.medianSize = 5,
    this.emaAlpha = 0.35,
    this.resetThresholdCents = 50,
    this.holdFrames = 3,
  }) : _history = Float64List(medianSize),
       _sorted = Float64List(medianSize) {
    if (medianSize < 1) throw ArgumentError.value(medianSize, 'medianSize');
    if (emaAlpha <= 0 || emaAlpha > 1) {
      throw ArgumentError.value(emaAlpha, 'emaAlpha', 'must be in (0, 1]');
    }
  }

  final int medianSize;
  final double emaAlpha;
  final double resetThresholdCents;
  final int holdFrames;

  final Float64List _history;
  final Float64List _sorted;
  int _count = 0;
  int _next = 0;
  int _misses = 0;
  double? _ema;

  /// Current smoothed value, or null when there is no pitch.
  double? get value => _ema;

  /// Feeds one frame ([cents] = null when the frame had no pitch) and returns
  /// the smoothed value.
  double? add(double? cents) {
    if (cents == null) {
      _misses++;
      if (_misses > holdFrames) reset();
      return _ema;
    }
    _misses = 0;
    _history[_next] = cents;
    _next = (_next + 1) % medianSize;
    if (_count < medianSize) _count++;

    final median = _median();
    final ema = _ema;
    if (ema == null || (median - ema).abs() > resetThresholdCents) {
      _ema = median;
    } else {
      _ema = ema + emaAlpha * (median - ema);
    }
    return _ema;
  }

  void reset() {
    _count = 0;
    _next = 0;
    _misses = 0;
    _ema = null;
  }

  double _median() {
    // Copy the filled part (ring order does not matter for a median) and
    // insertion-sort it; medianSize is tiny.
    for (var i = 0; i < _count; i++) {
      final v = _history[i];
      var j = i - 1;
      while (j >= 0 && _sorted[j] > v) {
        _sorted[j + 1] = _sorted[j];
        j--;
      }
      _sorted[j + 1] = v;
    }
    final mid = _count ~/ 2;
    return _count.isOdd ? _sorted[mid] : (_sorted[mid - 1] + _sorted[mid]) / 2;
  }
}
