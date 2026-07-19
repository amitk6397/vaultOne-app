import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../constants/app_colors.dart';

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.blue,
      brightness: Brightness.light,
      primary: AppColors.blue,
      secondary: AppColors.purple,
      surface: Colors.white,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: AppColors.scaffold,
      appBarTheme: _appBar(scheme, Colors.white, AppColors.navy),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
    );
  }

  static ThemeData dark() {
    const background = Color(0xFF070B16);
    const surface = Color(0xFF101827);
    const surfaceHigh = Color(0xFF172033);
    const primary = Color(0xFF64A7FF);
    const secondary = Color(0xFF9B7CFF);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.dark,
      primary: primary,
      secondary: secondary,
      surface: surface,
      onSurface: const Color(0xFFEAF0FF),
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: background,
      canvasColor: background,
      cardColor: surface,
      appBarTheme: _appBar(scheme, surface, const Color(0xFFEAF0FF)),
      bottomAppBarTheme: const BottomAppBarThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: GoogleFonts.inter(
          color: const Color(0xFFEAF0FF),
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      inputDecorationTheme: _inputDecoration(scheme).copyWith(
        fillColor: surfaceHigh,
        hintStyle: GoogleFonts.inter(color: const Color(0xFF8D99B3)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFFB9C5DD),
        textColor: Color(0xFFEAF0FF),
      ),
      dividerColor: const Color(0xFF263248),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      textTheme: textTheme,
      inputDecorationTheme: _inputDecoration(scheme),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          textStyle: GoogleFonts.inter(fontWeight: FontWeight.w800),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.outline,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? scheme.primary.withValues(alpha: .32)
              : scheme.surfaceContainerHighest,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: const CircleBorder(),
        elevation: 4,
        focusElevation: 6,
        hoverElevation: 6,
        highlightElevation: 8,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  static AppBarTheme _appBar(
    ColorScheme scheme,
    Color background,
    Color foreground,
  ) {
    return AppBarTheme(
      centerTitle: false,
      toolbarHeight: 72,
      titleSpacing: 16,
      elevation: 0,
      scrolledUnderElevation: 3,
      shadowColor: AppColors.shadow,
      backgroundColor: background,
      foregroundColor: foreground,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        color: foreground,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
      iconTheme: IconThemeData(color: foreground),
    );
  }

  static InputDecorationTheme _inputDecoration(ColorScheme scheme) {
    return InputDecorationTheme(
      filled: true,
      fillColor: scheme.surface,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: scheme.primary, width: 1.4),
      ),
    );
  }
}
