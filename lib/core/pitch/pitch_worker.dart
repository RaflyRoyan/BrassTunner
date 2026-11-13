import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';

import '../audio/pcm_convert.dart';
import '../audio/sliding_window.dart';
import 'note_mapper.dart';
import 'pitch_detector.dart';
import 'pitch_tracker.dart';

/// Runs the whole DSP chain (PCM decode → sliding window → [PitchTracker])
/// in a background isolate so the UI thread only receives finished readings.
class PitchWorker {
  PitchWorker._(this._isolate, this._commands, this._results, this.readings);

  final Isolate _isolate;
  final SendPort _commands;
  final ReceivePort _results;

  /// One event per analysis hop with a pitch; `null` once when the pitch is
  /// lost.
  final Stream<TunerReading?> readings;

  static Future<PitchWorker> spawn({
    double sampleRate = 44100,
    double a4 = 440,
    int windowSize = 4096,
    int hopSize = 1024,
  }) async {
    final results = ReceivePort();
    final isolate = await Isolate.spawn(
      _main,
      _Init(results.sendPort, sampleRate, a4, windowSize, hopSize),
      debugName: 'PitchWorker',
    );
    final events = results.asBroadcastStream();
    final commands = await events.first as SendPort;
    final readings = events
        .where((e) => e is TunerReading || e == null)
        .cast<TunerReading?>();
    return PitchWorker._(isolate, commands, results, readings);
  }

  /// Raw mono PCM16 little-endian bytes from the mic.
  void addPcm16(Uint8List bytes) => _commands.send(bytes);

  void setA4(double a4) => _commands.send(_SetA4(a4));

  /// Drops buffered audio and smoothing state (e.g. after the mic restarts).
  void reset() => _commands.send(const _Reset());

  void dispose() {
    _commands.send(const _Shutdown());
    _results.close();
    _isolate.kill(priority: Isolate.beforeNextEvent);
  }

  static void _main(_Init init) {
    final commands = ReceivePort();
    init.results.send(commands.sendPort);

    final decoder = Pcm16Decoder();
    final window = SlidingWindow(
      windowSize: init.windowSize,
      hopSize: init.hopSize,
    );
    final tracker = PitchTracker(
      detector: PitchDetector(
        sampleRate: init.sampleRate,
        windowSize: init.windowSize,
      ),
      mapper: NoteMapper(a4: init.a4),
    );
    var lastWasNull = true;

    void onWindow(Float32List frame) {
      final reading = tracker.process(frame);
      // Skip repeated nulls: silence would otherwise spam the UI isolate.
      if (reading == null && lastWasNull) return;
      lastWasNull = reading == null;
      init.results.send(reading);
    }

    commands.listen((message) {
      switch (message) {
        case Uint8List bytes:
          window.add(decoder.convert(bytes), onWindow);
        case _SetA4(:final a4):
          tracker.mapper = tracker.mapper.copyWith(a4: a4);
        case _Reset():
          decoder.reset();
          window.reset();
          tracker.reset();
          if (!lastWasNull) init.results.send(null);
          lastWasNull = true;
        case _Shutdown():
          commands.close();
      }
    });
  }
}

class _Init {
  const _Init(
    this.results,
    this.sampleRate,
    this.a4,
    this.windowSize,
    this.hopSize,
  );

  final SendPort results;
  final double sampleRate;
  final double a4;
  final int windowSize;
  final int hopSize;
}

class _SetA4 {
  const _SetA4(this.a4);
  final double a4;
}

class _Reset {
  const _Reset();
}

class _Shutdown {
  const _Shutdown();
}
