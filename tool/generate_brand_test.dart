// Renders the launcher icon and splash images from code.
//
//   flutter test tool/generate_brand_test.dart
//   dart run flutter_launcher_icons
//   dart run flutter_native_splash:create
//
// Design: a gold tuner gauge with the needle dead centre (in tune), on a
// deep navy background.
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const navy = Color(0xFF1B2030);
const gold = Color(0xFFC9A227);
const goldLight = Color(0xFFE9CB63);
const cream = Color(0xFFF6EFD9);
const green = Color(0xFF66BB6A);

/// Paints the gauge into a [size]² square; the artwork fills a circle of
/// [scale] × size, so it can be shrunk into adaptive-icon safe zones.
void paintGauge(Canvas canvas, double size, {double scale = 1}) {
  canvas.save();
  canvas.translate(size / 2, size / 2);
  canvas.scale(size * scale / 1024);
  // Artwork below is drawn on a 1024 canvas centred at the origin.
  const pivot = Offset(0, 170);
  const radius = 400.0;
  final arcRect = Rect.fromCircle(center: pivot, radius: radius);
  const start = math.pi * 1.12;
  const sweep = math.pi * 0.76;

  final arc = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 84
    ..strokeCap = StrokeCap.round
    ..shader = const LinearGradient(colors: [gold, goldLight, gold])
        .createShader(arcRect);
  canvas.drawArc(arcRect, start, sweep, false, arc);

  // Tick marks inside the arc; the centre one is the in-tune mark.
  final tick = Paint()
    ..color = gold
    ..strokeWidth = 24
    ..strokeCap = StrokeCap.round;
  for (var i = -2; i <= 2; i++) {
    if (i == 0) continue;
    final a = -math.pi / 2 + i * sweep / 5;
    final dir = Offset(math.cos(a), math.sin(a));
    canvas.drawLine(
      pivot + dir * (radius - 90),
      pivot + dir * (radius - 150),
      tick,
    );
  }
  canvas.drawCircle(
    pivot + const Offset(0, -(radius - 120)),
    28,
    Paint()..color = green,
  );

  // Needle pointing straight up: in tune.
  final needle = Path()
    ..moveTo(0, -(radius - 40) + pivot.dy)
    ..lineTo(34, pivot.dy)
    ..lineTo(-34, pivot.dy)
    ..close();
  canvas.drawPath(needle, Paint()..color = cream);
  canvas.drawCircle(pivot, 76, Paint()..color = gold);
  canvas.drawCircle(pivot, 32, Paint()..color = navy);
  canvas.restore();
}

Future<void> render(
  String path,
  int size,
  void Function(Canvas canvas, double size) paint,
) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder), size.toDouble());
  final image = await recorder.endRecording().toImage(size, size);
  final png = await image.toByteData(format: ui.ImageByteFormat.png);
  File(path)
    ..createSync(recursive: true)
    ..writeAsBytesSync(png!.buffer.asUint8List());
}

void main() {
  testWidgets('generate brand assets', (tester) async {
    await tester.runAsync(() async {
      const dir = 'assets/brand';
      // Legacy / iOS icon: full square, artwork at 80%.
      await render('$dir/icon.png', 1024, (c, s) {
        c.drawRect(Offset.zero & Size(s, s), Paint()..color = navy);
        paintGauge(c, s, scale: 0.85);
      });
      // Adaptive foreground: transparent, full size; flutter_launcher_icons
      // insets it 16%, which lands the artwork inside the 66% safe zone.
      await render(
        '$dir/icon_foreground.png',
        1024,
        (c, s) => paintGauge(c, s, scale: 1.0),
      );
      // Monochrome (Android 13 themed icons): same shape, single colour.
      await render('$dir/icon_monochrome.png', 1024, (c, s) {
        c.saveLayer(Offset.zero & Size(s, s), Paint());
        paintGauge(c, s, scale: 1.0);
        c.drawRect(
          Offset.zero & Size(s, s),
          Paint()
            ..color = Colors.white
            ..blendMode = BlendMode.srcIn,
        );
        c.restore();
      });
      // Splash (Android 12 shows it inside a 2/3 circle mask).
      await render(
        '$dir/splash_android12.png',
        1152,
        (c, s) => paintGauge(c, s, scale: 0.65),
      );
      // Play Store hi-res icon.
      await render('$dir/play_icon_512.png', 512, (c, s) {
        c.drawRect(Offset.zero & Size(s, s), Paint()..color = navy);
        paintGauge(c, s, scale: 0.85);
      });
      await render(
        '$dir/splash.png',
        768,
        (c, s) => paintGauge(c, s, scale: 0.9),
      );
    });
    expect(File('assets/brand/icon.png').existsSync(), isTrue);
  });
}
