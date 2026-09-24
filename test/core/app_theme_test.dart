import 'package:ezan/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dark theme uses charcoal surfaces and warm neutral text', () {
    final scheme = AppTheme.dark.colorScheme;

    expect(scheme.surface, const Color(0xFF071A1F));
    expect(scheme.surfaceContainerLow, const Color(0xFF0E2328));
    expect(scheme.onSurface, const Color(0xFFF2F0E9));
    expect(scheme.primary, const Color(0xFFD8B66B));
  });

  test('dark theme text and accents keep strong contrast', () {
    final scheme = AppTheme.dark.colorScheme;

    expect(
      _contrast(scheme.onSurface, scheme.surface),
      greaterThanOrEqualTo(7),
    );
    expect(
      _contrast(scheme.onSurfaceVariant, scheme.surfaceContainerLow),
      greaterThanOrEqualTo(7),
    );
    expect(_contrast(scheme.primary, scheme.surface), greaterThanOrEqualTo(7));
    expect(
      _contrast(scheme.onPrimary, scheme.primary),
      greaterThanOrEqualTo(7),
    );
  });

  test('light palette is unchanged by the dark theme definition', () {
    final scheme = AppTheme.light.colorScheme;

    expect(scheme.surface, const Color(0xFFF5F1E7));
    expect(scheme.onSurface, const Color(0xFF24231F));
    expect(scheme.primary, const Color(0xFF79571E));
  });

  test('light theme keeps text and action colors legible on warm surfaces', () {
    final scheme = AppTheme.light.colorScheme;

    expect(
      _contrast(scheme.onSurface, scheme.surface),
      greaterThanOrEqualTo(7),
    );
    expect(
      _contrast(scheme.onSurfaceVariant, scheme.surfaceContainerLow),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(scheme.primary, scheme.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(scheme.onPrimary, scheme.primary),
      greaterThanOrEqualTo(4.5),
    );
  });
}

double _contrast(Color foreground, Color background) {
  final foregroundLuminance = foreground.computeLuminance();
  final backgroundLuminance = background.computeLuminance();
  final lighter = foregroundLuminance > backgroundLuminance
      ? foregroundLuminance
      : backgroundLuminance;
  final darker = foregroundLuminance > backgroundLuminance
      ? backgroundLuminance
      : foregroundLuminance;
  return (lighter + 0.05) / (darker + 0.05);
}
