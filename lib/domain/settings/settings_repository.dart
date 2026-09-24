abstract interface class SettingsRepository {
  Future<AppSettings> load();
  Future<void> save(AppSettings settings);
}

class AppSettings {
  const AppSettings({
    required this.calculationMethodId,
    required this.asrMethodId,
    required this.adhanEnabled,
  });

  final String calculationMethodId;
  final String asrMethodId;
  final bool adhanEnabled;
}
