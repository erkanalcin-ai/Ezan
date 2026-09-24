class PrayerAlarmStatus {
  const PrayerAlarmStatus({
    required this.exactAlarmAllowed,
    required this.enabled,
    this.scheduleInvalidated = false,
  });

  final bool exactAlarmAllowed;
  final bool enabled;
  final bool scheduleInvalidated;
}

class PrayerAlarmEvent {
  const PrayerAlarmEvent({
    required this.timestamp,
    required this.assetId,
    required this.prayer,
  });

  final int timestamp;
  final String assetId;
  final String prayer;

  Map<String, Object> toMap() => {
    'timestamp': timestamp,
    'assetId': assetId,
    'prayer': prayer,
  };
}

abstract interface class PrayerAlarmScheduler {
  Future<PrayerAlarmStatus> getStatus();
  Future<void> requestExactAlarmAccess();
  Future<void> disable();
  Future<void> replaceSchedule(List<PrayerAlarmEvent> events);
}
