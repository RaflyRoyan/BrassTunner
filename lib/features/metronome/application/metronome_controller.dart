import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/synth/metronome_voice.dart';
import '../../../core/synth/tap_tempo.dart';
import '../../../shared/audio/practice_audio_provider.dart';
import '../../settings/application/settings_controller.dart';

class MetronomeState {
  const MetronomeState({
    this.bpm = 80,
    this.beatsPerBar = 4,
    this.volume = 0.8,
    this.running = false,
  });

  final int bpm;
  final int beatsPerBar;
  final double volume;
  final bool running;

  MetronomeState copyWith({
    int? bpm,
    int? beatsPerBar,
    double? volume,
    bool? running,
  }) => MetronomeState(
    bpm: bpm ?? this.bpm,
    beatsPerBar: beatsPerBar ?? this.beatsPerBar,
    volume: volume ?? this.volume,
    running: running ?? this.running,
  );
}

final metronomeProvider = NotifierProvider<MetronomeController, MetronomeState>(
  MetronomeController.new,
);

/// Beat-in-bar of the click just heard; drives the beat indicator.
final metronomeBeatProvider = StreamProvider<int>(
  (ref) => ref.watch(practiceAudioProvider).beats,
);

class MetronomeController extends Notifier<MetronomeState> {
  static const bpmKey = 'metronomeBpm';
  static const beatsKey = 'metronomeBeats';
  static const volumeKey = 'metronomeVolume';
  static const keys = {bpmKey, beatsKey, volumeKey};

  final _tapTempo = TapTempo();
  final _clock = Stopwatch()..start();

  @override
  MetronomeState build() {
    final store = ref.read(keyValueStoreProvider);
    const defaults = MetronomeState();
    final bpm = store.getInt(bpmKey);
    final beats = store.getInt(beatsKey);
    final volume = store.getDouble(volumeKey);
    final initial = MetronomeState(
      bpm:
          bpm != null &&
              bpm >= MetronomeVoice.minBpm &&
              bpm <= MetronomeVoice.maxBpm
          ? bpm
          : defaults.bpm,
      beatsPerBar:
          beats != null && beats >= 1 && beats <= MetronomeVoice.maxBeatsPerBar
          ? beats
          : defaults.beatsPerBar,
      volume: volume != null && volume >= 0 && volume <= 1
          ? volume
          : defaults.volume,
    );
    final voice = ref.read(practiceAudioProvider).engine.metronome;
    ref.onDispose(voice.stop);
    _apply(initial);
    return initial;
  }

  void toggle() {
    final running = !state.running;
    state = state.copyWith(running: running);
    final audio = ref.read(practiceAudioProvider);
    if (running) {
      audio.engine.metronome.start();
      audio.ensureRunning();
    } else {
      audio.engine.metronome.stop();
    }
  }

  void setBpm(int bpm) {
    final clamped = bpm.clamp(MetronomeVoice.minBpm, MetronomeVoice.maxBpm);
    state = state.copyWith(bpm: clamped);
    _apply(state);
    ref.read(keyValueStoreProvider).setInt(bpmKey, clamped);
  }

  void tap() {
    final bpm = _tapTempo.tap(_clock.elapsed);
    if (bpm != null) setBpm(bpm);
  }

  void setBeatsPerBar(int beats) {
    final clamped = beats.clamp(1, MetronomeVoice.maxBeatsPerBar);
    state = state.copyWith(beatsPerBar: clamped);
    _apply(state);
    ref.read(keyValueStoreProvider).setInt(beatsKey, clamped);
  }

  void setVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
    _apply(state);
    ref.read(keyValueStoreProvider).setDouble(volumeKey, state.volume);
  }

  void _apply(MetronomeState s) {
    final voice = ref.read(practiceAudioProvider).engine.metronome;
    voice.bpm = s.bpm;
    if (voice.beatsPerBar != s.beatsPerBar) voice.beatsPerBar = s.beatsPerBar;
    voice.volume = s.volume;
  }
}
