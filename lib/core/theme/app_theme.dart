import 'package:flutter/material.dart';

abstract final class AppColors {
  static const brand = Color(0xFF326B55);
  static const lightSurface = Color(0xFFF5F1E7);
  static const lightCard = Color(0xFFFFFCF5);
  static const lightLowSurface = Color(0xFFEEEAE0);
  static const lightPrimary = Color(0xFF79571E);
  static const lightText = Color(0xFF24231F);
  static const lightMutedText = Color(0xFF625E54);
  static const lightPrimaryContainer = Color(0xFFE6E2D7);
  static const lightOnPrimaryContainer = Color(0xFF292821);
  static const darkSurface = Color(0xFF071A1F);
  static const darkCard = Color(0xFF0E2328);
  static const darkLowSurface = Color(0xFF142B30);
  static const darkHighSurface = Color(0xFF1A3338);
  static const darkPrimary = Color(0xFFD8B66B);
  static const darkOnPrimary = Color(0xFF292316);
  static const darkText = Color(0xFFF2F0E9);
  static const darkMutedText = Color(0xFFBDB9AF);
  static const darkOutline = Color(0xFF45595D);
  static const darkOutlineVariant = Color(0xFF2A4044);
}

abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class AppRadius {
  static const double sm = 12;
  static const double md = 18;
  static const double lg = 24;
}

abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration standard = Duration(milliseconds: 240);
}

abstract final class AppTypography {
  static const String editorialFamily = 'serif';
}

abstract final class AppTheme {
  static ThemeData get light => _create(Brightness.light);
  static ThemeData get dark => _create(Brightness.dark);

  static ThemeData _create(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final baseScheme = ColorScheme.fromSeed(
      seedColor: isLight ? AppColors.lightPrimary : AppColors.brand,
      brightness: brightness,
      surface: isLight ? AppColors.lightSurface : AppColors.darkSurface,
    );
    final scheme = isLight
        ? baseScheme.copyWith(
            primary: AppColors.lightPrimary,
            onPrimary: Colors.white,
            secondary: AppColors.lightPrimary,
            onSurface: AppColors.lightText,
            onSurfaceVariant: AppColors.lightMutedText,
            primaryContainer: AppColors.lightPrimaryContainer,
            onPrimaryContainer: AppColors.lightOnPrimaryContainer,
            secondaryContainer: AppColors.lightPrimaryContainer,
            onSecondaryContainer: AppColors.lightOnPrimaryContainer,
            surfaceContainerLowest: AppColors.lightCard,
            surfaceContainerLow: AppColors.lightCard,
            surfaceContainer: AppColors.lightLowSurface,
            surfaceContainerHighest: AppColors.lightLowSurface,
            outline: const Color(0xFFD9D1C3),
            outlineVariant: const Color(0xFFE7E0D5),
          )
        : baseScheme.copyWith(
            primary: AppColors.darkPrimary,
            onPrimary: AppColors.darkOnPrimary,
            primaryContainer: const Color(0xFF493C20),
            onPrimaryContainer: const Color(0xFFF3E4C1),
            secondary: AppColors.darkPrimary,
            onSecondary: AppColors.darkOnPrimary,
            secondaryContainer: const Color(0xFF403824),
            onSecondaryContainer: const Color(0xFFEFE2C5),
            surface: AppColors.darkSurface,
            onSurface: AppColors.darkText,
            onSurfaceVariant: AppColors.darkMutedText,
            surfaceContainerLowest: AppColors.darkSurface,
            surfaceContainerLow: AppColors.darkCard,
            surfaceContainer: AppColors.darkLowSurface,
            surfaceContainerHigh: AppColors.darkHighSurface,
            surfaceContainerHighest: AppColors.darkHighSurface,
            surfaceTint: AppColors.darkPrimary,
            outline: AppColors.darkOutline,
            outlineVariant: AppColors.darkOutlineVariant,
          );
    final baseTextTheme = ThemeData(brightness: brightness).textTheme
        .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface);
    final textTheme = baseTextTheme.copyWith(
      displayLarge: baseTextTheme.displayLarge?.copyWith(
        fontFamily: AppTypography.editorialFamily,
        fontWeight: FontWeight.w400,
        letterSpacing: -1.2,
        height: 1.04,
      ),
      displayMedium: baseTextTheme.displayMedium?.copyWith(
        fontFamily: AppTypography.editorialFamily,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.8,
        height: 1.06,
      ),
      displaySmall: baseTextTheme.displaySmall?.copyWith(
        fontFamily: AppTypography.editorialFamily,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.5,
        height: 1.08,
      ),
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(
        fontFamily: AppTypography.editorialFamily,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.45,
      ),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(
        fontFamily: AppTypography.editorialFamily,
        fontWeight: FontWeight.w400,
        letterSpacing: -0.35,
      ),
      headlineSmall: baseTextTheme.headlineSmall?.copyWith(
        fontFamily: AppTypography.editorialFamily,
        fontWeight: FontWeight.w400,
      ),
      titleLarge: baseTextTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      titleMedium: baseTextTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      titleSmall: baseTextTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w500,
      ),
      labelLarge: baseTextTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w500,
      ),
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme.copyWith(
        headlineSmall: textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
        headlineMedium: textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
          letterSpacing: -0.5,
        ),
        titleMedium: textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        bodySmall: textTheme.bodySmall?.copyWith(
          color: isLight ? AppColors.lightMutedText : AppColors.darkMutedText,
        ),
      ),
      cardTheme: CardThemeData(
        color: isLight ? AppColors.lightCard : AppColors.darkCard,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 1,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surface,
        indicatorColor: isLight
            ? const Color(0xFFE9D9B9)
            : const Color(0xFF403824),
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 15),
          shape: const StadiumBorder(),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainer,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
