import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/settings/ui_preferences.dart';
import '../../infrastructure/settings/method_channel_ui_preferences.dart';

final uiPreferencesProvider = Provider<UiPreferences>(
  (ref) => const MethodChannelUiPreferences(),
);

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

final localeProvider = NotifierProvider<LocaleNotifier, Locale?>(
  LocaleNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  bool _restoring = false;
  bool _changedByUser = false;

  @override
  ThemeMode build() {
    if (!_restoring) {
      _restoring = true;
      unawaited(_restore());
    }
    return ThemeMode.system;
  }

  Future<void> _restore() async {
    try {
      final saved = await ref.read(uiPreferencesProvider).getThemeMode();
      if (ref.mounted && !_changedByUser) {
        state = switch (saved) {
          'light' => ThemeMode.light,
          'dark' => ThemeMode.dark,
          _ => ThemeMode.system,
        };
      }
    } catch (_) {
      // Use the system theme if local preference storage is unavailable.
    }
  }

  void setMode(ThemeMode mode) {
    _changedByUser = true;
    state = mode;
    final value = switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    };
    unawaited(
      ref.read(uiPreferencesProvider).setThemeMode(value).catchError((_) {}),
    );
  }
}

class LocaleNotifier extends Notifier<Locale?> {
  bool _restoring = false;
  bool _changedByUser = false;

  @override
  Locale? build() {
    if (!_restoring) {
      _restoring = true;
      unawaited(_restore());
    }
    return null;
  }

  Future<void> _restore() async {
    try {
      final languageCode = await ref.read(uiPreferencesProvider).getLocale();
      if (ref.mounted && !_changedByUser) {
        state = switch (languageCode) {
          'tr' => const Locale('tr'),
          'en' => const Locale('en'),
          _ => null,
        };
      }
    } catch (_) {
      // Use the device locale if local preference storage is unavailable.
    }
  }

  void setLocale(Locale? locale) {
    _changedByUser = true;
    state = locale;
    unawaited(
      ref
          .read(uiPreferencesProvider)
          .setLocale(locale?.languageCode)
          .catchError((_) {}),
    );
  }
}
