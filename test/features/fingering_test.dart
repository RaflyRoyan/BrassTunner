import 'package:brass_tunner/core/pitch/note_mapper.dart';
import 'package:brass_tunner/features/fingering/domain/fingering.dart';
import 'package:brass_tunner/features/fingering/domain/intonation_tip.dart';
import 'package:brass_tunner/features/tuner/domain/instrument.dart';
import 'package:flutter_test/flutter_test.dart';

/// Standard fingering for a note the player reads on [instrument].
String written(Instrument instrument, String label) {
  final chart = FingeringChart.of(instrument);
  final concert = parse(label).transpose(-instrument.writtenOffset);
  final options = chart.optionsFor(concert);
  expect(options, isNotEmpty, reason: '$label out of range on $instrument');
  return options.first.fingering.label;
}

Note parse(String label) {
  const names = {
    'C': 0, 'C#': 1, 'Db': 1, 'D': 2, 'Eb': 3, 'E': 4, 'F': 5, 'F#': 6, //
    'Gb': 6, 'G': 7, 'Ab': 8, 'A': 9, 'Bb': 10, 'B': 11,
  };
  final m = RegExp(r'^([A-G][b#]?)(-?\d)$').firstMatch(label)!;
  return Note(names[m[1]]! + (int.parse(m[2]!) + 1) * 12);
}

