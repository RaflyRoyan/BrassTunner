import 'dart:math' as math;

import '../../../core/pitch/note_mapper.dart';
import '../../../core/pitch/pitch_tracker.dart';

class LongTonePoint {
  const LongTonePoint(this.seconds, this.cents);

  /// Time since the take started.
  final double seconds;

  /// Deviation from the take's note. May exceed ±50 when the player drifts.
  final double cents;
}

/// One sustained note.
class LongToneTake {
  LongToneTake(this.note);

  final Note note;
  final List<LongTonePoint> points = [];

  double get durationSeconds => points.isEmpty ? 0 : points.last.seconds;

  double get meanCents => points.isEmpty
      ? 0
      : points.fold(0.0, (sum, p) => sum + p.cents) / points.length;

  /// Standard deviation in cents: lower is steadier.
  double get stabilityCents {
    if (points.length < 2) return 0;
    final mean = meanCents;
    final variance =
        points.fold(
          0.0,
          (sum, p) => sum + (p.cents - mean) * (p.cents - mean),
        ) /
        points.length;
    return math.sqrt(variance);
  }

  /// Share of samples within ±[toleranceCents], 0..1.
  double inTuneRatio([double toleranceCents = 5]) => points.isEmpty
      ? 0
      : points.where((p) => p.cents.abs() <= toleranceCents).length /
            points.length;
}

/// Splits a stream of tuner readings into takes, one per held note.
///
/// A take ends when the pitch is lost, or when a different note (more than a
/// semitone away) persists for [noteChangeHold]. Takes shorter than
/// [minDuration] are discarded as noise or passing notes.
class LongToneTracker {
  LongToneTracker({
    this.noteChangeHold = const Duration(milliseconds: 150),
    this.minDuration = const Duration(milliseconds: 500),
    this.maxDuration = const Duration(minutes: 5),
  });

  final Duration noteChangeHold;
  final Duration minDuration;
  final Duration maxDuration;

  LongToneTake? _current;
  LongToneTake? _last;
  Duration _start = Duration.zero;
  Duration? _otherNoteSince;

  /// The note being held right now.
  LongToneTake? get current => _current;

  /// The most recent finished take.
  LongToneTake? get last => _last;

  void add(Duration time, TunerReading? reading) {
    if (reading == null) {
      _finish();
      return;
    }
    final note = reading.note.note;
    final take = _current;
    if (take == null) {
      _begin(time, note);
      _append(time, reading.note.cents);
      return;
    }
    // Cents relative to the take's note, so drifting past ±50 does not flip
    // the note.
    final relative = reading.note.cents + (note.midi - take.note.midi) * 100;
    if (relative.abs() <= 100) {
      _otherNoteSince = null;
      _append(time, relative);
      return;
    }
    final since = _otherNoteSince ??= time;
    if (time - since >= noteChangeHold) {
      _finish();
      _begin(time, note);
      _append(time, reading.note.cents);
    }
  }

  void clear() {
    _current = null;
    _last = null;
    _otherNoteSince = null;
  }

  void _begin(Duration time, Note note) {
    _current = LongToneTake(note);
    _start = time;
    _otherNoteSince = null;
  }

  void _append(Duration time, double cents) {
    final elapsed = time - _start;
    if (elapsed > maxDuration) return;
    _current!.points.add(LongTonePoint(elapsed.inMicroseconds / 1e6, cents));
  }

  void _finish() {
    final take = _current;
    _current = null;
    _otherNoteSince = null;
    if (take != null &&
        take.durationSeconds * 1e6 >= minDuration.inMicroseconds) {
      _last = take;
    }
  }
}
