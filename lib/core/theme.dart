import 'package:flutter/material.dart';

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
  static const TextStyle heading = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: text,
  );
  static const TextStyle subheading = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: text,
  );
  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: text,
  );
  static const TextStyle caption = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textLight,
  );
  static const TextStyle small = TextStyle(
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
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient qwik = LinearGradient(
    colors: [Color(0xFF1E7F3D), Color(0xFF166534)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient sunset = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient night = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient dawn = LinearGradient(
    colors: [Color(0xFF0EA5E9), Color(0xFF38BDF8)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
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
