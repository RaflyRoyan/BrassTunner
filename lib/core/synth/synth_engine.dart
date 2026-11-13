import 'dart:typed_data';

import 'drone_voice.dart';
import 'metronome_voice.dart';

class RenderResult {
  const RenderResult(this.samples, this.beats);

  /// Mono 16-bit samples.
  final Int16List samples;
  final List<BeatEvent> beats;
}

/// Mixes the drone and the metronome into one mono stream.
class SynthEngine {
  SynthEngine({this.sampleRate = 44100})
    : drone = DroneVoice(sampleRate),
      metronome = MetronomeVoice(sampleRate);

  final double sampleRate;
  final DroneVoice drone;
  final MetronomeVoice metronome;

  bool get isSilent => drone.isSilent && metronome.isSilent;

  RenderResult render(int frames) {
    final mix = Float32List(frames);
    final beats = <BeatEvent>[];
    drone.addTo(mix);
    metronome.addTo(mix, beats);
    final out = Int16List(frames);
    for (var i = 0; i < frames; i++) {
      out[i] = (mix[i].clamp(-1.0, 1.0) * 32767).round();
    }
    return RenderResult(out, beats);
  }
}
