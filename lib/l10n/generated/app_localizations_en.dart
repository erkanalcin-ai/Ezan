// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Ezan';

  @override
  String get appTagline => 'Every prayer time, a moment of peace.';

  @override
  String get countdownSuffix => 'left';

  @override
  String get prayerVerseQuote =>
      'Indeed, prayer has been decreed upon the believers at appointed times.';

  @override
  String get prayerVerseCitation => 'An-Nisa 4:103';

  @override
  String get homeTab => 'Prayer times';

  @override
  String get qiblaTab => 'Qibla';

  @override
  String get settingsTab => 'Settings';

  @override
  String get homeTitle => 'Prayer times';

  @override
  String get locationRequestExplanation =>
      'Use this device\'s location to calculate prayer times. Location is processed only on this device.';

  @override
  String get locationRequestButton => 'Use location';

  @override
  String get locationRefreshButton => 'Refresh location';

  @override
  String get locationLoading => 'Getting location…';

  @override
  String get locationPrivacyNote => 'Location is never sent to a server.';

  @override
  String locationCoordinates(Object latitude, Object longitude) {
    return 'Location: $latitude, $longitude';
  }

  @override
  String get locationPermissionDenied =>
      'Location permission was not granted. Allow it to view prayer times.';

  @override
  String get locationPermissionPermanentlyDenied =>
      'Location permission is off. Enable it for Ezan in device settings.';

  @override
  String get locationServicesDisabled =>
      'Device location is off. Turn on location services and try again.';

  @override
  String get locationUnavailable =>
      'Could not get a location fix. You can try again.';

  @override
  String get timeZoneUnavailable => 'The device time zone could not be read.';

  @override
  String get nextPrayerTitle => 'Next prayer';

  @override
  String timeRemaining(int hours, int minutes) {
    return '$hours hr $minutes min remaining';
  }

  @override
  String get fajrLabel => 'Fajr';

  @override
  String get sunriseLabel => 'Sunrise';

  @override
  String get dhuhrLabel => 'Dhuhr';

  @override
  String get asrLabel => 'Asr';

  @override
  String get maghribLabel => 'Maghrib';

  @override
  String get ishaLabel => 'Isha';

  @override
  String get qiblaTitle => 'Qibla';

  @override
  String get qiblaSectionTitle => 'Qibla';

  @override
  String get qiblaNorthReferenceDescription =>
      'Use the same north reference as your device compass for the Qibla direction.';

  @override
  String get trueNorth => 'True north';

  @override
  String get magneticNorth => 'Magnetic north';

  @override
  String get qiblaSubtitle => 'Direction to the Kaaba';

  @override
  String get qiblaDirectionStable => 'Direction steady';

  @override
  String get kaabaLabel => 'Kaaba';

  @override
  String get bearingUnavailable => '--°';

  @override
  String get qiblaLocationRequired =>
      'Location is needed to calculate the Qibla direction.';

  @override
  String get qiblaCalibrating => 'Waiting for the direction sensor to settle…';

  @override
  String get qiblaSensorUnavailable =>
      'Direction sensors are unavailable on this device.';

  @override
  String get qiblaSensorUnreliable =>
      'Hold the device steady for a reliable reading.';

  @override
  String qiblaBearingSemantics(int degrees) {
    return 'Qibla bearing $degrees degrees';
  }

  @override
  String get settingsTitle => 'Settings';

  @override
  String appVersionLabel(String version) {
    return 'Version $version';
  }

  @override
  String get calculationMethod => 'Calculation method';

  @override
  String get turkiyeCalculationApproximation =>
      'Türkiye method (Diyanet approximation; exact agreement with official times is not guaranteed).';

  @override
  String get asrMethod => 'Asr method';

  @override
  String get standardAsr => 'Standard';

  @override
  String get hanafiAsr => 'Hanafi';

  @override
  String get adhanAlarmTitle => 'Automatic adhan';

  @override
  String get adhanAlarmDescription =>
      'Schedule local prayer alarms. Exact alarm access is managed by Android and can be changed in system settings.';

  @override
  String get lockScreenPrayerStatusTitle => 'Prayer status on lock screen';

  @override
  String get lockScreenPrayerStatusDescription =>
      'Show the next prayer and countdown. Tap the speaker icon to mute the adhan while it plays.';

  @override
  String get notificationPermissionRequired =>
      'Allow Ezan notifications to show the lock-screen status.';

  @override
  String get exactAlarmPermissionNeeded =>
      'Allow exact alarms to schedule prayer-time playback.';

  @override
  String get prayerScheduleTitle => 'Today\'s prayer times';

  @override
  String get locationSectionTitle => 'Location';

  @override
  String get adhanSectionTitle => 'Adhan';

  @override
  String get playAdhan => 'Play adhan';

  @override
  String get muteAdhan => 'Mute';

  @override
  String get unmuteAdhan => 'Turn sound on';

  @override
  String get adhanPlaybackFailed => 'The adhan could not be played.';

  @override
  String get volumeTitle => 'Playback volume';

  @override
  String get appearanceTitle => 'Appearance';

  @override
  String get themeTitle => 'Theme';

  @override
  String get systemTheme => 'System';

  @override
  String get lightTheme => 'Light';

  @override
  String get darkTheme => 'Dark';

  @override
  String get languageTitle => 'Language';

  @override
  String get englishLanguage => 'English';

  @override
  String get turkishLanguage => 'Turkish';

  @override
  String get aboutTitle => 'About Ezan';

  @override
  String get aboutDescription => 'An offline-first prayer times and Qibla app.';

  @override
  String get updateNow => 'Update';
}
