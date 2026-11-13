import 'package:brass_tunner/core/pitch/note_mapper.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoteMapper at A4 = 440', () {
    final mapper = NoteMapper();

    final cases = {
      440.0: 'A4',
      58.27: 'B♭1',
      233.08: 'B♭3',
      466.16: 'B♭4',
      932.33: 'B♭5',
      261.63: 'C4',
      29.14: 'B♭0',
      41.20: 'E1',
    };
    for (final MapEntry(key: hz, value: label) in cases.entries) {
      test('$hz Hz → $label', () {
        final reading = mapper.fromFrequency(hz);
        expect(reading.note.label, label);
        expect(reading.cents.abs(), lessThan(1));
      });
    }

    test('cents are signed: sharp is positive, flat is negative', () {
      // 10 cents sharp and flat of A4.
      expect(mapper.fromFrequency(442.549).cents, closeTo(10, 0.01));
      expect(mapper.fromFrequency(437.466).cents, closeTo(-10, 0.01));
    });

    test('40 Hz is E♭1 about 49 cents sharp', () {
      final reading = mapper.fromFrequency(40);
      expect(reading.note.label, 'E♭1');
      expect(reading.cents, closeTo(48.68, 0.05));
    });

    test('frequencyOf is the inverse of fromFrequency', () {
      for (var midi = 20; midi < 100; midi++) {
        final f = mapper.frequencyOf(Note(midi));
        final reading = mapper.fromFrequency(f);
        expect(reading.note.midi, midi);
        expect(reading.cents, closeTo(0, 1e-9));
      }
    });

    test('rejects non-positive frequencies', () {
      expect(() => mapper.fromFrequency(0), throwsArgumentError);
      expect(() => mapper.fromFrequency(-1), throwsArgumentError);
      expect(() => mapper.fromFrequency(double.nan), throwsArgumentError);
    });
  });

  group('A4 calibration', () {
    test('440 Hz reads about 7.85 cents flat at A4 = 442', () {
      final reading = NoteMapper(a4: 442).fromFrequency(440);
      expect(reading.note.label, 'A4');
      expect(reading.cents, closeTo(-7.85, 0.01));
    });

    test('A4 frequency follows the reference', () {
      expect(NoteMapper(a4: 430).frequencyOf(const Note(69)), 430);
      expect(
        NoteMapper(a4: 450).frequencyOf(const Note(57)),
        closeTo(225, 1e-9),
      );
    });

    test('A4 outside 430–450 Hz is rejected', () {
      expect(() => NoteMapper(a4: 429), throwsRangeError);
      expect(() => NoteMapper(a4: 451), throwsRangeError);
    });
  });

  group('Note', () {
    test('flat and sharp spelling', () {
      expect(const Note(70).label, 'B♭4');
      expect(const Note(70, accidental: Accidental.sharp).label, 'A♯4');
      expect(const Note(63).name, 'E♭');
    });

    test('octave boundaries follow scientific pitch notation', () {
      expect(const Note(60).label, 'C4');
      expect(const Note(59).label, 'B3');
      expect(const Note(21).label, 'A0');
    });

    test('transpose shifts by semitones', () {
      // Concert B♭3 is written C4 on a B♭ trumpet (+2 semitones).
      expect(const Note(58).transpose(2).label, 'C4');
    });
  });
}
