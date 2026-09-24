abstract interface class LocationService {
  Future<DeviceLocation> getCurrentLocation();
  Future<DeviceLocation?> getLastKnownLocation();
}

enum LocationFailureReason {
  servicesDisabled,
  permissionDenied,
  permissionPermanentlyDenied,
  unavailable,
}

class LocationFailure implements Exception {
  const LocationFailure(this.reason);

  final LocationFailureReason reason;
}

class DeviceLocation {
  const DeviceLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}
