import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/prayer/prayer_alarm_scheduler.dart';
import '../../infrastructure/prayer/method_channel_prayer_alarm_scheduler.dart';

final prayerAlarmSchedulerProvider = Provider<PrayerAlarmScheduler>(
  (ref) => const MethodChannelPrayerAlarmScheduler(),
);

final prayerAlarmSettingsProvider =
    AsyncNotifierProvider<PrayerAlarmSettingsController, PrayerAlarmStatus>(
      PrayerAlarmSettingsController.new,
    );

class PrayerAlarmSettingsController extends AsyncNotifier<PrayerAlarmStatus> {
  @override
  Future<PrayerAlarmStatus> build() =>
      ref.read(prayerAlarmSchedulerProvider).getStatus();

  Future<PrayerAlarmStatus> refresh() async {
    final status = await ref.read(prayerAlarmSchedulerProvider).getStatus();
    state = AsyncData(status);
    return status;
  }

  Future<void> enableOrRequestPermission() async {
    await ref.read(prayerAlarmSchedulerProvider).requestExactAlarmAccess();
    await refresh();
  }

  Future<void> disable() async {
    await ref.read(prayerAlarmSchedulerProvider).disable();
    await refresh();
  }
}
