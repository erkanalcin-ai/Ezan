import 'package:flutter/services.dart';

import '../../domain/adhan/adhan_playback_service.dart';

class MethodChannelAdhanPlaybackService implements AdhanPlaybackService {
  const MethodChannelAdhanPlaybackService({
    this._channel = const MethodChannel('com.ezan.app/adhan_playback'),
    this._stateChannel = const EventChannel(
      'com.ezan.app/adhan_playback_state',
    ),
  });

  final MethodChannel _channel;
  final EventChannel _stateChannel;

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

  @override
  Stream<AdhanPlaybackStatus> watchPlaybackStatus() => _stateChannel
      .receiveBroadcastStream()
      .map(AdhanPlaybackStatus.fromMap)
      .distinct();

  @override
  Future<bool> setPlaybackMuted(bool muted) async =>
      await _channel.invokeMethod<bool>(
        'setPlaybackMuted',
        {'muted': muted},
      ) ??
      false;
}
