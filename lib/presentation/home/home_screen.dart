import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../application/adhan/adhan_audio_preview_controller.dart';
import '../../application/prayer/prayer_dashboard_controller.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/location/location_service.dart';
import '../../domain/prayer/prayer_calculation_service.dart';
import '../../domain/prayer/prayer_verses.dart';
import '../../l10n/generated/app_localizations.dart';
import '../qibla/qibla_screen.dart';
import '../settings/settings_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  late final PrayerVerse _prayerVerse = randomPrayerVerse();

  void _showSettings() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => FractionallySizedBox(
        heightFactor: 0.92,
        child: SettingsScreen(onClose: () => Navigator.of(sheetContext).pop()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final dashboard = ref.watch(prayerDashboardProvider);
    final adhanStatus = ref.watch(adhanPlaybackStatusProvider).asData?.value;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: Theme.of(context).colorScheme.surface,
        systemNavigationBarIconBrightness: isDark
            ? Brightness.light
            : Brightness.dark,
        systemNavigationBarDividerColor: Theme.of(context).colorScheme.outline,
      ),
      child: Scaffold(
        body: dashboard.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                l10n.timeZoneUnavailable,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (state) {
            final location = state.location;
            final schedule = state.schedule;
            if (location == null || schedule == null) {
              return SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: _BrandHeader(onSettings: _showSettings),
                    ),
                    if (adhanStatus?.isPlaying ?? false) ...[
                      const SizedBox(height: AppSpacing.xs),
                      _AdhanMuteButton(isMuted: adhanStatus!.isMuted),
                    ],
                    Expanded(
                      child: _LocationPrompt(
                        loading: state.locationLoading,
                        failure: state.locationFailure,
                        onRequest: () => ref
                            .read(prayerDashboardProvider.notifier)
                            .requestLocation(),
                      ),
                    ),
                  ],
                ),
              );
            }

            final nextPrayer = schedule.nextPrayerAfter(state.now);
            final prayerRows = <(PrayerName, String)>[
              (PrayerName.fajr, l10n.fajrLabel),
              (PrayerName.sunrise, l10n.sunriseLabel),
              (PrayerName.dhuhr, l10n.dhuhrLabel),
              (PrayerName.asr, l10n.asrLabel),
              (PrayerName.maghrib, l10n.maghribLabel),
              (PrayerName.isha, l10n.ishaLabel),
            ];

            return LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                final ultraCompact = height < 500;
                final compact = height < 760;
                final showVerse = height >= 800;
                final topVisualHeight = compact
                    ? (height * 0.22).clamp(96.0, 140.0).toDouble()
                    : (height * 0.27).clamp(180.0, 250.0).toDouble();
                final sectionGap = ultraCompact
                    ? 2.0
                    : compact
                    ? 4.0
                    : 8.0;
                final dashboard = ConstrainedBox(
                  key: const Key('home-dashboard'),
                  constraints: BoxConstraints(
                    maxWidth: compact ? constraints.maxWidth : 620,
                  ),
                  child: Column(
                    mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
                    mainAxisAlignment: showVerse
                        ? MainAxisAlignment.spaceBetween
                        : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: _BrandHeader(
                          onSettings: _showSettings,
                          compact: compact,
                          ultraCompact: ultraCompact,
                        ),
                      ),
                      if (adhanStatus?.isPlaying ?? false) ...[
                        SizedBox(height: ultraCompact ? 1 : AppSpacing.xs),
                        _AdhanMuteButton(
                          isMuted: adhanStatus!.isMuted,
                          compact: compact,
                        ),
                      ],
                      SizedBox(height: ultraCompact ? 0 : AppSpacing.xxs),
                      if (state.locationFailure != null && !ultraCompact)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: Text(
                            _locationFailureMessage(
                              l10n,
                              state.locationFailure!,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                          ),
                        ),
                      SizedBox(height: compact ? 2 : AppSpacing.xxs),
                      _NextPrayerHero(
                        title: l10n.nextPrayerTitle,
                        prayer: _prayerName(l10n, nextPrayer.name),
                        time: DateFormat.Hm(l10n.localeName)
                            .format(nextPrayer.time),
                        targetTime: nextPrayer.time,
                        initialNow: state.now,
                        compact: compact,
                        ultraCompact: ultraCompact,
                      ),
                      SizedBox(height: sectionGap),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: _PrayerTimeStrip(
                          rows: prayerRows,
                          times: schedule.times,
                          nextPrayer: nextPrayer.name,
                          localeName: l10n.localeName,
                          compact: compact,
                          ultraCompact: ultraCompact,
                        ),
                      ),
                      SizedBox(height: sectionGap),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                        ),
                        child: QiblaSection(
                          compact: compact,
                          ultraCompact: ultraCompact,
                        ),
                      ),
                      if (showVerse) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                          ),
                          child: _PrayerVerseFooter(
                            compact: compact,
                            verse: _prayerVerse,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
                final topInset = MediaQuery.viewPaddingOf(context).top;
                return Stack(
                  fit: StackFit.expand,
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      height: topVisualHeight + topInset,
                      child: _HomeTopVisual(height: topVisualHeight + topInset),
                    ),
                    SafeArea(
                      child: Center(
                        child: compact
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.topCenter,
                                child: dashboard,
                              )
                            : dashboard,
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _AdhanMuteButton extends ConsumerWidget {
  const _AdhanMuteButton({required this.isMuted, this.compact = false});

  final bool isMuted;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final label = isMuted ? l10n.unmuteAdhan : l10n.muteAdhan;
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: isMuted ? scheme.surfaceContainer : scheme.primary,
      foregroundColor: isMuted ? scheme.primary : scheme.onPrimary,
      side: isMuted ? BorderSide(color: scheme.primary) : null,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 14 : 16,
        vertical: compact ? 7 : 9,
      ),
      minimumSize: const Size(0, 40),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: compact ? VisualDensity.compact : VisualDensity.standard,
      shape: const StadiumBorder(),
    );

    return Center(
      child: Semantics(
        liveRegion: true,
        child: FilledButton.icon(
          key: const Key('adhan-mute-toggle'),
          style: buttonStyle,
          onPressed: () async {
            await ref
                .read(adhanPlaybackServiceProvider)
                .setPlaybackMuted(!isMuted);
          },
          icon: Icon(
            isMuted ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            size: 18,
          ),
          label: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(fontSize: 13),
          ),
        ),
      ),
    );
  }
}

