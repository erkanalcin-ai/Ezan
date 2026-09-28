import 'package:flutter/services.dart';

import '../../domain/prayer/prayer_alarm_scheduler.dart';

class MethodChannelPrayerWidgetBridge {
  const MethodChannelPrayerWidgetBridge({
    this.channel = const MethodChannel('com.ezan.app/prayer_widgets'),
  });

  final MethodChannel channel;

  Future<bool> shouldSync() async =>
      await channel.invokeMethod<bool>('shouldSync') ?? false;

  Future<void> replaceSchedule(List<PrayerAlarmEvent> events) =>
      channel.invokeMethod<void>('replaceSchedule', {
        'events': events.map((event) => event.toMap()).toList(),
      });

  Future<void> clearSchedule() => channel.invokeMethod<void>('clearSchedule');
}
