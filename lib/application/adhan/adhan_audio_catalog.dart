import '../../domain/adhan/adhan_playback_service.dart';
import '../../domain/prayer/prayer_calculation_service.dart';

abstract final class AdhanAudioCatalog {
  static AdhanAudio forPrayer(PrayerName prayer) => AdhanAudio(
    assetId: switch (prayer) {
      PrayerName.fajr => 'adhan',
      PrayerName.dhuhr => 'adhan',
      PrayerName.asr => 'adhan',
      PrayerName.maghrib => 'adhan',
      PrayerName.isha => 'adhan',
      PrayerName.sunrise => throw ArgumentError.value(
        prayer,
        'prayer',
        'Sunrise is not an adhan prayer.',
      ),
    },
  );
}
