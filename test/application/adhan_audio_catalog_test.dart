import 'package:ezan/application/adhan/adhan_audio_catalog.dart';
import 'package:ezan/domain/adhan/adhan_playback_service.dart';
import 'package:ezan/domain/prayer/prayer_calculation_service.dart';
import 'package:ezan/infrastructure/adhan/method_channel_adhan_playback_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('uses the installed adhan recording for every prayer', () {
    for (final prayer in [
      PrayerName.fajr,
      PrayerName.dhuhr,
      PrayerName.asr,
      PrayerName.maghrib,
      PrayerName.isha,
    ]) {
      expect(AdhanAudioCatalog.forPrayer(prayer).assetId, 'adhan');
    }
    expect(
      () => AdhanAudioCatalog.forPrayer(PrayerName.sunrise),
      throwsArgumentError,
    );
  });

  test(
    'forwards local play and stop commands over the native channel',
    () async {
      const channel = MethodChannel('ezan.test/adhan_playback');
      final calls = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            calls.add(call);
            return null;
          });
      addTearDown(
        () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, null),
      );

      final service = MethodChannelAdhanPlaybackService(channel: channel);
      await service.play(const AdhanAudio(assetId: 'adhan_fajr'));
      await service.stop();
      await service.getVolume();
      await service.setVolume(0.4);

      expect(calls.map((call) => call.method), [
        'play',
        'stop',
        'getVolume',
        'setVolume',
      ]);
      expect(calls.first.arguments, {'assetId': 'adhan_fajr'});
      expect(calls.last.arguments, {'volume': 0.4});
    },
  );
}