void main() {
  group('Partials', () {
    test('semitones above the fundamental', () {
      expect(
        [for (var n = 1; n <= 8; n++) Partials.semitones(n)],
        [
          0, 12, 19, 24, 28, 31, 34, 36, //
        ],
      );
    });

    test('5th partial is about 14 cents flat, 3rd 2 cents sharp', () {
      expect(Partials.cents(5), closeTo(-13.7, 0.1));
      expect(Partials.cents(3), closeTo(2.0, 0.1));
      expect(Partials.cents(4), closeTo(0, 1e-9));
    });
  });

  group('Fingering', () {
    test('lowering per valve and position', () {
      expect(const Fingering.valves([1, 3]).lowering, 5);
      expect(const Fingering.valves([1, 2, 3]).lowering, 6);
      expect(const Fingering.valves([1, 2, 3, 4]).lowering, 11);
      expect(const Fingering.slide(7).lowering, 6);
    });

    test('combined valves run sharp, single valves do not', () {
      expect(const Fingering.valves([1]).comboCents, 0);
      expect(const Fingering.valves([1, 2]).comboCents, closeTo(10.6, 0.5));
      expect(const Fingering.valves([1, 3]).comboCents, closeTo(30.3, 0.5));
      expect(const Fingering.valves([1, 2, 3]).comboCents, closeTo(53.6, 0.5));
      expect(const Fingering.slide(6).comboCents, 0);
    });

    test('labels', () {
      expect(const Fingering.valves([]).label, '0');
      expect(const Fingering.valves([1, 2, 3]).label, '1-2-3');
      expect(const Fingering.slide(4).label, '4');
      expect(const Fingering.slide(3), isNot(const Fingering.valves([3])));
    });
  });

  group('trumpet chart (written pitch)', () {
    const t = Instrument.trumpet;
    final expected = {
      'F#3': '1-2-3', 'G3': '1-3', 'Ab3': '2-3', 'A3': '1-2', 'Bb3': '1', //
      'B3': '2', 'C4': '0', 'C#4': '1-2-3', 'D4': '1-3', 'Eb4': '2-3',
      'E4': '1-2', 'F4': '1', 'F#4': '2', 'G4': '0', 'Ab4': '2-3',
      'A4': '1-2', 'Bb4': '1', 'B4': '2', 'C5': '0', 'C#5': '1-2',
      'D5': '1', 'Eb5': '2', 'E5': '0', 'F5': '1', 'F#5': '2', 'G5': '0',
      'Ab5': '2-3', 'A5': '1-2', 'Bb5': '1', 'B5': '2', 'C6': '0',
    };
    for (final MapEntry(key: note, value: fingering) in expected.entries) {
      test('$note = $fingering', () => expect(written(t, note), fingering));
    }

    test('range is written F#3 to C6', () {
      final chart = FingeringChart.of(t);
      expect(Note(chart.lowestMidi).transpose(2).label, 'G♭3');
      expect(Note(chart.highestMidi).transpose(2).label, 'C6');
      expect(chart.notes, hasLength(31));
    });

    test('3 is listed as an alternate for 1-2', () {
      final a4 = parse('A4').transpose(-2);
      final options = FingeringChart.of(t).optionsFor(a4);
      expect(options.map((o) => o.fingering.label), contains('3'));
      expect(options.first.fingering.label, '1-2');
    });

    test('out of range is empty', () {
      expect(FingeringChart.of(t).optionsFor(const Note(30)), isEmpty);
    });
  });

  group('trombone positions (concert)', () {
    const tb = Instrument.trombone;
    final expected = {
      'E2': '7', 'F2': '6', 'Bb2': '1', 'B2': '7', 'C3': '6', 'F3': '1', //
      'Ab3': '3', 'Bb3': '1', 'B3': '4', 'C4': '3', 'D4': '1', 'Eb4': '3',
      'F4': '1', 'G4': '4', 'A4': '2', 'Bb4': '1', 'C5': '1', 'D5': '1',
    };
    for (final MapEntry(key: note, value: pos) in expected.entries) {
      test('$note = $pos', () => expect(written(tb, note), pos));
    }

    test('F3 has the 6th position alternate', () {
      final options = FingeringChart.of(tb).optionsFor(parse('F3'));
      expect(options.map((o) => o.fingering.label), ['1', '6']);
    });
  });

  group('four-valve euphonium uses the 4th valve', () {
    const e = Instrument.euphoniumBassClef;
    final expected = {
      'B1': '1-2-3-4', 'C2': '1-3-4', 'D2': '1-2-4', 'Eb2': '1-4', //
      'E2': '2-4', 'F2': '4', 'Bb2': '0', 'C3': '4', 'Eb3': '1', 'F3': '0',
    };
    for (final MapEntry(key: note, value: f) in expected.entries) {
      test('$note = $f', () => expect(written(e, note), f));
    }
  });

  group('F horn (written pitch)', () {
    const h = Instrument.frenchHorn;
    final expected = {
      'C4': '0', 'E4': '0', 'G4': '0', 'Bb4': '1', 'C5': '0', 'D5': '0', //
      'E5': '0', 'F5': '1', 'G5': '0', 'A5': '1-2', 'C6': '0',
    };
    for (final MapEntry(key: note, value: f) in expected.entries) {
      test('$note = $f', () => expect(written(h, note), f));
    }
  });

  test('every instrument has a continuous chromatic range', () {
    for (final instrument in Instrument.values) {
      final chart = FingeringChart.of(instrument);
      expect(
        chart.notes.length,
        chart.highestMidi - chart.lowestMidi + 1,
        reason: instrument.name,
      );
    }
  });

  group('IntonationTip', () {
    IntonationTip? tip(Instrument i, String writtenLabel) {
      final concert = parse(writtenLabel).transpose(-i.writtenOffset);
      return IntonationTip.of(i, FingeringChart.of(i).optionsFor(concert)[0]);
    }

    test('trumpet low D (1-3) is sharp: pull the 3rd slide', () {
      final t = tip(Instrument.trumpet, 'D4')!;
      expect(t.sharp, isTrue);
      expect(t.cents, greaterThan(25));
      expect(t.cause, IntonationCause.valveCombination);
      expect(t.remedy, IntonationRemedy.extendSlide3);
    });

    test('trumpet low C# (1-2-3) pulls the 3rd slide', () {
      expect(
        tip(Instrument.trumpet, 'C#4')!.remedy,
        IntonationRemedy.extendSlide3,
      );
    });

    test('trumpet A4 (1-2) kicks the 1st slide', () {
      expect(
        tip(Instrument.trumpet, 'A4')!.remedy,
        IntonationRemedy.extendSlide1,
      );
    });

    test('trumpet open E5 (5th partial) is flat', () {
      final t = tip(Instrument.trumpet, 'E5')!;
      expect(t.sharp, isFalse);
      expect(t.cause, IntonationCause.partial);
      expect(t.remedy, IntonationRemedy.lipUp);
    });

    test('open G4 and C5 need no tip', () {
      expect(tip(Instrument.trumpet, 'G4'), isNull);
      expect(tip(Instrument.trumpet, 'C5'), isNull);
    });

    test('flugelhorn has no slide ring: lip down', () {
      expect(
        tip(Instrument.flugelhorn, 'D4')!.remedy,
        IntonationRemedy.lipDown,
      );
    });

    test('trombone D4 in 1st position is flat: lip up', () {
      expect(tip(Instrument.trombone, 'D4')!.remedy, IntonationRemedy.lipUp);
    });

    test('trombone C4 in 3rd position is flat: slide in', () {
      expect(tip(Instrument.trombone, 'C4')!.remedy, IntonationRemedy.slideIn);
    });

    test('horn sharp combos close the hand', () {
      expect(
        tip(Instrument.frenchHorn, 'D3')!.remedy, // 1-3
        IntonationRemedy.handClose,
      );
    });
  });
}
