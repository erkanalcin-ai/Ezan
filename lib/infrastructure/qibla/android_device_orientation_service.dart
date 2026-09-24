import 'package:flutter/services.dart';

import '../../domain/qibla/qibla_service.dart';

class AndroidDeviceOrientationService implements DeviceOrientationService {
  const AndroidDeviceOrientationService();

  static const EventChannel _channel = EventChannel(
    'com.ezan.app/qibla/orientation',
  );

  @override
  Stream<DeviceOrientationSample> orientations({
    required double latitude,
    required double longitude,
  }) => _channel
      .receiveBroadcastStream({'latitude': latitude, 'longitude': longitude})
      .map((event) {
        final values = Map<Object?, Object?>.from(event as Map);
        return DeviceOrientationSample(
          azimuthDegrees: (values['azimuthDegrees']! as num).toDouble(),
          hasSensorAccuracy: values['hasSensorAccuracy']! as bool,
          magneticFieldStrengthMicroTesla:
              (values['magneticFieldStrengthMicroTesla']! as num).toDouble(),
          expectedFieldStrengthMicroTesla:
              (values['expectedFieldStrengthMicroTesla']! as num).toDouble(),
        );
      });
}
