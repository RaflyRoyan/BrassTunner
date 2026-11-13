import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/ui/tuning_colors.dart';
import '../../settings/application/settings_controller.dart';
import '../../tuner/application/tuner_controller.dart';
import '../../tuner/domain/tuning_zone.dart';
import '../../tuner/presentation/tuner_screen.dart';
import '../application/long_tone_controller.dart';
import 'long_tone_chart.dart';

class LongTonePage extends ConsumerWidget {
  const LongTonePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = ref.watch(tunerControllerProvider.select((s) => s.status));
    final longTone = ref.watch(longToneProvider);
    final instrument = ref.watch(settingsProvider.select((s) => s.instrument));
    final take = longTone.shown;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final oneDecimal = NumberFormat('0.0', locale);
    final muted = theme.colorScheme.onSurfaceVariant;

    String signed(double cents) {
      final r = cents.round();
      return '${r > 0
          ? '+'
          : r < 0
          ? '−'
          : ''}${r.abs()}¢';
    }

    return MicGate(
      status: status,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 72,
              child: take == null
                  ? Center(
                      child: Text(
                        l10n.longToneHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: muted,
                        ),
                      ),
                    )
                  : Row(
                      children: [
                        Text(
                          instrument.writtenNote(take.note).label,
                          key: const Key('longToneNote'),
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (instrument.isTransposing)
                          Text(
                            l10n.concertValue(take.note.label),
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        const Spacer(),
                        _StatusBadge(live: longTone.isLive),
                      ],
                    ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: LongToneChart(take: take, revision: longTone.revision),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Stat(
                  label: l10n.statDuration,
                  value: take == null
                      ? '–'
                      : l10n.secondsValue(
                          oneDecimal.format(take.durationSeconds),
                        ),
                ),
                _Stat(
                  label: l10n.statMean,
                  value: take == null ? '–' : signed(take.meanCents),
                  color: take == null
                      ? null
                      : tuningZoneColor(
                          TuningZone.of(take.meanCents),
                          theme.brightness,
                        ),
                ),
                _Stat(
                  label: l10n.statStability,
                  value: take == null
                      ? '–'
                      : '±${oneDecimal.format(take.stabilityCents)}¢',
                ),
                _Stat(
                  label: l10n.statInTune,
                  value: take == null
                      ? '–'
                      : NumberFormat.percentPattern(locale)
                            .format(take.inTuneRatio()),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.live});

  final bool live;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (live) ...[
          Icon(
            Icons.fiber_manual_record,
            size: 14,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 4),
        ],
        Text(
          live ? l10n.longToneLive : l10n.longToneLast,
          style: theme.textTheme.labelLarge,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.color});

  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
