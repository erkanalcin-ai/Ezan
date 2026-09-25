// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Ezan';

  @override
  String get appTagline => 'Vakit, huzura davet.';

  @override
  String get countdownSuffix => 'kaldı';

  @override
  String get prayerVerseQuote =>
      'Namaz, müminler üzerine vakitleri belirlenmiş bir farzdır.';

  @override
  String get prayerVerseCitation => 'Nisâ 4:103';

  @override
  String get homeTab => 'Vakitler';

  @override
  String get qiblaTab => 'Kıble';

  @override
  String get settingsTab => 'Ayarlar';

  @override
  String get homeTitle => 'Namaz vakitleri';

  @override
  String get locationRequestExplanation =>
      'Namaz vakitlerini hesaplamak için cihaz konumunu kullan. Konum yalnızca bu cihazda işlenir.';

  @override
  String get locationRequestButton => 'Konumu kullan';

  @override
  String get locationRefreshButton => 'Konumu yenile';

  @override
  String get locationLoading => 'Konum alınıyor…';

  @override
  String get locationPrivacyNote =>
      'Konum bilgisi hiçbir sunucuya gönderilmez.';

  @override
  String locationCoordinates(Object latitude, Object longitude) {
    return 'Konum: $latitude, $longitude';
  }

  @override
  String get locationPermissionDenied =>
      'Konum izni verilmedi. Vakitleri görmek için izin vermen gerekir.';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Konum izni kapalı. Cihaz ayarlarından Ezan için konum iznini aç.';

  @override
  String get locationServicesDisabled =>
      'Cihaz konumu kapalı. Konum servisini açıp tekrar dene.';

  @override
  String get locationUnavailable => 'Konum alınamadı. Tekrar deneyebilirsin.';

  @override
  String get timeZoneUnavailable => 'Cihazın saat dilimi okunamadı.';

  @override
  String get nextPrayerTitle => 'Sıradaki namaz';

  @override
  String timeRemaining(int hours, int minutes) {
    return '$hours sa $minutes dk kaldı';
  }

  @override
  String get fajrLabel => 'İmsak';

  @override
  String get sunriseLabel => 'Güneş';

  @override
  String get dhuhrLabel => 'Öğle';

  @override
  String get asrLabel => 'İkindi';

  @override
  String get maghribLabel => 'Akşam';

  @override
  String get ishaLabel => 'Yatsı';

  @override
  String get qiblaTitle => 'Kıble';

  @override
  String get qiblaSectionTitle => 'Kıble';

  @override
  String get qiblaNorthReferenceDescription =>
      'Kıble yönünü cihaz pusulanla aynı kuzey referansında göster.';

  @override
  String get trueNorth => 'Gerçek kuzey';

  @override
  String get magneticNorth => 'Manyetik kuzey';

  @override
  String get qiblaSubtitle => 'Kâbe yönü';

  @override
  String get qiblaDirectionStable => 'Yön sabit';

  @override
  String get kaabaLabel => 'Kâbe';

  @override
  String get bearingUnavailable => '--°';

  @override
  String get qiblaLocationRequired =>
      'Kıble yönünü hesaplamak için önce konum gerekir.';

  @override
  String get qiblaCalibrating => 'Yön sensörü kararlı hâle geliyor…';

  @override
  String get qiblaSensorUnavailable =>
      'Bu cihazda yön sensörleri kullanılamıyor.';

  @override
  String get qiblaSensorUnreliable => 'Daha doğru ölçüm için cihazı sabit tut.';

  @override
  String qiblaBearingSemantics(int degrees) {
    return 'Kıble açısı $degrees derece';
  }

  @override
  String get settingsTitle => 'Ayarlar';

  @override
  String appVersionLabel(String version) {
    return 'Sürüm $version';
  }

  @override
  String get calculationMethod => 'Hesaplama yöntemi';

  @override
  String get turkiyeCalculationApproximation =>
      'Türkiye yöntemi (Diyanet yaklaşımı; resmi vakitlerle birebir aynı olduğu garanti edilmez).';

  @override
  String get asrMethod => 'İkindi hesabı';

  @override
  String get standardAsr => 'Standart';

  @override
  String get hanafiAsr => 'Hanefi';

  @override
  String get placeholderAudioNotice =>
      'Yalnızca geliştirme testi: geçici, sözsüz ses. Gerçek ezan kaydı değildir.';

  @override
  String get playPlaceholderAudio => 'Test sesini çal';

  @override
  String get stopAudio => 'Durdur';

  @override
  String get audioPlaybackFailed => 'Yerel test sesi çalınamadı.';

  @override
  String get adhanAlarmTitle => 'Otomatik ezan';

  @override
  String get adhanAlarmDescription =>
      'Namaz vakitleri için yerel alarmları planla. Kesin alarm izni Android tarafından yönetilir ve sistem ayarlarından değiştirilebilir.';

  @override
  String get exactAlarmPermissionNeeded =>
      'Namaz vakti sesini planlamak için kesin alarm izni ver.';

  @override
  String get prayerScheduleTitle => 'Bugünün namaz vakitleri';

  @override
  String get locationSectionTitle => 'Konum';

  @override
  String get adhanSectionTitle => 'Ezan';

  @override
  String get playAdhan => 'Ezan\'ı çal';

  @override
  String get muteAdhan => 'Sessize al';

  @override
  String get unmuteAdhan => 'Sesi aç';

  @override
  String get adhanPlaybackFailed => 'Ezan çalınamadı.';

  @override
  String get volumeTitle => 'Çalma düzeyi';

  @override
  String get appearanceTitle => 'Görünüm';

  @override
  String get themeTitle => 'Tema';

  @override
  String get systemTheme => 'Sistemle aynı';

  @override
  String get lightTheme => 'Açık';

  @override
  String get darkTheme => 'Koyu';

  @override
  String get languageTitle => 'Dil';

  @override
  String get englishLanguage => 'İngilizce';

  @override
  String get turkishLanguage => 'Türkçe';

  @override
  String get aboutTitle => 'Ezan hakkında';

  @override
  String get aboutDescription =>
      'Çevrimdışı öncelikli namaz vakitleri ve kıble uygulaması.';

  @override
  String get updateNow => 'Güncelle';
}
