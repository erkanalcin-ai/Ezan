import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../domain/location/location_service.dart';
import '../../domain/location/time_zone_service.dart';
import '../../domain/prayer/prayer_calculation_preferences.dart';
import '../../domain/prayer/prayer_calculation_service.dart';
import '../../infrastructure/location/device_time_zone_service.dart';
import '../../infrastructure/location/geolocator_location_service.dart';
import '../../infrastructure/prayer/adhan_prayer_calculation_service.dart';
import '../../infrastructure/prayer/method_channel_prayer_calculation_preferences.dart';
import '../../infrastructure/time/time_zone_database.dart';
import 'prayer_alarm_queue.dart';
import 'prayer_alarm_settings_controller.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => GeolocatorLocationService(),
);

final timeZoneServiceProvider = Provider<TimeZoneService>(
  (ref) => DeviceTimeZoneService(),
);

final prayerCalculationServiceProvider = Provider<PrayerCalculationService>(
  (ref) => AdhanPrayerCalculationService(),
);

final prayerCalculationPreferencesProvider =
    Provider<PrayerCalculationPreferences>(
      (ref) => const MethodChannelPrayerCalculationPreferences(),
    );

final prayerDashboardProvider =
    AsyncNotifierProvider<PrayerDashboardController, PrayerDashboardState>(
      PrayerDashboardController.new,
    );

class PrayerDashboardController extends AsyncNotifier<PrayerDashboardState> {
  @override
  Future<PrayerDashboardState> build() async {
    await TimeZoneDatabase.ensureInitialized();
    final timeZoneId = await ref
        .read(timeZoneServiceProvider)
        .getLocalTimeZoneId();
    final zone = tz.getLocation(timeZoneId);
    final now = tz.TZDateTime.now(zone);
    final lastKnown = await ref
        .read(locationServiceProvider)
        .getLastKnownLocation();
    final asrMethod = await ref
        .read(prayerCalculationPreferencesProvider)
        .getAsrMethod()
        .catchError((_) => AsrMethod.standard);
    final schedule = lastKnown == null
        ? null
        : await _calculate(lastKnown, now, timeZoneId, asrMethod);
    final result = PrayerDashboardState(
      timeZoneId: timeZoneId,
      now: now,
      location: lastKnown,
      schedule: schedule,
      asrMethod: asrMethod,
    );
    unawaited(_syncAlarmSchedule(result));
    return result;
  }

  Future<void> requestLocation() async {
    final previous = state.asData?.value;
    if (previous == null) return;
    state = AsyncData(
      previous.copyWith(locationLoading: true, clearFailure: true),
    );
    try {
      final location = await ref
          .read(locationServiceProvider)
          .getCurrentLocation();
      final current = state.asData?.value ?? previous;
      final schedule = await _calculate(
        location,
        current.now,
        current.timeZoneId,
        current.asrMethod,
      );
      state = AsyncData(
        current.copyWith(
          location: location,
          schedule: schedule,
          locationLoading: false,
          clearFailure: true,
        ),
      );
      await _syncAlarmSchedule(state.requireValue);
    } on LocationFailure catch (failure) {
      final current = state.asData?.value ?? previous;
      state = AsyncData(
        current.copyWith(
          locationLoading: false,
          locationFailure: failure.reason,
        ),
      );
    } catch (_) {
      final current = state.asData?.value ?? previous;
      state = AsyncData(
        current.copyWith(
          locationLoading: false,
          locationFailure: LocationFailureReason.unavailable,
        ),
      );
    }
  }

  Future<void> setAsrMethod(AsrMethod method) async {
    final current = state.asData?.value;
    if (current == null || current.asrMethod == method) return;
    try {
      await ref.read(prayerCalculationPreferencesProvider).setAsrMethod(method);
    } catch (_) {
      // Keep the current selection for this session if local storage is unavailable.
    }
    state = AsyncData(current.copyWith(asrMethod: method));
    final location = current.location;
    if (location == null) return;
    final schedule = await _calculate(
      location,
      current.now,
      current.timeZoneId,
      method,
    );
    final latest = state.asData?.value;
    if (latest != null && latest.asrMethod == method) {
      final updated = latest.copyWith(schedule: schedule);
      state = AsyncData(updated);
      await _syncAlarmSchedule(updated);
    }
  }

