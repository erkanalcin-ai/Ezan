import 'dart:math' as math;

const kaabaLatitude = 21.4225;
const kaabaLongitude = 39.8262;

abstract interface class QiblaService {
  double bearingFromTrueNorth({
    required double latitude,
    required double longitude,
  });
}

abstract interface class DeviceOrientationService {
  Stream<DeviceOrientationSample> orientations({
    required double latitude,
    required double longitude,
  });
}

class DeviceOrientationSample {
  const DeviceOrientationSample({
    required this.azimuthDegrees,
    required this.hasSensorAccuracy,
    required this.magneticFieldStrengthMicroTesla,
    required this.expectedFieldStrengthMicroTesla,
  });

  /// Heading corrected to true north using the local geomagnetic declination.
  final double azimuthDegrees;
  final bool hasSensorAccuracy;
  final double magneticFieldStrengthMicroTesla;
  final double expectedFieldStrengthMicroTesla;
}

class DeviceOrientation {
  const DeviceOrientation({
    required this.azimuthDegrees,
    required this.isReliable,
  });

  final double azimuthDegrees;
  final bool isReliable;
}

class QiblaBearingCalculator implements QiblaService {
  const QiblaBearingCalculator();

  @override
  double bearingFromTrueNorth({
    required double latitude,
    required double longitude,
  }) {
    final latitude1 = _radians(latitude);
    final latitude2 = _radians(kaabaLatitude);
    final longitudeDelta = _radians(kaabaLongitude - longitude);
    final y = math.sin(longitudeDelta) * math.cos(latitude2);
    final x =
        math.cos(latitude1) * math.sin(latitude2) -
        math.sin(latitude1) * math.cos(latitude2) * math.cos(longitudeDelta);
    return normalizeDegrees(math.atan2(y, x) * 180 / math.pi);
  }

  static double normalizeDegrees(double degrees) => (degrees % 360 + 360) % 360;

  static double shortestAngleDelta(double degrees) {
    final normalized = (degrees + 180) % 360;
    return (normalized < 0 ? normalized + 360 : normalized) - 180;
  }

  static double _radians(double degrees) => degrees * math.pi / 180;
}

class QiblaOrientationFilter {
  QiblaOrientationFilter({this.sampleCount = 8, this.maxDeviationDegrees = 10});

  final int sampleCount;
  final double maxDeviationDegrees;
  final List<double> _headings = [];

  DeviceOrientation add(DeviceOrientationSample sample) {
    final heading = QiblaBearingCalculator.normalizeDegrees(
      sample.azimuthDegrees,
    );
    _headings.add(heading);
    if (_headings.length > sampleCount) _headings.removeAt(0);

    final mean = _circularMean(_headings);
    final fieldRatio = sample.expectedFieldStrengthMicroTesla <= 0
        ? double.infinity
        : sample.magneticFieldStrengthMicroTesla /
              sample.expectedFieldStrengthMicroTesla;
    final fieldIsPlausible = fieldRatio >= 0.65 && fieldRatio <= 1.35;
    final isStable =
        _headings.length == sampleCount &&
        _headings.every(
          (value) =>
              QiblaBearingCalculator.shortestAngleDelta(value - mean).abs() <=
              maxDeviationDegrees,
        );

    return DeviceOrientation(
      azimuthDegrees: mean,
      isReliable: sample.hasSensorAccuracy && fieldIsPlausible && isStable,
    );
  }

  static double _circularMean(List<double> headings) {
    final radians = headings.map((value) => value * math.pi / 180);
    final sine = radians.fold<double>(0, (sum, value) => sum + math.sin(value));
    final cosine = radians.fold<double>(
      0,
      (sum, value) => sum + math.cos(value),
    );
    return QiblaBearingCalculator.normalizeDegrees(
      math.atan2(sine, cosine) * 180 / math.pi,
    );
  }
}
