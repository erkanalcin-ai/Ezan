abstract interface class AdhanPlaybackService {
  Future<void> play(AdhanAudio audio);
  Future<void> stop();
  Future<double> getVolume();
  Future<void> setVolume(double volume);
  Stream<AdhanPlaybackStatus> watchPlaybackStatus();
  Future<bool> setPlaybackMuted(bool muted);
}

class AdhanAudio {
  const AdhanAudio({required this.assetId});

  /// Local identifier for the installed adhan recording.
  final String assetId;
}

class AdhanPlaybackStatus {
  const AdhanPlaybackStatus({
    required this.isPlaying,
    required this.prayer,
    required this.isMuted,
  });

  const AdhanPlaybackStatus.stopped()
    : isPlaying = false,
      prayer = null,
      isMuted = false;

  final bool isPlaying;
  final String? prayer;
  final bool isMuted;

  factory AdhanPlaybackStatus.fromMap(Object? value) {
    final map = Map<String, dynamic>.from(value as Map);
    return AdhanPlaybackStatus(
      isPlaying: map['isPlaying'] == true,
      prayer: map['prayer'] as String?,
      isMuted: map['isMuted'] == true,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is AdhanPlaybackStatus &&
      other.isPlaying == isPlaying &&
      other.prayer == prayer &&
      other.isMuted == isMuted;

  @override
  int get hashCode => Object.hash(isPlaying, prayer, isMuted);
}
