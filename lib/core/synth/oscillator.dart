import 'dart:math' as math;

enum Waveform { sine, saw }

/// Phase-accumulator oscillator. Frequency changes are phase-continuous, so
/// switching notes never clicks.
class Oscillator {
  Oscillator({required this.sampleRate});

  final double sampleRate;
  double frequency = 440;
  Waveform waveform = Waveform.sine;

  double _phase = 0;

  /// Next sample in -1..1.
  double next() {
    final dt = frequency / sampleRate;
    final t = _phase;
    _phase += dt;
    if (_phase >= 1) _phase -= 1;
    return switch (waveform) {
      Waveform.sine => math.sin(2 * math.pi * t),
      // PolyBLEP smooths the reset edge, removing the harsh aliasing a naive
      // sawtooth produces at high notes.
      Waveform.saw => (2 * t - 1) - _polyBlep(t, dt),
    };
  }

  static double _polyBlep(double t, double dt) {
    if (t < dt) {
      final x = t / dt;
      return x + x - x * x - 1;
    }
    if (t > 1 - dt) {
      final x = (t - 1) / dt;
      return x * x + x + x + 1;
    }
    return 0;
  }
}
