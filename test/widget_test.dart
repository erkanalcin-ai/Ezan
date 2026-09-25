// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ezan/app/app_router.dart';
import 'package:ezan/app/ezan_app.dart';
import 'package:ezan/application/prayer/prayer_dashboard_controller.dart';
import 'package:ezan/application/prayer/prayer_alarm_settings_controller.dart';
import 'package:ezan/application/theme/theme_mode_notifier.dart';
import 'package:ezan/domain/location/location_service.dart';
import 'package:ezan/domain/location/time_zone_service.dart';
import 'package:ezan/domain/prayer/prayer_alarm_scheduler.dart';
import 'package:ezan/domain/prayer/prayer_calculation_preferences.dart';
import 'package:ezan/domain/prayer/prayer_calculation_service.dart';
import 'package:ezan/domain/settings/ui_preferences.dart';

void main() {
  testWidgets('single-page dashboard keeps the first-run location prompt', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        prayerDashboardProvider.overrideWith(
          () => _StaticPrayerDashboardController(
            _dashboardState(hasLocation: false),
          ),
        ),
        uiPreferencesProvider.overrideWithValue(_MemoryUiPreferences()),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const EzanApp()),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);

    expect(find.byKey(const Key('home-dashboard')), findsNothing);
    expect(find.text('EZAN'), findsOneWidget);
    expect(find.text('Use location'), findsOneWidget);
    expect(find.text('Qibla'), findsNothing);
    expect(find.text('Settings'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard contains prayer times, Qibla and modal settings', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(411, 891);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        prayerDashboardProvider.overrideWith(
          () => _StaticPrayerDashboardController(
            _dashboardState(hasLocation: true),
          ),
        ),
        uiPreferencesProvider.overrideWithValue(_MemoryUiPreferences()),
        prayerAlarmSchedulerProvider.overrideWithValue(
          _DisabledPrayerAlarmScheduler(),
        ),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const EzanApp()),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.byKey(const Key('home-dashboard')), findsOneWidget);
    expect(find.byKey(const Key('home-cityscape')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const Key('home-cityscape'))).dy,
      closeTo(0, 1),
    );
    expect(
      tester.getBottomRight(find.byKey(const Key('home-prayer-quote'))).dy,
      closeTo(891, 1),
    );
    expect(find.byKey(const Key('qibla-section')), findsOneWidget);
    expect(find.byKey(const Key('qibla-landscape-background')), findsOneWidget);
    expect(find.byKey(const Key('qibla-kaaba-illustration')), findsOneWidget);
    expect(find.textContaining('°'), findsNothing);
    expect(find.byType(Scrollable), findsNothing);
    expect(find.text('Fajr'), findsOneWidget);
    expect(find.text('Sunrise'), findsOneWidget);
    expect(find.text('Dhuhr'), findsOneWidget);
    expect(find.text('Asr'), findsOneWidget);
    expect(find.text('Maghrib'), findsOneWidget);
    expect(find.text('Isha'), findsOneWidget);
    expect(find.byKey(const Key('open-settings')), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
    expect(find.text('Qibla'), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('open-settings')));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Calculation method'), findsOneWidget);
    expect(find.text('Asr method'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const Key('close-settings')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byKey(const Key('home-dashboard')), findsOneWidget);

    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      '/home',
    );

    container.read(appRouterProvider).go('/qibla');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      container.read(appRouterProvider).routeInformationProvider.value.uri.path,
      '/home',
    );
  });

  testWidgets(
    'premium screens adapt across sizes, themes, locales and scaling',
    (tester) async {
      final container = ProviderContainer(
        overrides: [
          locationServiceProvider.overrideWithValue(_KnownLocationService()),
          timeZoneServiceProvider.overrideWithValue(_UtcTimeZoneService()),
          prayerCalculationPreferencesProvider.overrideWithValue(
            _MemoryCalculationPreferences(),
          ),
          uiPreferencesProvider.overrideWithValue(_MemoryUiPreferences()),
          prayerAlarmSchedulerProvider.overrideWithValue(
            _DisabledPrayerAlarmScheduler(),
          ),
        ],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(container: container, child: const EzanApp()),
      );

      const viewports = [
        Size(320, 640),
        Size(360, 800),
        Size(411, 891),
        Size(600, 960),
        Size(800, 400),
      ];
      const modes = [ThemeMode.system, ThemeMode.light, ThemeMode.dark];
      const locales = [Locale('tr'), Locale('en')];
      const routes = ['/home'];
      final router = container.read(appRouterProvider);

      for (final viewport in viewports) {
        tester.view.physicalSize = viewport;
        tester.view.devicePixelRatio = 1;
        for (final mode in modes) {
          container.read(themeModeProvider.notifier).setMode(mode);
          for (final locale in locales) {
            container.read(localeProvider.notifier).setLocale(locale);
            for (final route in routes) {
              router.go(route);
              await tester.pump();
              await tester.pump(const Duration(milliseconds: 220));
              expect(
                tester.takeException(),
                isNull,
                reason: '$route at $viewport, $mode, ${locale.languageCode}',
              );
            }
          }
        }
      }

      tester.binding.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(
        tester.binding.platformDispatcher.clearTextScaleFactorTestValue,
      );
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      for (final mode in modes) {
        container.read(themeModeProvider.notifier).setMode(mode);
        for (final locale in locales) {
          container.read(localeProvider.notifier).setLocale(locale);
          for (final route in routes) {
            router.go(route);
            await tester.pump();
            await tester.pump(const Duration(milliseconds: 220));
            expect(
              tester.takeException(),
              isNull,
              reason:
                  '$route at 320x640, 160% text, $mode, ${locale.languageCode}',
            );
          }
        }
      }

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    },
  );

  test('theme and locale choices restore from local preferences', () async {
    final preferences = _MemoryUiPreferences();
    final firstContainer = ProviderContainer(
      overrides: [uiPreferencesProvider.overrideWithValue(preferences)],
    );
    firstContainer.read(themeModeProvider.notifier).setMode(ThemeMode.dark);
    firstContainer.read(localeProvider.notifier).setLocale(const Locale('en'));
    await Future<void>.delayed(Duration.zero);
    firstContainer.dispose();

    final reopenedContainer = ProviderContainer(
      overrides: [uiPreferencesProvider.overrideWithValue(preferences)],
    );
    addTearDown(reopenedContainer.dispose);
    reopenedContainer.read(themeModeProvider);
    reopenedContainer.read(localeProvider);
    await Future<void>.delayed(Duration.zero);

    expect(reopenedContainer.read(themeModeProvider), ThemeMode.dark);
    expect(reopenedContainer.read(localeProvider), const Locale('en'));
  });
}

