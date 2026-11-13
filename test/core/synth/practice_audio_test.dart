import 'package:brass_tunner/core/audio/practice_audio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers.dart';

void main() {
  late FakePcmSink sink;
  late PracticeAudio audio;

  setUp(() {
    sink = FakePcmSink();
    audio = PracticeAudio(sink: sink);
  });
  tearDown(() => audio.dispose());

  test('stays idle until a voice is enabled', () {
    expect(sink.setups, 0);
    expect(audio.isActive, isFalse);
  });

  test(
    'starts with a double chunk, then feeds one chunk per callback',
    () async {
      audio.engine.drone.playing = true;
      await audio.ensureRunning();
      expect(sink.setups, 1);
      expect(sink.fed.single.length, PracticeAudio.chunkFrames * 2);

      sink.callback!(1500);
      expect(sink.fed.last.length, PracticeAudio.chunkFrames);
    },
  );

  test('ensureRunning twice sets up once', () async {
    audio.engine.drone.playing = true;
    await Future.wait([audio.ensureRunning(), audio.ensureRunning()]);
    expect(sink.setups, 1);
  });

  test('after stopping, drains and then releases the device', () async {
    audio.engine.drone.playing = true;
    await audio.ensureRunning();
    audio.engine.drone.playing = false;

    // Keep feeding the fade-out until the engine is silent.
    var guard = 0;
    while (!audio.engine.isSilent && guard++ < 100) {
      sink.callback!(1000);
    }
    final fedBefore = sink.fed.length;
    sink.callback!(1000); // silent but audio still queued: wait
    expect(sink.fed.length, fedBefore);
    expect(sink.releases, 0);

    sink.callback!(0); // drained
    expect(sink.releases, 1);
    expect(audio.isActive, isFalse);
  });

  test('restarts after a release', () async {
    audio.engine.drone.playing = true;
    await audio.ensureRunning();
    audio.engine.drone.playing = false;
    while (!audio.engine.isSilent) {
      sink.callback!(1000);
    }
    sink.callback!(0);

    audio.engine.drone.playing = true;
    await audio.ensureRunning();
    expect(sink.setups, 2);
  });

  test('emits metronome beats', () async {
    final beats = <int>[];
    audio.beats.listen(beats.add);
    audio.engine.metronome
      ..beatsPerBar = 4
      ..start();
    await audio.ensureRunning();
    // First beat is at frame 0 of the first block, i.e. immediately.
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(beats, [0]);
  });
}
