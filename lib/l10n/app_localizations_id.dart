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
  String get targetLabel => 'Target';

  @override
  String get chooseTarget => 'Pilih nada target';

  @override
  String get lowerSemitone => 'Turun setengah nada';

  @override
  String get raiseSemitone => 'Naik setengah nada';

  @override
  String get chartInput => 'Input (Anda)';

  @override
  String get chartOutput => 'Output (target)';

  @override
  String targetDiffCents(String value) {
    return 'Selisih target: $value¢';
  }

  @override
  String targetDiffSemitones(String value) {
    return 'Selisih target: $value semiton';
  }

  @override
  String get earphoneHint =>
      'Pakai earphone agar tuner tidak ikut mendengar bunyi target.';

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
  String get meterSingle => 'Satu birama';

  @override
  String get meterMulti => 'Multi birama';

  @override
  String segmentTitle(int index) {
    return 'Bagian $index';
  }

  @override
  String barsCount(int count) {
    return '$count birama';
  }

  @override
  String get fewerBars => 'Kurangi birama';

  @override
  String get moreBars => 'Tambah birama';

  @override
  String get beatUnit => 'Nilai ketukan';

  @override
  String get addSegment => 'Tambah bagian';

  @override
  String get removeSegment => 'Hapus bagian';

  @override
  String programPosition(int part, String signature, int bar, int bars) {
    return 'Bagian $part · $signature · birama $bar/$bars';
  }

  @override
  String programSummary(int count) {
    return 'Total $count birama, lalu diulang dari awal tanpa berhenti. BPM dihitung per ketukan.';
  }

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

  @override
  String get tabLipSlur => 'Lip slur';

  @override
  String get fingeringChartTitle => 'Tabel penjarian';

  @override
  String get fingeringOpen => 'Terbuka';

  @override
  String slidePosition(int position) {
    return 'Posisi $position';
  }

  @override
  String fingeringValves(String valves) {
    return 'Valve $valves';
  }

  @override
  String fingeringAlternates(String list) {
    return 'Alt: $list';
  }

  @override
  String get outOfRange => 'Di luar jangkauan alat ini';

  @override
  String tendencySharp(int cents, String cause) {
    return 'Cenderung sharp ~$cents¢ ($cause)';
  }

  @override
  String tendencyFlat(int cents, String cause) {
    return 'Cenderung flat ~$cents¢ ($cause)';
  }

  @override
  String causeCombination(String fingering) {
    return 'kombinasi $fingering';
  }

  @override
  String causePartial(int partial) {
    return 'partial ke-$partial';
  }

  @override
  String get remedyExtendSlide1 => 'Tarik slide valve 1.';

  @override
  String get remedyExtendSlide3 => 'Tarik slide valve 3.';

  @override
  String get remedySlideOut => 'Posisikan slide sedikit lebih keluar.';

  @override
  String get remedySlideIn => 'Posisikan slide sedikit lebih ke dalam.';

  @override
  String get remedyHandClose => 'Tutup bell sedikit lebih rapat dengan tangan.';

  @override
  String get remedyHandOpen => 'Buka tangan di bell sedikit.';

  @override
  String get remedyLipDown => 'Turunkan sedikit dengan bibir dan udara.';

  @override
  String get remedyLipUp => 'Naikkan sedikit dengan bibir dan udara.';

  @override
  String get tipDisclaimer =>
      'Kecenderungan adalah perkiraan teoretis; tiap alat bisa berbeda.';

  @override
  String get lipSlurHint =>
      'Slur antar-partial tanpa mengganti penjarian. Tahan tiap nada sebentar.';

  @override
  String get lipSlurFingering => 'Penjarian';

  @override
  String lipSlurRange(int low, int high) {
    return 'Partial $low–$high';
  }

  @override
  String lipSlurTarget(String note) {
    return 'Mainkan $note';
  }

  @override
  String lipSlurDone(String cents) {
    return 'Selesai! Rata-rata ±$cents¢';
  }

  @override
  String lipSlurMisses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kali meleset',
      zero: 'Tidak ada nada meleset',
    );
    return '$_temp0';
  }

  @override
  String get restart => 'Ulangi';

  @override
  String get themeTitle => 'Tema';

  @override
  String get themeSystem => 'Sistem';

  @override
  String get themeLight => 'Terang';

  @override
  String get themeDark => 'Gelap';

  @override
  String get historyTitle => 'Riwayat & statistik';

  @override
  String get historyEmpty =>
      'Belum ada sesi latihan untuk alat ini. Sesi tersimpan otomatis saat tuner, nada panjang, atau lip slur mendengar Anda bermain minimal 10 detik.';

  @override
  String get historyLoadError => 'Riwayat tidak dapat dimuat.';

  @override
  String get statSessions => 'Sesi';

  @override
  String get statTotalTime => 'Total waktu';

  @override
  String get statMeanDeviation => 'Rata-rata deviasi';

  @override
  String get mostSharpTitle => 'Paling sering sharp';

  @override
  String get mostFlatTitle => 'Paling sering flat';

  @override
  String get notEnoughData => 'Belum cukup data';

  @override
  String sharpShare(String percent, String cents) {
    return '$percent sharp · rata-rata $cents';
  }

  @override
  String flatShare(String percent, String cents) {
    return '$percent flat · rata-rata $cents';
  }

  @override
  String get sessionsTitle => 'Sesi latihan';

  @override
  String sessionSummary(String duration, String cents, int count) {
    return '$duration · ±$cents¢ · $count nada';
  }

  @override
  String durationMinutes(int minutes, int seconds) {
    return '$minutes mnt $seconds dtk';
  }

  @override
  String durationHours(int hours, int minutes) {
    return '$hours j $minutes mnt';
  }

  @override
  String get deleteSession => 'Hapus sesi';

  @override
  String get deleteAll => 'Hapus semua riwayat';

  @override
  String get deleteAllConfirm =>
      'Hapus semua sesi yang tersimpan? Tindakan ini tidak bisa dibatalkan.';

  @override
  String get cancel => 'Batal';

  @override
  String get delete => 'Hapus';
}
