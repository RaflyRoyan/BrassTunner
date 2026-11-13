import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// Nama aplikasi
  ///
  /// In id, this message translates to:
  /// **'Brass Tuner'**
  String get appTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In id, this message translates to:
  /// **'Pengaturan'**
  String get settingsTitle;

  /// No description provided for @calibrationTitle.
  ///
  /// In id, this message translates to:
  /// **'Kalibrasi A4'**
  String get calibrationTitle;

  /// No description provided for @calibrationHint.
  ///
  /// In id, this message translates to:
  /// **'Frekuensi referensi nada A4. Standar umum 440 Hz; beberapa orkestra memakai 442 Hz.'**
  String get calibrationHint;

  /// No description provided for @resetA4.
  ///
  /// In id, this message translates to:
  /// **'Kembalikan ke 440 Hz'**
  String get resetA4;

  /// No description provided for @decreaseA4.
  ///
  /// In id, this message translates to:
  /// **'Turunkan A4'**
  String get decreaseA4;

  /// No description provided for @increaseA4.
  ///
  /// In id, this message translates to:
  /// **'Naikkan A4'**
  String get increaseA4;

  /// No description provided for @a4Value.
  ///
  /// In id, this message translates to:
  /// **'A4 = {hz} Hz'**
  String a4Value(String hz);

  /// No description provided for @instrumentTitle.
  ///
  /// In id, this message translates to:
  /// **'Alat musik'**
  String get instrumentTitle;

  /// Nama alat dan nada dasarnya, mis. Trumpet (B♭)
  ///
  /// In id, this message translates to:
  /// **'{name} ({key})'**
  String instrumentInKey(String name, String key);

  /// Label untuk alat yang tidak transposisi
  ///
  /// In id, this message translates to:
  /// **'concert'**
  String get concertKey;

  /// No description provided for @instrumentTrumpet.
  ///
  /// In id, this message translates to:
  /// **'Trumpet'**
  String get instrumentTrumpet;

  /// No description provided for @instrumentFlugelhorn.
  ///
  /// In id, this message translates to:
  /// **'Flugelhorn'**
  String get instrumentFlugelhorn;

  /// No description provided for @instrumentBaritoneTrebleClef.
  ///
  /// In id, this message translates to:
  /// **'Bariton (kunci G)'**
  String get instrumentBaritoneTrebleClef;

  /// No description provided for @instrumentMellophone.
  ///
  /// In id, this message translates to:
  /// **'Mellophone'**
  String get instrumentMellophone;

  /// No description provided for @instrumentFrenchHorn.
  ///
  /// In id, this message translates to:
  /// **'Horn'**
  String get instrumentFrenchHorn;

  /// No description provided for @instrumentAltoHorn.
  ///
  /// In id, this message translates to:
  /// **'Alto horn'**
  String get instrumentAltoHorn;

  /// No description provided for @instrumentTrombone.
  ///
  /// In id, this message translates to:
  /// **'Trombon'**
  String get instrumentTrombone;

  /// No description provided for @instrumentEuphoniumBassClef.
  ///
  /// In id, this message translates to:
  /// **'Euphonium (kunci F)'**
  String get instrumentEuphoniumBassClef;

  /// No description provided for @instrumentTuba.
  ///
  /// In id, this message translates to:
  /// **'Tuba'**
  String get instrumentTuba;

  /// Nada yang dibaca pemain alat transposisi
  ///
  /// In id, this message translates to:
  /// **'Tertulis'**
  String get writtenLabel;

  /// No description provided for @concertValue.
  ///
  /// In id, this message translates to:
  /// **'Concert {note}'**
  String concertValue(String note);

  /// No description provided for @playANote.
  ///
  /// In id, this message translates to:
  /// **'Mainkan sebuah nada'**
  String get playANote;

  /// No description provided for @startingMic.
  ///
  /// In id, this message translates to:
  /// **'Menyiapkan mikrofon…'**
  String get startingMic;

  /// No description provided for @micPermissionDenied.
  ///
  /// In id, this message translates to:
  /// **'Izin mikrofon ditolak'**
  String get micPermissionDenied;

  /// No description provided for @micPermissionHint.
  ///
  /// In id, this message translates to:
  /// **'Brass Tuner perlu mikrofon untuk mendengar nada Anda. Audio hanya diproses di perangkat ini. Jika dialog izin tidak muncul, aktifkan mikrofon untuk Brass Tuner di Pengaturan perangkat.'**
  String get micPermissionHint;

  /// No description provided for @micError.
  ///
  /// In id, this message translates to:
  /// **'Mikrofon tidak dapat digunakan. Pastikan tidak sedang dipakai aplikasi lain.'**
  String get micError;

  /// No description provided for @retry.
  ///
  /// In id, this message translates to:
  /// **'Coba lagi'**
  String get retry;

  /// No description provided for @tabTuner.
  ///
  /// In id, this message translates to:
  /// **'Tuner'**
  String get tabTuner;

  /// No description provided for @tabLongTone.
  ///
  /// In id, this message translates to:
  /// **'Nada panjang'**
  String get tabLongTone;

  /// No description provided for @tabDrone.
  ///
  /// In id, this message translates to:
  /// **'Drone'**
  String get tabDrone;

  /// No description provided for @tabMetronome.
  ///
  /// In id, this message translates to:
  /// **'Metronom'**
  String get tabMetronome;

  /// No description provided for @play.
  ///
  /// In id, this message translates to:
  /// **'Mainkan'**
  String get play;

  /// No description provided for @stop.
  ///
  /// In id, this message translates to:
  /// **'Hentikan'**
  String get stop;

  /// No description provided for @volume.
  ///
  /// In id, this message translates to:
  /// **'Volume'**
  String get volume;

  /// No description provided for @droneOctave.
  ///
  /// In id, this message translates to:
  /// **'Oktaf {octave}'**
  String droneOctave(int octave);

  /// No description provided for @lowerOctave.
  ///
  /// In id, this message translates to:
  /// **'Turunkan oktaf'**
  String get lowerOctave;

  /// No description provided for @raiseOctave.
  ///
  /// In id, this message translates to:
  /// **'Naikkan oktaf'**
  String get raiseOctave;

  /// No description provided for @waveSine.
  ///
  /// In id, this message translates to:
  /// **'Sinus'**
  String get waveSine;

  /// No description provided for @waveSaw.
  ///
  /// In id, this message translates to:
  /// **'Gergaji'**
  String get waveSaw;

  /// No description provided for @droneWritten.
  ///
  /// In id, this message translates to:
  /// **'Tertulis {note}'**
  String droneWritten(String note);

  /// No description provided for @droneFeedbackHint.
  ///
  /// In id, this message translates to:
  /// **'Saat drone berbunyi dari speaker, tuner ikut mendengarnya. Pakai earphone jika ingin melihat intonasi Anda sendiri.'**
  String get droneFeedbackHint;

  /// No description provided for @droneChip.
  ///
  /// In id, this message translates to:
  /// **'Drone {note}'**
  String droneChip(String note);

  /// No description provided for @stopDrone.
  ///
  /// In id, this message translates to:
  /// **'Hentikan drone'**
  String get stopDrone;

  /// No description provided for @slower.
  ///
  /// In id, this message translates to:
  /// **'Lebih lambat'**
  String get slower;

  /// No description provided for @faster.
  ///
  /// In id, this message translates to:
  /// **'Lebih cepat'**
  String get faster;

  /// No description provided for @tapTempo.
  ///
  /// In id, this message translates to:
  /// **'Ketuk tempo'**
  String get tapTempo;

  /// No description provided for @beatsPerBar.
  ///
  /// In id, this message translates to:
  /// **'{count} ketukan per birama'**
  String beatsPerBar(int count);

  /// No description provided for @fewerBeats.
  ///
  /// In id, this message translates to:
  /// **'Kurangi ketukan'**
  String get fewerBeats;

  /// No description provided for @moreBeats.
  ///
  /// In id, this message translates to:
  /// **'Tambah ketukan'**
  String get moreBeats;

  /// No description provided for @longToneHint.
  ///
  /// In id, this message translates to:
  /// **'Tahan sebuah nada untuk mulai merekam'**
  String get longToneHint;

  /// No description provided for @longToneLive.
  ///
  /// In id, this message translates to:
  /// **'Merekam'**
  String get longToneLive;

  /// No description provided for @longToneLast.
  ///
  /// In id, this message translates to:
  /// **'Nada terakhir'**
  String get longToneLast;

  /// No description provided for @statDuration.
  ///
  /// In id, this message translates to:
  /// **'Durasi'**
  String get statDuration;

  /// No description provided for @statMean.
  ///
  /// In id, this message translates to:
  /// **'Rata-rata'**
  String get statMean;

  /// No description provided for @statStability.
  ///
  /// In id, this message translates to:
  /// **'Kestabilan'**
  String get statStability;

  /// No description provided for @statInTune.
  ///
  /// In id, this message translates to:
  /// **'Tepat (±5¢)'**
  String get statInTune;

  /// No description provided for @secondsValue.
  ///
  /// In id, this message translates to:
  /// **'{value} dtk'**
  String secondsValue(String value);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
