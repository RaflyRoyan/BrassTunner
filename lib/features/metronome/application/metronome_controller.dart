import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/synth/metronome_voice.dart';
import '../../../core/synth/tap_tempo.dart';
import '../../../shared/audio/practice_audio_provider.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/bar_program.dart';

class MetronomeState {
  MetronomeState({
    this.bpm = 80,
    this.beatsPerBar = 4,
    this.volume = 0.8,
    this.running = false,
    this.multiBar = false,
    BarProgram? program,
  }) : program = program ?? BarProgram.example;

  final int bpm;

  /// Beats per bar in single-bar mode.
  final int beatsPerBar;
  final double volume;
  final bool running;

  /// Plays [program] (several time signatures in sequence) instead of
  /// repeating one bar of [beatsPerBar].
  final bool multiBar;
  final BarProgram program;

  MetronomeState copyWith({
    int? bpm,
    int? beatsPerBar,
    double? volume,
    bool? running,
    bool? multiBar,
    BarProgram? program,
  }) => MetronomeState(
    bpm: bpm ?? this.bpm,
    beatsPerBar: beatsPerBar ?? this.beatsPerBar,
    volume: volume ?? this.volume,
    running: running ?? this.running,
    multiBar: multiBar ?? this.multiBar,
    program: program ?? this.program,
  );
}

final metronomeProvider = NotifierProvider<MetronomeController, MetronomeState>(
  MetronomeController.new,
);

/// The click just heard; drives the beat and bar indicators.
final metronomeBeatProvider = StreamProvider<BeatEvent>(
  (ref) => ref.watch(practiceAudioProvider).beats,
);

class MetronomeController extends Notifier<MetronomeState> {
  static const bpmKey = 'metronomeBpm';
  static const beatsKey = 'metronomeBeats';
  static const volumeKey = 'metronomeVolume';
  static const multiBarKey = 'metronomeMultiBar';
  static const programKey = 'metronomeProgram';
  static const keys = {bpmKey, beatsKey, volumeKey, multiBarKey, programKey};

  final _tapTempo = TapTempo();
  final _clock = Stopwatch()..start();

  @override
  MetronomeState build() {
    final store = ref.read(keyValueStoreProvider);
    final defaults = MetronomeState();
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
      multiBar: store.getInt(multiBarKey) == 1,
      program: BarProgram.decode(store.getString(programKey)),
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
    _update(state.copyWith(bpm: clamped));
    ref.read(keyValueStoreProvider).setInt(bpmKey, clamped);
  }

  void tap() {
    final bpm = _tapTempo.tap(_clock.elapsed);
    if (bpm != null) setBpm(bpm);
  }

  void setBeatsPerBar(int beats) {
    final clamped = beats.clamp(1, MetronomeVoice.maxBeatsPerBar);
    _update(state.copyWith(beatsPerBar: clamped));
    ref.read(keyValueStoreProvider).setInt(beatsKey, clamped);
  }

  void setVolume(double volume) {
    _update(state.copyWith(volume: volume.clamp(0.0, 1.0)));
    ref.read(keyValueStoreProvider).setDouble(volumeKey, state.volume);
  }

  /// Switches between one repeating bar and the multi-bar program, without
  /// stopping the clicks.
  void setMultiBar(bool multiBar) {
    _update(state.copyWith(multiBar: multiBar));
    ref.read(keyValueStoreProvider).setInt(multiBarKey, multiBar ? 1 : 0);
  }

  void setProgram(BarProgram program) {
    _update(state.copyWith(program: program));
    ref.read(keyValueStoreProvider).setString(programKey, program.encode());
  }

  void updateSegment(int index, BarSegment segment) =>
      setProgram(state.program.replace(index, segment));

  void addSegment() => setProgram(state.program.add());

  void removeSegment(int index) => setProgram(state.program.removeAt(index));

  void _update(MetronomeState next) {
    state = next;
    _apply(next);
  }

  void _apply(MetronomeState s) {
    final voice = ref.read(practiceAudioProvider).engine.metronome;
    voice.bpm = s.bpm;
    voice.volume = s.volume;
    // Only touch the bar structure when it changes: doing so restarts the
    // bar count.
    final pattern = s.multiBar ? s.program.barBeats : null;
    if (!listEquals(voice.barPattern, pattern)) voice.barPattern = pattern;
    if (voice.beatsPerBar != s.beatsPerBar) voice.beatsPerBar = s.beatsPerBar;
  }
}