class _HomeTopVisual extends StatelessWidget {
  const _HomeTopVisual({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surface = theme.colorScheme.surface;
    final image = theme.brightness == Brightness.dark
        ? 'assets/images/istanbul_night.png'
        : 'assets/images/istanbul_dawn.png';

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            image,
            key: const Key('home-cityscape'),
            fit: BoxFit.cover,
            alignment: const Alignment(0, 0.12),
            excludeFromSemantics: true,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0, 0.42, 0.76, 1],
                colors: [
                  surface.withValues(alpha: 0.02),
                  surface.withValues(alpha: 0.05),
                  surface.withValues(alpha: 0.72),
                  surface,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({
    required this.onSettings,
    this.compact = false,
    this.ultraCompact = false,
  });

  final VoidCallback onSettings;
  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(
        vertical: ultraCompact
            ? 0
            : compact
            ? 1
            : AppSpacing.xxs,
      ),
      child: SizedBox(
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.appTitle.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontFamily: AppTypography.editorialFamily,
                      fontSize: ultraCompact
                          ? 18
                          : compact
                          ? 21
                          : null,
                      height: 0.95,
                      letterSpacing: 3.2,
                    ),
                  ),
                  Text(
                    l10n.appTagline,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: ultraCompact
                          ? 9
                          : compact
                          ? 10
                          : 12,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 0,
              child: IconButton(
                key: const Key('open-settings'),
                tooltip: l10n.settingsTitle,
                onPressed: onSettings,
                color: theme.colorScheme.primary,
                iconSize: ultraCompact
                    ? 18
                    : compact
                    ? 20
                    : 24,
                padding: EdgeInsets.zero,
                visualDensity: compact
                    ? VisualDensity.compact
                    : VisualDensity.standard,
                constraints: BoxConstraints.tightFor(
                  width: ultraCompact
                      ? 32
                      : compact
                      ? 36
                      : 48,
                  height: ultraCompact
                      ? 32
                      : compact
                      ? 36
                      : 48,
                ),
                icon: const Icon(Icons.settings_outlined),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextPrayerHero extends StatelessWidget {
  const _NextPrayerHero({
    required this.title,
    required this.prayer,
    required this.time,
    required this.targetTime,
    required this.initialNow,
    required this.compact,
    required this.ultraCompact,
  });

  final String title;
  final String prayer;
  final String time;
  final DateTime targetTime;
  final DateTime initialNow;
  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final width = MediaQuery.sizeOf(context).width;
    final prayerFontSize = ultraCompact
        ? 24.0
        : compact
        ? 30.0
        : (width * 0.09).clamp(36.0, 42.0).toDouble();
    final timeFontSize = ultraCompact
        ? 38.0
        : compact
        ? 48.0
        : (width * 0.14).clamp(52.0, 60.0).toDouble();
    final focusColor = isDark ? colorScheme.primary : AppColors.brand;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontSize: ultraCompact
                  ? 11
                  : compact
                  ? 12
                  : null,
              letterSpacing: 1.1,
            ),
          ),
          Text(
            prayer.toUpperCase(),
            textAlign: TextAlign.center,
            style: theme.textTheme.displayMedium?.copyWith(
              fontSize: prayerFontSize,
              letterSpacing: 1.6,
              height: 1.04,
            ),
          ),
          Text(
            time,
            textAlign: TextAlign.center,
            style: theme.textTheme.displayLarge?.copyWith(
              color: focusColor,
              fontSize: timeFontSize,
              letterSpacing: -1.2,
              height: 0.98,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          _CountdownDisplay(
            targetTime: targetTime,
            initialNow: initialNow,
            compact: compact,
            ultraCompact: ultraCompact,
          ),
        ],
      ),
    );
  }
}

