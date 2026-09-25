import 'package:flutter/services.dart';

import '../../domain/settings/ui_preferences.dart';

class MethodChannelUiPreferences implements UiPreferences {
  const MethodChannelUiPreferences({
    this.channel = const MethodChannel('com.ezan.app/ui_preferences'),
  });

  final MethodChannel channel;

  @override
  Future<String?> getThemeMode() =>
      channel.invokeMethod<String>('getThemeMode');

  @override
  Future<void> setThemeMode(String mode) =>
      channel.invokeMethod<void>('setThemeMode', {'mode': mode});

  @override
  Future<String?> getLocale() => channel.invokeMethod<String>('getLocale');

  @override
  Future<void> setLocale(String? languageCode) =>
      channel.invokeMethod<void>('setLocale', {'languageCode': languageCode});

  @override
  Future<String?> getQiblaNorthReference() =>
      channel.invokeMethod<String>('getQiblaNorthReference');

  @override
  Future<void> setQiblaNorthReference(String reference) => channel
      .invokeMethod<void>('setQiblaNorthReference', {'reference': reference});
}
