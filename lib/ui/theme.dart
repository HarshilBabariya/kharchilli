import 'package:flutter/material.dart';

class Palette {
  const Palette(this.primary, this.secondary, this.tertiary, this.lightBg, this.darkBg, this.darkSurface);
  final int primary;
  final int secondary;
  final int tertiary;
  final int lightBg;
  final int darkBg;
  final int darkSurface;
}

const palettes = <String, Palette>{
  'theme_sunrise': Palette(0xFFE8203F, 0xFFFFB627, 0xFF2EC4B6, 0xFFFFF7F5, 0xFF140C0E, 0xFF21151A),
  'theme_ocean': Palette(0xFF2563EB, 0xFF0EA5E9, 0xFF14B8A6, 0xFFF4F7FB, 0xFF0B1220, 0xFF131C2E),
  'theme_forest': Palette(0xFF15803D, 0xFF4ADE80, 0xFFA3E635, 0xFFF3F8F4, 0xFF0C1510, 0xFF152219),
  'theme_midnight': Palette(0xFF7C3AED, 0xFF06B6D4, 0xFFF472B6, 0xFFF6F3FD, 0xFF0E0B1A, 0xFF181330),
  'theme_candy': Palette(0xFFEC4899, 0xFFA78BFA, 0xFFFBBF24, 0xFFFDF4F8, 0xFF1C1016, 0xFF2A1823),
  'theme_royal': Palette(0xFF6D28D9, 0xFFF59E0B, 0xFF14B8A6, 0xFFF7F3FB, 0xFF130B1C, 0xFF21142C),
  'theme_glass': Palette(0xFF6366F1, 0xFF06B6D4, 0xFFEC4899, 0xFFEEF0FF, 0xFF110E2B, 0xFF1C1842),
  'theme_diwali': Palette(0xFFB4231F, 0xFFF5B301, 0xFFFF7A1A, 0xFFFFF6E8, 0xFF1A0B07, 0xFF2A130C),
  'theme_holi': Palette(0xFFE91E8C, 0xFFFFC400, 0xFF00B8D4, 0xFFFFF5FB, 0xFF1A0A16, 0xFF2A1224),
  'theme_garba': Palette(0xFFD9271C, 0xFFFF9F1C, 0xFF16A34A, 0xFFFFF4EE, 0xFF1A0C09, 0xFF291512),
  'theme_kites': Palette(0xFF0284C7, 0xFFFACC15, 0xFFEF4444, 0xFFF0F8FF, 0xFF07131F, 0xFF0F2031),
  'theme_rakhi': Palette(0xFFDB2777, 0xFFF59E0B, 0xFFFB923C, 0xFFFFF5F8, 0xFF1C0E14, 0xFF2B1720),
  'theme_bappa': Palette(0xFFEA580C, 0xFFDC2626, 0xFFEAB308, 0xFFFFF7ED, 0xFF1C0F06, 0xFF2B190C),
  'theme_tiranga': Palette(0xFFF26B0F, 0xFF138808, 0xFF1E3A8A, 0xFFFBFAF6, 0xFF0E1210, 0xFF181E1A),
  'theme_christmas': Palette(0xFFC62828, 0xFF2E7D32, 0xFFD4A017, 0xFFFBF6F2, 0xFF0D1410, 0xFF16201A),
  'theme_new_year': Palette(0xFF7C3AED, 0xFFF5C451, 0xFFE879F9, 0xFFF3F0FF, 0xFF0C0A1F, 0xFF17143A),
};

Palette paletteOf(String themeId) => palettes[themeId] ?? palettes['theme_sunrise']!;

Color _lift(Color c, double amount) => Color.lerp(c, Colors.white, amount)!;

