/// Which algorithm produced a pitch estimate.
enum PitchAlgorithm { mpm, yin }

/// A single-frame pitch estimate before smoothing.
class PitchEstimate {
  const PitchEstimate({
    required this.frequency,
    required this.clarity,
    required this.algorithm,
  });

  /// Fundamental frequency in Hz.
  final double frequency;

  /// Periodicity confidence in 0..1 (1 = perfectly periodic).
  final double clarity;

  final PitchAlgorithm algorithm;

  @override
  String toString() =>
      'PitchEstimate(${frequency.toStringAsFixed(3)} Hz, '
      'clarity ${clarity.toStringAsFixed(3)}, ${algorithm.name})';
}

/// Parabolic interpolation through three equally spaced points around an
/// extremum at index 0. Returns the offset of the true extremum in -1..1.
double parabolicOffset(double left, double center, double right) {
  final denominator = left - 2 * center + right;
  if (denominator.abs() < 1e-12) return 0;
  final offset = 0.5 * (left - right) / denominator;
  return offset.clamp(-1.0, 1.0);
}
