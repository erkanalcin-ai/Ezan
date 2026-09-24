import 'package:flutter_timezone/flutter_timezone.dart';

import '../../domain/location/time_zone_service.dart';

class DeviceTimeZoneService implements TimeZoneService {
  @override
  Future<String> getLocalTimeZoneId() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;
}