class _CountdownDisplay extends StatefulWidget {
  const _CountdownDisplay({
    required this.targetTime,
    required this.initialNow,
    required this.compact,
    required this.ultraCompact,
  });

  final DateTime targetTime;
  final DateTime initialNow;
  final bool compact;
  final bool ultraCompact;

  @override
  State<_CountdownDisplay> createState() => _CountdownDisplayState();
}

class _CountdownDisplayState extends State<_CountdownDisplay> {
  late DateTime _now = widget.initialNow;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void didUpdateWidget(covariant _CountdownDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.targetTime != widget.targetTime ||
        oldWidget.initialNow != widget.initialNow) {
      _now = widget.initialNow;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining = widget.targetTime.difference(_now);
    final minutes = remaining.inMinutes.clamp(0, 24 * 60);
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final countdownFontSize = widget.ultraCompact
        ? 14.0
        : widget.compact
        ? 16.0
        : 20.0;
    final suffixFontSize = widget.ultraCompact
        ? 11.0
        : widget.compact
        ? 13.0
        : 16.0;
    return Semantics(
      label: l10n.timeRemaining(minutes ~/ 60, minutes % 60),
      child: ExcludeSemantics(
        child: Padding(
          padding: EdgeInsets.only(top: widget.ultraCompact ? 0 : 2),
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: _countdownText(remaining),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontSize: countdownFontSize,
                    fontWeight: FontWeight.w400,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                TextSpan(
                  text: ' ${l10n.countdownSuffix}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: suffixFontSize,
                  ),
                ),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _PrayerTimeStrip extends StatelessWidget {
  const _PrayerTimeStrip({
    required this.rows,
    required this.times,
    required this.nextPrayer,
    required this.localeName,
    required this.compact,
    required this.ultraCompact,
  });

  final List<(PrayerName, String)> rows;
  final Map<PrayerName, DateTime> times;
  final PrayerName nextPrayer;
  final String localeName;
  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.all(
        ultraCompact
            ? 1
            : compact
            ? 2
            : AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.92),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          for (final (prayer, label) in rows)
            Expanded(
              child: _PrayerTimeTile(
                prayer: prayer,
                label: label,
                time: DateFormat.Hm(localeName).format(times[prayer]!),
                selected: prayer == nextPrayer,
                compact: compact,
                ultraCompact: ultraCompact,
              ),
            ),
        ],
      ),
    );
  }
}

class _PrayerTimeTile extends StatelessWidget {
  const _PrayerTimeTile({
    required this.prayer,
    required this.label,
    required this.time,
    required this.selected,
    required this.compact,
    required this.ultraCompact,
  });

