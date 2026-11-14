import 'package:brass_tunner/core/pitch/note_mapper.dart';
import 'package:brass_tunner/features/history/data/session_repository.dart';
import 'package:brass_tunner/features/history/domain/practice_session.dart';
import 'package:brass_tunner/features/tuner/application/tuner_controller.dart';
import 'package:brass_tunner/features/tuner/domain/instrument.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers.dart';

FakeTunerController fakeTuner(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(NavigationBar)))
            .read(tunerControllerProvider.notifier)
        as FakeTunerController;

double hz(int midi) => NoteMapper().frequencyOf(Note(midi)) * 1.006; // +10¢

Future<void> openHistory(WidgetTester tester) async {
  await tester.tap(find.byTooltip('Riwayat & statistik'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('empty history explains how sessions are saved', (tester) async {
    await pumpApp(tester, tuner: const TunerState(TunerStatus.listening));
    await openHistory(tester);
    expect(find.textContaining('Belum ada sesi latihan'), findsOneWidget);
  });

  testWidgets('playing then leaving the tuner saves a session', (tester) async {
    final app = await pumpApp(
      tester,
      tuner: const TunerState(TunerStatus.listening),
    );
    final tuner = fakeTuner(tester);
    // 12 s of concert B♭3 (written C4), 10¢ sharp.
    for (var i = 0; i < 520; i++) {
      tuner.emit(readingAt(hz(58)));
      app.clock.advance(const Duration(milliseconds: 23));
    }
    tuner.state = TunerState.idle; // mic stops, e.g. drone tab
    await tester.pumpAndSettle();

    final saved = await app.sessions.list();
    expect(saved, hasLength(1));
    expect(saved.single.notes.single.midi, 58);
    expect(saved.single.notes.single.meanCents, closeTo(10, 0.5));

    await openHistory(tester);
    expect(find.text('Sesi'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('mostSharp')),
        matching: find.text('C4'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('100% sharp'), findsOneWidget);
  });

  testWidgets('history filters by instrument and deletes sessions', (
    tester,
  ) async {
    final repo = MemorySessionRepository();
    for (final instrument in [Instrument.trumpet, Instrument.tuba]) {
      await repo.insert(
        PracticeSession(
          startedAt: DateTime(2026, 11, 12, 18, 30),
          duration: const Duration(minutes: 3, seconds: 5),
          instrument: instrument,
          a4: 440,
          notes: const [
            NoteStat(
              midi: 62,
              samples: 200,
              meanCents: -12,
              sharp: 0,
              flat: 150,
            ),
          ],
        ),
      );
    }
    await pumpApp(
      tester,
      sessions: repo,
      tuner: const TunerState(TunerStatus.listening),
    );
    await openHistory(tester);
    // Trumpet: concert D4 is written E4.
    expect(
      find.descendant(
        of: find.byKey(const Key('mostFlat')),
        matching: find.text('E4'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('3 mnt 5 dtk'), findsWidgets);

    await tester.tap(find.byKey(const Key('historyInstrument')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tuba (concert)').last);
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byKey(const Key('mostFlat')),
        matching: find.text('D4'),
      ),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Hapus semua riwayat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(await repo.list(), isEmpty);
    expect(find.textContaining('Belum ada sesi latihan'), findsOneWidget);
  });
}
