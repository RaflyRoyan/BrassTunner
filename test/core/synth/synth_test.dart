import 'dart:math' as math;
import 'dart:typed_data';

import 'package:brass_tunner/core/pitch/pitch_detector.dart';
import 'package:brass_tunner/core/synth/metronome_voice.dart';
import 'package:brass_tunner/core/synth/oscillator.dart';
import 'package:brass_tunner/core/synth/synth_engine.dart';
import 'package:brass_tunner/core/synth/tap_tempo.dart';
import 'package:flutter_test/flutter_test.dart';

double cents(double measured, double expected) =>
    1200 * math.log(measured / expected) / math.ln2;

double peak(Int16List s) => s.fold(0, (m, v) => math.max(m, v.abs())) / 32767;

/// Renders [frames] and returns them as floats.
Float32List renderFloat(SynthEngine engine, int frames) => Float32List.fromList(
  [for (final s in engine.render(frames).samples) s / 32767],
);

void main() {
  group('drone', () {
    for (final waveform in Waveform.values) {
      for (final hz in [58.27, 233.08, 932.33]) {
        test('${waveform.name} at $hz Hz reads in tune on our own tuner', () {
          final engine = SynthEngine();
          engine.drone
            ..frequency = hz
            ..waveform = waveform
            ..playing = true;
          engine.render(4410); // let the fade-in settle
          final estimate = PitchDetector().detect(renderFloat(engine, 4096));
          expect(estimate, isNotNull);
          // The saw's residual aliasing slightly disturbs one 93 ms window;
          // the generator itself is exact (see the cycle-count test below).
          expect(cents(estimate!.frequency, hz).abs(), lessThan(2));
        });
      }
    }

    for (final waveform in Waveform.values) {
      test('${waveform.name} frequency is exact over 10 s', () {
        const hz = 932.33;
        final engine = SynthEngine();
        engine.drone
          ..frequency = hz
          ..waveform = waveform
          ..volume = 1
          ..playing = true;
        final s = engine.render(441000).samples;
        // Count rising zero crossings (sine) or falling resets (saw): one per
        // cycle.
        var cycles = 0;
        for (var i = 1; i < s.length; i++) {
          final crossed = waveform == Waveform.sine
              ? s[i - 1] < 0 && s[i] >= 0
              : s[i - 1] > 0 && s[i] <= 0 && s[i - 1] - s[i] > 1000;
          if (crossed) cycles++;
        }
        // ±1 cycle in 9323 is ±0.19 cents.
        expect(cycles, closeTo(hz * 10, 1));
      });
    }

    test('fades in and out without a jump', () {
      final engine = SynthEngine();
      engine.drone
        ..frequency = 440
        ..playing = true;
      final start = engine.render(64).samples;
      expect(start.first.abs(), lessThan(50), reason: 'starts near silence');

      engine.render(4410);
      engine.drone.playing = false;
      final tail = engine.render(64).samples;
      expect(peak(tail), greaterThan(0.1), reason: 'does not cut instantly');

      engine.render(44100);
      expect(engine.isSilent, isTrue);
      expect(peak(engine.render(1024).samples), 0);
    });

    test('volume scales the level', () {
      double levelAt(double volume) {
        final engine = SynthEngine();
        engine.drone
          ..frequency = 440
          ..volume = volume
          ..playing = true;
        engine.render(8820);
        return peak(engine.render(4096).samples);
      }

      expect(levelAt(0.25) / levelAt(1), closeTo(0.25, 0.01));
    });
  });

  group('metronome', () {
    List<(int, int)> collectBeats(
      SynthEngine engine,
      int totalFrames, {
      int block = 1000,
    }) {
      final beats = <(int, int)>[];
      for (var at = 0; at < totalFrames; at += block) {
        // Last block is partial so exactly totalFrames are rendered.
        final frames = math.min(block, totalFrames - at);
        for (final b in engine.render(frames).beats) {
          beats.add((at + b.frameOffset, b.beatInBar));
        }
      }
      return beats;
    }

    test('clicks are sample-accurate across render blocks', () {
      final engine = SynthEngine();
      engine.metronome
        ..bpm = 120
        ..start();
      final beats = collectBeats(engine, 44100 * 4);
      expect(beats.length, 8);
      for (var i = 0; i < beats.length; i++) {
        // 120 BPM at 44.1 kHz = 22050 frames per beat.
        expect(beats[i].$1, i * 22050);
      }
    });

    test('non-integer beat length does not drift', () {
      final engine = SynthEngine();
      engine.metronome
        ..bpm =
            97 // 27278.35... frames per beat
        ..start();
      final beats = collectBeats(engine, 44100 * 60, block: 777);
      expect(beats.length, 97);
      final expected = 96 * 44100 * 60 / 97;
      expect(beats.last.$1, closeTo(expected, 1));
    });

    test('accents the first beat of each bar', () {
      final engine = SynthEngine();
      engine.metronome
        ..beatsPerBar = 3
        ..start();
      final pattern = collectBeats(engine, 44100 * 5).map((b) => b.$2);
      expect(pattern.take(7), [0, 1, 2, 0, 1, 2, 0]);
    });

    test('tempo change keeps the last beat and applies the new spacing', () {
      final engine = SynthEngine();
      engine.metronome
        ..bpm = 60
        ..start();
      collectBeats(engine, 22050); // beat at 0, halfway to the next
      engine.metronome.bpm = 120;
      final beats = collectBeats(engine, 44100);
      // Next beat at 22050 (0 + new spacing), then every 22050.
      expect(beats.first.$1, 0);
      expect(beats.length, 2);
    });

    test('stop lets the last click ring out, then goes silent', () {
      final engine = SynthEngine();
      engine.metronome.start();
      engine.render(100);
      engine.metronome.stop();
      expect(engine.isSilent, isFalse);
      engine.render(44100 ~/ 20); // 50 ms > 30 ms click
      expect(engine.isSilent, isTrue);
    });

    test('bpm is clamped to the supported range', () {
      final voice = MetronomeVoice(44100)..bpm = 500;
      expect(voice.bpm, MetronomeVoice.maxBpm);
      voice.bpm = 5;
      expect(voice.bpm, MetronomeVoice.minBpm);
    });
  });

  test('drone and click mix without overflowing 16 bits', () {
    final engine = SynthEngine();
    engine.drone
      ..waveform = Waveform.saw
      ..volume = 1
      ..playing = true;
    engine.metronome
      ..volume = 1
      ..start();
    final samples = engine.render(44100).samples;
    expect(samples.every((s) => s.abs() <= 32767), isTrue);
  });

  group('TapTempo', () {
    Duration ms(int v) => Duration(milliseconds: v);

    test('averages the tap intervals', () {
      final tap = TapTempo();
      expect(tap.tap(ms(0)), isNull);
      expect(tap.tap(ms(500)), 120);
      expect(tap.tap(ms(1010)), 119); // avg 505 ms
    });

    test('a long pause starts over', () {
      final tap = TapTempo();
      tap.tap(ms(0));
      tap.tap(ms(1000));
      expect(tap.tap(ms(5000)), isNull);
      expect(tap.tap(ms(5250)), 240);
    });

    test('result is clamped', () {
      final tap = TapTempo();
      tap.tap(ms(0));
      expect(tap.tap(ms(100)), MetronomeVoice.maxBpm);
    });
  });
}
