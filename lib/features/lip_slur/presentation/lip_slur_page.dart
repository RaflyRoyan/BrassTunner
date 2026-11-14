import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/ui/tuning_colors.dart';
import '../../fingering/presentation/fingering_view.dart';
import '../../settings/application/settings_controller.dart';
import '../../tuner/application/tuner_controller.dart';
import '../../tuner/domain/instrument.dart';
import '../../tuner/domain/tuning_zone.dart';
import '../../tuner/presentation/tuner_screen.dart';
import '../application/lip_slur_controller.dart';
import '../domain/lip_slur.dart';

/// Lip slur trainer: play the partials of one fingering in order; each note
/// is checked for the right partial and its intonation.
class LipSlurPage extends ConsumerWidget {
  const LipSlurPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final status = ref.watch(tunerControllerProvider.select((s) => s.status));
    final slur = ref.watch(lipSlurProvider);
    final controller = ref.read(lipSlurProvider.notifier);
    final instrument = ref.watch(settingsProvider.select((s) => s.instrument));
    final exercise = slur.exercise;
    final tracker = slur.tracker;
    final spec = exercise.spec;
    final muted = theme.colorScheme.onSurfaceVariant;
    final partials = spec.partials;
    final lowIndex = partials.indexOf(exercise.lowPartial);
    final highIndex = partials.indexOf(exercise.highPartial);

    return MicGate(
      status: status,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.lipSlurHint,
            style: theme.textTheme.bodyMedium?.copyWith(color: muted),
          ),
          const SizedBox(height: 16),
          Text(l10n.lipSlurFingering, style: theme.textTheme.labelLarge),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final f in LipSlurController.fingeringChoices(spec))
                ChoiceChip(
                  label: Text(f.isOpen ? l10n.fingeringOpen : f.label),
                  selected: f == exercise.fingering,
                  onSelected: (_) => controller.setFingering(f),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: FingeringView(
              fingering: exercise.fingering,
              valveCount: spec.valveCount,
              size: 24,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            l10n.lipSlurRange(exercise.lowPartial, exercise.highPartial),
            style: theme.textTheme.labelLarge,
          ),
          RangeSlider(
            values: RangeValues(lowIndex.toDouble(), highIndex.toDouble()),
            min: 0,
            max: (partials.length - 1).toDouble(),
            divisions: partials.length - 1,
            labels: RangeLabels(
              '${exercise.lowPartial}',
              '${exercise.highPartial}',
            ),
            onChanged: (v) => controller.setRange(
              partials[v.start.round()],
              partials[v.end.round()],
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final (i, step) in tracker.steps.indexed)
                _StepTile(
                  key: ValueKey('slurStep$i'),
                  step: step,
                  instrument: instrument,
                  current: i == tracker.index,
                ),
            ],
          ),
          const SizedBox(height: 24),
          _Prompt(state: slur, instrument: instrument),
          const SizedBox(height: 24),
          Center(
            child: OutlinedButton.icon(
              onPressed: controller.restart,
              icon: const Icon(Icons.replay),
              label: Text(l10n.restart),
            ),
          ),
        ],
      ),
    );
  }
}

/// What to play next, what is heard, or the summary when done.
class _Prompt extends StatelessWidget {
  const _Prompt({required this.state, required this.instrument});

  final LipSlurState state;
  final Instrument instrument;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final locale = Localizations.localeOf(context).toLanguageTag();
    final tracker = state.tracker;
    final muted = theme.colorScheme.onSurfaceVariant;

    if (tracker.finished) {
      final mean = tracker.meanAbsCents ?? 0;
      return Column(
        key: const Key('slurSummary'),
        children: [
          Text(
            l10n.lipSlurDone(NumberFormat('0.0', locale).format(mean)),
            style: theme.textTheme.headlineSmall?.copyWith(
              color: tuningZoneColor(TuningZone.of(mean), theme.brightness),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.lipSlurMisses(tracker.totalMisses),
            style: theme.textTheme.titleMedium,
          ),
        ],
      );
    }

    final target = tracker.current!.target;
    final reading = state.reading;
    final heard = reading == null
        ? '–'
        : '${instrument.writtenNote(reading.note.note).label} '
              '${_signed(reading.note.cents)}';
    final onTarget = reading?.note.note == target;
    return Column(
      children: [
        Text(
          l10n.lipSlurTarget(instrument.writtenNote(target).label),
          key: const Key('slurTarget'),
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        if (instrument.isTransposing)
          Text(
            l10n.concertValue(target.label),
            style: theme.textTheme.titleSmall?.copyWith(color: muted),
          ),
        const SizedBox(height: 8),
        Text(
          heard,
          style: theme.textTheme.titleLarge?.copyWith(
            color: reading == null
                ? muted
                : onTarget
                ? tuningZoneColor(
                    TuningZone.of(reading.note.cents),
                    theme.brightness,
                  )
                : theme.colorScheme.error,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    super.key,
    required this.step,
    required this.instrument,
    required this.current,
  });

  final LipSlurStep step;
  final Instrument instrument;
  final bool current;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final mean = step.meanCents;
    final color = mean == null
        ? scheme.onSurfaceVariant
        : tuningZoneColor(TuningZone.of(mean), theme.brightness);
    return Container(
      width: 56,
      padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: step.done ? color.withValues(alpha: 0.12) : null,
        border: Border.all(
          color: current ? scheme.primary : scheme.outlineVariant,
          width: current ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            instrument.writtenNote(step.target).label,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            mean == null ? '–' : _signed(mean),
            style: theme.textTheme.labelMedium?.copyWith(color: color),
          ),
          if (step.misses > 0)
            Text(
              '✕${step.misses}',
              style: theme.textTheme.labelSmall?.copyWith(color: scheme.error),
            ),
        ],
      ),
    );
  }
}

String _signed(double cents) {
  final r = cents.round();
  // U+2212 minus sign lines up with the plus sign.
  return '${r > 0
      ? '+'
      : r < 0
      ? '−'
      : ''}${r.abs()}¢';
}
