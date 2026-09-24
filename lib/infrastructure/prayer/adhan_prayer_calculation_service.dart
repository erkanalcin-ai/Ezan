import 'package:adhan_dart/adhan_dart.dart' as adhan;
import 'package:timezone/timezone.dart' as tz;

import '../../domain/prayer/prayer_calculation_service.dart';

class AdhanPrayerCalculationService implements PrayerCalculationService {
  @override
  Future<PrayerSchedule> calculate(PrayerCalculationRequest request) async {
    if (request.latitude < -90 || request.latitude > 90) {
      throw ArgumentError.value(request.latitude, 'latitude');
    }
    if (request.longitude < -180 || request.longitude > 180) {
      throw ArgumentError.value(request.longitude, 'longitude');
    }

    final zone = tz.getLocation(request.timeZoneId);
    final coordinates = adhan.Coordinates(request.latitude, request.longitude);
    final localDate = tz.TZDateTime(
      zone,
      request.date.year,
      request.date.month,
      request.date.day,
    );
    final parameters = adhan.CalculationMethodParameters.turkiye()
      ..madhab = request.asrMethod == AsrMethod.hanafi
          ? adhan.Madhab.hanafi
          : adhan.Madhab.shafi
      ..highLatitudeRule = adhan.HighLatitudeRule.recommended(coordinates)
      ..polarCircleResolution = adhan.PolarCircleResolution.aqrabYaum;
    final calculated = adhan.PrayerTimes(
      coordinates: coordinates,
      date: localDate,
      calculationParameters: parameters,
    );

    DateTime local(DateTime utcTime) => tz.TZDateTime.from(utcTime, zone);

    return PrayerSchedule(
      times: {
        PrayerName.fajr: local(calculated.fajr),
        PrayerName.sunrise: local(calculated.sunrise),
        PrayerName.dhuhr: local(calculated.dhuhr),
        PrayerName.asr: local(calculated.asr),
        PrayerName.maghrib: local(calculated.maghrib),
        PrayerName.isha: local(calculated.isha),
      },
      tomorrowFajr: local(calculated.fajrAfter),
    );
  }
}
