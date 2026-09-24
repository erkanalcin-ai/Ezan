abstract interface class AdhanPlaybackService {
  Future<void> play(AdhanAudio audio);
  Future<void> stop();
  Future<double> getVolume();
  Future<void> setVolume(double volume);
}

class AdhanAudio {
  const AdhanAudio({required this.assetId});

  /// Local identifier; temporary placeholder audio is used during development.
  final String assetId;
}
