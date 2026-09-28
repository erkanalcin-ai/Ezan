import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_tr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('tr'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ezan'**
  String get appTitle;

  /// No description provided for @appTagline.
  ///
  /// In tr, this message translates to:
  /// **'Vakit, huzura davet.'**
  String get appTagline;

  /// No description provided for @countdownSuffix.
  ///
  /// In tr, this message translates to:
  /// **'kaldı'**
  String get countdownSuffix;

  /// No description provided for @prayerVerseQuote.
  ///
  /// In tr, this message translates to:
  /// **'Namaz, müminler üzerine vakitleri belirlenmiş bir farzdır.'**
  String get prayerVerseQuote;

  /// No description provided for @prayerVerseCitation.
  ///
  /// In tr, this message translates to:
  /// **'Nisâ 4:103'**
  String get prayerVerseCitation;

  /// No description provided for @homeTab.
  ///
  /// In tr, this message translates to:
  /// **'Vakitler'**
  String get homeTab;

  /// No description provided for @qiblaTab.
  ///
  /// In tr, this message translates to:
  /// **'Kıble'**
  String get qiblaTab;

  /// No description provided for @settingsTab.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTab;

  /// No description provided for @homeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Namaz vakitleri'**
  String get homeTitle;

  /// No description provided for @locationRequestExplanation.
  ///
  /// In tr, this message translates to:
  /// **'Namaz vakitlerini hesaplamak için cihaz konumunu kullan. Konum yalnızca bu cihazda işlenir.'**
  String get locationRequestExplanation;

  /// No description provided for @locationRequestButton.
  ///
  /// In tr, this message translates to:
  /// **'Konumu kullan'**
  String get locationRequestButton;

  /// No description provided for @locationRefreshButton.
  ///
  /// In tr, this message translates to:
  /// **'Konumu yenile'**
  String get locationRefreshButton;

  /// No description provided for @locationLoading.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınıyor…'**
  String get locationLoading;

  /// No description provided for @locationPrivacyNote.
  ///
  /// In tr, this message translates to:
  /// **'Konum bilgisi hiçbir sunucuya gönderilmez.'**
  String get locationPrivacyNote;

  /// No description provided for @locationCoordinates.
  ///
  /// In tr, this message translates to:
  /// **'Konum: {latitude}, {longitude}'**
  String locationCoordinates(Object latitude, Object longitude);

  /// No description provided for @locationPermissionDenied.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni verilmedi. Vakitleri görmek için izin vermen gerekir.'**
  String get locationPermissionDenied;

  /// No description provided for @locationPermissionPermanentlyDenied.
  ///
  /// In tr, this message translates to:
  /// **'Konum izni kapalı. Cihaz ayarlarından Ezan için konum iznini aç.'**
  String get locationPermissionPermanentlyDenied;

  /// No description provided for @locationServicesDisabled.
  ///
  /// In tr, this message translates to:
  /// **'Cihaz konumu kapalı. Konum servisini açıp tekrar dene.'**
  String get locationServicesDisabled;

  /// No description provided for @locationUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Konum alınamadı. Tekrar deneyebilirsin.'**
  String get locationUnavailable;

  /// No description provided for @timeZoneUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Cihazın saat dilimi okunamadı.'**
  String get timeZoneUnavailable;

  /// No description provided for @nextPrayerTitle.
  ///
  /// In tr, this message translates to:
  /// **'Sıradaki namaz'**
  String get nextPrayerTitle;

  /// No description provided for @timeRemaining.
  ///
  /// In tr, this message translates to:
  /// **'{hours} sa {minutes} dk kaldı'**
  String timeRemaining(int hours, int minutes);

  /// No description provided for @fajrLabel.
  ///
  /// In tr, this message translates to:
  /// **'İmsak'**
  String get fajrLabel;

  /// No description provided for @sunriseLabel.
  ///
  /// In tr, this message translates to:
  /// **'Güneş'**
  String get sunriseLabel;

  /// No description provided for @dhuhrLabel.
  ///
  /// In tr, this message translates to:
  /// **'Öğle'**
  String get dhuhrLabel;

  /// No description provided for @asrLabel.
  ///
  /// In tr, this message translates to:
  /// **'İkindi'**
  String get asrLabel;

  /// No description provided for @maghribLabel.
  ///
  /// In tr, this message translates to:
  /// **'Akşam'**
  String get maghribLabel;

  /// No description provided for @ishaLabel.
  ///
  /// In tr, this message translates to:
  /// **'Yatsı'**
  String get ishaLabel;

  /// No description provided for @qiblaTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kıble'**
  String get qiblaTitle;

  /// No description provided for @qiblaSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kıble'**
  String get qiblaSectionTitle;

  /// No description provided for @qiblaNorthReferenceDescription.
  ///
  /// In tr, this message translates to:
  /// **'Kıble yönünü cihaz pusulanla aynı kuzey referansında göster.'**
  String get qiblaNorthReferenceDescription;

  /// No description provided for @trueNorth.
  ///
  /// In tr, this message translates to:
  /// **'Gerçek kuzey'**
  String get trueNorth;

  /// No description provided for @magneticNorth.
  ///
  /// In tr, this message translates to:
  /// **'Manyetik kuzey'**
  String get magneticNorth;

  /// No description provided for @qiblaSubtitle.
  ///
  /// In tr, this message translates to:
  /// **'Kâbe yönü'**
  String get qiblaSubtitle;

  /// No description provided for @qiblaDirectionStable.
  ///
  /// In tr, this message translates to:
  /// **'Yön sabit'**
  String get qiblaDirectionStable;

  /// No description provided for @kaabaLabel.
  ///
  /// In tr, this message translates to:
  /// **'Kâbe'**
  String get kaabaLabel;

  /// No description provided for @bearingUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'--°'**
  String get bearingUnavailable;

  /// No description provided for @qiblaLocationRequired.
  ///
  /// In tr, this message translates to:
  /// **'Kıble yönünü hesaplamak için önce konum gerekir.'**
  String get qiblaLocationRequired;

  /// No description provided for @qiblaCalibrating.
  ///
  /// In tr, this message translates to:
  /// **'Yön sensörü kararlı hâle geliyor…'**
  String get qiblaCalibrating;

  /// No description provided for @qiblaSensorUnavailable.
  ///
  /// In tr, this message translates to:
  /// **'Bu cihazda yön sensörleri kullanılamıyor.'**
  String get qiblaSensorUnavailable;

  /// No description provided for @qiblaSensorUnreliable.
  ///
  /// In tr, this message translates to:
  /// **'Daha doğru ölçüm için cihazı sabit tut.'**
  String get qiblaSensorUnreliable;

  /// No description provided for @qiblaBearingSemantics.
  ///
  /// In tr, this message translates to:
  /// **'Kıble açısı {degrees} derece'**
  String qiblaBearingSemantics(int degrees);

  /// No description provided for @settingsTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ayarlar'**
  String get settingsTitle;

  /// No description provided for @appVersionLabel.
  ///
  /// In tr, this message translates to:
  /// **'Sürüm {version}'**
  String appVersionLabel(String version);

  /// No description provided for @calculationMethod.
  ///
  /// In tr, this message translates to:
  /// **'Hesaplama yöntemi'**
  String get calculationMethod;

  /// No description provided for @turkiyeCalculationApproximation.
  ///
  /// In tr, this message translates to:
  /// **'Türkiye yöntemi (Diyanet yaklaşımı; resmi vakitlerle birebir aynı olduğu garanti edilmez).'**
  String get turkiyeCalculationApproximation;

  /// No description provided for @asrMethod.
  ///
  /// In tr, this message translates to:
  /// **'İkindi hesabı'**
  String get asrMethod;

  /// No description provided for @standardAsr.
  ///
  /// In tr, this message translates to:
  /// **'Standart'**
  String get standardAsr;

  /// No description provided for @hanafiAsr.
  ///
  /// In tr, this message translates to:
  /// **'Hanefi'**
  String get hanafiAsr;

  /// No description provided for @adhanAlarmTitle.
  ///
  /// In tr, this message translates to:
  /// **'Otomatik ezan'**
  String get adhanAlarmTitle;

  /// No description provided for @adhanAlarmDescription.
  ///
  /// In tr, this message translates to:
  /// **'Namaz vakitleri için yerel alarmları planla. Kesin alarm izni Android tarafından yönetilir ve sistem ayarlarından değiştirilebilir.'**
  String get adhanAlarmDescription;

  /// No description provided for @lockScreenPrayerStatusTitle.
  ///
  /// In tr, this message translates to:
  /// **'Kilit ekranında namaz vakti'**
  String get lockScreenPrayerStatusTitle;

  /// No description provided for @lockScreenPrayerStatusDescription.
  ///
  /// In tr, this message translates to:
  /// **'Sıradaki namazı ve geri sayımı göster. Ezan okunurken simgeye dokunarak sesi kıs.'**
  String get lockScreenPrayerStatusDescription;

  /// No description provided for @notificationPermissionRequired.
  ///
  /// In tr, this message translates to:
  /// **'Kilit ekranı durumunu göstermek için Ezan bildirim iznini aç.'**
  String get notificationPermissionRequired;

  /// No description provided for @exactAlarmPermissionNeeded.
  ///
  /// In tr, this message translates to:
  /// **'Namaz vakti sesini planlamak için kesin alarm izni ver.'**
  String get exactAlarmPermissionNeeded;

  /// No description provided for @prayerScheduleTitle.
  ///
  /// In tr, this message translates to:
  /// **'Bugünün namaz vakitleri'**
  String get prayerScheduleTitle;

  /// No description provided for @locationSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Konum'**
  String get locationSectionTitle;

  /// No description provided for @adhanSectionTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ezan'**
  String get adhanSectionTitle;

  /// No description provided for @playAdhan.
  ///
  /// In tr, this message translates to:
  /// **'Ezan\'ı çal'**
  String get playAdhan;

  /// No description provided for @muteAdhan.
  ///
  /// In tr, this message translates to:
  /// **'Sessize al'**
  String get muteAdhan;

  /// No description provided for @unmuteAdhan.
  ///
  /// In tr, this message translates to:
  /// **'Sesi aç'**
  String get unmuteAdhan;

  /// No description provided for @adhanPlaybackFailed.
  ///
  /// In tr, this message translates to:
  /// **'Ezan çalınamadı.'**
  String get adhanPlaybackFailed;

  /// No description provided for @volumeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Çalma düzeyi'**
  String get volumeTitle;

  /// No description provided for @appearanceTitle.
  ///
  /// In tr, this message translates to:
  /// **'Görünüm'**
  String get appearanceTitle;

  /// No description provided for @themeTitle.
  ///
  /// In tr, this message translates to:
  /// **'Tema'**
  String get themeTitle;

  /// No description provided for @systemTheme.
  ///
  /// In tr, this message translates to:
  /// **'Sistemle aynı'**
  String get systemTheme;

  /// No description provided for @lightTheme.
  ///
  /// In tr, this message translates to:
  /// **'Açık'**
  String get lightTheme;

  /// No description provided for @darkTheme.
  ///
  /// In tr, this message translates to:
  /// **'Koyu'**
  String get darkTheme;

  /// No description provided for @languageTitle.
  ///
  /// In tr, this message translates to:
  /// **'Dil'**
  String get languageTitle;

  /// No description provided for @englishLanguage.
  ///
  /// In tr, this message translates to:
  /// **'İngilizce'**
  String get englishLanguage;

  /// No description provided for @turkishLanguage.
  ///
  /// In tr, this message translates to:
  /// **'Türkçe'**
  String get turkishLanguage;

  /// No description provided for @aboutTitle.
  ///
  /// In tr, this message translates to:
  /// **'Ezan hakkında'**
  String get aboutTitle;

  /// No description provided for @aboutDescription.
  ///
  /// In tr, this message translates to:
  /// **'Çevrimdışı öncelikli namaz vakitleri ve kıble uygulaması.'**
  String get aboutDescription;

  /// No description provided for @updateNow.
  ///
  /// In tr, this message translates to:
  /// **'Güncelle'**
  String get updateNow;
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
      <String>['en', 'tr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'tr':
      return AppLocalizationsTr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
