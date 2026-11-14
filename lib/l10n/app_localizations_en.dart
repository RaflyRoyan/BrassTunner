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
  String get targetLabel => 'Target';

  @override
  String get chooseTarget => 'Choose target note';

  @override
  String get lowerSemitone => 'Down a semitone';

  @override
  String get raiseSemitone => 'Up a semitone';

  @override
  String get chartInput => 'Input (you)';

  @override
  String get chartOutput => 'Output (target)';

  @override
  String targetDiffCents(String value) {
    return 'vs target: $value¢';
  }

  @override
  String targetDiffSemitones(String value) {
    return 'vs target: $value semitones';
  }

  @override
  String get earphoneHint =>
      'Use earphones so the tuner does not hear the target tone.';

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
  String get meterSingle => 'Single meter';

  @override
  String get meterMulti => 'Multi meter';

  @override
  String segmentTitle(int index) {
    return 'Part $index';
  }

  @override
  String barsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bars',
      one: '1 bar',
    );
    return '$_temp0';
  }

  @override
  String get fewerBars => 'Fewer bars';

  @override
  String get moreBars => 'More bars';

  @override
  String get beatUnit => 'Beat unit';

  @override
  String get addSegment => 'Add part';

  @override
  String get removeSegment => 'Remove part';

  @override
  String programPosition(int part, String signature, int bar, int bars) {
    return 'Part $part · $signature · bar $bar/$bars';
  }

  @override
  String programSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bars in total',
      one: '1 bar in total',
    );
    return '$_temp0, then repeats without stopping. BPM counts beats.';
  }

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

  @override
  String get tabLipSlur => 'Lip slur';

  @override
  String get fingeringChartTitle => 'Fingering chart';

  @override
  String get fingeringOpen => 'Open';

  @override
  String slidePosition(int position) {
    return 'Position $position';
  }

  @override
  String fingeringValves(String valves) {
    return 'Valves $valves';
  }

  @override
  String fingeringAlternates(String list) {
    return 'Alt: $list';
  }

  @override
  String get outOfRange => 'Out of range for this instrument';

  @override
  String tendencySharp(int cents, String cause) {
    return 'Tends sharp ~$cents¢ ($cause)';
  }

  @override
  String tendencyFlat(int cents, String cause) {
    return 'Tends flat ~$cents¢ ($cause)';
  }

  @override
  String causeCombination(String fingering) {
    return '$fingering combination';
  }

  @override
  String causePartial(int partial) {
    return 'partial $partial';
  }

  @override
  String get remedyExtendSlide1 => 'Kick out the 1st valve slide.';

  @override
  String get remedyExtendSlide3 => 'Pull out the 3rd valve slide.';

  @override
  String get remedySlideOut => 'Place the slide slightly further out.';

  @override
  String get remedySlideIn => 'Place the slide slightly further in.';

  @override
  String get remedyHandClose => 'Cover the bell a little more with your hand.';

  @override
  String get remedyHandOpen => 'Open your hand in the bell a little.';

  @override
  String get remedyLipDown => 'Lip the note down slightly.';

  @override
  String get remedyLipUp => 'Lip the note up slightly.';

  @override
  String get tipDisclaimer =>
      'Tendencies are theoretical estimates; every instrument differs.';

  @override
  String get lipSlurHint =>
      'Slur between partials without changing the fingering. Hold each note briefly.';

  @override
  String get lipSlurFingering => 'Fingering';

  @override
  String lipSlurRange(int low, int high) {
    return 'Partials $low–$high';
  }

  @override
  String lipSlurTarget(String note) {
    return 'Play $note';
  }

  @override
  String lipSlurDone(String cents) {
    return 'Done! Average ±$cents¢';
  }

  @override
  String lipSlurMisses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count missed notes',
      one: '1 missed note',
      zero: 'No missed notes',
    );
    return '$_temp0';
  }

  @override
  String get restart => 'Restart';

  @override
  String get themeTitle => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get historyTitle => 'History & stats';

  @override
  String get historyEmpty =>
      'No practice sessions for this instrument yet. A session is saved automatically when the tuner, long tone or lip slur hears you play for at least 10 seconds.';

  @override
  String get historyLoadError => 'Could not load history.';

  @override
  String get statSessions => 'Sessions';

  @override
  String get statTotalTime => 'Total time';

  @override
  String get statMeanDeviation => 'Avg. deviation';

  @override
  String get mostSharpTitle => 'Most often sharp';

  @override
  String get mostFlatTitle => 'Most often flat';

  @override
  String get notEnoughData => 'Not enough data yet';

  @override
  String sharpShare(String percent, String cents) {
    return '$percent sharp · avg $cents';
  }

  @override
  String flatShare(String percent, String cents) {
    return '$percent flat · avg $cents';
  }

  @override
  String get sessionsTitle => 'Sessions';

  @override
  String sessionSummary(String duration, String cents, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count notes',
      one: '1 note',
    );
    return '$duration · ±$cents¢ · $_temp0';
  }

  @override
  String durationMinutes(int minutes, int seconds) {
    return '$minutes min $seconds s';
  }

  @override
  String durationHours(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String get deleteSession => 'Delete session';

  @override
  String get deleteAll => 'Delete all history';

  @override
  String get deleteAllConfirm =>
      'Delete every saved session? This cannot be undone.';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';
}
