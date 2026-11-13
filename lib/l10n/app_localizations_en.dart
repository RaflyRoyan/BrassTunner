// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Brass Tuner';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get calibrationTitle => 'A4 calibration';

  @override
  String get calibrationHint =>
      'Reference frequency for A4. 440 Hz is standard; some orchestras use 442 Hz.';

  @override
  String get resetA4 => 'Reset to 440 Hz';

  @override
  String get decreaseA4 => 'Lower A4';

  @override
  String get increaseA4 => 'Raise A4';

  @override
  String a4Value(String hz) {
    return 'A4 = $hz Hz';
  }

  @override
  String get instrumentTitle => 'Instrument';

  @override
  String instrumentInKey(String name, String key) {
    return '$name ($key)';
  }

  @override
  String get concertKey => 'concert';

  @override
  String get instrumentTrumpet => 'Trumpet';

  @override
  String get instrumentFlugelhorn => 'Flugelhorn';

  @override
  String get instrumentBaritoneTrebleClef => 'Baritone (treble clef)';

  @override
  String get instrumentMellophone => 'Mellophone';

  @override
  String get instrumentFrenchHorn => 'Horn';

  @override
  String get instrumentAltoHorn => 'Alto horn';

  @override
  String get instrumentTrombone => 'Trombone';

  @override
  String get instrumentEuphoniumBassClef => 'Euphonium (bass clef)';

  @override
  String get instrumentTuba => 'Tuba';

  @override
  String get writtenLabel => 'Written';

  @override
  String concertValue(String note) {
    return 'Concert $note';
  }

  @override
  String get playANote => 'Play a note';

  @override
  String get startingMic => 'Starting microphone…';

  @override
  String get micPermissionDenied => 'Microphone permission denied';

  @override
  String get micPermissionHint =>
      'Brass Tuner needs the microphone to hear your notes. Audio is only processed on this device. If no permission dialog appears, enable the microphone for Brass Tuner in your device settings.';

  @override
  String get micError =>
      'The microphone could not be used. Make sure no other app is using it.';

  @override
  String get retry => 'Try again';

  @override
  String get tabTuner => 'Tuner';

  @override
  String get tabLongTone => 'Long tone';

  @override
  String get tabDrone => 'Drone';

  @override
  String get tabMetronome => 'Metronome';

  @override
  String get play => 'Play';

  @override
  String get stop => 'Stop';

  @override
  String get volume => 'Volume';

  @override
  String droneOctave(int octave) {
    return 'Octave $octave';
  }

  @override
  String get lowerOctave => 'Octave down';

  @override
  String get raiseOctave => 'Octave up';

  @override
  String get waveSine => 'Sine';

  @override
  String get waveSaw => 'Saw';

  @override
  String droneWritten(String note) {
    return 'Written $note';
  }

  @override
  String get droneFeedbackHint =>
      'While the drone plays through the speaker, the tuner hears it too. Use earphones to see your own intonation.';

  @override
  String droneChip(String note) {
    return 'Drone $note';
  }

  @override
  String get stopDrone => 'Stop drone';

  @override
  String get slower => 'Slower';

  @override
  String get faster => 'Faster';

  @override
  String get tapTempo => 'Tap tempo';

  @override
  String beatsPerBar(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count beats per bar',
      one: '1 beat per bar',
    );
    return '$_temp0';
  }

  @override
  String get fewerBeats => 'Fewer beats';

  @override
  String get moreBeats => 'More beats';

  @override
  String get longToneHint => 'Hold a note to start recording';

  @override
  String get longToneLive => 'Recording';

  @override
  String get longToneLast => 'Last note';

  @override
  String get statDuration => 'Duration';

  @override
  String get statMean => 'Average';

  @override
  String get statStability => 'Stability';

  @override
  String get statInTune => 'In tune (±5¢)';

  @override
  String secondsValue(String value) {
    return '$value s';
  }
}
