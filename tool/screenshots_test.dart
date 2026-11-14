// Renders Play Store phone screenshots (1080×1920) with real fonts.
//
//   flutter test tool/screenshots_test.dart
//
// Output: store/screenshots/*.png
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:brass_tunner/core/pitch/note_mapper.dart';
import 'package:brass_tunner/features/history/data/session_repository.dart';
import 'package:brass_tunner/features/history/domain/practice_session.dart';
import 'package:brass_tunner/features/tuner/application/tuner_controller.dart';
import 'package:brass_tunner/features/tuner/domain/instrument.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test/helpers.dart';
import 'generate_brand_test.dart' as brand;

const physical = Size(1080, 1920);
const dpr = 2.625;

/// Provides ♭ and ♯, which Roboto lacks (phones fall back to Noto Symbols).
const symbolFont = 'Symbols';

Future<void> loadFonts() async {
  final root = Platform.environment['FLUTTER_ROOT']!;
  final dir = '$root/bin/cache/artifacts/material_fonts';
  Future<ByteData> read(String f) async =>
      ByteData.sublistView(await File('$dir/$f').readAsBytes());
  final roboto = FontLoader('Roboto');
  for (final f in [
    'roboto-regular.ttf',
    'roboto-medium.ttf',
    'roboto-bold.ttf',
    'roboto-light.ttf',
  ]) {
    roboto.addFont(read(f));
  }
  await roboto.load();
  // Windows ships ♭ ♯ ♩ ▲ ▼ in Segoe UI Symbol.
  final symbols = File(r'C:\Windows\Fonts\seguisym.ttf');
  if (symbols.existsSync()) {
    await (FontLoader(symbolFont)..addFont(
          Future.value(ByteData.sublistView(symbols.readAsBytesSync())),
        ))
        .load();
  }
  await (FontLoader(
    'MaterialIcons',
  )..addFont(read('materialicons-regular.otf'))).load();
}

Future<void> capture(WidgetTester tester, String name) async {
  await tester.pumpAndSettle();
  await tester.runAsync(() async {
    final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
    final image = await layer.toImage(Offset.zero & physical);
    final png = await image.toByteData(format: ui.ImageByteFormat.png);
    File('store/screenshots/$name.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(png!.buffer.asUint8List());
  });
}

double hz(int midi, [double cents = 0]) =>
    NoteMapper().frequencyOf(Note(midi)) * math.pow(2, cents / 1200);

/// Feeds 7 s of readings around [midi], 50 ms apart, with [cents] over time.
Future<void> playPhrase(
  WidgetTester tester,
  TestApp app,
  int midi,
  double Function(double seconds) cents,
) async {
  final tuner = tunerOf(tester);
  for (var i = 0; i <= 140; i++) {
    app.clock.advance(const Duration(milliseconds: 50));
    tuner.emit(readingAt(hz(midi, cents(i * 0.05))));
    await tester.pump();
  }
}

FakeTunerController tunerOf(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(NavigationBar)))
            .read(tunerControllerProvider.notifier)
        as FakeTunerController;

