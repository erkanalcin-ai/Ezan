import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

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
  static const AssetImage _launchSplashImage = AssetImage(
    'assets/images/ezan_splash.png',
  );

  Timer? _scheduleCheck;
  Timer? _launchSplashTimer;
  Timer? _playUpdatePromptTimer;
  bool _launchSplashPrecacheStarted = false;
  bool _showLaunchSplash = true;
  bool _isForeground = true;
  bool _showPlayUpdateButton = false;
  bool _playUpdateCheckStarted = false;
  bool _playUpdateFlowStarted = false;

  static const _playUpdateChannel = MethodChannel('com.ezan.app/play_updates');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _launchSplashTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _showLaunchSplash = false);
      unawaited(_checkForPlayUpdate());
    });
    _scheduleCheck = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isForeground) unawaited(_refreshIfNeeded());
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_launchSplashPrecacheStarted) return;
    _launchSplashPrecacheStarted = true;
    unawaited(precacheImage(_launchSplashImage, context));
  }

  @override
  void dispose() {
    _scheduleCheck?.cancel();
    _launchSplashTimer?.cancel();
    _playUpdatePromptTimer?.cancel();
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

  Future<void> _checkForPlayUpdate() async {
    if (_playUpdateCheckStarted || !_isForeground) return;
    _playUpdateCheckStarted = true;
    try {
      final updateAvailable =
          await _playUpdateChannel.invokeMethod<bool>('checkForUpdate') ??
          false;
      if (!mounted || !updateAvailable) return;
      setState(() => _showPlayUpdateButton = true);
      _playUpdatePromptTimer = Timer(const Duration(seconds: 2), () {
        if (!mounted) return;
        setState(() => _showPlayUpdateButton = false);
        unawaited(_startImmediateUpdate());
      });
    } on PlatformException {
      // Updates are available only for eligible Play-installed Android builds.
    } on MissingPluginException {
      // Keep widget tests and non-Android builds independent of Play Core.
    }
  }

  Future<void> _startImmediateUpdate() async {
    if (_playUpdateFlowStarted || !_isForeground) return;
    _playUpdateFlowStarted = true;
    try {
      await _playUpdateChannel.invokeMethod<bool>('startImmediateUpdate');
    } on PlatformException {
      // Play Core may reject the flow if the update is no longer available.
    } on MissingPluginException {
      // Keep widget tests and non-Android builds independent of Play Core.
    }
  }

  void _startUpdateFromButton() {
    _playUpdatePromptTimer?.cancel();
    setState(() => _showPlayUpdateButton = false);
    unawaited(_startImmediateUpdate());
  }

  Widget _buildLaunchSplash() {
    return ExcludeSemantics(
      child: ColoredBox(
        color: const Color(0xFF253A2E),
        child: Image(
          image: _launchSplashImage,
          fit: BoxFit.cover,
          gaplessPlayback: true,
        ),
      ),
    );
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
          if (_showLaunchSplash) _buildLaunchSplash(),
          if (_showPlayUpdateButton)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: FilledButton.icon(
                      onPressed: _startUpdateFromButton,
                      icon: const Icon(Icons.system_update_alt_rounded),
                      label: Text(AppLocalizations.of(context)!.updateNow),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
