import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pitch/pitch_tracker.dart';
import '../../fingering/domain/fingering.dart';
import '../../settings/application/settings_controller.dart';
import '../../tuner/application/tuner_controller.dart';
import '../../tuner/domain/instrument.dart';
import '../domain/lip_slur.dart';

class LipSlurState {
  const LipSlurState({
    required this.exercise,
    required this.tracker,
    this.reading,
    this.revision = 0,
  });

  final LipSlurExercise exercise;

  /// Mutated in place; [revision] bumps on every change.
  final LipSlurTracker tracker;

  /// Latest tuner reading, for the live display.
  final TunerReading? reading;
  final int revision;
}

/// Runs a lip slur exercise while its page is on screen. Changing the
/// instrument starts a fresh default exercise.
final lipSlurProvider =
    NotifierProvider.autoDispose<LipSlurController, LipSlurState>(
      LipSlurController.new,
    );

class LipSlurController extends Notifier<LipSlurState> {
  final _clock = Stopwatch();

  @override
  LipSlurState build() {
    final instrument = ref.watch(settingsProvider.select((s) => s.instrument));
    _clock
      ..reset()
      ..start();
    ref.listen(tunerControllerProvider.select((s) => s.reading), (_, reading) {
      state.tracker.add(_clock.elapsed, reading);
      state = LipSlurState(
        exercise: state.exercise,
        tracker: state.tracker,
        reading: reading,
        revision: state.revision + 1,
      );
    });
    final exercise = defaultExercise(instrument);
    return LipSlurState(exercise: exercise, tracker: LipSlurTracker(exercise));
  }

  /// Open (or 1st position), four partials from the 2nd; the horn starts on
  /// the 3rd because its 2nd partial is rarely used.
  static LipSlurExercise defaultExercise(Instrument instrument) {
    final spec = FingeringSpec.of(instrument);
    final start = spec.system == FingeringSystem.fHorn ? 1 : 0;
    return LipSlurExercise(
      spec: spec,
      fingering: spec.fingerings.first,
      lowPartial: spec.partials[start],
      highPartial: spec.partials[math.min(start + 3, spec.partials.length - 1)],
    );
  }

  /// One fingering per lowering (1-2 rather than 3, 4 rather than 1-3).
  static List<Fingering> fingeringChoices(FingeringSpec spec) {
    final seen = <int>{};
    return [
      for (final f in spec.fingerings)
        if (seen.add(f.lowering)) f,
    ];
  }

  void setFingering(Fingering fingering) => _start(
    LipSlurExercise(
      spec: state.exercise.spec,
      fingering: fingering,
      lowPartial: state.exercise.lowPartial,
      highPartial: state.exercise.highPartial,
    ),
  );

  void setRange(int lowPartial, int highPartial) {
    if (lowPartial >= highPartial) return;
    _start(
      LipSlurExercise(
        spec: state.exercise.spec,
        fingering: state.exercise.fingering,
        lowPartial: lowPartial,
        highPartial: highPartial,
      ),
    );
  }

  void restart() => _start(state.exercise);

  void _start(LipSlurExercise exercise) => state = LipSlurState(
    exercise: exercise,
    tracker: LipSlurTracker(exercise),
    reading: state.reading,
    revision: state.revision + 1,
  );
}
