import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../tuner/domain/instrument.dart';
import '../../tuner/presentation/instrument_l10n.dart';
import '../application/settings_controller.dart';

/// Selectable list of instruments bound to [settingsProvider].
class InstrumentList extends ConsumerWidget {
  const InstrumentList({super.key, this.onSelected});

  final VoidCallback? onSelected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selected = ref.watch(settingsProvider.select((s) => s.instrument));
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final instrument in Instrument.values)
          ListTile(
            title: Text(instrument.name(l10n)),
            subtitle: Text(
              instrument.isTransposing ? instrument.key.label : l10n.concertKey,
            ),
            selected: instrument == selected,
            trailing: instrument == selected ? const Icon(Icons.check) : null,
            onTap: () {
              ref.read(settingsProvider.notifier).setInstrument(instrument);
              onSelected?.call();
            },
          ),
      ],
    );
  }
}
