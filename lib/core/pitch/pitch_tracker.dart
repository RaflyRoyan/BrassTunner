import 'dart:math' as math;

import 'noise_gate.dart';
import 'note_mapper.dart';
import 'pitch_detector.dart';
import 'pitch_result.dart';
import 'smoothing.dart';

/// One tuner update: smoothed note plus the raw data behind it.
class TunerReading {
  const TunerReading({
    required this.note,
    required this.rawFrequency,
    required this.clarity,
    required this.levelDb,
    required this.algorithm,
  });

  /// Smoothed note, deviation and frequency.
  final NoteReading note;

  /// Unsmoothed frequency of the latest pitched frame, in Hz.
  final double rawFrequency;

  final double clarity;

  /// Input level of the latest frame in dBFS.
  final double levelDb;

  final PitchAlgorithm algorithm;

  @override
  String toString() =>
      'TunerReading($note, raw '
      '${rawFrequency.toStringAsFixed(2)} Hz, ${algorithm.name})';
}

/// Full per-frame pipeline: noise gate → pitch detector → smoother → note.
///
/// Pure Dart with no Flutter imports, so it can run in a background isolate.
class PitchTracker {
  PitchTracker({
    PitchDetector? detector,
    NoiseGate? gate,
    PitchSmoother? smoother,
    NoteMapper? mapper,
  }) : detector = detector ?? PitchDetector(),
       gate = gate ?? NoiseGate(),
       smoother = smoother ?? PitchSmoother(),
       mapper = mapper ?? NoteMapper();

  final PitchDetector detector;
  final NoiseGate gate;
  final PitchSmoother smoother;

  /// Replace to change A4 or note spelling; smoothing is unaffected because
  /// it works on absolute cents.
  NoteMapper mapper;

  PitchEstimate? _lastEstimate;

  int get windowSize => detector.windowSize;

  /// Processes one window of [windowSize] samples in -1..1. Returns null when
  /// there is no pitch to show.
  TunerReading? process(List<double> frame) {
    PitchEstimate? estimate;
    if (gate.process(frame)) estimate = detector.detect(frame);
    if (estimate != null) _lastEstimate = estimate;

    final smoothedCents = smoother.add(
      estimate == null ? null : _absoluteCents(estimate.frequency),
    );
    final last = _lastEstimate;
    if (smoothedCents == null || last == null) {
      _lastEstimate = null;
      return null;
    }
    return TunerReading(
      note: mapper.fromFrequency(math.pow(2, smoothedCents / 1200).toDouble()),
      rawFrequency: last.frequency,
      clarity: last.clarity,
      levelDb: gate.lastLevelDb,
      algorithm: last.algorithm,
    );
  }

  void reset() {
    gate.reset();
    smoother.reset();
    _lastEstimate = null;
  }

  /// Cents above 1 Hz; a log-frequency scale independent of A4.
  static double _absoluteCents(double frequency) =>
      1200 * math.log(frequency) / math.ln2;
}
