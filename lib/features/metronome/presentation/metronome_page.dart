import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/synth/metronome_voice.dart';
import '../../../l10n/app_localizations.dart';
import '../application/metronome_controller.dart';
import '../domain/bar_program.dart';

class MetronomePage extends ConsumerWidget {
  const MetronomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final metronome = ref.watch(metronomeProvider);
    final controller = ref.read(metronomeProvider.notifier);
    final event = metronome.running
        ? ref.watch(metronomeBeatProvider).value
        : null;
    final program = metronome.program;
    // Where the program is now: from the last click, else its start.
    final position = metronome.multiBar
        ? program.locate(event?.bar ?? 0)
        : null;
    final segment = position == null
        ? null
        : program.segments[position.segment];

    final list = ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      children: [
        const SizedBox(height: 8),
        _BeatDots(
          count: segment?.beats ?? metronome.beatsPerBar,
          current: event?.beatInBar,
        ),
        if (position != null && segment != null) ...[
          const SizedBox(height: 12),
          Text(
            l10n.programPosition(
              position.segment + 1,
              segment.signature,
              position.barInSegment + 1,
              segment.bars,
            ),
            key: const Key('programPosition'),
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.primary,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Text(
          '${metronome.bpm}',
          key: const Key('bpm'),
          textAlign: TextAlign.center,
          style: theme.textTheme.displayLarge?.copyWith(
            fontWeight: FontWeight.w600,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        Text(
          'BPM',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            IconButton(
              tooltip: l10n.slower,
              onPressed: () => controller.setBpm(metronome.bpm - 1),
              icon: const Icon(Icons.remove),
            ),
            Expanded(
              child: Slider(
                value: metronome.bpm.toDouble(),
                min: MetronomeVoice.minBpm.toDouble(),
                max: MetronomeVoice.maxBpm.toDouble(),
                onChanged: (v) => controller.setBpm(v.round()),
              ),
            ),
            IconButton(
              tooltip: l10n.faster,
              onPressed: () => controller.setBpm(metronome.bpm + 1),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
        Center(
          child: OutlinedButton.icon(
            onPressed: controller.tap,
            icon: const Icon(Icons.touch_app_outlined),
            label: Text(l10n.tapTempo),
          ),
        ),
        const SizedBox(height: 24),
        Center(
          child: SegmentedButton<bool>(
            segments: [
              ButtonSegment(value: false, label: Text(l10n.meterSingle)),
              ButtonSegment(value: true, label: Text(l10n.meterMulti)),
            ],
            selected: {metronome.multiBar},
            onSelectionChanged: (s) => controller.setMultiBar(s.single),
          ),
        ),
        const SizedBox(height: 16),
        if (!metronome.multiBar)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton.filledTonal(
                tooltip: l10n.fewerBeats,
                onPressed: metronome.beatsPerBar > 1
                    ? () => controller.setBeatsPerBar(metronome.beatsPerBar - 1)
                    : null,
                icon: const Icon(Icons.remove),
              ),
              SizedBox(
                width: 200,
                child: Text(
                  l10n.beatsPerBar(metronome.beatsPerBar),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton.filledTonal(
                tooltip: l10n.moreBeats,
                onPressed: metronome.beatsPerBar < MetronomeVoice.maxBeatsPerBar
                    ? () => controller.setBeatsPerBar(metronome.beatsPerBar + 1)
                    : null,
                icon: const Icon(Icons.add),
              ),
            ],
          )
        else ...[
          for (var i = 0; i < program.segments.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SegmentCard(
                index: i,
                segment: program.segments[i],
                active: metronome.running && position?.segment == i,
                canRemove: program.segments.length > 1,
                onChanged: (s) => controller.updateSegment(i, s),
                onRemove: () => controller.removeSegment(i),
              ),
            ),
          Center(
            child: TextButton.icon(
              onPressed: program.segments.length < BarProgram.maxSegments
                  ? controller.addSegment
                  : null,
              icon: const Icon(Icons.add),
              label: Text(l10n.addSegment),
            ),
          ),
          Text(
            l10n.programSummary(program.totalBars),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.volume_down, semanticLabel: l10n.volume),
            Expanded(
              child: Slider(
                value: metronome.volume,
                onChanged: controller.setVolume,
              ),
            ),
            const Icon(Icons.volume_up),
          ],
        ),
      ],
    );

    // Play stays pinned below the list, so a long program never pushes it
    // out of reach.
    return Column(
      children: [
        Expanded(child: list),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
              onPressed: controller.toggle,
              icon: Icon(metronome.running ? Icons.stop : Icons.play_arrow),
              label: Text(metronome.running ? l10n.stop : l10n.play),
            ),
          ),
        ),
      ],
    );
  }
}

/// One part of the multi-bar program: time signature and length in bars.
class _SegmentCard extends StatelessWidget {
  const _SegmentCard({
    required this.index,
    required this.segment,
    required this.active,
    required this.canRemove,
    required this.onChanged,
    required this.onRemove,
  });

  final int index;
  final BarSegment segment;

  /// The metronome is playing this part right now.
  final bool active;
  final bool canRemove;
  final ValueChanged<BarSegment> onChanged;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    const compact = VisualDensity.compact;

    return Card.outlined(
      key: Key('segment$index'),
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: active ? scheme.primary : scheme.outlineVariant,
          width: active ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 4, 4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.segmentTitle(index + 1),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: active ? scheme.primary : scheme.onSurfaceVariant,
                    ),
                  ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      // Time signature: numerator stepper + unit menu.
                      IconButton(
                        visualDensity: compact,
                        tooltip: l10n.fewerBeats,
                        onPressed: segment.beats > 1
                            ? () => onChanged(
                                segment.copyWith(beats: segment.beats - 1),
                              )
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      PopupMenuButton<int>(
                        tooltip: l10n.beatUnit,
                        initialValue: segment.unit,
                        onSelected: (unit) =>
                            onChanged(segment.copyWith(unit: unit)),
                        itemBuilder: (_) => [
                          for (final unit in BarSegment.units)
                            PopupMenuItem(
                              value: unit,
                              child: Text('${segment.beats}/$unit'),
                            ),
                        ],
                        child: Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                segment.signature,
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, size: 20),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        visualDensity: compact,
                        tooltip: l10n.moreBeats,
                        onPressed: segment.beats < BarSegment.maxBeats
                            ? () => onChanged(
                                segment.copyWith(beats: segment.beats + 1),
                              )
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                      const SizedBox(width: 8),
                      // Length in bars.
                      IconButton(
                        visualDensity: compact,
                        tooltip: l10n.fewerBars,
                        onPressed: segment.bars > 1
                            ? () => onChanged(
                                segment.copyWith(bars: segment.bars - 1),
                              )
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '× ${l10n.barsCount(segment.bars)}',
                        style: theme.textTheme.titleMedium,
                      ),
                      IconButton(
                        visualDensity: compact,
                        tooltip: l10n.moreBars,
                        onPressed: segment.bars < BarSegment.maxBars
                            ? () => onChanged(
                                segment.copyWith(bars: segment.bars + 1),
                              )
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: l10n.removeSegment,
              onPressed: canRemove ? onRemove : null,
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }
}

class _BeatDots extends StatelessWidget {
  const _BeatDots({required this.count, required this.current});

  final int count;
  final int? current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 60),
            width: i == 0 && count > 1 ? 28 : 20,
            height: i == 0 && count > 1 ? 28 : 20,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == current
                  ? (i == 0 ? scheme.primary : scheme.tertiary)
                  : scheme.surfaceContainerHighest,
            ),
          ),
      ],
    );
  }
}
