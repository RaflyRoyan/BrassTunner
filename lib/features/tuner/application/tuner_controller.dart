import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/audio/mic_source.dart';
import '../../../core/pitch/pitch_tracker.dart';
import '../../../core/pitch/pitch_worker.dart';
import '../../settings/application/settings_controller.dart';

enum TunerStatus { idle, starting, listening, permissionDenied, error }

class TunerState {
  const TunerState(this.status, [this.reading]);

  static const idle = TunerState(TunerStatus.idle);

  final TunerStatus status;

  /// Latest smoothed reading; null while there is no pitch.
  final TunerReading? reading;
}

final micSourceProvider = Provider<MicSource>((ref) {
  final mic = MicSource();
  ref.onDispose(mic.dispose);
  return mic;
});

/// Spawns the DSP isolate; overridable in tests.
final pitchWorkerFactoryProvider =
    Provider<Future<PitchWorker> Function({required double a4})>(
      (ref) =>
          ({required double a4}) => PitchWorker.spawn(
            sampleRate: MicSource.sampleRate.toDouble(),
            a4: a4,
          ),
    );

final tunerControllerProvider = NotifierProvider<TunerController, TunerState>(
  TunerController.new,
);

/// Owns the mic → DSP isolate → UI pipeline.
class TunerController extends Notifier<TunerState> {
  PitchWorker? _worker;
  StreamSubscription<Uint8List>? _audio;
  StreamSubscription<TunerReading?>? _readings;

  /// What the UI last asked for; checked after every await so a stop during
  /// start-up wins.
  bool _wantRunning = false;

  @override
  TunerState build() {
    ref.listen(settingsProvider.select((s) => s.a4), (_, a4) {
      _worker?.setA4(a4);
    });
    ref.onDispose(() {
      _wantRunning = false;
      _audio?.cancel();
      _readings?.cancel();
      _worker?.dispose();
      _worker = null;
    });
    return TunerState.idle;
  }

  Future<void> start() async {
    _wantRunning = true;
    if (state.status == TunerStatus.starting ||
        state.status == TunerStatus.listening) {
      return;
    }
    state = const TunerState(TunerStatus.starting);
    final mic = ref.read(micSourceProvider);
    try {
      if (!await mic.requestPermission()) {
        if (ref.mounted) state = const TunerState(TunerStatus.permissionDenied);
        return;
      }
      if (!ref.mounted || !_wantRunning) return _settleStopped();

      final worker = _worker ??= await ref.read(pitchWorkerFactoryProvider)(
        a4: ref.read(settingsProvider).a4,
      );
      if (!ref.mounted || !_wantRunning) return _settleStopped();

      _readings ??= worker.readings.listen((reading) {
        if (ref.mounted && state.status == TunerStatus.listening) {
          state = TunerState(TunerStatus.listening, reading);
        }
      });
      final audio = await mic.start();
      if (!ref.mounted || !_wantRunning) {
        await mic.stop();
        return _settleStopped();
      }
      _audio = audio.listen(worker.addPcm16, onError: (Object _) => _fail());
      state = const TunerState(TunerStatus.listening);
    } catch (_) {
      _fail();
    }
  }

  Future<void> stop() async {
    _wantRunning = false;
    await _audio?.cancel();
    _audio = null;
    await ref.read(micSourceProvider).stop();
    _worker?.reset();
    _settleStopped();
  }

  void _settleStopped() {
    if (ref.mounted && state.status != TunerStatus.permissionDenied) {
      state = TunerState.idle;
    }
  }

  void _fail() {
    _audio?.cancel();
    _audio = null;
    if (ref.mounted) state = const TunerState(TunerStatus.error);
  }
}
