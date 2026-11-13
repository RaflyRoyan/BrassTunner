import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../tuner/application/tuner_controller.dart';
import '../domain/long_tone_tracker.dart';

class LongToneState {
  const LongToneState({this.current, this.last, this.revision = 0});

  final LongToneTake? current;
  final LongToneTake? last;

  /// Bumped on every update; takes are mutated in place.
  final int revision;

  /// What to show: the live take, else the last finished one.
  LongToneTake? get shown => current ?? last;
  bool get isLive => current != null;
}

/// Records takes only while the long-tone page is on screen.
final longToneProvider =
    NotifierProvider.autoDispose<LongToneController, LongToneState>(
      LongToneController.new,
    );

class LongToneController extends Notifier<LongToneState> {
  final _tracker = LongToneTracker();
  final _clock = Stopwatch();

  @override
  LongToneState build() {
    _clock.start();
    ref.listen(tunerControllerProvider.select((s) => s.reading), (_, reading) {
      _tracker.add(_clock.elapsed, reading);
      _publish();
    });
    return const LongToneState();
  }

  void clear() {
    _tracker.clear();
    _publish();
  }

  void _publish() => state = LongToneState(
    current: _tracker.current,
    last: _tracker.last,
    revision: state.revision + 1,
  );
}
