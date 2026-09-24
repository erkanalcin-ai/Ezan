import 'package:flutter/services.dart';

import '../../domain/adhan/adhan_playback_service.dart';

class MethodChannelAdhanPlaybackService implements AdhanPlaybackService {
  const MethodChannelAdhanPlaybackService({
    this._channel = const MethodChannel('com.ezan.app/adhan_playback'),
  });

  final MethodChannel _channel;

  @override
  Future<void> play(AdhanAudio audio) =>
      _channel.invokeMethod<void>('play', {'assetId': audio.assetId});

  @override
  Future<void> stop() => _channel.invokeMethod<void>('stop');

  @override
  Future<double> getVolume() async =>
      await _channel.invokeMethod<double>('getVolume') ?? 1;

  @override
  Future<void> setVolume(double volume) =>
      _channel.invokeMethod<void>('setVolume', {'volume': volume});
}
