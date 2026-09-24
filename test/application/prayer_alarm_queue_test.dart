import 'package:ezan/application/prayer/prayer_alarm_queue.dart';
import 'package:ezan/domain/location/location_service.dart';
import 'package:ezan/domain/prayer/prayer_calculation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test('queue covers local day 1 through day 30 and excludes day 31', () async {
    const zoneId = 'Europe/Istanbul';
    final zone = tz.getLocation(zoneId);
    final now = tz.TZDateTime(zone, 2026, 9, 1, 0, 1);
    final engine = _FixturePrayerCalculationService();
    const location = DeviceLocation(latitude: 41.0082, longitude: 28.9784);
    final today = await _calculate(engine, location, now, zoneId);

    final events = await buildPrayerAlarmQueue(
      calculationService: engine,
      location: location,
      todaySchedule: today,
      now: now,
      timeZoneId: zoneId,
      asrMethod: AsrMethod.standard,
    );

    expect(events, hasLength(150));
    expect(events.first.prayer, PrayerName.fajr.name);
    expect(
      events.first.timestamp,
      today.times[PrayerName.fajr]!.millisecondsSinceEpoch,
    );

    final day30 = await _calculate(
      engine,
      location,
      tz.TZDateTime(zone, 2026, 9, 30),
      zoneId,
    );
    expect(events.last.prayer, PrayerName.isha.name);
    expect(
      events.last.timestamp,
      day30.times[PrayerName.isha]!.millisecondsSinceEpoch,
    );

    final day31 = await _calculate(
      engine,
      location,
      tz.TZDateTime(zone, 2026, 10, 1),
      zoneId,
    );
    expect(
      events.any(
        (event) =>
            event.timestamp ==
            day31.times[PrayerName.fajr]!.millisecondsSinceEpoch,
      ),
      isFalse,
    );
  });

  test(
    'timezone, location and Asr inputs are used when rebuilding the queue',
    () async {
      final engine = _FixturePrayerCalculationService();
      final istanbul = tz.getLocation('Europe/Istanbul');
      final now = tz.TZDateTime(istanbul, 2026, 9, 1, 0, 1);
      const location = DeviceLocation(latitude: 39.9334, longitude: 32.8597);
      final today = await _calculate(
        engine,
        location,
        now,
        'Europe/Istanbul',
        asrMethod: AsrMethod.hanafi,
      );

      final events = await buildPrayerAlarmQueue(
        calculationService: engine,
        location: location,
        todaySchedule: today,
        now: now,
        timeZoneId: 'Europe/Istanbul',
        asrMethod: AsrMethod.hanafi,
      );

      expect(engine.requests.skip(1), isNotEmpty);
      expect(
        engine.requests
            .skip(1)
            .every(
              (request) =>
                  request.latitude == location.latitude &&
                  request.longitude == location.longitude &&
                  request.timeZoneId == 'Europe/Istanbul' &&
                  request.asrMethod == AsrMethod.hanafi,
            ),
        isTrue,
      );
      expect(events[2].prayer, PrayerName.asr.name);
      final asrLocal = tz.TZDateTime.from(
        DateTime.fromMillisecondsSinceEpoch(events[2].timestamp, isUtc: true),
        istanbul,
      );
      expect(asrLocal.hour, 17);
    },
  );

  test('a timezone change changes the scheduled absolute instants', () async {
    final utc = tz.getLocation('Etc/UTC');
    final istanbul = tz.getLocation('Europe/Istanbul');
    const location = DeviceLocation(latitude: 41.0082, longitude: 28.9784);
    final utcNow = tz.TZDateTime(utc, 2026, 9, 1, 0, 1);
    final istanbulNow = tz.TZDateTime(istanbul, 2026, 9, 1, 0, 1);
    final utcEngine = _FixturePrayerCalculationService();
    final istanbulEngine = _FixturePrayerCalculationService();

    final utcToday = await _calculate(utcEngine, location, utcNow, 'Etc/UTC');
    final istanbulToday = await _calculate(
      istanbulEngine,
      location,
      istanbulNow,
      'Europe/Istanbul',
    );
    final utcEvents = await buildPrayerAlarmQueue(
      calculationService: utcEngine,
      location: location,
      todaySchedule: utcToday,
      now: utcNow,
      timeZoneId: 'Etc/UTC',
      asrMethod: AsrMethod.standard,
    );
    final istanbulEvents = await buildPrayerAlarmQueue(
      calculationService: istanbulEngine,
      location: location,
      todaySchedule: istanbulToday,
      now: istanbulNow,
      timeZoneId: 'Europe/Istanbul',
      asrMethod: AsrMethod.standard,
    );

    expect(utcEvents.first.timestamp, isNot(istanbulEvents.first.timestamp));
  });
}

Future<PrayerSchedule> _calculate(
  _FixturePrayerCalculationService engine,
  DeviceLocation location,
  DateTime date,
  String timeZoneId, {
  AsrMethod asrMethod = AsrMethod.standard,
}) => engine.calculate(
  PrayerCalculationRequest(
    latitude: location.latitude,
    longitude: location.longitude,
    date: date,
    timeZoneId: timeZoneId,
    asrMethod: asrMethod,
  ),
);

class _FixturePrayerCalculationService implements PrayerCalculationService {
  final requests = <PrayerCalculationRequest>[];

  @override
  Future<PrayerSchedule> calculate(PrayerCalculationRequest request) async {
    requests.add(request);
    final zone = tz.getLocation(request.timeZoneId);
    final date = tz.TZDateTime(
      zone,
      request.date.year,
      request.date.month,
      request.date.day,
    );
    final asrHour = request.asrMethod == AsrMethod.hanafi ? 17 : 16;
    return PrayerSchedule(
      times: {
        PrayerName.fajr: date.add(const Duration(hours: 5)),
        PrayerName.sunrise: date.add(const Duration(hours: 6)),
        PrayerName.dhuhr: date.add(const Duration(hours: 12)),
        PrayerName.asr: date.add(Duration(hours: asrHour)),
        PrayerName.maghrib: date.add(const Duration(hours: 19)),
        PrayerName.isha: date.add(const Duration(hours: 20)),
      },
      tomorrowFajr: date.add(const Duration(days: 1, hours: 5)),
    );
  }
}
