import 'package:flutter/material.dart';

import '../../../shared/ui/tuning_colors.dart';
import '../../tuner/domain/tuning_zone.dart';
import '../domain/long_tone_tracker.dart';

/// Cents (y, ±50) over time (x) for one take, with in-tune bands.
class LongToneChart extends StatelessWidget {
  const LongToneChart({super.key, required this.take, required this.revision});

  final LongToneTake? take;

  /// Changes whenever [take] gains points, to trigger a repaint.
  final int revision;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomPaint(
      size: Size.infinite,
      painter: _ChartPainter(
        take: take,
        revision: revision,
        brightness: theme.brightness,
        lineColor: theme.colorScheme.primary,
        gridColor: theme.colorScheme.outlineVariant,
        labelStyle: theme.textTheme.labelSmall!.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  _ChartPainter({
    required this.take,
    required this.revision,
    required this.brightness,
    required this.lineColor,
    required this.gridColor,
    required this.labelStyle,
  });

  final LongToneTake? take;
  final int revision;
  final Brightness brightness;
  final Color lineColor;
  final Color gridColor;
  final TextStyle labelStyle;

  static const double _range = 50;
  static const double _leftGutter = 32;
  static const double _bottomGutter = 20;

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(
      _leftGutter,
      4,
      size.width,
      size.height - _bottomGutter,
    );
    final duration = take?.durationSeconds ?? 0;
    // Show at least 10 s; grow in 5 s steps as the note is held.
    final maxSeconds = duration <= 10 ? 10.0 : (duration / 5).ceil() * 5.0;

    double x(double s) => plot.left + s / maxSeconds * plot.width;
    double y(double c) =>
        plot.center.dy - c.clamp(-_range, _range) / _range * plot.height / 2;

    void band(double cents, TuningZone zone) => canvas.drawRect(
      Rect.fromLTRB(plot.left, y(cents), plot.right, y(-cents)),
      Paint()
        ..color = tuningZoneColor(zone, brightness).withValues(alpha: 0.14),
    );
    band(TuningZone.closeCents, TuningZone.close);
    band(TuningZone.inTuneCents, TuningZone.inTune);

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (final c in [-50.0, -25.0, 0.0, 25.0, 50.0]) {
      canvas.drawLine(Offset(plot.left, y(c)), Offset(plot.right, y(c)), grid);
      _label(
        canvas,
        c > 0 ? '+${c.round()}' : '${c.round()}',
        Offset(0, y(c)),
        alignRight: _leftGutter - 6,
      );
    }
    final step = maxSeconds <= 20 ? 5.0 : 10.0;
    for (var s = 0.0; s <= maxSeconds; s += step) {
      _label(
        canvas,
        '${s.round()}s',
        Offset(x(s), plot.bottom + 4),
        center: true,
      );
    }

    final points = take?.points;
    if (points == null || points.isEmpty) return;
    final path = Path()..moveTo(x(points.first.seconds), y(points.first.cents));
    for (final p in points.skip(1)) {
      path.lineTo(x(p.seconds), y(p.cents));
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
    final last = points.last;
    canvas.drawCircle(
      Offset(x(last.seconds), y(last.cents)),
      5,
      Paint()..color = tuningZoneColor(TuningZone.of(last.cents), brightness),
    );
  }

  void _label(
    Canvas canvas,
    String text,
    Offset at, {
    double? alignRight,
    bool center = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: labelStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final dx = alignRight != null
        ? alignRight - painter.width
        : center
        ? at.dx - painter.width / 2
        : at.dx;
    final dy = center ? at.dy : at.dy - painter.height / 2;
    painter.paint(canvas, Offset(dx, dy));
  }

  @override
  bool shouldRepaint(_ChartPainter old) =>
      old.revision != revision ||
      old.take != take ||
      old.brightness != brightness;
}
