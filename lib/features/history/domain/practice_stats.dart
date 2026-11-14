import 'practice_session.dart';

/// Totals and per-note tendencies over many sessions.
class PracticeStats {
  PracticeStats(List<PracticeSession> sessions)
    : sessionCount = sessions.length,
      totalDuration = sessions.fold(
        Duration.zero,
        (sum, s) => sum + s.duration,
      ),
      notes = _mergeNotes(sessions);

  final int sessionCount;
  final Duration totalDuration;

  /// Every note played, merged across sessions, low to high.
  final List<NoteStat> notes;

  /// Notes need this much data before they are ranked (about 2 seconds).
  static const int minSamples = 86;

  /// Sample-weighted mean |deviation| over all notes.
  double get meanAbsCents {
    final total = notes.fold(0, (sum, n) => sum + n.samples);
    if (total == 0) return 0;
    return notes.fold(0.0, (sum, n) => sum + n.meanCents.abs() * n.samples) /
        total;
  }

  /// A note must be off in one direction at least this often to be listed.
  static const double minRatio = 0.2;

  /// Notes most often sharp, worst first. Only notes that are sharp more
  /// often than flat, at least [minRatio] of the time and sharp on average
  /// are listed.
  List<NoteStat> mostSharp([int limit = 5]) => _rank(
    (n) => n.sharpRatio,
    (n) => n.sharp > n.flat && n.sharpRatio >= minRatio && n.meanCents > 0,
    limit,
  );

  /// Notes most often flat, worst first (mirror of [mostSharp]).
  List<NoteStat> mostFlat([int limit = 5]) => _rank(
    (n) => n.flatRatio,
    (n) => n.flat > n.sharp && n.flatRatio >= minRatio && n.meanCents < 0,
    limit,
  );

  List<NoteStat> _rank(
    double Function(NoteStat) ratio,
    bool Function(NoteStat) leaning,
    int limit,
  ) {
    final ranked =
        notes.where((n) => n.samples >= minSamples && leaning(n)).toList()
          ..sort((a, b) {
            final byRatio = ratio(b).compareTo(ratio(a));
            return byRatio != 0 ? byRatio : b.samples.compareTo(a.samples);
          });
    return ranked.take(limit).toList();
  }

  static List<NoteStat> _mergeNotes(List<PracticeSession> sessions) {
    final byMidi = <int, NoteStat>{};
    for (final session in sessions) {
      for (final note in session.notes) {
        final existing = byMidi[note.midi];
        byMidi[note.midi] = existing == null ? note : existing.merge(note);
      }
    }
    return (byMidi.keys.toList()..sort()).map((m) => byMidi[m]!).toList();
  }
}
