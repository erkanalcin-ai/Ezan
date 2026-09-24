import 'prayer_calculation_service.dart';

abstract interface class PrayerCalculationPreferences {
  Future<AsrMethod> getAsrMethod();
  Future<void> setAsrMethod(AsrMethod method);
}
