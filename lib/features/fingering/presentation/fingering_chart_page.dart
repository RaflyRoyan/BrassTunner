import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../settings/application/settings_controller.dart';
import '../../tuner/presentation/instrument_l10n.dart';
import '../domain/fingering.dart';
import '../domain/intonation_tip.dart';
import 'fingering_view.dart';

/// Every note of the selected instrument with its fingerings and tendencies.
/// Notes are shown as the player reads them (written pitch).
class FingeringChartPage extends ConsumerWidget {
  const FingeringChartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final instrument = ref.watch(settingsProvider.select((s) => s.instrument));
    final chart = FingeringChart.of(instrument);
    final notes = chart.notes.reversed.toList(); // high notes on top
    final muted = theme.colorScheme.onSurfaceVariant;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.fingeringChartTitle)),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.only(bottom: 16),
          itemCount: notes.length + 1,
          separatorBuilder: (_, i) =>
              i == 0 ? const SizedBox.shrink() : const Divider(height: 1),
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      instrument.nameWithKey(l10n),
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.tipDisclaimer,
                      style: theme.textTheme.bodySmall?.copyWith(color: muted),
                    ),
                  ],
                ),
              );
            }
            final concert = notes[i - 1];
            final options = chart.optionsFor(concert);
            final primary = options.first;
            final tip = IntonationTip.of(instrument, primary);
            final alternates = options
                .skip(1)
                .map((o) => o.fingering.label)
                .join(', ');
            return Padding(
              key: ValueKey('chart-${concert.midi}'),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SizedBox(
                        width: 96,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              instrument.writtenNote(concert).label,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (instrument.isTransposing)
                              Text(
                                l10n.concertValue(concert.label),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: muted,
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: FingeringView(
                            fingering: primary.fingering,
                            valveCount: chart.spec.valveCount,
                            size: 24,
                          ),
                        ),
                      ),
                      if (alternates.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            l10n.fingeringAlternates(alternates),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: muted,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (tip != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: IntonationTipText(tip: tip),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
