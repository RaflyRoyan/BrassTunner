import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/pitch/note_mapper.dart';
import '../../../shared/ui/tuning_colors.dart';
import '../../tuner/domain/instrument.dart';
import '../../tuner/domain/tuning_zone.dart';
import '../domain/fingering.dart';
import '../domain/intonation_tip.dart';

/// Draws a fingering: numbered valve buttons (filled = pressed) or a
/// trombone slide with its position marked.
class FingeringView extends StatelessWidget {
  const FingeringView({
    super.key,
    required this.fingering,
    required this.valveCount,
    this.size = 28,
  });

  final Fingering fingering;

  /// 3 or 4; ignored for slide positions.
  final int valveCount;

  /// Diameter of one valve button.
  final double size;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final semantics = fingering.isSlide
        ? l10n.slidePosition(fingering.position!)
        : fingering.isOpen
        ? l10n.fingeringOpen
        : l10n.fingeringValves(fingering.label);

    if (fingering.isSlide) {
      return Semantics(
        label: semantics,
        excludeSemantics: true,
        child: _SlideView(position: fingering.position!, height: size),
      );
    }
    return Semantics(
      label: semantics,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var v = 1; v <= valveCount; v++)
            Padding(
              padding: EdgeInsets.only(left: v == 1 ? 0 : size * 0.25),
              child: Container(
                width: size,
                height: size,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: fingering.uses(v) ? scheme.primary : null,
                  border: Border.all(color: scheme.primary, width: 2),
                ),
                child: Text(
                  '$v',
                  style: TextStyle(
                    fontSize: size * 0.45,
                    fontWeight: FontWeight.w600,
                    color: fingering.uses(v)
                        ? scheme.onPrimary
                        : scheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SlideView extends StatelessWidget {
  const _SlideView({required this.position, required this.height});

  final int position;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    final step = height * 0.9;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: step * 7,
          height: height,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(height: 3, color: scheme.outlineVariant),
              for (var p = 1; p <= 7; p++)
                Positioned(
                  left: step * (p - 1) + step / 2 - 1,
                  child: Container(
                    width: 2,
                    height: height * 0.5,
                    color: scheme.outline,
                  ),
                ),
              Positioned(
                left: step * (position - 1) + step / 2 - height * 0.3,
                child: Container(
                  width: height * 0.6,
                  height: height * 0.6,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          l10n.slidePosition(position),
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}

/// Text and colour for an [IntonationTip].
extension IntonationTipL10n on IntonationTip {
  String tendency(AppLocalizations l10n) {
    final cause = switch (this.cause) {
      IntonationCause.valveCombination => l10n.causeCombination(
        option.fingering.label,
      ),
      IntonationCause.partial => l10n.causePartial(option.partial),
    };
    final rounded = cents.abs().round();
    return sharp
        ? l10n.tendencySharp(rounded, cause)
        : l10n.tendencyFlat(rounded, cause);
  }

  String advice(AppLocalizations l10n) => switch (remedy) {
    IntonationRemedy.extendSlide1 => l10n.remedyExtendSlide1,
    IntonationRemedy.extendSlide3 => l10n.remedyExtendSlide3,
    IntonationRemedy.slideOut => l10n.remedySlideOut,
    IntonationRemedy.slideIn => l10n.remedySlideIn,
    IntonationRemedy.handClose => l10n.remedyHandClose,
    IntonationRemedy.handOpen => l10n.remedyHandOpen,
    IntonationRemedy.lipDown => l10n.remedyLipDown,
    IntonationRemedy.lipUp => l10n.remedyLipUp,
  };

  Color color(Brightness brightness) =>
      tuningZoneColor(TuningZone.of(cents), brightness);
}

/// One-line tendency + advice, coloured by how far off the note runs.
class IntonationTipText extends StatelessWidget {
  const IntonationTipText({super.key, required this.tip, this.textAlign});

  final IntonationTip tip;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '${tip.sharp ? '▲' : '▼'} ${tip.tendency(l10n)}. ',
            style: TextStyle(
              color: tip.color(theme.brightness),
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(text: tip.advice(l10n)),
        ],
      ),
      textAlign: textAlign,
      style: theme.textTheme.bodyMedium,
    );
  }
}

/// Standard fingering, alternates and tip for a sounding note, as shown on
/// the tuner.
class FingeringHint extends StatelessWidget {
  const FingeringHint({
    super.key,
    required this.instrument,
    required this.note,
  });

  final Instrument instrument;

  /// Sounding (concert) note.
  final Note note;

  /// Alternates shown next to the standard fingering.
  static const maxAlternates = 2;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final chart = FingeringChart.of(instrument);
    final options = chart.optionsFor(note);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    if (options.isEmpty) {
      return Text(l10n.outOfRange, style: muted, key: const Key('fingering'));
    }
    final primary = options.first;
    final alternates = options
        .skip(1)
        .take(maxAlternates)
        .map((o) => o.fingering.label)
        .join(', ');
    final tip = IntonationTip.of(instrument, primary);
    return Column(
      key: const Key('fingering'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FingeringView(
              fingering: primary.fingering,
              valveCount: chart.spec.valveCount,
            ),
            if (alternates.isNotEmpty) ...[
              const SizedBox(width: 12),
              Text(l10n.fingeringAlternates(alternates), style: muted),
            ],
          ],
        ),
        if (tip != null) ...[
          const SizedBox(height: 6),
          IntonationTipText(tip: tip, textAlign: TextAlign.center),
        ],
      ],
    );
  }
}
