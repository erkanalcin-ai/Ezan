abstract interface class UiPreferences {
  Future<String?> getThemeMode();
  Future<void> setThemeMode(String mode);
  Future<String?> getLocale();
  Future<void> setLocale(String? languageCode);
}
