import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pitch/note_mapper.dart';
import '../../../core/synth/oscillator.dart';
import '../../../shared/audio/practice_audio_provider.dart';
import '../../settings/application/settings_controller.dart';

class DroneState {
  const DroneState({
    this.midi = 58, // concert B♭3, the usual band tuning note
    this.waveform = Waveform.sine,
    this.volume = 0.6,
    this.playing = false,
  });

  /// Lowest and highest selectable octave (concert pitch).
  static const int minOctave = 1;
  static const int maxOctave = 5;

  final int midi;
  final Waveform waveform;
  final double volume;
  final bool playing;

  Note get note => Note(midi);

  DroneState copyWith({
    int? midi,
    Waveform? waveform,
    double? volume,
    bool? playing,
  }) => DroneState(
    midi: midi ?? this.midi,
    waveform: waveform ?? this.waveform,
    volume: volume ?? this.volume,
    playing: playing ?? this.playing,
  );
}

final droneProvider = NotifierProvider<DroneController, DroneState>(
  DroneController.new,
);

class DroneController extends Notifier<DroneState> {
  static const midiKey = 'droneMidi';
  static const waveformKey = 'droneWaveform';
  static const volumeKey = 'droneVolume';
  static const keys = {midiKey, waveformKey, volumeKey};

  @override
  DroneState build() {
    final store = ref.read(keyValueStoreProvider);
    const defaults = DroneState();
    final midi = store.getInt(midiKey);
    final volume = store.getDouble(volumeKey);
    final initial = DroneState(
      midi: midi != null && _validMidi(midi) ? midi : defaults.midi,
      waveform:
          Waveform.values.asNameMap()[store.getString(waveformKey)] ??
          defaults.waveform,
      volume: volume != null && volume >= 0 && volume <= 1
          ? volume
          : defaults.volume,
    );
    ref.listen(settingsProvider.select((s) => s.a4), (_, _) => _apply(state));
    final voice = ref.read(practiceAudioProvider).engine.drone;
    ref.onDispose(() => voice.playing = false);
    _apply(initial);
    return initial;
  }

  void toggle() => _update(state.copyWith(playing: !state.playing));

  void stop() => _update(state.copyWith(playing: false));

  /// Keeps the octave, changes the note name (0 = C … 11 = B).
  void setPitchClass(int pitchClass) {
    final octaveStart = (state.midi ~/ 12) * 12;
    _update(state.copyWith(midi: octaveStart + pitchClass % 12));
    ref.read(keyValueStoreProvider).setInt(midiKey, state.midi);
  }

  void setOctave(int octave) {
    final clamped = octave.clamp(DroneState.minOctave, DroneState.maxOctave);
    _update(state.copyWith(midi: (clamped + 1) * 12 + state.midi % 12));
    ref.read(keyValueStoreProvider).setInt(midiKey, state.midi);
  }

  /// Sets the concert note, clamped to the selectable octaves.
  void setMidi(int midi) {
    final clamped = midi.clamp(
      (DroneState.minOctave + 1) * 12,
      (DroneState.maxOctave + 2) * 12 - 1,
    );
    _update(state.copyWith(midi: clamped));
    ref.read(keyValueStoreProvider).setInt(midiKey, state.midi);
  }

  void setWaveform(Waveform waveform) {
    _update(state.copyWith(waveform: waveform));
    ref.read(keyValueStoreProvider).setString(waveformKey, waveform.name);
  }

  void setVolume(double volume) {
    _update(state.copyWith(volume: volume.clamp(0.0, 1.0)));
    ref.read(keyValueStoreProvider).setDouble(volumeKey, state.volume);
  }

  /// Exact frequency of the current drone note at the current A4.
  double get frequency =>
      NoteMapper(a4: ref.read(settingsProvider).a4).frequencyOf(state.note);

  void _update(DroneState next) {
    state = next;
    _apply(next);
  }

  void _apply(DroneState s) {
    final audio = ref.read(practiceAudioProvider);
    final voice = audio.engine.drone
      ..frequency = NoteMapper(a4: ref.read(settingsProvider).a4)
          .frequencyOf(s.note)
      ..waveform = s.waveform
      ..volume = s.volume
      ..playing = s.playing;
    if (voice.playing) audio.ensureRunning();
  }

  static bool _validMidi(int midi) =>
      midi >= (DroneState.minOctave + 1) * 12 &&
      midi < (DroneState.maxOctave + 2) * 12;
}
