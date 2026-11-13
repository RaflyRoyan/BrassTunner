import 'dart:math' as math;
import 'dart:typed_data';

import 'oscillator.dart';

/// Sustained reference tone with click-free start, stop and volume changes.
class DroneVoice {
  DroneVoice(double sampleRate)
    : _oscillator = Oscillator(sampleRate: sampleRate),
      // ~15 ms time constant: fast enough to feel instant, slow enough to
      // avoid a pop.
      _rampCoefficient = 1 - math.exp(-1 / (0.015 * sampleRate));

  final Oscillator _oscillator;
  final double _rampCoefficient;

  /// Output level 0..1.
  double volume = 0.5;
  bool playing = false;

  double _gain = 0;

  double get frequency => _oscillator.frequency;
  set frequency(double hz) => _oscillator.frequency = hz;

  Waveform get waveform => _oscillator.waveform;
  set waveform(Waveform w) => _oscillator.waveform = w;

  /// True once stopped and fully faded out.
  bool get isSilent => !playing && _gain == 0;

  /// Mixes this voice into [buffer].
  void addTo(Float32List buffer) {
    if (isSilent) return;
    final target = playing ? volume : 0.0;
    // A saw has many harmonics and sounds much louder than a sine at the
    // same peak level.
    final level = waveform == Waveform.saw ? 0.35 : 0.5;
    for (var i = 0; i < buffer.length; i++) {
      _gain += (target - _gain) * _rampCoefficient;
      buffer[i] += _oscillator.next() * _gain * level;
    }
    if (!playing && _gain < 1e-4) _gain = 0;
  }
}
