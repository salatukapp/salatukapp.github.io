import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Premium theme tuned for an Islamic prayer app.
///
/// Color story:
/// - Deep emerald green primary — culturally grounded
/// - Soft gold accent — luxurious without being flashy
/// - Rich near-black surface in dark mode — meditation-feel
/// - Ivory in light mode — quiet, daylight-friendly
class AppTheme {
  // Brand colors
  static const Color emerald = Color(0xFF1E6B52);
  static const Color emeraldDeep = Color(0xFF0E4A37);
  static const Color emeraldLight = Color(0xFF2D8F6E);
  static const Color gold = Color(0xFFC9A961);
  static const Color goldSoft = Color(0xFFE6D29B);
  static const Color ivory = Color(0xFFFBF8F1);
  static const Color charcoal = Color(0xFF14201B);
  static const Color charcoalDeep = Color(0xFF0A1411);

  static ThemeData light() {
    final scheme = ColorScheme(
      brightness: Brightness.light,
      primary: emerald,
      onPrimary: ivory,
      primaryContainer: const Color(0xFFD4E9DD),
      onPrimaryContainer: emeraldDeep,
      secondary: gold,
      onSecondary: charcoal,
      secondaryContainer: const Color(0xFFF5E8C8),
      onSecondaryContainer: const Color(0xFF4A3C0F),
      tertiary: const Color(0xFF8B6B3D),
      onTertiary: ivory,
      tertiaryContainer: const Color(0xFFEBDFC9),
      onTertiaryContainer: const Color(0xFF3A2C10),
      error: const Color(0xFFB94A4A),
      onError: ivory,
      surface: ivory,
      onSurface: charcoal,
      surfaceContainerLowest: const Color(0xFFFFFFFF),
      surfaceContainerLow: const Color(0xFFF6F2E8),
      surfaceContainer: const Color(0xFFF0EBDF),
      surfaceContainerHigh: const Color(0xFFE9E2D2),
      surfaceContainerHighest: const Color(0xFFE0D7C2),
      // `outline` doubles as the secondary-TEXT token across the app (borders
      // use outlineVariant). Darkened from #A89F8A (~2.4:1, failed WCAG) to
      // #5E5640 (~6.5:1 on ivory, ~5.6:1 on the high surface) so body text is
      // legible in light mode.
      outline: const Color(0xFF5E5640),
      outlineVariant: const Color(0xFFC4BBA3),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: charcoal,
      onInverseSurface: ivory,
      inversePrimary: emeraldLight,
    );
    return _build(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme(
      brightness: Brightness.dark,
      primary: emeraldLight,
      onPrimary: charcoalDeep,
      primaryContainer: const Color(0xFF1A4A38),
      onPrimaryContainer: const Color(0xFFBEE3D1),
      secondary: gold,
      onSecondary: charcoalDeep,
      secondaryContainer: const Color(0xFF4A3C0F),
      onSecondaryContainer: goldSoft,
      tertiary: const Color(0xFFD5B584),
      onTertiary: charcoalDeep,
      tertiaryContainer: const Color(0xFF564320),
      onTertiaryContainer: const Color(0xFFF1E2C0),
      error: const Color(0xFFFFB4A8),
      onError: const Color(0xFF560B0B),
      surface: charcoalDeep,
      onSurface: const Color(0xFFEDE5D2),
      surfaceContainerLowest: const Color(0xFF050908),
      surfaceContainerLow: const Color(0xFF111C18),
      surfaceContainer: const Color(0xFF17231F),
      surfaceContainerHigh: const Color(0xFF1F2D28),
      surfaceContainerHighest: const Color(0xFF273731),
      // Lightened from #6F7873 (~3.1–4.1:1, sub-4.5 for body) to #97A09B so
      // secondary text clears 4.5:1 on the dark surfaces. Borders use
      // outlineVariant, which stays dim.
      outline: const Color(0xFF97A09B),
      outlineVariant: const Color(0xFF3A4540),
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: const Color(0xFFEDE5D2),
      onInverseSurface: charcoal,
      inversePrimary: emerald,
    );
    return _build(scheme);
  }

  static ThemeData _build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);

    return base.copyWith(
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: scheme.onSurface,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        iconColor: scheme.primary,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow.withValues(alpha: 0.95),
        elevation: 0,
        height: 72,
        indicatorColor: scheme.primary.withValues(alpha: 0.18),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            letterSpacing: 0.3,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? scheme.primary : scheme.onSurfaceVariant,
            size: selected ? 26 : 24,
          );
        }),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        showDragHandle: true,
        dragHandleColor: scheme.outlineVariant,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        },
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }

  /// Style used for body Arabic text.
  static const TextStyle arabicBody = TextStyle(
    fontFamily: 'Amiri',
    fontSize: 24,
    height: 2.0,
    letterSpacing: 0.5,
  );

  /// Style used for Arabic from the Quran or hadith — slightly larger.
  static const TextStyle arabicQuran = TextStyle(
    fontFamily: 'AmiriQuran',
    fontSize: 26,
    height: 2.1,
  );

  /// Hero gradient for prayer times and main accents.
  static LinearGradient heroGradient(ColorScheme cs, {bool isDark = true}) {
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          emeraldDeep,
          emerald,
          const Color(0xFF1A5A45),
        ],
        stops: const [0.0, 0.6, 1.0],
      );
    }
    // Light-mode hero: keep the stops dark enough that white/gold text clears
    // WCAG 4.5:1 over the WHOLE gradient (the old #3FA37D bottom stop dropped
    // white text to ~1.9:1). Lightest stop is now #1A5A45.
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        emeraldDeep,
        emerald,
        const Color(0xFF1A5A45),
      ],
      stops: const [0.0, 0.6, 1.0],
    );
  }

  /// Soft gold-tinged gradient used for "now is" highlights and accents.
  static LinearGradient goldHighlight(ColorScheme cs) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [gold, goldSoft],
    );
  }
}
