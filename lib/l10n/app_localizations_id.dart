// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get appTitle => 'Brass Tuner';

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get calibrationTitle => 'Kalibrasi A4';

  @override
  String get calibrationHint =>
      'Frekuensi referensi nada A4. Standar umum 440 Hz; beberapa orkestra memakai 442 Hz.';

  @override
  String get resetA4 => 'Kembalikan ke 440 Hz';

  @override
  String get decreaseA4 => 'Turunkan A4';

  @override
  String get increaseA4 => 'Naikkan A4';

  @override
  String a4Value(String hz) {
    return 'A4 = $hz Hz';
  }

  @override
  String get instrumentTitle => 'Alat musik';

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
  String get instrumentBaritoneTrebleClef => 'Bariton (kunci G)';

  @override
  String get instrumentMellophone => 'Mellophone';

  @override
  String get instrumentFrenchHorn => 'Horn';

  @override
  String get instrumentAltoHorn => 'Alto horn';

  @override
  String get instrumentTrombone => 'Trombon';

  @override
  String get instrumentEuphoniumBassClef => 'Euphonium (kunci F)';

  @override
  String get instrumentTuba => 'Tuba';

  @override
  String get writtenLabel => 'Tertulis';

  @override
  String concertValue(String note) {
    return 'Concert $note';
  }

  @override
  String get playANote => 'Mainkan sebuah nada';

  @override
  String get startingMic => 'Menyiapkan mikrofon…';

  @override
  String get micPermissionDenied => 'Izin mikrofon ditolak';

  @override
  String get micPermissionHint =>
      'Brass Tuner perlu mikrofon untuk mendengar nada Anda. Audio hanya diproses di perangkat ini. Jika dialog izin tidak muncul, aktifkan mikrofon untuk Brass Tuner di Pengaturan perangkat.';

  @override
  String get micError =>
      'Mikrofon tidak dapat digunakan. Pastikan tidak sedang dipakai aplikasi lain.';

  @override
  String get retry => 'Coba lagi';

  @override
  String get tabTuner => 'Tuner';

  @override
  String get tabLongTone => 'Nada panjang';

  @override
  String get tabDrone => 'Drone';

  @override
  String get tabMetronome => 'Metronom';

  @override
  String get play => 'Mainkan';

  @override
  String get stop => 'Hentikan';

  @override
  String get volume => 'Volume';

  @override
  String droneOctave(int octave) {
    return 'Oktaf $octave';
  }

  @override
  String get lowerOctave => 'Turunkan oktaf';

  @override
  String get raiseOctave => 'Naikkan oktaf';

  @override
  String get waveSine => 'Sinus';

  @override
  String get waveSaw => 'Gergaji';

  @override
  String droneWritten(String note) {
    return 'Tertulis $note';
  }

  @override
  String get droneFeedbackHint =>
      'Saat drone berbunyi dari speaker, tuner ikut mendengarnya. Pakai earphone jika ingin melihat intonasi Anda sendiri.';

  @override
  String droneChip(String note) {
    return 'Drone $note';
  }

  @override
  String get stopDrone => 'Hentikan drone';

  @override
  String get slower => 'Lebih lambat';

  @override
  String get faster => 'Lebih cepat';

  @override
  String get tapTempo => 'Ketuk tempo';

  @override
  String beatsPerBar(int count) {
    return '$count ketukan per birama';
  }

  @override
  String get fewerBeats => 'Kurangi ketukan';

  @override
  String get moreBeats => 'Tambah ketukan';

  @override
  String get longToneHint => 'Tahan sebuah nada untuk mulai merekam';

  @override
  String get longToneLive => 'Merekam';

  @override
  String get longToneLast => 'Nada terakhir';

  @override
  String get statDuration => 'Durasi';

  @override
  String get statMean => 'Rata-rata';

  @override
  String get statStability => 'Kestabilan';

  @override
  String get statInTune => 'Tepat (±5¢)';

  @override
  String secondsValue(String value) {
    return '$value dtk';
  }
}
