import 'package:timezone/data/latest_all.dart' as timezone_data;

class TimeZoneDatabase {
  static bool _initialized = false;

  static void ensureInitialized() {
    if (_initialized) return;
    timezone_data.initializeTimeZones();
    _initialized = true;
  }
}
