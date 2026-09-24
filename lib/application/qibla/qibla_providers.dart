import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/qibla/qibla_service.dart';
import '../../infrastructure/qibla/android_device_orientation_service.dart';

final qiblaServiceProvider = Provider<QiblaService>(
  (ref) => const QiblaBearingCalculator(),
);

final deviceOrientationServiceProvider = Provider<DeviceOrientationService>(
  (ref) => const AndroidDeviceOrientationService(),
);

final qiblaOrientationProvider = StreamProvider.autoDispose
    .family<DeviceOrientation, (double, double)>((ref, coordinates) {
      final filter = QiblaOrientationFilter();
      return ref
          .read(deviceOrientationServiceProvider)
          .orientations(latitude: coordinates.$1, longitude: coordinates.$2)
          .map(filter.add);
    });
