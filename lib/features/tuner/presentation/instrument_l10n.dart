import '../../../l10n/app_localizations.dart';
import '../domain/instrument.dart';

extension InstrumentL10n on Instrument {
  String name(AppLocalizations l10n) => switch (this) {
    Instrument.trumpet => l10n.instrumentTrumpet,
    Instrument.flugelhorn => l10n.instrumentFlugelhorn,
    Instrument.baritoneTrebleClef => l10n.instrumentBaritoneTrebleClef,
    Instrument.mellophone => l10n.instrumentMellophone,
    Instrument.frenchHorn => l10n.instrumentFrenchHorn,
    Instrument.altoHorn => l10n.instrumentAltoHorn,
    Instrument.trombone => l10n.instrumentTrombone,
    Instrument.euphoniumBassClef => l10n.instrumentEuphoniumBassClef,
    Instrument.tuba => l10n.instrumentTuba,
  };

  /// e.g. "Trumpet (B♭)" or "Tuba (concert)".
  String nameWithKey(AppLocalizations l10n) => l10n.instrumentInKey(
    name(l10n),
    isTransposing ? key.label : l10n.concertKey,
  );
}