  final PrayerName prayer;
  final String label;
  final String time;
  final bool selected;
  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected
        ? scheme.onPrimaryContainer
        : scheme.onSurfaceVariant;
    final iconSize = ultraCompact
        ? 12.0
        : compact
        ? 14.0
        : 17.0;
    final icon = switch (prayer) {
      PrayerName.fajr => Icons.wb_twilight_outlined,
      PrayerName.sunrise => Icons.wb_sunny_outlined,
      PrayerName.dhuhr => Icons.wb_sunny_rounded,
      PrayerName.asr => Icons.light_mode_outlined,
      PrayerName.maghrib => Icons.wb_twilight_rounded,
      PrayerName.isha => Icons.nightlight_outlined,
    };
    return Semantics(
      label: '$label, $time',
      child: ExcludeSemantics(
        child: Container(
          constraints: BoxConstraints(
            minHeight: ultraCompact
                ? 54
                : compact
                ? 62
                : 76,
          ),
          margin: const EdgeInsets.symmetric(horizontal: 1),
          padding: EdgeInsets.symmetric(
            vertical: ultraCompact
                ? 1
                : compact
                ? 2
                : AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: selected ? scheme.primaryContainer : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: iconSize, color: foreground),
              SizedBox(height: ultraCompact ? 1 : 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: ultraCompact
                      ? 8
                      : compact
                      ? 9
                      : 10,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: ultraCompact ? 0 : 1),
              Text(
                time,
                maxLines: 1,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: ultraCompact
                      ? 9
                      : compact
                      ? 10
                      : 12,
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrayerVerseFooter extends StatelessWidget {
  const _PrayerVerseFooter({required this.compact, required this.verse});

  final bool compact;
  final PrayerVerse verse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Container(
      key: const Key('home-prayer-quote'),
      padding: EdgeInsets.fromLTRB(
        compact ? 14 : 18,
        compact ? 7 : 10,
        compact ? 14 : 18,
        compact ? 8 : 10,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow.withValues(alpha: 0.42),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 1.5,
            color: scheme.primary.withValues(alpha: 0.75),
          ),
          SizedBox(height: compact ? 5 : 8),
          Text(
            '“${l10n.localeName == 'tr' ? verse.tr : verse.en}”',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleSmall?.copyWith(
              fontFamily: AppTypography.editorialFamily,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w400,
              fontSize: compact ? 12 : null,
              height: 1.3,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            verse.reference
                .split(' · ')
                .elementAt(l10n.localeName == 'tr' ? 0 : 1),
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: compact ? 10 : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationPrompt extends StatelessWidget {
  const _LocationPrompt({
    required this.loading,
    required this.failure,
    required this.onRequest,
  });

  final bool loading;
  final LocationFailureReason? failure;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final message = failure == null
        ? l10n.locationRequestExplanation
        : _locationFailureMessage(l10n, failure!);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 34,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                l10n.locationPrivacyNote,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton.icon(
                onPressed: loading ? null : onRequest,
                icon: loading
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location_outlined),
                label: Text(
                  loading ? l10n.locationLoading : l10n.locationRequestButton,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _prayerName(AppLocalizations l10n, PrayerName prayer) =>
    switch (prayer) {
      PrayerName.fajr => l10n.fajrLabel,
      PrayerName.sunrise => l10n.sunriseLabel,
      PrayerName.dhuhr => l10n.dhuhrLabel,
      PrayerName.asr => l10n.asrLabel,
      PrayerName.maghrib => l10n.maghribLabel,
      PrayerName.isha => l10n.ishaLabel,
    };

String _countdownText(Duration remaining) {
  final seconds = remaining.inSeconds.clamp(0, 99 * 60 * 60 + 3599);
  final hours = (seconds ~/ 3600).toString().padLeft(2, '0');
  final minutes = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
  final remainder = (seconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$remainder';
}

String _locationFailureMessage(
  AppLocalizations l10n,
  LocationFailureReason failure,
) => switch (failure) {
  LocationFailureReason.servicesDisabled => l10n.locationServicesDisabled,
  LocationFailureReason.permissionDenied => l10n.locationPermissionDenied,
  LocationFailureReason.permissionPermanentlyDenied =>
    l10n.locationPermissionPermanentlyDenied,
  LocationFailureReason.unavailable => l10n.locationUnavailable,
};
