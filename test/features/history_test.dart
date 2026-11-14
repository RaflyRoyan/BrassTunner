import 'dart:math' as math;

import 'package:brass_tunner/core/pitch/note_mapper.dart';
import 'package:brass_tunner/features/history/data/session_repository.dart';
import 'package:brass_tunner/features/history/domain/practice_session.dart';
import 'package:brass_tunner/features/history/domain/practice_stats.dart';
import 'package:brass_tunner/features/history/domain/session_recorder.dart';
import 'package:brass_tunner/features/tuner/domain/instrument.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers.dart';

final t0 = DateTime(2026, 11, 13, 9);

double hzOf(int midi, [double cents = 0]) =>
    NoteMapper().frequencyOf(Note(midi)) * math.pow(2, cents / 1200);

/// Plays [midi] at [cents] for [seconds] in 23 ms frames from [start];
/// returns the time after the last frame.
DateTime play(
  SessionRecorder r,
  DateTime start,
  int midi, {
  double cents = 0,
  double seconds = 6,
}) {
  var time = start;
  final end = start.add(Duration(milliseconds: (seconds * 1000).round()));
  while (time.isBefore(end)) {
    r.add(time, readingAt(hzOf(midi, cents)));
    time = time.add(const Duration(milliseconds: 23));
  }
  return time;
}

NoteStat stat(
  int midi, {
  int samples = 100,
  double mean = 0,
  int sharp = 0,
  int flat = 0,
}) => NoteStat(
  midi: midi,
  samples: samples,
  meanCents: mean,
  sharp: sharp,
  flat: flat,
);

PracticeSession session(
  List<NoteStat> notes, {
  DateTime? at,
  Instrument instrument = Instrument.trumpet,
  Duration duration = const Duration(minutes: 1),
}) => PracticeSession(
  startedAt: at ?? t0,
  duration: duration,
  instrument: instrument,
  a4: 440,
  notes: notes,
);

void main() {
  group('SessionRecorder', () {
    SessionRecorder recorder() =>
        SessionRecorder(instrument: Instrument.trumpet, a4: 442);

    test('records per-note averages and sharp/flat counts', () {
      final r = recorder();
      var time = play(r, t0, 58, cents: 12); // B♭3, sharp
      time = play(r, time, 65, cents: -8); // F4, flat
      final s = r.finish()!;
      expect(s.instrument, Instrument.trumpet);
      expect(s.a4, 442);
      expect(
        s.startedAt.difference(t0).inMilliseconds,
        inInclusiveRange(150, 200),
      );
      expect(s.duration.inSeconds, closeTo(12, 1));
      expect(s.notes.map((n) => n.midi), [58, 65]);
      expect(s.notes[0].meanCents, closeTo(12, 0.5));
      expect(s.notes[0].sharpRatio, 1);
      expect(s.notes[1].flatRatio, 1);
      expect(s.meanAbsCents, closeTo(10, 0.5));
    });

    test('skips the attack of each note', () {
      final r = recorder();
      // 100 ms of a wrong note, then the real one.
      var time = play(r, t0, 60, seconds: 0.1);
      play(r, time, 58, seconds: 11);
      expect(r.finish()!.notes.map((n) => n.midi), [58]);
    });

    test('drops sessions shorter than 10 s of playing', () {
      final r = recorder();
      play(r, t0, 58, seconds: 5);
      expect(r.finish(), isNull);
      expect(r.isRecording, isFalse);
    });

    test('a long silence closes the session', () {
      final r = recorder();
      play(r, t0, 58, seconds: 11);
      final later = t0.add(const Duration(minutes: 5));
      final closed = r.add(later, readingAt(hzOf(58)));
      expect(closed, isNotNull);
      expect(closed!.duration.inSeconds, closeTo(11, 1));
      expect(r.isRecording, isFalse); // new note still settling
    });
  });

  group('PracticeStats', () {
    test('merges notes across sessions, weighted by samples', () {
      final stats = PracticeStats([
        session([stat(58, samples: 100, mean: 10, sharp: 80)]),
        session([stat(58, samples: 300, mean: 2, sharp: 60)]),
      ]);
      expect(stats.sessionCount, 2);
      expect(stats.totalDuration, const Duration(minutes: 2));
      expect(stats.notes.single.samples, 400);
      expect(stats.notes.single.meanCents, closeTo(4, 1e-9));
      expect(stats.notes.single.sharpRatio, closeTo(0.35, 1e-9));
    });

    test('ranks notes most often sharp and flat', () {
      final stats = PracticeStats([
        session([
          stat(60, mean: 20, sharp: 90, flat: 2),
          stat(62, mean: 8, sharp: 50, flat: 10),
          stat(64, mean: -15, sharp: 0, flat: 70),
          stat(65, mean: -3, sharp: 5, flat: 30),
          stat(67, samples: 20, mean: 40, sharp: 20), // too little data
        ]),
      ]);
      expect(stats.mostSharp().map((n) => n.midi), [60, 62]);
      expect(stats.mostFlat().map((n) => n.midi), [64, 65]);
      expect(stats.mostSharp(1).map((n) => n.midi), [60]);
    });

    test('rarely or barely off notes are not ranked', () {
      final stats = PracticeStats([
        session([
          stat(60, mean: -1, sharp: 10, flat: 5), // 10% sharp, flat on avg
          stat(62, mean: 3, sharp: 15, flat: 2), // only 15% sharp
          stat(64, mean: -6, sharp: 0, flat: 25),
        ]),
      ]);
      expect(stats.mostSharp(), isEmpty);
      expect(stats.mostFlat().map((n) => n.midi), [64]);
    });
  });

  group('SqliteSessionRepository', () {
    late SqliteSessionRepository repo;

    setUpAll(sqfliteFfiInit);
    setUp(() async {
      repo = await SqliteSessionRepository.open(
        factory: databaseFactoryFfi,
        path: inMemoryDatabasePath,
      );
    });
    tearDown(() => repo.close());

    test('round-trips sessions with their notes, newest first', () async {
      final a = await repo.insert(
        session([stat(58, mean: 4.5, sharp: 30, flat: 2), stat(65, mean: -7)]),
      );
      final b = await repo.insert(
        session(
          [stat(46)],
          at: t0.add(const Duration(days: 1)),
          instrument: Instrument.tuba,
        ),
      );
      expect(a.id, isNotNull);
      final all = await repo.list();
      expect(all.map((s) => s.id), [b.id, a.id]);
      final first = all.last;
      expect(first.startedAt, t0);
      expect(first.duration, const Duration(minutes: 1));
      expect(first.notes.map((n) => n.midi), [58, 65]);
      expect(first.notes[0].meanCents, 4.5);
      expect(first.notes[0].sharp, 30);

      final tuba = await repo.list(instrument: Instrument.tuba);
      expect(tuba.single.notes.single.midi, 46);
    });

    test('delete removes the session and its notes; clear empties', () async {
      final a = await repo.insert(session([stat(58)]));
      await repo.insert(session([stat(60)]));
      await repo.delete(a.id!);
      expect((await repo.list()).single.notes.single.midi, 60);
      await repo.clear();
      expect(await repo.list(), isEmpty);
    });
  });

  test('MemorySessionRepository mirrors the SQLite behaviour', () async {
    final repo = MemorySessionRepository();
    final a = await repo.insert(session([stat(58)]));
    await repo.insert(
      session([stat(60)], at: t0.add(const Duration(hours: 1))),
    );
    expect((await repo.list()).first.notes.single.midi, 60);
    await repo.delete(a.id!);
    expect(await repo.list(), hasLength(1));
  });
}
