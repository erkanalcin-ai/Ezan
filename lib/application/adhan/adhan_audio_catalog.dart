import '../../domain/adhan/adhan_playback_service.dart';
import '../../domain/prayer/prayer_calculation_service.dart';

abstract final class AdhanAudioCatalog {
  static AdhanAudio forPrayer(PrayerName prayer) => AdhanAudio(
    assetId: switch (prayer) {
      PrayerName.fajr => 'adhan_fajr',
      PrayerName.dhuhr => 'adhan_dhuhr',
      PrayerName.asr => 'adhan_asr',
      PrayerName.maghrib => 'adhan_maghrib',
      PrayerName.isha => 'adhan_isha',
      PrayerName.sunrise => throw ArgumentError.value(
        prayer,
        'prayer',
        'Sunrise is not an adhan prayer.',
      ),
    },
  );
}
