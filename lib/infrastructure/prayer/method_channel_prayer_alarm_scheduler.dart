import 'package:flutter/services.dart';

import '../../domain/prayer/prayer_alarm_scheduler.dart';

class MethodChannelPrayerAlarmScheduler implements PrayerAlarmScheduler {
  const MethodChannelPrayerAlarmScheduler({
    this.channel = const MethodChannel('com.ezan.app/prayer_alarms'),
  });

  final MethodChannel channel;

  @override
  Future<PrayerAlarmStatus> getStatus() async {
    final result = await channel.invokeMapMethod<String, bool>('status');
    return PrayerAlarmStatus(
      exactAlarmAllowed: result?['exactAlarmAllowed'] ?? false,
      enabled: result?['enabled'] ?? false,
      scheduleInvalidated: result?['scheduleInvalidated'] ?? false,
    );
  }

  @override
  Future<void> requestExactAlarmAccess() =>
      channel.invokeMethod<void>('requestAccess');

  @override
  Future<void> disable() => channel.invokeMethod<void>('disable');

  @override
  Future<void> replaceSchedule(List<PrayerAlarmEvent> events) =>
      channel.invokeMethod<void>('schedule', {
        'events': events.map((event) => event.toMap()).toList(),
      });
}
