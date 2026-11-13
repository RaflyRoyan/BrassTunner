import 'dart:typed_data';

import 'autocorrelation.dart';
import 'mpm.dart';
import 'pitch_result.dart';
import 'yin.dart';

/// Single-frame pitch detector: MPM first, YIN when MPM is not confident.
///
/// Defaults cover the brass family: ~27 Hz (below tuba pedal B♭0) up to
/// 1600 Hz (above trumpet high G).
class PitchDetector {
  PitchDetector({
    this.sampleRate = 44100,
    this.windowSize = 4096,
    this.minFrequency = 27,
    this.maxFrequency = 1600,
    this.minClarity = 0.8,
    Mpm? mpm,
    Yin? yin,
  }) : mpm = mpm ?? Mpm(),
       yin = yin ?? Yin(),
       minLag = (sampleRate / maxFrequency).floor().clamp(2, windowSize),
       maxLag = (sampleRate / minFrequency).ceil() + 2,
       _x = Float64List(windowSize) {
    if (minFrequency <= 0 || maxFrequency <= minFrequency) {
      throw ArgumentError('Need 0 < minFrequency < maxFrequency');
    }
    if (maxLag > windowSize ~/ 2) {
      throw ArgumentError(
        'windowSize $windowSize is too short for minFrequency $minFrequency '
        'Hz at $sampleRate Hz (needs at least ${2 * maxLag} samples)',
      );
    }
    _ac = AutocorrelationEngine(windowSize: windowSize, maxLag: maxLag);
  }

  final double sampleRate;
  final int windowSize;
  final double minFrequency;
  final double maxFrequency;

  /// MPM results below this clarity fall back to YIN.
  final double minClarity;

  final Mpm mpm;
  final Yin yin;
  final int minLag;
  final int maxLag;

  final Float64List _x;
  late final AutocorrelationEngine _ac;

  /// Estimates the pitch of exactly [windowSize] samples in -1..1.
  /// Returns null when the frame has no reliable pitch in range.
  PitchEstimate? detect(List<double> samples) {
    if (samples.length != windowSize) {
      throw ArgumentError(
        'Expected $windowSize samples, got ${samples.length}',
      );
    }
    // Remove DC offset; mic input often has one and it biases correlation.
    var mean = 0.0;
    for (var i = 0; i < windowSize; i++) {
      mean += samples[i];
    }
    mean /= windowSize;
    for (var i = 0; i < windowSize; i++) {
      _x[i] = samples[i] - mean;
    }
    _ac.compute(_x);

    final fromMpm = mpm.estimate(_ac, sampleRate: sampleRate, minLag: minLag);
    if (fromMpm != null &&
        fromMpm.clarity >= minClarity &&
        _inRange(fromMpm.frequency)) {
      return fromMpm;
    }
    final fromYin = yin.estimate(_ac, sampleRate: sampleRate, minLag: minLag);
    if (fromYin != null && _inRange(fromYin.frequency)) return fromYin;
    return null;
  }

  bool _inRange(double f) => f >= minFrequency && f <= maxFrequency;
}
