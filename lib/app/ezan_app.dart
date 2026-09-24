import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/prayer/prayer_alarm_settings_controller.dart';
import '../application/prayer/prayer_dashboard_controller.dart';
import '../application/theme/theme_mode_notifier.dart';
import '../core/theme/app_theme.dart';
import '../l10n/generated/app_localizations.dart';
import 'app_router.dart';

class EzanApp extends ConsumerStatefulWidget {
  const EzanApp({super.key});

  @override
  ConsumerState<EzanApp> createState() => _EzanAppState();
}

class _EzanAppState extends ConsumerState<EzanApp> with WidgetsBindingObserver {
  Timer? _scheduleCheck;
  Timer? _launchSplashTimer;
  bool _showLaunchSplash = true;
  bool _isForeground = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _launchSplashTimer = Timer(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => _showLaunchSplash = false);
    });
    _scheduleCheck = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isForeground) unawaited(_refreshIfNeeded());
    });
  }

  @override
  void dispose() {
    _scheduleCheck?.cancel();
    _launchSplashTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshIfNeeded(refreshSettings: true));
    }
  }

  Future<void> _refreshIfNeeded({bool refreshSettings = false}) async {
    try {
      await ref.read(prayerDashboardProvider.notifier).refreshClock();
      final status = refreshSettings
          ? await ref.read(prayerAlarmSettingsProvider.notifier).refresh()
          : await ref.read(prayerAlarmSchedulerProvider).getStatus();
      if (status.enabled && status.scheduleInvalidated) {
        await ref.read(prayerDashboardProvider.notifier).syncAlarms();
      }
    } catch (_) {
      // A transient platform-channel failure is retried at the next foreground check.
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      onGenerateTitle: (context) => AppLocalizations.of(context)!.appTitle,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(appRouterProvider),
      builder: (context, child) => Stack(
        fit: StackFit.expand,
        children: [
          child ?? const SizedBox.shrink(),
          if (_showLaunchSplash)
            ExcludeSemantics(
              child: Image.asset(
                'assets/images/ezan_splash.png',
                fit: BoxFit.cover,
                gaplessPlayback: true,
              ),
            ),
        ],
      ),
    );
  }
}
