import 'package:timezone/timezone.dart' as tz;

import '../../domain/location/location_service.dart';
import '../../domain/prayer/prayer_alarm_scheduler.dart';
import '../../domain/prayer/prayer_calculation_service.dart';

Future<List<PrayerAlarmEvent>> buildPrayerAlarmQueue({
  required PrayerCalculationService calculationService,
  required DeviceLocation location,
  required PrayerSchedule todaySchedule,
  required DateTime now,
  required String timeZoneId,
  required AsrMethod asrMethod,
  int days = 30,
}) async {
  if (days < 1) return const [];

  final zone = tz.getLocation(timeZoneId);
  final localNow = tz.TZDateTime.from(now, zone);
  final events = <PrayerAlarmEvent>[];
  const prayerOrder = [
    PrayerName.fajr,
    PrayerName.dhuhr,
    PrayerName.asr,
    PrayerName.maghrib,
    PrayerName.isha,
  ];

  for (var offset = 0; offset < days; offset++) {
    final date = tz.TZDateTime(
      zone,
      localNow.year,
      localNow.month,
      localNow.day + offset,
    );
    final schedule = offset == 0
        ? todaySchedule
        : await calculationService.calculate(
            PrayerCalculationRequest(
              latitude: location.latitude,
              longitude: location.longitude,
              date: date,
              timeZoneId: timeZoneId,
              asrMethod: asrMethod,
            ),
          );

    for (final prayer in prayerOrder) {
      final time = schedule.times[prayer]!;
      if (!time.isAfter(localNow)) continue;
      events.add(
        PrayerAlarmEvent(
          timestamp: time.millisecondsSinceEpoch,
          assetId: 'adhan',
          prayer: prayer.name,
        ),
      );
    }
  }
  return events;
}
