import 'package:flutter/services.dart';

import '../../domain/prayer/prayer_calculation_preferences.dart';
import '../../domain/prayer/prayer_calculation_service.dart';

class MethodChannelPrayerCalculationPreferences
    implements PrayerCalculationPreferences {
  const MethodChannelPrayerCalculationPreferences({
    this.channel = const MethodChannel(
      'com.ezan.app/prayer_calculation_settings',
    ),
  });

  final MethodChannel channel;

  @override
  Future<AsrMethod> getAsrMethod() async {
    final method = await channel.invokeMethod<String>('getAsrMethod');
    return method == 'hanafi' ? AsrMethod.hanafi : AsrMethod.standard;
  }

  @override
  Future<void> setAsrMethod(AsrMethod method) =>
      channel.invokeMethod<void>('setAsrMethod', {'method': method.name});
}
