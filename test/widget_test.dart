import 'dart:math' as math;

import 'package:brass_tunner/features/tuner/application/tuner_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers.dart';

/// [hz] raised by [cents].
double plusCents(double hz, double cents) => hz * math.pow(2, cents / 1200);

String noteText(WidgetTester tester) => tester
    .widget<Text>(find.byKey(const Key('noteName')))
    .textSpan!
    .toPlainText();

void main() {
  testWidgets('waiting state asks the player to play', (tester) async {
    await pumpApp(tester, tuner: const TunerState(TunerStatus.listening));
    expect(find.text('Mainkan sebuah nada'), findsOneWidget);
    expect(find.text('A4 = 440 Hz'), findsOneWidget);
    expect(find.text('Trumpet (B♭)'), findsOneWidget);
  });

  testWidgets('trumpet shows written C4 for concert B♭3', (tester) async {
    await pumpApp(
      tester,
      tuner: TunerState(TunerStatus.listening, readingAt(plusCents(233.08, 3))),
    );
    expect(noteText(tester), 'C4');
    expect(find.text('Tertulis (B♭)'), findsOneWidget);
    expect(find.text('Concert B♭3'), findsOneWidget);
    expect(find.text('+3¢'), findsOneWidget);
    expect(find.text('233,5 Hz'), findsOneWidget); // Indonesian decimal comma
  });

  testWidgets('tuba shows the concert note only', (tester) async {
    await pumpApp(
      tester,
      stored: {'instrument': 'tuba'},
      tuner: TunerState(
        TunerStatus.listening,
        readingAt(plusCents(58.27, -20)),
      ),
    );
    expect(noteText(tester), 'B♭1');
    expect(find.textContaining('Concert'), findsNothing);
    expect(find.text('−20¢'), findsOneWidget);
  });

  testWidgets('cents colour follows the tuning zones', (tester) async {
    Color centsColor() =>
        tester.widget<Text>(find.byKey(const Key('cents'))).style!.color!;

    await pumpApp(
      tester,
      tuner: TunerState(TunerStatus.listening, readingAt(plusCents(440, 4))),
    );
    final green = centsColor();
    await pumpApp(
      tester,
      tuner: TunerState(TunerStatus.listening, readingAt(plusCents(440, 12))),
    );
    final yellow = centsColor();
    await pumpApp(
      tester,
      tuner: TunerState(TunerStatus.listening, readingAt(plusCents(440, 30))),
    );
    final red = centsColor();
    expect({green, yellow, red}.length, 3);
  });

  testWidgets('choosing an instrument from the chip saves it', (tester) async {
    final store = (await pumpApp(
      tester,
      tuner: const TunerState(TunerStatus.listening),
    )).store;
    await tester.tap(find.text('Trumpet (B♭)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Alto horn'));
    await tester.pumpAndSettle();
    expect(find.text('Alto horn (E♭)'), findsOneWidget);
    expect(store.values['instrument'], 'altoHorn');
  });

  testWidgets('permission denied shows a retry button', (tester) async {
    await pumpApp(
      tester,
      tuner: const TunerState(TunerStatus.permissionDenied),
    );
    expect(find.text('Izin mikrofon ditolak'), findsOneWidget);
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('settings: A4 buttons change and persist the value', (
    tester,
  ) async {
    final store = (await pumpApp(
      tester,
      tuner: const TunerState(TunerStatus.listening),
    )).store;
    await tester.tap(find.text('A4 = 440 Hz'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Naikkan A4'));
    await tester.pump();
    await tester.tap(find.byTooltip('Naikkan A4'));
    await tester.pumpAndSettle();
    expect(find.text('442 Hz'), findsOneWidget);
    expect(store.values['a4'], 442.0);

    await tester.tap(find.text('Kembalikan ke 440 Hz'));
    await tester.pumpAndSettle();
    expect(store.values['a4'], 440.0);
  });
}
