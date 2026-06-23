import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // ── Brand Colors: Blue → Cyan ──────────────────────────────────────────────
  static const Color primary      = Color(0xFF0A84FF); // iOS Blue
  static const Color primaryDark  = Color(0xFF0066CC);
  static const Color primaryDeep  = Color(0xFF003F88);
  static const Color accent       = Color(0xFF00C2E0); // Cyan
  static const Color accentLight  = Color(0xFF4DD9EC);
  static const Color surface      = Color(0xFFF0F6FF); // Cool blue-white
  static const Color surfaceCard  = Color(0xFFFFFFFF);
  static const Color textPrimary  = Color(0xFF0D1B2A);
  static const Color textSecondary= Color(0xFF4A6080);
  static const Color textLight    = Color(0xFF8FA4BC);
  static const Color success      = Color(0xFF30D158);
  static const Color warning      = Color(0xFFFF9F0A);
  static const Color error        = Color(0xFFFF453A);
  static const Color divider      = Color(0xFFD6E4F7);
  static const Color borderColor  = Color(0xFFB8D0EE);

  // ── Gradients ──────────────────────────────────────────────────────────────
  /// Main brand: deep blue → bright blue
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF003F88), Color(0xFF0A84FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Button / CTA: blue → cyan
  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFF0A84FF), Color(0xFF00C2E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Card hero: mid-blue → cyan
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF0066CC), Color(0xFF00C2E0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Soft: cyan → light cyan
  static const LinearGradient warmGradient = LinearGradient(
    colors: [Color(0xFF00C2E0), Color(0xFF4DD9EC)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Dark header: navy → deep blue
  static const LinearGradient deepGradient = LinearGradient(
    colors: [Color(0xFF001F5B), Color(0xFF003F88)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shared header style ─────────────────────────────────────────────────────
  /// Use this for EVERY screen's AppBar `titleTextStyle` so headers stay
  /// visually consistent (same font + size) across the whole app. Pass
  /// [color] only when the AppBar sits on a colored/gradient background
  /// (e.g. Colors.white) — otherwise it defaults to the normal dark text
  /// color used on plain/transparent AppBars.
  static TextStyle appBarTitleStyle({Color color = textPrimary}) {
    return GoogleFonts.plusJakartaSans(
        fontSize: 20, fontWeight: FontWeight.w700, color: color);
  }

  /// Same idea as [appBarTitleStyle] but for the bigger gradient "hero"
  /// headers used on tab screens like Services/Nearby/Explore (these sit
  /// above a subtitle + action chips, so they're a bit larger than a plain
  /// AppBar title). Keeping all three on this one helper is what makes
  /// those three pages feel like siblings instead of each having its own
  /// random size (24 / 22 / 24 before this).
  static TextStyle heroTitleStyle({Color color = Colors.white}) {
    return GoogleFonts.plusJakartaSans(
        fontSize: 22, fontWeight: FontWeight.w800, color: color);
  }

  // ── ThemeData ──────────────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: accent,
        surface: surface,
      ),
      scaffoldBackgroundColor: surface,
      textTheme: GoogleFonts.plusJakartaSansTextTheme().copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
            fontSize: 32, fontWeight: FontWeight.w800,
            color: textPrimary, letterSpacing: -0.5),
        displayMedium: GoogleFonts.plusJakartaSans(
            fontSize: 26, fontWeight: FontWeight.w700,
            color: textPrimary, letterSpacing: -0.3),
        displaySmall: GoogleFonts.plusJakartaSans(
            fontSize: 22, fontWeight: FontWeight.w700, color: textPrimary),
        headlineMedium: GoogleFonts.plusJakartaSans(
            fontSize: 18, fontWeight: FontWeight.w600, color: textPrimary),
        titleLarge: GoogleFonts.plusJakartaSans(
            fontSize: 16, fontWeight: FontWeight.w600, color: textPrimary),
        bodyLarge: GoogleFonts.plusJakartaSans(
            fontSize: 15, color: textPrimary),
        bodyMedium: GoogleFonts.plusJakartaSans(
            fontSize: 14, color: textSecondary),
        bodySmall: GoogleFonts.plusJakartaSans(
            fontSize: 12, color: textLight),
        labelLarge: GoogleFonts.plusJakartaSans(
            fontSize: 14, fontWeight: FontWeight.w600,
            color: Colors.white, letterSpacing: 0.3),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: appBarTitleStyle(),
        iconTheme: const IconThemeData(color: textPrimary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: const BorderSide(color: primary, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
          textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: divider)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: divider)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: primary, width: 2)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: error)),
        hintStyle: GoogleFonts.plusJakartaSans(
            color: textLight, fontSize: 14),
        labelStyle: GoogleFonts.plusJakartaSans(
            color: textSecondary, fontSize: 14),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: textLight,
        elevation: 20,
        type: BottomNavigationBarType.fixed,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withValues(alpha: 0.1),
        labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 13, fontWeight: FontWeight.w500),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: primaryDeep,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12)),
        contentTextStyle:
            const TextStyle(color: Colors.white, fontSize: 14),
      ),
      dividerTheme:
          const DividerThemeData(color: divider, thickness: 1),
    );
  }
}
