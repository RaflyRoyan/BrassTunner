import 'package:brass_tunner/core/pitch/note_mapper.dart';
import 'package:brass_tunner/features/tuner/domain/instrument.dart';
import 'package:brass_tunner/features/tuner/domain/tuning_zone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('written note for concert pitch', () {
    // Each instrument's written C4 and the concert note it sounds.
    final writtenC4Sounds = {
      Instrument.trumpet: 'B♭3',
      Instrument.flugelhorn: 'B♭3',
      Instrument.baritoneTrebleClef: 'B♭2',
      Instrument.mellophone: 'F3',
      Instrument.frenchHorn: 'F3',
      Instrument.altoHorn: 'E♭3',
      Instrument.trombone: 'C4',
      Instrument.euphoniumBassClef: 'C4',
      Instrument.tuba: 'C4',
    };

    for (final MapEntry(key: instrument, value: concertLabel)
        in writtenC4Sounds.entries) {
      test('${instrument.name}: written C4 sounds $concertLabel', () {
        final concert = const Note(60).transpose(-instrument.writtenOffset);
        expect(concert.label, concertLabel);
        expect(instrument.writtenNote(concert).label, 'C4');
      });
    }

    test('only concert-pitch instruments are non-transposing', () {
      expect(Instrument.values.where((i) => !i.isTransposing), [
        Instrument.trombone,
        Instrument.euphoniumBassClef,
        Instrument.tuba,
      ]);
    });
  });

  group('TuningZone', () {
    test('boundaries are inclusive: ±5 green, ±15 yellow', () {
      expect(TuningZone.of(0), TuningZone.inTune);
      expect(TuningZone.of(5), TuningZone.inTune);
      expect(TuningZone.of(-5), TuningZone.inTune);
      expect(TuningZone.of(5.1), TuningZone.close);
      expect(TuningZone.of(-15), TuningZone.close);
      expect(TuningZone.of(15.1), TuningZone.off);
      expect(TuningZone.of(-49), TuningZone.off);
    });
  });
}
