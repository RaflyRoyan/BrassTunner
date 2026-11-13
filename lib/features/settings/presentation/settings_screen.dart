import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/pitch/note_mapper.dart';
import '../../../l10n/app_localizations.dart';
import '../application/settings_controller.dart';
import 'instrument_list.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final a4 = ref.watch(settingsProvider.select((s) => s.a4));
    final controller = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionTitle(l10n.calibrationTitle),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                IconButton.filledTonal(
                  tooltip: l10n.decreaseA4,
                  onPressed: a4 > NoteMapper.minA4
                      ? () => controller.setA4(a4 - 1)
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                Expanded(
                  child: Text(
                    '${a4.round()} Hz',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.displaySmall,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: l10n.increaseA4,
                  onPressed: a4 < NoteMapper.maxA4
                      ? () => controller.setA4(a4 + 1)
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Slider(
            value: a4,
            min: NoteMapper.minA4,
            max: NoteMapper.maxA4,
            divisions: (NoteMapper.maxA4 - NoteMapper.minA4).round(),
            label: '${a4.round()} Hz',
            onChanged: controller.setA4,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              l10n.calibrationHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: TextButton(
                onPressed: a4 == 440 ? null : () => controller.setA4(440),
                child: Text(l10n.resetA4),
              ),
            ),
          ),
          const Divider(height: 32),
          _SectionTitle(l10n.instrumentTitle),
          const InstrumentList(),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(
        text,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
