import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../application/adhan/adhan_audio_catalog.dart';
import '../../application/adhan/adhan_audio_preview_controller.dart';
import '../../application/prayer/prayer_alarm_settings_controller.dart';
import '../../application/prayer/prayer_dashboard_controller.dart';
import '../../application/qibla/qibla_providers.dart';
import '../../application/theme/theme_mode_notifier.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/prayer/prayer_calculation_service.dart';
import '../../domain/qibla/qibla_north_reference.dart';
import '../../l10n/generated/app_localizations.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({this.onClose, super.key});

  final VoidCallback? onClose;

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();
  bool _isStartingAdhan = false;

  static const _privacyPolicyChannel = MethodChannel(
    'com.ezan.app/privacy_policy',
  );

  Future<void> _playAdhan() async {
    setState(() => _isStartingAdhan = true);
    try {
      await ref
          .read(adhanPlaybackServiceProvider)
          .play(AdhanAudioCatalog.forPrayer(PrayerName.fajr));
      if (mounted) {
        ref.read(adhanManualPlaybackMutedProvider.notifier).setMuted(false);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.adhanPlaybackFailed),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStartingAdhan = false);
    }
  }

  Future<void> _toggleAdhanMute(
    bool isMuted, {
    required bool scheduledPlayback,
  }) async {
    final nextMuted = !isMuted;
    final changed = await ref
        .read(adhanPlaybackServiceProvider)
        .setPlaybackMuted(nextMuted);
    if (changed && mounted && !scheduledPlayback) {
      ref.read(adhanManualPlaybackMutedProvider.notifier).setMuted(nextMuted);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final alarmStatus = ref.watch(prayerAlarmSettingsProvider).asData?.value;
    final dashboard = ref.watch(prayerDashboardProvider).asData?.value;
    final volume = ref.watch(adhanVolumeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);
    final qiblaNorthReference = ref.watch(qiblaNorthReferenceProvider);
    final manualPlaybackMuted = ref.watch(adhanManualPlaybackMutedProvider);
    final playbackStatus = ref.watch(adhanPlaybackStatusProvider).asData?.value;
    final scheduledPlayback = playbackStatus?.isPlaying ?? false;
    final isMuted = scheduledPlayback
        ? playbackStatus!.isMuted
        : manualPlaybackMuted;
    final selected = dashboard?.asrMethod ?? AsrMethod.standard;
    final previewStatus = kDebugMode
        ? ref.watch(adhanAudioPreviewProvider)
        : AdhanAudioPreviewStatus.stopped;
    final activeLocale = locale ?? Localizations.localeOf(context);
    final currentVolume = volume.asData?.value;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl,
      ),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.settingsTitle,
                        style: theme.textTheme.headlineMedium,
                      ),
                    ),
                    if (widget.onClose != null)
                      IconButton(
                        key: const Key('close-settings'),
                        tooltip: MaterialLocalizations.of(context)
                            .closeButtonTooltip,
                        onPressed: widget.onClose,
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                _SettingsSectionTitle(title: l10n.locationSectionTitle),
                _SettingsGroup(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _LeadingIcon(icon: Icons.location_on_outlined),
                    title: Text(
                      dashboard?.location == null
                          ? l10n.locationRequestButton
                          : l10n.locationCoordinates(
                              dashboard!.location!.latitude.toStringAsFixed(4),
                              dashboard.location!.longitude.toStringAsFixed(4),
                            ),
                    ),
                    subtitle: Text(l10n.locationPrivacyNote),
                    trailing: IconButton(
                      tooltip: l10n.locationRefreshButton,
                      onPressed: dashboard?.locationLoading == true
                          ? null
                          : () => ref
                                .read(prayerDashboardProvider.notifier)
                                .requestLocation(),
                      icon: dashboard?.locationLoading == true
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh_rounded),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SettingsSectionTitle(title: l10n.qiblaSectionTitle),
                _SettingsGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.qiblaNorthReferenceDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      RadioGroup<QiblaNorthReference>(
                        groupValue: qiblaNorthReference,
                        onChanged: (reference) {
                          if (reference != null) {
                            ref
                                .read(qiblaNorthReferenceProvider.notifier)
                                .setReference(reference);
                          }
                        },
                        child: Column(
                          children: [
                            RadioListTile<QiblaNorthReference>(
                              visualDensity: VisualDensity.compact,
                              contentPadding: EdgeInsets.zero,
                              value: QiblaNorthReference.trueNorth,
                              title: Text(l10n.trueNorth),
                            ),
                            RadioListTile<QiblaNorthReference>(
                              visualDensity: VisualDensity.compact,
                              contentPadding: EdgeInsets.zero,
                              value: QiblaNorthReference.magneticNorth,
                              title: Text(l10n.magneticNorth),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SettingsSectionTitle(title: l10n.calculationMethod),
                _SettingsGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.turkiyeCalculationApproximation,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(l10n.asrMethod, style: theme.textTheme.titleSmall),
                      const SizedBox(height: 4),
                      RadioGroup<AsrMethod>(
                        groupValue: selected,
                        onChanged: (method) {
                          if (method != null) {
                            ref
                                .read(prayerDashboardProvider.notifier)
                                .setAsrMethod(method);
                          }
                        },
                        child: Column(
                          children: [
                            RadioListTile<AsrMethod>(
                              visualDensity: VisualDensity.compact,
                              contentPadding: EdgeInsets.zero,
                              value: AsrMethod.standard,
                              title: Text(l10n.standardAsr),
                            ),
                            RadioListTile<AsrMethod>(
                              visualDensity: VisualDensity.compact,
                              contentPadding: EdgeInsets.zero,
                              value: AsrMethod.hanafi,
                              title: Text(l10n.hanafiAsr),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SettingsSectionTitle(title: l10n.adhanSectionTitle),
                _SettingsGroup(
                  child: Column(
                    children: [
                      SwitchListTile.adaptive(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                        title: Text(l10n.adhanAlarmTitle),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            alarmStatus?.exactAlarmAllowed == false
                                ? l10n.exactAlarmPermissionNeeded
                                : l10n.adhanAlarmDescription,
                          ),
                        ),
                        value: alarmStatus?.enabled ?? false,
                        onChanged: (enabled) {
                          final controller = ref.read(
                            prayerAlarmSettingsProvider.notifier,
                          );
                          if (enabled) {
                            controller.enableOrRequestPermission().then((_) {
                              ref
                                  .read(prayerDashboardProvider.notifier)
                                  .syncAlarms();
                            });
                          } else {
                            controller.disable();
                          }
                        },
                      ),
                      const _PanelDivider(),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text(l10n.volumeTitle)),
                                Text(
                                  currentVolume == null
                                      ? '—'
                                      : '${(currentVolume * 100).round()}%',
                                  style: theme.textTheme.labelLarge?.copyWith(
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: currentVolume ?? 1,
                              onChanged: currentVolume == null
                                  ? null
                                  : (value) => unawaited(
                                      ref
                                          .read(adhanVolumeProvider.notifier)
                                          .setVolume(value),
                                    ),
                            ),
                          ],
                        ),
                      ),
                      const _PanelDivider(),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilledButton.icon(
                              key: const Key('settings-play-adhan'),
                              onPressed: _isStartingAdhan || scheduledPlayback
                                  ? null
                                  : _playAdhan,
                              icon: _isStartingAdhan
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.play_arrow_rounded),
                              label: Text(l10n.playAdhan),
                            ),
                            OutlinedButton.icon(
                              key: const Key('settings-mute-adhan'),
                              onPressed: () => _toggleAdhanMute(
                                isMuted,
                                scheduledPlayback: scheduledPlayback,
                              ),
                              icon: Icon(
                                isMuted
                                    ? Icons.volume_up_rounded
                                    : Icons.volume_off_rounded,
                              ),
                              label: Text(
                                isMuted ? l10n.unmuteAdhan : l10n.muteAdhan,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (kDebugMode) ...[
                        const _PanelDivider(),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.placeholderAudioNotice,
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  FilledButton.icon(
                                    onPressed: () => ref
                                        .read(
                                          adhanAudioPreviewProvider.notifier,
                                        )
                                        .play(),
                                    icon: const Icon(Icons.play_arrow_rounded),
                                    label: Text(l10n.playPlaceholderAudio),
                                  ),
                                  OutlinedButton.icon(
                                    onPressed: () => ref
                                        .read(
                                          adhanAudioPreviewProvider.notifier,
                                        )
                                        .stop(),
                                    icon: const Icon(Icons.stop_rounded),
                                    label: Text(l10n.stopAudio),
                                  ),
                                ],
                              ),
                              if (previewStatus ==
                                  AdhanAudioPreviewStatus.failed)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    l10n.audioPlaybackFailed,
                                    style: TextStyle(color: scheme.error),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SettingsSectionTitle(title: l10n.appearanceTitle),
                _SettingsGroup(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 48,
                        child: Row(
                          children: [
                            Text(
                              l10n.themeTitle,
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<ThemeMode>(
                                  value: themeMode,
                                  isExpanded: true,
                                  alignment: AlignmentDirectional.centerEnd,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.sm,
                                  ),
                                  items: [
                                    DropdownMenuItem(
                                      value: ThemeMode.system,
                                      child: Text(
                                        l10n.systemTheme,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    DropdownMenuItem(
                                      value: ThemeMode.light,
                                      child: Text(l10n.lightTheme),
                                    ),
                                    DropdownMenuItem(
                                      value: ThemeMode.dark,
                                      child: Text(l10n.darkTheme),
                                    ),
                                  ],
                                  onChanged: (mode) {
                                    if (mode != null) {
                                      ref
                                          .read(themeModeProvider.notifier)
                                          .setMode(mode);
                                    }
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        l10n.languageTitle,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        isExpanded: true,
                        initialValue: activeLocale.languageCode == 'tr'
                            ? 'tr'
                            : 'en',
                        decoration: const InputDecoration(),
                        items: [
                          DropdownMenuItem(
                            value: 'tr',
                            child: Text(l10n.turkishLanguage),
                          ),
                          DropdownMenuItem(
                            value: 'en',
                            child: Text(l10n.englishLanguage),
                          ),
                        ],
                        onChanged: (code) => ref
                            .read(localeProvider.notifier)
                            .setLocale(code == null ? null : Locale(code)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                _SettingsGroup(
                  child: ListTileTheme(
                    data: const ListTileThemeData(
                      contentPadding: EdgeInsets.zero,
                    ),
                    child: AboutListTile(
                      icon: _LeadingIcon(icon: Icons.info_outline_rounded),
                      applicationName: l10n.appTitle,
                      aboutBoxChildren: [Text(l10n.aboutDescription)],
                      child: Text(l10n.aboutTitle),
                    ),
                  ),
                ),
                _SettingsGroup(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _LeadingIcon(icon: Icons.privacy_tip_outlined),
                    title: Text(
                      activeLocale.languageCode == 'tr'
                          ? 'Gizlilik Politikası'
                          : 'Privacy Policy',
                    ),
                    trailing: const Icon(Icons.open_in_new_rounded),
                    onTap: () =>
                        _privacyPolicyChannel.invokeMethod<void>('open'),
                  ),
                ),
                FutureBuilder<PackageInfo>(
                  future: _packageInfo,
                  builder: (context, snapshot) {
                    final version = snapshot.data?.version;
                    if (version == null || version.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.md),
                      child: Center(
                        child: Text(
                          l10n.appVersionLabel(version),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 2, bottom: 9),
    child: Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        letterSpacing: 1.4,
      ),
    ),
  );
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Material(color: Colors.transparent, child: child);
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => Icon(
    icon,
    size: 20,
    color: Theme.of(context).colorScheme.onSurfaceVariant,
  );
}

class _PanelDivider extends StatelessWidget {
  const _PanelDivider();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
    child: Divider(color: Theme.of(context).colorScheme.outlineVariant),
  );
}
