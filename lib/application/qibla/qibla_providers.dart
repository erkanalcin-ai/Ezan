import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/qibla/qibla_north_reference.dart';
import '../../domain/qibla/qibla_service.dart';
import '../../infrastructure/qibla/android_device_orientation_service.dart';
import '../theme/theme_mode_notifier.dart';

final qiblaServiceProvider = Provider<QiblaService>(
  (ref) => const QiblaBearingCalculator(),
);

final deviceOrientationServiceProvider = Provider<DeviceOrientationService>(
  (ref) => const AndroidDeviceOrientationService(),
);

final qiblaNorthReferenceProvider =
    NotifierProvider<QiblaNorthReferenceNotifier, QiblaNorthReference>(
      QiblaNorthReferenceNotifier.new,
    );

class QiblaNorthReferenceNotifier extends Notifier<QiblaNorthReference> {
  bool _restoring = false;
  bool _changedByUser = false;

  @override
  QiblaNorthReference build() {
    if (!_restoring) {
      _restoring = true;
      unawaited(_restore());
    }
    return QiblaNorthReference.trueNorth;
  }

  Future<void> _restore() async {
    try {
      final saved = await ref
          .read(uiPreferencesProvider)
          .getQiblaNorthReference();
      if (ref.mounted && !_changedByUser) {
        state = QiblaNorthReference.fromStorage(saved);
      }
    } catch (_) {
      // Keep true north if local preference storage is unavailable.
    }
  }

  void setReference(QiblaNorthReference reference) {
    _changedByUser = true;
    state = reference;
    unawaited(
      ref
          .read(uiPreferencesProvider)
          .setQiblaNorthReference(reference.storageValue)
          .catchError((_) {}),
    );
  }
}

final qiblaOrientationProvider = StreamProvider.autoDispose
    .family<DeviceOrientation, (double, double)>((ref, coordinates) {
      final filter = QiblaOrientationFilter();
      final northReference = ref.watch(qiblaNorthReferenceProvider);
      return ref
          .read(deviceOrientationServiceProvider)
          .orientations(
            latitude: coordinates.$1,
            longitude: coordinates.$2,
            useTrueNorth: northReference.usesTrueNorth,
          )
          .map(filter.add);
    });
