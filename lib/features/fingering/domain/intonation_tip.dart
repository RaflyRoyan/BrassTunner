import '../../tuner/domain/instrument.dart';
import 'fingering.dart';

/// What makes a note tend sharp or flat.
enum IntonationCause {
  /// Combined valves add too little tubing.
  valveCombination,

  /// The harmonic itself is out of equal temperament (e.g. the 5th partial).
  partial,
}

/// How the player can correct it.
enum IntonationRemedy {
  /// Trumpet: kick out the 1st valve slide.
  extendSlide1,

  /// Trumpet: pull the 3rd valve slide (ring).
  extendSlide3,

  /// Trombone: move the slide slightly further out.
  slideOut,

  /// Trombone: move the slide slightly in.
  slideIn,

  /// Horn: cover the bell more with the right hand.
  handClose,

  /// Horn: open the right hand in the bell.
  handOpen,

  /// Bring the pitch down with the embouchure / air.
  lipDown,

  /// Bring the pitch up with the embouchure / air.
  lipUp,
}

/// A predicted intonation tendency with advice.
class IntonationTip {
  const IntonationTip({
    required this.cents,
    required this.cause,
    required this.remedy,
    required this.option,
  });

  /// Predicted deviation, positive is sharp.
  final double cents;
  final IntonationCause cause;
  final IntonationRemedy remedy;
  final FingeringOption option;

  bool get sharp => cents > 0;

  /// Tendencies smaller than this are not worth a tip.
  static const double thresholdCents = 8;

  /// Advice for playing [option] on [instrument], or null when the note is
  /// expected to be in tune.
  static IntonationTip? of(Instrument instrument, FingeringOption option) {
    final cents = option.tendencyCents;
    if (cents.abs() < thresholdCents) return null;
    final fingering = option.fingering;
    final cause =
        fingering.comboCents.abs() >= Partials.cents(option.partial).abs()
        ? IntonationCause.valveCombination
        : IntonationCause.partial;
    final system = FingeringSpec.of(instrument).system;
    final sharp = cents > 0;

    final IntonationRemedy remedy;
    if (system == FingeringSystem.slide) {
      remedy = sharp
          ? IntonationRemedy.slideOut
          : (fingering.position! > 1
                ? IntonationRemedy.slideIn
                : IntonationRemedy.lipUp);
    } else if (system == FingeringSystem.fHorn) {
      remedy = sharp ? IntonationRemedy.handClose : IntonationRemedy.handOpen;
    } else if (!sharp) {
      remedy = IntonationRemedy.lipUp;
    } else if (instrument == Instrument.trumpet && fingering.uses(3)) {
      // Trumpets have a ring or saddle on the 3rd (and 1st) valve slide.
      remedy = IntonationRemedy.extendSlide3;
    } else if (instrument == Instrument.trumpet && fingering.uses(1)) {
      remedy = IntonationRemedy.extendSlide1;
    } else {
      remedy = IntonationRemedy.lipDown;
    }
    return IntonationTip(
      cents: cents,
      cause: cause,
      remedy: remedy,
      option: option,
    );
  }
}
