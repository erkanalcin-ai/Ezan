import 'package:ezan/domain/prayer/prayer_calculation_service.dart';
import 'package:ezan/infrastructure/prayer/adhan_prayer_calculation_service.dart';
import 'package:ezan/infrastructure/time/time_zone_database.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/timezone.dart' as tz;

void main() {
  late AdhanPrayerCalculationService service;

  setUpAll(TimeZoneDatabase.ensureInitialized);

  setUp(() => service = AdhanPrayerCalculationService());

  test('published Diyanet city tables stay within the declared two-minute '
      'tolerance', () async {
    // Source tables, 23 Sep 2026: Diyanet Istanbul (9541), Ankara (9206),
    // Antalya (9225). Times are İmsak, Güneş, Öğle, İkindi, Akşam, Yatsı.
    final fixtures = [
      (
        city: 'Istanbul',
        latitude: 41.005616,
        longitude: 28.97638,
        published: ['05:20', '06:45', '13:02', '16:26', '19:08', '20:28'],
      ),
      (
        city: 'Ankara',
        latitude: 39.939382,
        longitude: 32.819713,
        published: ['05:06', '06:30', '12:46', '16:11', '18:53', '20:11'],
      ),
      (
        city: 'Antalya',
        latitude: 36.8969,
        longitude: 30.7133,
        published: ['05:19', '06:39', '12:55', '16:21', '19:01', '20:16'],
      ),
    ];
    const prayers = [
      PrayerName.fajr,
      PrayerName.sunrise,
      PrayerName.dhuhr,
      PrayerName.asr,
      PrayerName.maghrib,
      PrayerName.isha,
    ];

    for (final fixture in fixtures) {
      final schedule = await service.calculate(
        PrayerCalculationRequest(
          latitude: fixture.latitude,
          longitude: fixture.longitude,
          date: DateTime(2026, 9, 23),
          timeZoneId: 'Europe/Istanbul',
        ),
      );
      for (var index = 0; index < prayers.length; index++) {
        final actual = schedule.times[prayers[index]]!;
        final actualMinutes = actual.hour * 60 + actual.minute;
        final parts = fixture.published[index].split(':');
        final expectedMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
        final delta = (actualMinutes - expectedMinutes).abs();
        expect(
          delta,
          lessThanOrEqualTo(2),
          reason:
              '${fixture.city} ${prayers[index]}: $actual versus '
              '${fixture.published[index]} (delta $delta min)',
        );
      }
    }
  });

  test('Hanafi Asr is later than Standard Asr', () async {
    Future<PrayerSchedule> calculate(AsrMethod method) => service.calculate(
      PrayerCalculationRequest(
        latitude: 41.005616,
        longitude: 28.97638,
        date: DateTime(2026, 9, 23),
        timeZoneId: 'Europe/Istanbul',
        asrMethod: method,
      ),
    );

    final standard = await calculate(AsrMethod.standard);
    final hanafi = await calculate(AsrMethod.hanafi);
    expect(
      hanafi.times[PrayerName.asr]!.isAfter(standard.times[PrayerName.asr]!),
      isTrue,
    );
  });

  test(
    'DST date uses the requested IANA zone and keeps local wall times',
    () async {
      final schedule = await service.calculate(
        PrayerCalculationRequest(
          latitude: 51.5072,
          longitude: -0.1276,
          date: DateTime(2026, 3, 29),
          timeZoneId: 'Europe/London',
        ),
      );
      final london = tz.getLocation('Europe/London');
      final fajr = schedule.times[PrayerName.fajr]!;
      expect(fajr, isA<tz.TZDateTime>());
      expect(
        tz.TZDateTime.from(fajr, london).timeZoneOffset,
        const Duration(hours: 1),
      );
      expect(fajr.year, 2026);
      expect(fajr.month, 3);
      expect(fajr.day, 29);
    },
  );

  test('polar-day location has resolved finite prayer times', () async {
    final schedule = await service.calculate(
      PrayerCalculationRequest(
        latitude: 69.6492,
        longitude: 18.9553,
        date: DateTime(2026, 6, 21),
        timeZoneId: 'Europe/Oslo',
      ),
    );
    for (final time in schedule.times.values) {
      expect(time.millisecondsSinceEpoch.isFinite, isTrue);
    }
    expect(schedule.tomorrowFajr.millisecondsSinceEpoch.isFinite, isTrue);
  });

  test(
    'after Isha the next prayer is tomorrow Fajr; sunrise is not a prayer',
    () async {
      final schedule = await service.calculate(
        PrayerCalculationRequest(
          latitude: 41.005616,
          longitude: 28.97638,
          date: DateTime(2026, 9, 23),
          timeZoneId: 'Europe/Istanbul',
        ),
      );
      final afterIsha = schedule.nextPrayerAfter(
        schedule.times[PrayerName.isha]!.add(const Duration(minutes: 1)),
      );
      expect(afterIsha.name, PrayerName.fajr);
      expect(afterIsha.time, schedule.tomorrowFajr);

      final afterFajr = schedule.nextPrayerAfter(
        schedule.times[PrayerName.fajr]!.add(const Duration(minutes: 1)),
      );
      expect(afterFajr.name, PrayerName.dhuhr);
    },
  );
}
