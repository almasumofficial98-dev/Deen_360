import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  // Centralized Font Families
  static String get primaryFont => GoogleFonts.plusJakartaSans().fontFamily!;
  static String get arabicFont => GoogleFonts.notoNaskhArabic().fontFamily!;
  static String get urduFont => GoogleFonts.notoNastaliqUrdu().fontFamily!;
  static String get hindiFont => GoogleFonts.hind().fontFamily!;
  static String get bengaliFont => GoogleFonts.hindSiliguri().fontFamily!;

  // Helpers to get styles for specific languages
  static TextStyle arabic({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return GoogleFonts.notoNaskhArabic(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle urdu({double? fontSize, FontWeight? fontWeight, Color? color}) {
    return GoogleFonts.notoNastaliqUrdu(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  static TextStyle getStyleByLang(String lang, {double? fontSize, FontWeight? fontWeight, Color? color}) {
    switch (lang.toLowerCase()) {
      case 'ar': return arabic(fontSize: fontSize, fontWeight: fontWeight, color: color);
      case 'ur': return urdu(fontSize: fontSize, fontWeight: fontWeight, color: color);
      case 'hi': return GoogleFonts.hind(fontSize: fontSize, fontWeight: fontWeight, color: color);
      case 'bn': return GoogleFonts.hindSiliguri(fontSize: fontSize, fontWeight: fontWeight, color: color);
      default: return GoogleFonts.plusJakartaSans(fontSize: fontSize, fontWeight: fontWeight, color: color);
    }
  }
}

class AppTheme {
  // THEME Colors
  static const Color primary = Color(0xFF10B981);
  static const Color primaryDark = Color(0xFF059669);
  static const Color primaryLight = Color(0xFFECFDF5);
  
  // Qwik Deen Library Palette
  static const Color qwikGreen = Color(0xFF1E7F3D);
  static const Color qwikCream = Color(0xFFFDF8EE);
  static const Color qwikNavy = Color(0xFF1E293B);
  static const Color qwikYellow = Color(0xFFFCD34D);

  // Standard Colors
  static const Color background = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF9FAFB);
  static const Color card = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color text = Color(0xFF111827);
  static const Color textLight = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);
  
  // UI Elements
  static const Color border = Color(0xFFE5E7EB);
  static const Color inputBg = Color(0xFFF3F4F6);
  
  // Status Colors
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);
  static const Color white = Color(0xFFFFFFFF);

  // TYPOGRAPHY
  static TextStyle heading = GoogleFonts.plusJakartaSans(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: text,
  );
  static TextStyle subheading = GoogleFonts.plusJakartaSans(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: text,
  );
  static TextStyle body = GoogleFonts.plusJakartaSans(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: text,
  );
  static TextStyle caption = GoogleFonts.plusJakartaSans(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textLight,
  );
  static TextStyle small = GoogleFonts.plusJakartaSans(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textMuted,
  );
}

class AppShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(
      color: Color(0x0D000000), // ~5% opacity black
      offset: Offset(0, 4),
      blurRadius: 15,
      spreadRadius: 2,
    ),
  ];

  static const List<BoxShadow> floating = [
    BoxShadow(
      color: Color(0x33059669), // ~20% opacity primaryDark
      offset: Offset(0, 8),
      blurRadius: 20,
      spreadRadius: 8,
    ),
  ];

  static List<BoxShadow> dynamicSoft(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.12),
      offset: const Offset(0, 4),
      blurRadius: 15,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> dynamicFloating(Color color) => [
    BoxShadow(
      color: color.withValues(alpha: 0.25),
      offset: const Offset(0, 8),
      blurRadius: 24,
      spreadRadius: 4,
    ),
  ];
}

class AppGradients {
  static const Alignment _begin = Alignment.topLeft;
  static const Alignment _end = Alignment.bottomRight;

  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: _begin, end: _end,
  );

  static const LinearGradient fajr = LinearGradient(
    colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
    begin: _begin, end: _end,
  );

  static const LinearGradient sunrise = LinearGradient(
    colors: [Color(0xFFFF7E5F), Color(0xFFFEB47B)],
    begin: _begin, end: _end,
  );

  static const LinearGradient dhuhr = LinearGradient(
    colors: [Color(0xFF56CCF2), Color(0xFF2F80ED)],
    begin: _begin, end: _end,
  );

  static const LinearGradient asr = LinearGradient(
    colors: [Color(0xFFF2994A), Color(0xFFF2C94C)],
    begin: _begin, end: _end,
  );

  static const LinearGradient maghrib = LinearGradient(
    colors: [Color(0xFFEE0979), Color(0xFFFF6A00)],
    begin: _begin, end: _end,
  );

  static const LinearGradient isha = LinearGradient(
    colors: [Color(0xFF141E30), Color(0xFF243B55)],
    begin: _begin, end: _end,
  );

  static const LinearGradient midnight = LinearGradient(
    colors: [Color(0xFF000000), Color(0xFF0F2027)],
    begin: _begin, end: _end,
  );

  static const LinearGradient tahajjud = LinearGradient(
    colors: [Color(0xFF1A2980), Color(0xFF26D0CE)],
    begin: _begin, end: _end,
  );

  static bool isLightText(String prayerName) {
    return true; // Use white text for all gradients per user feedback
  }

  static const LinearGradient qwik = LinearGradient(
    colors: [Color(0xFF1E7F3D), Color(0xFF166534)],
    begin: _begin, end: _end,
  );
  static const LinearGradient sunset = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: _begin, end: _end,
  );
  static const LinearGradient night = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
    begin: _begin, end: _end,
  );
  static const LinearGradient dawn = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    begin: _begin, end: _end,
  );
}

class AppSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
}

class AppRadius {
  static const double card = 24.0;
  static const double modal = 32.0;
  static const double pill = 100.0;
  static const double input = 16.0;
}
