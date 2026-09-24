import 'package:geolocator/geolocator.dart';

import '../../domain/location/location_service.dart';

class GeolocatorLocationService implements LocationService {
  @override
  Future<DeviceLocation> getCurrentLocation() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationFailure(LocationFailureReason.servicesDisabled);
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationFailure(
        LocationFailureReason.permissionPermanentlyDenied,
      );
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.unableToDetermine) {
      throw const LocationFailure(LocationFailureReason.permissionDenied);
    }

    try {
      return _toDeviceLocation(
        await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium,
            timeLimit: Duration(seconds: 20),
          ),
        ),
      );
    } on LocationFailure {
      rethrow;
    } catch (_) {
      throw const LocationFailure(LocationFailureReason.unavailable);
    }
  }

  @override
  Future<DeviceLocation?> getLastKnownLocation() async {
    final permission = await Geolocator.checkPermission();
    if (permission != LocationPermission.whileInUse &&
        permission != LocationPermission.always) {
      return null;
    }
    try {
      final position = await Geolocator.getLastKnownPosition();
      return position == null ? null : _toDeviceLocation(position);
    } catch (_) {
      return null;
    }
  }

  DeviceLocation _toDeviceLocation(Position position) => DeviceLocation(
    latitude: position.latitude,
    longitude: position.longitude,
  );
}
