import 'package:ezan/domain/qibla/qibla_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const calculator = QiblaBearingCalculator();

  group('great-circle initial bearing to the Kaaba', () {
    test('matches independent city fixtures', () {
      final fixtures = <({double latitude, double longitude, double bearing})>[
        (latitude: 41.0082, longitude: 28.9784, bearing: 151.6206),
        (latitude: 39.9334, longitude: 32.8597, bearing: 160.1682),
        (latitude: 40.7128, longitude: -74.0060, bearing: 58.4817),
        (latitude: 35.6762, longitude: 139.6503, bearing: 292.9987),
      ];

      for (final fixture in fixtures) {
        expect(
          calculator.bearingFromTrueNorth(
            latitude: fixture.latitude,
            longitude: fixture.longitude,
          ),
          closeTo(fixture.bearing, 0.001),
        );
      }
    });

    test('normalizes bearings and chooses the shortest angular path', () {
      expect(QiblaBearingCalculator.normalizeDegrees(-10), 350);
      expect(QiblaBearingCalculator.normalizeDegrees(370), 10);
      expect(QiblaBearingCalculator.shortestAngleDelta(358), -2);
      expect(QiblaBearingCalculator.shortestAngleDelta(-358), 2);
      expect(QiblaBearingCalculator.shortestAngleDelta(180), -180);
    });
  });

  group('orientation stability filter', () {
    test(
      'handles headings that straddle north and stabilizes after eight reads',
      () {
        final filter = QiblaOrientationFilter();
        final readings = [358.0, 359.0, 0.0, 1.0, 359.5, 0.5, 1.0, 0.0];
        DeviceOrientation? result;

        for (final heading in readings) {
          result = filter.add(_sample(heading));
        }

        expect(result!.isReliable, isTrue);
        expect(result.azimuthDegrees, anyOf(closeTo(0, 1), closeTo(360, 1)));
      },
    );

    test(
      'marks sensor inaccuracy, magnetic interference, and jitter unreliable',
      () {
        final inaccurate = QiblaOrientationFilter(sampleCount: 3);
        DeviceOrientation? result;
        for (var i = 0; i < 3; i++) {
          result = inaccurate.add(_sample(80, hasAccuracy: false));
        }
        expect(result!.isReliable, isFalse);

        final disturbed = QiblaOrientationFilter(sampleCount: 3);
        for (var i = 0; i < 3; i++) {
          result = disturbed.add(_sample(80, fieldStrength: 90));
        }
        expect(result!.isReliable, isFalse);

        final unstable = QiblaOrientationFilter(sampleCount: 3);
        for (final heading in [50.0, 80.0, 110.0]) {
          result = unstable.add(_sample(heading));
        }
        expect(result!.isReliable, isFalse);
      },
    );
  });
}

DeviceOrientationSample _sample(
  double heading, {
  bool hasAccuracy = true,
  double fieldStrength = 50,
}) => DeviceOrientationSample(
  azimuthDegrees: heading,
  hasSensorAccuracy: hasAccuracy,
  magneticFieldStrengthMicroTesla: fieldStrength,
  expectedFieldStrengthMicroTesla: 50,
);