class _UtcTimeZoneService implements TimeZoneService {
  @override
  Future<String> getLocalTimeZoneId() async => 'Etc/UTC';
}

class _KnownLocationService implements LocationService {
  static const _location = DeviceLocation(
    latitude: 41.0082,
    longitude: 28.9784,
  );

  @override
  Future<DeviceLocation> getCurrentLocation() async => _location;

  @override
  Future<DeviceLocation?> getLastKnownLocation() async => _location;
}

class _DisabledPrayerAlarmScheduler implements PrayerAlarmScheduler {
  @override
  Future<PrayerAlarmStatus> getStatus() async =>
      const PrayerAlarmStatus(exactAlarmAllowed: false, enabled: false);

  @override
  Future<void> requestExactAlarmAccess() async {}

  @override
  Future<void> disable() async {}

  @override
  Future<void> replaceSchedule(List<PrayerAlarmEvent> events) async {}
}

class _MemoryCalculationPreferences implements PrayerCalculationPreferences {
  @override
  Future<AsrMethod> getAsrMethod() async => AsrMethod.standard;

  @override
  Future<void> setAsrMethod(AsrMethod method) async {}
}

class _MemoryUiPreferences implements UiPreferences {
  String? themeMode;
  String? locale;
  String? qiblaNorthReference;

  @override
  Future<String?> getThemeMode() async => themeMode;

  @override
  Future<void> setThemeMode(String mode) async {
    themeMode = mode;
  }

  @override
  Future<String?> getLocale() async => locale;

  @override
  Future<void> setLocale(String? languageCode) async {
    locale = languageCode;
  }

  @override
  Future<String?> getQiblaNorthReference() async => qiblaNorthReference;

  @override
  Future<void> setQiblaNorthReference(String reference) async {
    qiblaNorthReference = reference;
  }
}

class _StaticPrayerDashboardController extends PrayerDashboardController {
  _StaticPrayerDashboardController(this._dashboard);

  final PrayerDashboardState _dashboard;

  @override
  Future<PrayerDashboardState> build() async => _dashboard;
}

PrayerDashboardState _dashboardState({required bool hasLocation}) {
  final now = DateTime.utc(2026, 9, 26);
  final location = hasLocation
      ? const DeviceLocation(latitude: 41.0082, longitude: 28.9784)
      : null;
  final schedule = hasLocation
      ? PrayerSchedule(
          times: {
            PrayerName.fajr: DateTime.utc(2026, 9, 26, 5),
            PrayerName.sunrise: DateTime.utc(2026, 9, 26, 6, 30),
            PrayerName.dhuhr: DateTime.utc(2026, 9, 26, 13),
            PrayerName.asr: DateTime.utc(2026, 9, 26, 16),
            PrayerName.maghrib: DateTime.utc(2026, 9, 26, 19),
            PrayerName.isha: DateTime.utc(2026, 9, 26, 21),
          },
          tomorrowFajr: DateTime.utc(2026, 9, 27, 5),
        )
      : null;

  return PrayerDashboardState(
    timeZoneId: 'Etc/UTC',
    now: now,
    location: location,
    schedule: schedule,
    asrMethod: AsrMethod.standard,
  );
}
