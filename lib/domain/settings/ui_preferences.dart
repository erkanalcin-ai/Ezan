abstract interface class UiPreferences {
  Future<String?> getThemeMode();
  Future<void> setThemeMode(String mode);
  Future<String?> getLocale();
  Future<void> setLocale(String? languageCode);
  Future<String?> getQiblaNorthReference();
  Future<void> setQiblaNorthReference(String reference);
}
