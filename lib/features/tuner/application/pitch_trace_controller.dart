import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/platform/clock.dart';
import '../domain/pitch_trace.dart';
import 'tuner_controller.dart';

class PitchTraceState {
  const PitchTraceState(this.trace, this.revision);

  final PitchTrace trace;

  /// Bumped on every sample; the trace is mutated in place.
  final int revision;
}

/// Records the input pitch only while the tuner graph is on screen.
final pitchTraceProvider =
    NotifierProvider.autoDispose<PitchTraceController, PitchTraceState>(
      PitchTraceController.new,
    );

class PitchTraceController extends Notifier<PitchTraceState> {
  final _trace = PitchTrace();

  @override
  PitchTraceState build() {
    final clock = ref.read(clockProvider);
    final start = clock();
    ref.listen(tunerControllerProvider.select((s) => s.reading), (_, reading) {
      _trace.add(clock().difference(start), reading);
      state = PitchTraceState(_trace, state.revision + 1);
    });
    return PitchTraceState(_trace, 0);
  }
}
