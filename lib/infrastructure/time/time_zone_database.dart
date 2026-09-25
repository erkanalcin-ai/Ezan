import 'package:timezone/data/latest_all.dart' as timezone_data;

class TimeZoneDatabase {
  static Future<void>? _initialization;

  static Future<void> ensureInitialized() =>
      _initialization ??= Future<void>(timezone_data.initializeTimeZones);
}
