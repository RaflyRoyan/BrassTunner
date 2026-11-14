import '../../../core/pitch/note_mapper.dart';
import '../../../core/pitch/pitch_tracker.dart';
import '../../fingering/domain/fingering.dart';

/// A lip slur: partials played up and back down on one fingering.
class LipSlurExercise {
  LipSlurExercise({
    required this.spec,
    required this.fingering,
    required this.lowPartial,
    required this.highPartial,
  }) : assert(lowPartial < highPartial);

  final FingeringSpec spec;
  final Fingering fingering;
  final int lowPartial;
  final int highPartial;

  /// e.g. 2-3-4-5-4-3-2 for partials 2..5.
  List<int> get partials {
    final up = [
      for (final p in spec.partials)
        if (p >= lowPartial && p <= highPartial) p,
    ];
    return [...up, ...up.reversed.skip(1)];
  }

  /// Sounding notes to play, in order.
  List<Note> get targets => [
    for (final p in partials) spec.noteOf(p, fingering),
  ];
}

/// Result of one note of the exercise.
class LipSlurStep {
  LipSlurStep(this.target, this.partial);

  final Note target;
  final int partial;

  /// Deviations while the note was held; empty until it is hit.
  final List<double> cents = [];

  /// Times another note was held instead (a missed or cracked partial).
  int misses = 0;

  bool get done => cents.isNotEmpty;

  double? get meanCents =>
      done ? cents.reduce((a, b) => a + b) / cents.length : null;
}

/// Follows tuner readings through a [LipSlurExercise].
///
/// A step counts when its note is held for [hold]. Holding a different note
/// for [hold] counts a miss, except the note just completed (the player is
/// still on it before slurring on).
class LipSlurTracker {
  LipSlurTracker(
    LipSlurExercise exercise, {
    this.hold = const Duration(milliseconds: 250),
  }) : steps = [
         for (final (i, p) in exercise.partials.indexed)
           LipSlurStep(exercise.targets[i], p),
       ];

  final Duration hold;
  final List<LipSlurStep> steps;

  int _index = 0;
  int? _heldMidi;
  Duration _heldSince = Duration.zero;
  bool _missCounted = false;
  final List<double> _samples = [];

  int get index => _index;
  bool get finished => _index >= steps.length;
  LipSlurStep? get current => finished ? null : steps[_index];

  int get totalMisses => steps.fold(0, (sum, s) => sum + s.misses);

  /// Mean absolute deviation over completed steps.
  double? get meanAbsCents {
    final done = steps.where((s) => s.done).toList();
    if (done.isEmpty) return null;
    return done.fold(0.0, (sum, s) => sum + s.meanCents!.abs()) / done.length;
  }

  void add(Duration time, TunerReading? reading) {
    if (finished) return;
    if (reading == null) {
      _heldMidi = null;
      _samples.clear();
      return;
    }
    final midi = reading.note.note.midi;
    if (midi != _heldMidi) {
      _heldMidi = midi;
      _heldSince = time;
      _missCounted = false;
      _samples.clear();
    }
    final step = steps[_index];
    final held = time - _heldSince >= hold;
    if (midi == step.target.midi) {
      _samples.add(reading.note.cents);
      if (held) {
        step.cents.addAll(_samples);
        _samples.clear();
        _index++;
      }
      return;
    }
    final previous = _index > 0 ? steps[_index - 1].target.midi : null;
    if (held && !_missCounted && midi != previous) {
      step.misses++;
      _missCounted = true;
    }
  }
}
