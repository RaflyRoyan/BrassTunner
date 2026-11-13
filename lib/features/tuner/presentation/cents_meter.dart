import 'package:flutter/material.dart';

import '../../../shared/ui/tuning_colors.dart';
import '../domain/tuning_zone.dart';

/// Horizontal ±50 cent meter with coloured zones and a needle.
///
/// [cents] null hides the needle (no pitch).
class CentsMeter extends StatelessWidget {
  const CentsMeter({super.key, required this.cents});

  final double? cents;

  static const double range = 50;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = (cents ?? 0).clamp(-range, range).toDouble();
    return Semantics(
      label: cents == null ? null : '${cents!.round()} cents',
      child: SizedBox(
        height: 72,
        child: TweenAnimationBuilder<double>(
          tween: Tween(end: target),
          // Short glide hides frame-to-frame steps without adding lag.
          duration: const Duration(milliseconds: 80),
          builder: (context, value, _) => CustomPaint(
            size: Size.infinite,
            painter: _MeterPainter(
              cents: cents == null ? null : value,
              brightness: theme.brightness,
              trackColor: theme.colorScheme.surfaceContainerHighest,
              tickColor: theme.colorScheme.onSurfaceVariant,
              labelStyle: theme.textTheme.labelSmall!.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MeterPainter extends CustomPainter {
  _MeterPainter({
    required this.cents,
    required this.brightness,
    required this.trackColor,
    required this.tickColor,
    required this.labelStyle,
  });

  final double? cents;
  final Brightness brightness;
  final Color trackColor;
  final Color tickColor;
  final TextStyle labelStyle;

  static const double _trackTop = 18;
  static const double _trackHeight = 22;

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    double x(double c) =>
        (c + CentsMeter.range) / (2 * CentsMeter.range) * width;

    // Track with faint zone bands.
    final track = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, _trackTop, width, _trackHeight),
      const Radius.circular(6),
    );
    canvas.drawRRect(track, Paint()..color = trackColor);
    canvas.save();
    canvas.clipRRect(track);
    void band(double from, double to, TuningZone zone) {
      canvas.drawRect(
        Rect.fromLTRB(x(from), _trackTop, x(to), _trackTop + _trackHeight),
        Paint()
          ..color = tuningZoneColor(zone, brightness).withValues(alpha: 0.28),
      );
    }

    band(-TuningZone.closeCents, -TuningZone.inTuneCents, TuningZone.close);
    band(TuningZone.inTuneCents, TuningZone.closeCents, TuningZone.close);
    band(-TuningZone.inTuneCents, TuningZone.inTuneCents, TuningZone.inTune);
    canvas.restore();

    // Ticks every 5 cents, longer every 10, labels at -50/-25/0/+25/+50.
    final tickPaint = Paint()
      ..color = tickColor
      ..strokeWidth = 1;
    for (var c = -50; c <= 50; c += 5) {
      final major = c % 10 == 0;
      final len = c == 0 ? _trackHeight : (major ? 10.0 : 6.0);
      final top = _trackTop + _trackHeight - len;
      canvas.drawLine(
        Offset(x(c.toDouble()), top),
        Offset(x(c.toDouble()), _trackTop + _trackHeight),
        tickPaint..strokeWidth = c == 0 ? 2 : 1,
      );
    }
    for (final c in [-50, -25, 0, 25, 50]) {
      final text = TextPainter(
        text: TextSpan(text: c > 0 ? '+$c' : '$c', style: labelStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      final dx = (x(c.toDouble()) - text.width / 2).clamp(
        0,
        width - text.width,
      );
      text.paint(canvas, Offset(dx.toDouble(), _trackTop + _trackHeight + 6));
    }

    // Needle.
    final value = cents;
    if (value == null) return;
    final color = tuningZoneColor(TuningZone.of(value), brightness);
    final nx = x(value);
    final needle = Paint()
      ..color = color
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(nx, _trackTop - 4),
      Offset(nx, _trackTop + _trackHeight + 2),
      needle,
    );
    final head = Path()
      ..moveTo(nx - 8, 0)
      ..lineTo(nx + 8, 0)
      ..lineTo(nx, _trackTop - 4)
      ..close();
    canvas.drawPath(head, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_MeterPainter old) =>
      old.cents != cents ||
      old.brightness != brightness ||
      old.trackColor != trackColor;
}
