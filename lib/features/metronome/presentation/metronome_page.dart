import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/synth/metronome_voice.dart';
import '../../../l10n/app_localizations.dart';
import '../application/metronome_controller.dart';

class MetronomePage extends ConsumerWidget {
  const MetronomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final metronome = ref.watch(metronomeProvider);
    final controller = ref.read(metronomeProvider.notifier);
    final beat = metronome.running
        ? ref.watch(metronomeBeatProvider).value
        : null;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SizedBox(height: 8),
        _BeatDots(count: metronome.beatsPerBar, current: beat),
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
        ),
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
        const SizedBox(height: 16),
        FilledButton.icon(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 56)),
          onPressed: controller.toggle,
          icon: Icon(metronome.running ? Icons.stop : Icons.play_arrow),
          label: Text(metronome.running ? l10n.stop : l10n.play),
        ),
      ],
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
