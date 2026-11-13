import 'package:flutter/material.dart';

import '../../features/tuner/domain/tuning_zone.dart';

/// Green / amber / red for the tuner, tuned for contrast in both themes.
Color tuningZoneColor(TuningZone zone, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (zone) {
    TuningZone.inTune =>
      dark ? const Color(0xFF66BB6A) : const Color(0xFF2E7D32),
    TuningZone.close =>
      dark ? const Color(0xFFFFCA28) : const Color(0xFFB7791F),
    TuningZone.off => dark ? const Color(0xFFEF5350) : const Color(0xFFC62828),
  };
}