  Future<void> refreshClock() async {
    final current = state.asData?.value;
    if (current == null) return;
    final timeZoneId = await ref
        .read(timeZoneServiceProvider)
        .getLocalTimeZoneId();
    final now = tz.TZDateTime.now(tz.getLocation(timeZoneId));
    final dateChanged =
        current.now.year != now.year ||
        current.now.month != now.month ||
        current.now.day != now.day;
    final zoneChanged = current.timeZoneId != timeZoneId;
    final location = current.location;
    final schedule = (dateChanged || zoneChanged) && location != null
        ? await _calculate(location, now, timeZoneId, current.asrMethod)
        : current.schedule;
    final updated = current.copyWith(
      now: now,
      schedule: schedule,
      timeZoneId: timeZoneId,
    );
    state = AsyncData(updated);
    if (dateChanged || zoneChanged) await _syncAlarmSchedule(updated);
  }

  Future<void> _syncAlarmSchedule(PrayerDashboardState dashboard) async {
    try {
      final scheduler = ref.read(prayerAlarmSchedulerProvider);
      if (!(await scheduler.getStatus()).enabled) return;
      final location = dashboard.location;
      final currentSchedule = dashboard.schedule;
      if (location == null || currentSchedule == null) {
        await scheduler.replaceSchedule(const []);
        return;
      }

      final zone = tz.getLocation(dashboard.timeZoneId);
      final now = tz.TZDateTime.now(zone);
      final events = await buildPrayerAlarmQueue(
        calculationService: ref.read(prayerCalculationServiceProvider),
        location: location,
        todaySchedule: currentSchedule,
        now: now,
        timeZoneId: dashboard.timeZoneId,
        asrMethod: dashboard.asrMethod,
      );
      await scheduler.replaceSchedule(events);
    } catch (_) {
      // A platform channel can be unavailable in tests or during a platform failure.
    }
  }

  Future<void> syncAlarms() async {
    final current = state.asData?.value;
    if (current != null) await _syncAlarmSchedule(current);
  }

  Future<PrayerSchedule> _calculate(
    DeviceLocation location,
    DateTime date,
    String timeZoneId,
    AsrMethod asrMethod,
  ) => ref
      .read(prayerCalculationServiceProvider)
      .calculate(
        PrayerCalculationRequest(
          latitude: location.latitude,
          longitude: location.longitude,
          date: date,
          timeZoneId: timeZoneId,
          asrMethod: asrMethod,
        ),
      );
}

class PrayerDashboardState {
  const PrayerDashboardState({
    required this.timeZoneId,
    required this.now,
    required this.location,
    required this.schedule,
    required this.asrMethod,
    this.locationLoading = false,
    this.locationFailure,
  });

  final String timeZoneId;
  final DateTime now;
  final DeviceLocation? location;
  final PrayerSchedule? schedule;
  final AsrMethod asrMethod;
  final bool locationLoading;
  final LocationFailureReason? locationFailure;

  PrayerDashboardState copyWith({
    String? timeZoneId,
    DateTime? now,
    DeviceLocation? location,
    PrayerSchedule? schedule,
    AsrMethod? asrMethod,
    bool? locationLoading,
    LocationFailureReason? locationFailure,
    bool clearFailure = false,
  }) => PrayerDashboardState(
    timeZoneId: timeZoneId ?? this.timeZoneId,
    now: now ?? this.now,
    location: location ?? this.location,
    schedule: schedule ?? this.schedule,
    asrMethod: asrMethod ?? this.asrMethod,
    locationLoading: locationLoading ?? this.locationLoading,
    locationFailure: clearFailure
        ? null
        : locationFailure ?? this.locationFailure,
  );
}
