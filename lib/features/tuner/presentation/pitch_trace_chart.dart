import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/pitch/note_mapper.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/ui/tuning_colors.dart';
import '../domain/instrument.dart';
import '../domain/pitch_trace.dart';
import '../domain/tuning_zone.dart';

/// Input pitch (the player) against the target note (the reference tone)
/// over the last few seconds. Rows are semitones around the target, labelled
/// in the instrument's written pitch.
class PitchTraceChart extends StatelessWidget {
  const PitchTraceChart({
    super.key,
    required this.trace,
    required this.revision,
    required this.target,
    required this.instrument,
    required this.targetSounding,
  });

  final PitchTrace trace;

  /// Changes whenever [trace] gains points, to trigger a repaint.
  final int revision;

  /// Target note, concert pitch.
  final Note target;
  final Instrument instrument;

  /// Whether the target tone is playing (solid line) or silent (dashed).
  final bool targetSounding;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final labelStyle = theme.textTheme.labelSmall!.copyWith(
      color: scheme.onSurfaceVariant,
    );

    Widget legend(Color color, String text) => Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: 6),
        Text(text, style: labelStyle),
      ],
    );

    return Column(
      children: [
        Wrap(
          spacing: 16,
          children: [
            legend(scheme.primary, l10n.chartInput),
            legend(scheme.tertiary, l10n.chartOutput),
          ],
        ),
        const SizedBox(height: 4),
        Expanded(
          child: Semantics(
            label: '${l10n.chartInput} / ${l10n.chartOutput}',
            child: CustomPaint(
              size: Size.infinite,
              painter: _TracePainter(
                trace: trace,
                revision: revision,
                target: target,
                instrument: instrument,
                targetSounding: targetSounding,
                brightness: theme.brightness,
                inputColor: scheme.primary,
                targetColor: scheme.tertiary,
                gridColor: scheme.outlineVariant,
                labelStyle: labelStyle,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TracePainter extends CustomPainter {
  _TracePainter({
    required this.trace,
    required this.revision,
    required this.target,
    required this.instrument,
    required this.targetSounding,
    required this.brightness,
    required this.inputColor,
    required this.targetColor,
    required this.gridColor,
    required this.labelStyle,
  });

  final PitchTrace trace;
  final int revision;
  final Note target;
  final Instrument instrument;
  final bool targetSounding;
  final Brightness brightness;
  final Color inputColor;
  final Color targetColor;
  final Color gridColor;
  final TextStyle labelStyle;

  /// Most semitones shown above and below the target.
  static const int maxSpan = 3;
  static const double _leftGutter = 36;

  /// Zooms in while the player stays near the target, so a few cents are
  /// visible; zooms out to [maxSpan] when they wander.
  int _span() {
    var deviation = 0.0;
    for (final p in trace.points) {
      final midi = p.midi;
      if (midi != null) {
        deviation = math.max(deviation, (midi - target.midi).abs());
      }
    }
    return deviation <= 0.9
        ? 1
        : deviation <= 1.9
        ? 2
        : maxSpan;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final plot = Rect.fromLTRB(_leftGutter, 6, size.width, size.height - 6);
    final span = _span();
    final rowHeight = plot.height / (span * 2);
    double y(double semitones) =>
        plot.center.dy - semitones.clamp(-span, span) * rowHeight;

    // In-tune bands around the target.
    for (final (cents, zone) in [
      (TuningZone.closeCents, TuningZone.close),
      (TuningZone.inTuneCents, TuningZone.inTune),
    ]) {
      canvas.drawRect(
        Rect.fromLTRB(plot.left, y(cents / 100), plot.right, y(-cents / 100)),
        Paint()
          ..color = tuningZoneColor(zone, brightness).withValues(alpha: 0.18),
      );
    }

    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var k = -span; k <= span; k++) {
      final rowY = y(k.toDouble());
      if (k != 0) {
        canvas.drawLine(
          Offset(plot.left, rowY),
          Offset(plot.right, rowY),
          grid,
        );
      }
      _label(
        canvas,
        instrument.writtenNote(target.transpose(k)).label,
        Offset(_leftGutter - 6, rowY),
        bold: k == 0,
      );
    }
    // Zoomed in: quarter-tone guides, labelled in cents on the right.
    if (span == 1) {
      for (final half in [0.5, -0.5]) {
        final rowY = y(half);
        for (var x = plot.left; x < plot.right; x += 8) {
          canvas.drawLine(
            Offset(x, rowY),
            Offset(math.min(x + 3, plot.right), rowY),
            grid,
          );
        }
        _label(
          canvas,
          half > 0 ? '+50¢' : '−50¢',
          Offset(plot.right, rowY - 9),
        );
      }
    }

    // Output: the target tone.
    final targetPaint = Paint()
      ..color = targetColor
      ..strokeWidth = 3;
    final mid = plot.center.dy;
    if (targetSounding) {
      canvas.drawLine(
        Offset(plot.left, mid),
        Offset(plot.right, mid),
        targetPaint,
      );
    } else {
      for (var x = plot.left; x < plot.right; x += 12) {
        canvas.drawLine(
          Offset(x, mid),
          Offset((x + 6).clamp(plot.left, plot.right), mid),
          targetPaint,
        );
      }
    }

    // Input: the detected pitch, newest sample at the right edge.
    final points = trace.points;
    if (points.isEmpty) return;
    final now = trace.now;
    final window = trace.windowSeconds;
    double x(double s) => plot.right - (now - s) / window * plot.width;

    canvas.save();
    canvas.clipRect(plot);
    final path = Path();
    var penDown = false;
    for (final p in points) {
      final midi = p.midi;
      if (midi == null) {
        penDown = false;
        continue;
      }
      final at = Offset(x(p.seconds), y(midi - target.midi));
      if (penDown) {
        path.lineTo(at.dx, at.dy);
      } else {
        path.moveTo(at.dx, at.dy);
        penDown = true;
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = inputColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.restore();

    final lastMidi = points.last.midi;
    if (lastMidi != null) {
      final cents = (lastMidi - target.midi) * 100;
      canvas.drawCircle(
        Offset(plot.right - 5, y(lastMidi - target.midi)),
        5,
        Paint()..color = tuningZoneColor(TuningZone.of(cents), brightness),
      );
    }
  }

  void _label(
    Canvas canvas,
    String text,
    Offset rightCenter, {
    bool bold = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: bold
            ? labelStyle.copyWith(
                color: targetColor,
                fontWeight: FontWeight.w700,
              )
            : labelStyle,
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      Offset(
        rightCenter.dx - painter.width,
        rightCenter.dy - painter.height / 2,
      ),
    );
  }

  @override
  bool shouldRepaint(_TracePainter old) =>
      old.revision != revision ||
      old.trace != trace ||
      old.target.midi != target.midi ||
      old.instrument != instrument ||
      old.targetSounding != targetSounding ||
      old.brightness != brightness;
}
