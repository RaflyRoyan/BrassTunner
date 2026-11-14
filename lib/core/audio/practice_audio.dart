import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

import '../synth/metronome_voice.dart';
import '../synth/synth_engine.dart';

/// Speaker output that pulls PCM through a feed callback.
abstract interface class PcmSink {
  Future<void> setup(int sampleRate);
  void setFeedCallback(void Function(int remainingFrames) callback);
  Future<void> feed(Int16List samples);
  Future<void> release();
}

class FlutterPcmSink implements PcmSink {
  @override
  Future<void> setup(int sampleRate) async {
    await FlutterPcmSound.setLogLevel(LogLevel.error);
    await FlutterPcmSound.setup(
      sampleRate: sampleRate,
      channelCount: 1,
      // `playback` (the default) would disable the mic on iOS while the
      // drone or metronome runs next to the tuner.
      iosAudioCategory: IosAudioCategory.playAndRecord,
    );
    await FlutterPcmSound.setFeedThreshold(PracticeAudio.chunkFrames);
  }

  @override
  void setFeedCallback(void Function(int remainingFrames) callback) =>
      FlutterPcmSound.setFeedCallback(callback);

  @override
  Future<void> feed(Int16List samples) => FlutterPcmSound.feed(
    // Int16List uses host byte order, which is what the plugin expects.
    PcmArrayInt16(bytes: samples.buffer.asByteData()),
  );

  @override
  Future<void> release() => FlutterPcmSound.release();
}

/// Drives the speaker for the drone and metronome. Starts on demand and
/// releases the audio device once everything has faded out.
class PracticeAudio {
  PracticeAudio({PcmSink? sink, this.sampleRate = 44100})
    : _sink = sink ?? FlutterPcmSink(),
      engine = SynthEngine(sampleRate: sampleRate.toDouble());

  /// Frames per feed (~46 ms): small enough for responsive controls, large
  /// enough to ride out UI-thread hiccups.
  static const int chunkFrames = 2048;

  final int sampleRate;
  final SynthEngine engine;
  final PcmSink _sink;

  final _beats = StreamController<BeatEvent>.broadcast();
  final _beatTimers = <Timer>{};

  bool _active = false;
  Future<void>? _starting;

  /// Each click (beat in bar and bar count), emitted roughly when heard.
  Stream<BeatEvent> get beats => _beats.stream;

  bool get isActive => _active;

  /// Starts output if it is not running. Call after enabling a voice.
  Future<void> ensureRunning() {
    if (_active) return Future.value();
    return _starting ??= _start().whenComplete(() => _starting = null);
  }

  Future<void> _start() async {
    await _sink.setup(sampleRate);
    _sink.setFeedCallback(_onFeed);
    _active = true;
    _onFeed(0);
  }

  void _onFeed(int remainingFrames) {
    if (!_active) return;
    if (engine.isSilent) {
      // Let queued audio (the fade-out tail) finish, then free the device.
      if (remainingFrames == 0) {
        _active = false;
        _sink.release();
      }
      return;
    }
    // After an underrun, refill with extra margin.
    final frames = remainingFrames == 0 ? chunkFrames * 2 : chunkFrames;
    final result = engine.render(frames);
    _sink.feed(result.samples);
    for (final beat in result.beats) {
      final delay = Duration(
        microseconds:
            (remainingFrames + beat.frameOffset) * 1000000 ~/ sampleRate,
      );
      late final Timer timer;
      timer = Timer(delay, () {
        _beatTimers.remove(timer);
        if (!_beats.isClosed) _beats.add(beat);
      });
      _beatTimers.add(timer);
    }
  }

  Future<void> dispose() async {
    for (final t in _beatTimers) {
      t.cancel();
    }
    _beatTimers.clear();
    await _beats.close();
    if (_active) {
      _active = false;
      await _sink.release();
    }
  }
}
