import '../../tuner/domain/instrument.dart';

/// Intonation of one note (sounding pitch) within a session.
class NoteStat {
  const NoteStat({
    required this.midi,
    required this.samples,
    required this.meanCents,
    required this.sharp,
    required this.flat,
  });

  /// Sounding MIDI number.
  final int midi;

  /// Tuner frames counted (about 43 per second).
  final int samples;

  /// Mean deviation, positive is sharp.
  final double meanCents;

  /// Frames more than [NoteStat.toleranceCents] sharp / flat.
  final int sharp;
  final int flat;

  /// Frames within this many cents count as in tune.
  static const double toleranceCents = 5;

  double get sharpRatio => samples == 0 ? 0 : sharp / samples;
  double get flatRatio => samples == 0 ? 0 : flat / samples;

  /// Combines stats of the same note, weighting by sample count.
  NoteStat merge(NoteStat other) {
    assert(other.midi == midi);
    final total = samples + other.samples;
    return NoteStat(
      midi: midi,
      samples: total,
      meanCents: total == 0
          ? 0
          : (meanCents * samples + other.meanCents * other.samples) / total,
      sharp: sharp + other.sharp,
      flat: flat + other.flat,
    );
  }
}

/// One stretch of practice with the mic on.
class PracticeSession {
  const PracticeSession({
    this.id,
    required this.startedAt,
    required this.duration,
    required this.instrument,
    required this.a4,
    required this.notes,
  });

  /// Database id; null until saved.
  final int? id;
  final DateTime startedAt;

  /// From the first to the last counted note.
  final Duration duration;
  final Instrument instrument;
  final double a4;

  /// Per-note results, low to high.
  final List<NoteStat> notes;

  int get samples => notes.fold(0, (sum, n) => sum + n.samples);

  /// Sample-weighted mean of |deviation| per note.
  double get meanAbsCents {
    final total = samples;
    if (total == 0) return 0;
    return notes.fold(0.0, (sum, n) => sum + n.meanCents.abs() * n.samples) /
        total;
  }

  PracticeSession withId(int id) => PracticeSession(
    id: id,
    startedAt: startedAt,
    duration: duration,
    instrument: instrument,
    a4: a4,
    notes: notes,
  );
}
