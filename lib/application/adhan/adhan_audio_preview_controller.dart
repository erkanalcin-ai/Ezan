import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/adhan/adhan_playback_service.dart';
import '../../domain/prayer/prayer_calculation_service.dart';
import '../../infrastructure/adhan/method_channel_adhan_playback_service.dart';
import 'adhan_audio_catalog.dart';

final adhanPlaybackServiceProvider = Provider<AdhanPlaybackService>(
  (ref) => const MethodChannelAdhanPlaybackService(),
);

final adhanVolumeProvider =
    AsyncNotifierProvider<AdhanVolumeController, double>(
      AdhanVolumeController.new,
    );

final adhanAudioPreviewProvider =
    NotifierProvider<AdhanAudioPreviewController, AdhanAudioPreviewStatus>(
      AdhanAudioPreviewController.new,
    );

final adhanPlaybackStatusProvider =
    StreamProvider.autoDispose<AdhanPlaybackStatus>(
      (ref) => ref.read(adhanPlaybackServiceProvider).watchPlaybackStatus(),
    );

final adhanManualPlaybackMutedProvider =
    NotifierProvider<AdhanManualPlaybackMuteController, bool>(
      AdhanManualPlaybackMuteController.new,
    );

enum AdhanAudioPreviewStatus { stopped, playing, failed }

class AdhanManualPlaybackMuteController extends Notifier<bool> {
  @override
  bool build() => false;

  void setMuted(bool muted) => state = muted;
}

class AdhanVolumeController extends AsyncNotifier<double> {
  @override
  Future<double> build() => ref.read(adhanPlaybackServiceProvider).getVolume();

  Future<void> setVolume(double volume) async {
    final normalized = volume.clamp(0.0, 1.0).toDouble();
    await ref.read(adhanPlaybackServiceProvider).setVolume(normalized);
    state = AsyncData(normalized);
  }
}

class AdhanAudioPreviewController extends Notifier<AdhanAudioPreviewStatus> {
  @override
  AdhanAudioPreviewStatus build() => AdhanAudioPreviewStatus.stopped;

  Future<void> play() async {
    try {
      await ref
          .read(adhanPlaybackServiceProvider)
          .play(AdhanAudioCatalog.forPrayer(PrayerName.fajr));
      ref.read(adhanManualPlaybackMutedProvider.notifier).setMuted(false);
      state = AdhanAudioPreviewStatus.playing;
    } catch (_) {
      state = AdhanAudioPreviewStatus.failed;
    }
  }

  Future<void> stop() async {
    try {
      await ref.read(adhanPlaybackServiceProvider).stop();
      ref.read(adhanManualPlaybackMutedProvider.notifier).setMuted(false);
      state = AdhanAudioPreviewStatus.stopped;
    } catch (_) {
      state = AdhanAudioPreviewStatus.failed;
    }
  }
}
