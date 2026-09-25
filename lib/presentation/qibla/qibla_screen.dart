import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/prayer/prayer_dashboard_controller.dart';
import '../../application/qibla/qibla_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/qibla/qibla_service.dart';
import '../../l10n/generated/app_localizations.dart';

class QiblaSection extends ConsumerWidget {
  const QiblaSection({
    super.key,
    this.compact = false,
    this.ultraCompact = false,
  });

  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final dashboard = ref.watch(prayerDashboardProvider);
    final northReference = ref.watch(qiblaNorthReferenceProvider);
    return dashboard.when(
      loading: () => _QiblaContent(
        bearing: null,
        orientation: null,
        status: l10n.qiblaCalibrating,
        compact: compact,
        ultraCompact: ultraCompact,
      ),
      error: (error, stackTrace) => _QiblaContent(
        bearing: null,
        orientation: null,
        status: l10n.qiblaLocationRequired,
        compact: compact,
        ultraCompact: ultraCompact,
      ),
      data: (state) {
        final location = state.location;
        if (location == null) {
          return _QiblaContent(
            bearing: null,
            orientation: null,
            status: l10n.qiblaLocationRequired,
            compact: compact,
            ultraCompact: ultraCompact,
          );
        }

        final bearing = ref
            .read(qiblaServiceProvider)
            .bearingFromTrueNorth(
              latitude: location.latitude,
              longitude: location.longitude,
            );
        final orientation = ref.watch(
          qiblaOrientationProvider((location.latitude, location.longitude)),
        );
        return orientation.when(
          loading: () => _QiblaContent(
            bearing: bearing,
            orientation: null,
            status: l10n.qiblaCalibrating,
            compact: compact,
            ultraCompact: ultraCompact,
          ),
          error: (error, stackTrace) => _QiblaContent(
            bearing: bearing,
            orientation: null,
            status: l10n.qiblaSensorUnavailable,
            compact: compact,
            ultraCompact: ultraCompact,
          ),
          data: (value) {
            final referenceBearing = northReference.usesTrueNorth
                ? bearing
                : QiblaBearingCalculator.normalizeDegrees(
                    bearing - value.declinationDegrees,
                  );
            return _QiblaContent(
              bearing: referenceBearing,
              orientation: value,
              status: value.isReliable
                  ? l10n.qiblaDirectionStable
                  : l10n.qiblaSensorUnreliable,
              compact: compact,
              ultraCompact: ultraCompact,
            );
          },
        );
      },
    );
  }
}

class _QiblaContent extends StatelessWidget {
  const _QiblaContent({
    required this.bearing,
    required this.orientation,
    required this.status,
    required this.compact,
    required this.ultraCompact,
  });

  final double? bearing;
  final DeviceOrientation? orientation;
  final String? status;
  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isReliable = orientation?.isReliable ?? false;
    final isDark = theme.brightness == Brightness.dark;
    final directionColor = isReliable
        ? (isDark ? colorScheme.primary : AppColors.brand)
        : colorScheme.onSurfaceVariant;
    final relativeDirection = isReliable
        ? QiblaBearingCalculator.shortestAngleDelta(
            bearing! - orientation!.azimuthDegrees,
          )
        : 0.0;

    return Container(
      key: const Key('qibla-section'),
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.85),
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceContainerLow,
            colorScheme.surfaceContainerHigh.withValues(alpha: 0.62),
          ],
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg - 1),
        child: Stack(
          children: [
            Image.asset(
              'assets/images/qibla_landscape.png',
              key: const Key('qibla-landscape-background'),
              fit: BoxFit.cover,
              alignment: const Alignment(0, 0.8),
              excludeFromSemantics: true,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0, 0.56, 1],
                    colors: isDark
                        ? [
                            colorScheme.surface.withValues(alpha: 0.34),
                            colorScheme.surface.withValues(alpha: 0.14),
                            colorScheme.surface.withValues(alpha: 0.08),
                          ]
                        : [
                            colorScheme.surface.withValues(alpha: 0.72),
                            colorScheme.surface.withValues(alpha: 0.4),
                            colorScheme.surface.withValues(alpha: 0.46),
                          ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: ultraCompact
                    ? AppSpacing.xxs
                    : compact
                    ? AppSpacing.xs
                    : AppSpacing.sm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.qiblaTitle.toUpperCase(),
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontFamily: AppTypography.editorialFamily,
                      fontSize: ultraCompact
                          ? 16
                          : compact
                          ? 18
                          : null,
                      fontWeight: FontWeight.w400,
                      letterSpacing: 2.3,
                    ),
                  ),
                  Text(
                    l10n.qiblaSubtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: ultraCompact
                          ? 11
                          : compact
                          ? 12
                          : null,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(
                    height: ultraCompact
                        ? 64
                        : compact
                        ? 96
                        : 124,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          top: 2,
                          child: _KaabaIllustration(
                            size: ultraCompact
                                ? 38
                                : compact
                                ? 54
                                : 80,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          child: _ShortestPathArrow(
                            degrees: relativeDirection,
                            color: directionColor,
                            size: ultraCompact
                                ? 34
                                : compact
                                ? 44
                                : 56,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isReliable
                              ? const Color(0xFF4E9B69)
                              : colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          status ?? l10n.qiblaCalibrating,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: ultraCompact ? 10 : null,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShortestPathArrow extends StatefulWidget {
  const _ShortestPathArrow({
    required this.degrees,
    required this.color,
    required this.size,
  });

  final double degrees;
  final Color color;
  final double size;

  @override
  State<_ShortestPathArrow> createState() => _ShortestPathArrowState();
}

class _ShortestPathArrowState extends State<_ShortestPathArrow> {
  late double _turns = widget.degrees / 360;
  late double _lastDegrees = widget.degrees;

  @override
  void didUpdateWidget(covariant _ShortestPathArrow oldWidget) {
    super.didUpdateWidget(oldWidget);
    final delta = QiblaBearingCalculator.shortestAngleDelta(
      widget.degrees - _lastDegrees,
    );
    _turns += delta / 360;
    _lastDegrees = widget.degrees;
  }

  @override
  Widget build(BuildContext context) => AnimatedRotation(
    turns: _turns,
    duration: AppMotion.fast,
    curve: Curves.easeOutCubic,
    child: Icon(
      Icons.navigation_rounded,
      size: widget.size,
      color: widget.color,
    ),
  );
}

class _KaabaIllustration extends StatelessWidget {
  const _KaabaIllustration({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    label: AppLocalizations.of(context)!.kaabaLabel,
    image: true,
    child: Image.asset(
      'assets/images/kaaba_premium.png',
      key: const Key('qibla-kaaba-illustration'),
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
    ),
  );
}
