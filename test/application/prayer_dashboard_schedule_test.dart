import 'package:ezan/application/prayer/prayer_dashboard_controller.dart';
import 'package:ezan/application/prayer/prayer_alarm_settings_controller.dart';
import 'package:ezan/domain/location/location_service.dart';
import 'package:ezan/domain/location/time_zone_service.dart';
import 'package:ezan/domain/prayer/prayer_alarm_scheduler.dart';
import 'package:ezan/domain/prayer/prayer_calculation_preferences.dart';
import 'package:ezan/domain/prayer/prayer_calculation_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

void main() {
  setUpAll(tzdata.initializeTimeZones);

  test(
    'location, timezone, Asr and app reopen rebuild the exact queue',
    () async {
      const firstLocation = DeviceLocation(
        latitude: 41.0082,
        longitude: 28.9784,
      );
      const movedLocation = DeviceLocation(
        latitude: 39.9334,
        longitude: 32.8597,
      );
      final locationService = _MutableLocationService(firstLocation);
      final timeZoneService = _MutableTimeZoneService('Etc/UTC');
      final preferences = _MemoryCalculationPreferences();
      final engine = _FixturePrayerCalculationService();
      final scheduler = _CapturingPrayerAlarmScheduler();
      final container = _createContainer(
        locationService: locationService,
        timeZoneService: timeZoneService,
        preferences: preferences,
        engine: engine,
        scheduler: scheduler,
      );

      await container.read(prayerDashboardProvider.future);
      await _waitForSchedule(scheduler);
      final beforeLocationChange = scheduler.schedules.last;

      locationService.current = movedLocation;
      locationService.lastKnown = movedLocation;
      await container.read(prayerDashboardProvider.notifier).requestLocation();
      final afterLocationChange = scheduler.schedules.last;
      expect(
        engine.requests.any(
          (request) =>
              request.latitude == movedLocation.latitude &&
              request.longitude == movedLocation.longitude,
        ),
        isTrue,
      );

      await container
          .read(prayerDashboardProvider.notifier)
          .setAsrMethod(AsrMethod.hanafi);
      final afterAsrChange = scheduler.schedules.last;
      expect(preferences.asrMethod, AsrMethod.hanafi);
      final standardAsr = beforeLocationChange.firstWhere(
        (event) => event.prayer == PrayerName.asr.name,
      );
      final hanafiAsr = afterAsrChange.firstWhere(
        (event) => event.prayer == PrayerName.asr.name,
      );
      expect(
        hanafiAsr.timestamp - standardAsr.timestamp,
        const Duration(hours: 1).inMilliseconds,
      );

      final utcFajr = afterLocationChange.firstWhere(
        (event) => event.prayer == PrayerName.fajr.name,
      );
      timeZoneService.timeZoneId = 'Europe/Istanbul';
      await container.read(prayerDashboardProvider.notifier).refreshClock();
      final istanbulFajr = scheduler.schedules.last.firstWhere(
        (event) => event.prayer == PrayerName.fajr.name,
      );
      expect(istanbulFajr.timestamp, isNot(utcFajr.timestamp));
      container.dispose();

      final reopenedEngine = _FixturePrayerCalculationService();
      final reopenedScheduler = _CapturingPrayerAlarmScheduler();
      final reopened = _createContainer(
        locationService: locationService,
        timeZoneService: timeZoneService,
        preferences: preferences,
        engine: reopenedEngine,
        scheduler: reopenedScheduler,
      );
      addTearDown(reopened.dispose);
      final reopenedState = await reopened.read(prayerDashboardProvider.future);
      await _waitForSchedule(reopenedScheduler);
      expect(reopenedState.asrMethod, AsrMethod.hanafi);
      expect(reopenedState.location?.latitude, movedLocation.latitude);
      expect(reopenedState.timeZoneId, 'Europe/Istanbul');
      expect(reopenedScheduler.schedules, isNotEmpty);
    },
  );
}

ProviderContainer _createContainer({
  required LocationService locationService,
  required TimeZoneService timeZoneService,
  required PrayerCalculationPreferences preferences,
  required PrayerCalculationService engine,
  required PrayerAlarmScheduler scheduler,
}) => ProviderContainer(
  overrides: [
    locationServiceProvider.overrideWithValue(locationService),
    timeZoneServiceProvider.overrideWithValue(timeZoneService),
    prayerCalculationPreferencesProvider.overrideWithValue(preferences),
    prayerCalculationServiceProvider.overrideWithValue(engine),
    prayerAlarmSchedulerProvider.overrideWithValue(scheduler),
  ],
);

Future<void> _waitForSchedule(_CapturingPrayerAlarmScheduler scheduler) async {
  for (
    var attempt = 0;
    attempt < 20 && scheduler.schedules.isEmpty;
    attempt++
  ) {
    await Future<void>.delayed(Duration.zero);
  }
  expect(scheduler.schedules, isNotEmpty);
}

class _MutableLocationService implements LocationService {
  _MutableLocationService(DeviceLocation location)
    : current = location,
      lastKnown = location;

  DeviceLocation current;
  DeviceLocation? lastKnown;

  @override
  Future<DeviceLocation> getCurrentLocation() async => current;

  @override
  Future<DeviceLocation?> getLastKnownLocation() async => lastKnown;
}

class _MutableTimeZoneService implements TimeZoneService {
  _MutableTimeZoneService(this.timeZoneId);

  String timeZoneId;

  @override
  Future<String> getLocalTimeZoneId() async => timeZoneId;
}

class _MemoryCalculationPreferences implements PrayerCalculationPreferences {
  AsrMethod asrMethod = AsrMethod.standard;

  @override
  Future<AsrMethod> getAsrMethod() async => asrMethod;

  @override
  Future<void> setAsrMethod(AsrMethod method) async {
    asrMethod = method;
  }
}

class _CapturingPrayerAlarmScheduler implements PrayerAlarmScheduler {
  final schedules = <List<PrayerAlarmEvent>>[];

  @override
  Future<PrayerAlarmStatus> getStatus() async =>
      const PrayerAlarmStatus(exactAlarmAllowed: true, enabled: true);

  @override
  Future<void> requestExactAlarmAccess() async {}

  @override
  Future<void> disable() async {}

  @override
  Future<void> replaceSchedule(List<PrayerAlarmEvent> events) async {
    schedules.add(List.unmodifiable(events));
  }
}

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
