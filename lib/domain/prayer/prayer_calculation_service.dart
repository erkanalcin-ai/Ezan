abstract interface class PrayerCalculationService {
  Future<PrayerSchedule> calculate(PrayerCalculationRequest request);
}

class PrayerCalculationRequest {
  const PrayerCalculationRequest({
    required this.latitude,
    required this.longitude,
    required this.date,
    required this.timeZoneId,
    this.asrMethod = AsrMethod.standard,
  });

  final double latitude;
  final double longitude;
  final DateTime date;
  final String timeZoneId;
  final AsrMethod asrMethod;
}

class PrayerSchedule {
  const PrayerSchedule({required this.times, required this.tomorrowFajr});

  final Map<PrayerName, DateTime> times;
  final DateTime tomorrowFajr;

  PrayerOccurrence nextPrayerAfter(DateTime instant) {
    for (final prayer in const [
      PrayerName.fajr,
      PrayerName.dhuhr,
      PrayerName.asr,
      PrayerName.maghrib,
      PrayerName.isha,
    ]) {
      final time = times[prayer]!;
      if (time.isAfter(instant)) {
        return PrayerOccurrence(name: prayer, time: time);
      }
    }
    return PrayerOccurrence(name: PrayerName.fajr, time: tomorrowFajr);
  }
}

class PrayerOccurrence {
  const PrayerOccurrence({required this.name, required this.time});

  final PrayerName name;
  final DateTime time;
}

enum PrayerName { fajr, sunrise, dhuhr, asr, maghrib, isha }

enum AsrMethod { standard, hanafi }