void main() {
  setUpAll(loadFonts);

  setUp(() {
    final view =
        TestWidgetsFlutterBinding.instance.platformDispatcher.views.first;
    view.physicalSize = physical;
    view.devicePixelRatio = dpr;
  });

  testWidgets('01 tuner', (tester) async {
    // Target written D4 (concert C4) on trumpet, sounding. The player slides
    // up into it and settles 18¢ sharp: shows the 1-3 tip.
    final app = await pumpApp(
      tester,
      fontFamilyFallback: const [symbolFont],
      stored: {'droneMidi': 60},
      tuner: const TunerState(TunerStatus.listening),
    );
    await tester.tap(find.byKey(const Key('targetPlay')));
    await playPhrase(tester, app, 60, (t) => 18 - 90 * math.exp(-t / 0.7));
    await capture(tester, '01_tuner');
  });

  testWidgets('02 tuner dark, trombone', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    // Target concert F3, silent (dashed line); the player wobbles around it.
    final app = await pumpApp(
      tester,
      fontFamilyFallback: const [symbolFont],
      stored: {'instrument': 'trombone', 'droneMidi': 53},
      tuner: const TunerState(TunerStatus.listening),
    );
    await playPhrase(
      tester,
      app,
      53,
      (t) => -3 + 9 * math.sin(t * 2.2) * math.exp(-t / 3),
    );
    await capture(tester, '02_tuner_dark_trombone');
  });

  testWidgets('03 fingering chart', (tester) async {
    await pumpApp(
      tester,
      fontFamilyFallback: const [symbolFont],
      tuner: const TunerState(TunerStatus.listening),
    );
    await tester.tap(find.byTooltip('Tabel penjarian'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('chart-60')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await capture(tester, '03_fingering_chart');
  });

  testWidgets('04 lip slur', (tester) async {
    await pumpApp(
      tester,
      fontFamilyFallback: const [symbolFont],
      tuner: const TunerState(TunerStatus.listening),
    );
    await tester.tap(find.text('Lip slur'));
    await tester.pumpAndSettle();
    final tuner = tunerOf(tester);
    for (final (midi, cents) in [(58, 3.0), (65, -6.0), (70, 2.0)]) {
      for (var i = 0; i < 8; i++) {
        tuner.emit(readingAt(hz(midi, cents)));
        await tester.pump();
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 40)),
        );
      }
    }
    tuner.emit(readingAt(hz(74, 9)));
    await capture(tester, '04_lip_slur');
  });

  testWidgets('feature graphic', (tester) async {
    final view = tester.view;
    view.physicalSize = const Size(1024, 500);
    view.devicePixelRatio = 1;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Container(
          color: brand.navy,
          padding: const EdgeInsets.symmetric(horizontal: 64),
          child: Row(
            children: [
              CustomPaint(size: const Size(340, 340), painter: _GaugePainter()),
              const SizedBox(width: 48),
              const Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Brass Tuner',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 72,
                        fontWeight: FontWeight.w700,
                        color: brand.goldLight,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Tuner, penjarian & latihan\nuntuk trumpet sampai tuba',
                      style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 34,
                        height: 1.3,
                        color: brand.cream,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      final layer = tester.binding.renderViews.first.debugLayer! as OffsetLayer;
      final image = await layer.toImage(const Rect.fromLTWH(0, 0, 1024, 500));
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      File('store/feature_graphic.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    });
  });

  testWidgets('06 metronome multi meter', (tester) async {
    await pumpApp(
      tester,
      fontFamilyFallback: const [symbolFont],
      stored: {
        'metronomeMultiBar': 1,
        'metronomeProgram': '4/4x4,3/4x6,6/8x2',
        'metronomeBpm': 96,
      },
      tuner: const TunerState(TunerStatus.listening),
    );
    await tester.tap(find.text('Metronom'));
    await tester.pumpAndSettle();
    await capture(tester, '06_metronome');
  });

  testWidgets('05 history', (tester) async {
    final repo = MemorySessionRepository();
    final rng = math.Random(7);
    for (var d = 0; d < 6; d++) {
      await repo.insert(
        PracticeSession(
          startedAt: DateTime(2026, 11, 13 - d, 18, 10 + d * 7),
          duration: Duration(
            minutes: 12 + rng.nextInt(20),
            seconds: rng.nextInt(60),
          ),
          instrument: Instrument.trumpet,
          a4: 440,
          notes: [
            for (final (midi, bias) in [
              (52, 28.0),
              (55, 22.0),
              (58, 1.0),
              (60, 18.0),
              (63, -2.0),
              (65, 3.0),
              (67, 9.0),
              (70, -1.0),
              (72, -12.0),
              (74, -9.0),
              (77, 4.0),
            ])
              NoteStat(
                midi: midi,
                samples: 300 + rng.nextInt(300),
                meanCents: bias + rng.nextDouble() * 4 - 2,
                sharp: bias > 5 ? 220 + rng.nextInt(60) : 40,
                flat: bias < -5 ? 200 + rng.nextInt(60) : 30,
              ),
          ],
        ),
      );
    }
    await pumpApp(
      tester,
      fontFamilyFallback: const [symbolFont],
      sessions: repo,
      tuner: const TunerState(TunerStatus.listening),
    );
    await tester.tap(find.byTooltip('Riwayat & statistik'));
    await capture(tester, '05_history');
  });
}

class _GaugePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) =>
      brand.paintGauge(canvas, size.width, scale: 1);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
