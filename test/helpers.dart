import 'dart:typed_data';

import 'package:brass_tunner/app.dart';
import 'package:brass_tunner/core/audio/practice_audio.dart';
import 'package:brass_tunner/core/pitch/note_mapper.dart';
import 'package:brass_tunner/core/pitch/pitch_result.dart';
import 'package:brass_tunner/core/pitch/pitch_tracker.dart';
import 'package:brass_tunner/features/history/application/history_controller.dart';
import 'package:brass_tunner/features/history/data/session_repository.dart';
import 'package:brass_tunner/features/settings/application/settings_controller.dart';
import 'package:brass_tunner/features/settings/data/key_value_store.dart';
import 'package:brass_tunner/features/tuner/application/tuner_controller.dart';
import 'package:brass_tunner/shared/audio/practice_audio_provider.dart';
import 'package:brass_tunner/shared/platform/screen_wake_lock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class InMemoryStore implements KeyValueStore {
  InMemoryStore([Map<String, Object>? initial]) : values = {...?initial};

  final Map<String, Object> values;

  @override
  double? getDouble(String key) => values[key] as double?;

  @override
  int? getInt(String key) => values[key] as int?;

  @override
  String? getString(String key) => values[key] as String?;

  @override
  Future<void> setDouble(String key, double value) async => values[key] = value;

  @override
  Future<void> setInt(String key, int value) async => values[key] = value;

  @override
  Future<void> setString(String key, String value) async => values[key] = value;
}

/// Tuner controller with no mic access. [emit] pushes readings as if they
/// came from the DSP isolate.
class FakeTunerController extends TunerController {
  FakeTunerController(this.initial);

  final TunerState initial;
  int starts = 0;
  int stops = 0;

  @override
  TunerState build() => initial;

  @override
  Future<void> start() async => starts++;

  @override
  Future<void> stop() async => stops++;

  void emit(TunerReading? reading) =>
      state = TunerState(TunerStatus.listening, reading);
}

/// Records what PracticeAudio sends to the speaker.
class FakePcmSink implements PcmSink {
  int setups = 0;
  int releases = 0;
  final List<Int16List> fed = [];
  void Function(int remainingFrames)? callback;

  int get framesFed => fed.fold(0, (sum, b) => sum + b.length);

  @override
  Future<void> setup(int sampleRate) async => setups++;

  @override
  void setFeedCallback(void Function(int remainingFrames) callback) =>
      this.callback = callback;

  @override
  Future<void> feed(Int16List samples) async => fed.add(samples);

  @override
  Future<void> release() async => releases++;
}

/// A reading of [frequency] at A4 = 440.
TunerReading readingAt(double frequency) => TunerReading(
  note: NoteMapper().fromFrequency(frequency),
  rawFrequency: frequency,
  clarity: 0.99,
  levelDb: -20,
  algorithm: PitchAlgorithm.mpm,
);

class FakeWakeLock implements ScreenWakeLock {
  bool enabled = false;

  @override
  Future<void> setEnabled(bool enabled) async => this.enabled = enabled;
}

/// Manually advanced wall clock for session recording.
class FakeClock {
  FakeClock([DateTime? start]) : now = start ?? DateTime(2026, 11, 13, 9);

  DateTime now;

  void advance(Duration d) => now = now.add(d);
}

class TestApp {
  TestApp(this.store, this.sink, this.sessions, this.clock, this.wakeLock);

  final FakeWakeLock wakeLock;
  final InMemoryStore store;
  final FakePcmSink sink;
  final SessionRepository sessions;
  final FakeClock clock;
}

Future<TestApp> pumpApp(
  WidgetTester tester, {
  TunerState tuner = TunerState.idle,
  Map<String, Object>? stored,
  SessionRepository? sessions,
  List<String>? fontFamilyFallback,
}) async {
  final store = InMemoryStore(stored);
  final sink = FakePcmSink();
  final repository = sessions ?? MemorySessionRepository();
  final clock = FakeClock();
  final wakeLock = FakeWakeLock();
  await tester.pumpWidget(
    ProviderScope(
      // Fresh scope per pump, so one test can pump several states.
      key: UniqueKey(),
      overrides: [
        keyValueStoreProvider.overrideWithValue(store),
        sessionRepositoryProvider.overrideWithValue(repository),
        clockProvider.overrideWithValue(() => clock.now),
        screenWakeLockProvider.overrideWithValue(wakeLock),
        tunerControllerProvider.overrideWith(() => FakeTunerController(tuner)),
        practiceAudioProvider.overrideWith((ref) {
          final audio = PracticeAudio(sink: sink);
          ref.onDispose(audio.dispose);
          return audio;
        }),
      ],
      child: BrassTunerApp(fontFamilyFallback: fontFamilyFallback),
    ),
  );
  await tester.pumpAndSettle();
  return TestApp(store, sink, repository, clock, wakeLock);
}
