import 'package:flutter/material.dart';

/// Centralized theme. Greens chosen for Islamic-cultural fit but soft
/// (not the saturated mosque-tile green). Works for both LTR and RTL.
class AppTheme {
  static const _seed = Color(0xFF1E6B52);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.light);
    return _build(scheme, Brightness.light);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(seedColor: _seed, brightness: Brightness.dark);
    return _build(scheme, Brightness.dark);
  }

  static ThemeData _build(ColorScheme scheme, Brightness brightness) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: null, // default; explicit Amiri applied per-Arabic-widget
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: true,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        iconColor: scheme.primary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        ),
      ),
    );
  }

  /// Style used for body Arabic text.
  static const TextStyle arabicBody = TextStyle(
    fontFamily: 'Amiri',
    fontSize: 22,
    height: 2.0,
    letterSpacing: 0.5,
  );

  /// Style used for Arabic from the Quran or hadith — slightly larger.
  static const TextStyle arabicQuran = TextStyle(
    fontFamily: 'AmiriQuran',
    fontSize: 24,
    height: 2.1,
  );
}