ThemeData buildTheme(String themeId, Brightness brightness) {
  final p = paletteOf(themeId);
  final dark = brightness == Brightness.dark;
  final primary = dark ? _lift(Color(p.primary), 0.22) : Color(p.primary);
  final background = Color(dark ? p.darkBg : p.lightBg);
  final surface = dark ? Color(p.darkSurface) : Colors.white;
  final onSurface = dark ? const Color(0xFFF6F1F2) : const Color(0xFF1D1517);
  final muted = dark ? const Color(0xFFB9ADB1) : const Color(0xFF6E6064);
  final scheme = ColorScheme.fromSeed(seedColor: Color(p.primary), brightness: brightness).copyWith(
    primary: primary,
    onPrimary: Colors.white,
    secondary: dark ? _lift(Color(p.secondary), 0.1) : Color(p.secondary),
    tertiary: dark ? _lift(Color(p.tertiary), 0.15) : Color(p.tertiary),
    surface: surface,
    onSurface: onSurface,
    onSurfaceVariant: muted,
    primaryContainer: Color.alphaBlend(primary.withValues(alpha: dark ? 0.24 : 0.12), surface),
    onPrimaryContainer: dark ? _lift(primary, 0.4) : Color(p.primary),
    surfaceContainerHighest: Color.alphaBlend(onSurface.withValues(alpha: dark ? 0.09 : 0.05), surface),
    outlineVariant: onSurface.withValues(alpha: dark ? 0.12 : 0.08),
    error: dark ? const Color(0xFFFF8A80) : const Color(0xFFD32F2F),
  );
  TextStyle display(double size, FontWeight weight, [double height = 1.15]) =>
      TextStyle(fontFamily: 'Poppins', fontSize: size, fontWeight: weight, height: height, color: onSurface, letterSpacing: -0.3);
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: background,
    splashFactory: InkSparkle.splashFactory,
    textTheme: TextTheme(
      displaySmall: display(40, FontWeight.w700, 1.05),
      headlineMedium: display(28, FontWeight.w700),
      headlineSmall: display(22, FontWeight.w700),
      titleLarge: display(19, FontWeight.w700),
      titleMedium: display(16, FontWeight.w500, 1.25),
      titleSmall: display(14, FontWeight.w500, 1.25),
      bodyLarge: TextStyle(fontSize: 16, height: 1.4, color: onSurface),
      bodyMedium: TextStyle(fontSize: 14, height: 1.4, color: onSurface),
      bodySmall: TextStyle(fontSize: 12.5, height: 1.35, color: muted),
      labelLarge: display(15, FontWeight.w500, 1.2),
      labelMedium: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: muted, letterSpacing: 0.2),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: muted, letterSpacing: 0.4),
    ),
    appBarTheme: AppBarTheme(backgroundColor: Colors.transparent, surfaceTintColor: Colors.transparent, elevation: 0, scrolledUnderElevation: 0, centerTitle: false, titleTextStyle: display(22, FontWeight.w700)),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHighest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(18), borderSide: BorderSide(color: primary, width: 1.6)),
      hintStyle: TextStyle(color: muted.withValues(alpha: 0.7)),
      labelStyle: TextStyle(color: muted),
    ),
    bottomSheetTheme: BottomSheetThemeData(backgroundColor: surface, surfaceTintColor: Colors.transparent, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32)))),
    dialogTheme: DialogThemeData(backgroundColor: surface, surfaceTintColor: Colors.transparent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28))),
    snackBarTheme: SnackBarThemeData(behavior: SnackBarBehavior.floating, backgroundColor: onSurface, contentTextStyle: TextStyle(color: background, fontWeight: FontWeight.w600), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
    pageTransitionsTheme: const PageTransitionsTheme(builders: {
      TargetPlatform.android: ZoomPageTransitionsBuilder(),
      TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    }),
  );
}

extension ThemeX on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;
  TextTheme get tt => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// The brand gradient used on hero cards and primary buttons.
  LinearGradient get heroGradient {
    final c = cs;
    return LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [
      Color.lerp(c.primary, c.secondary, 0.18)!,
      c.primary,
      Color.lerp(c.primary, const Color(0xFF3B0A45), isDark ? 0.45 : 0.3)!,
    ]);
  }
}

const good = Color(0xFF22A861);
const bad = Color(0xFFE5484D);
