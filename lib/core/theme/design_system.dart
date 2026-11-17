/// Design System - All design tokens, colors, typography, and spacing
/// Enterprise-grade design tokens following Apple HIG, Stripe, and Notion aesthetics

import 'package:flutter/material.dart';

/// Color Palette - Premium fintech-inspired colors
class AppColors {
  // Primary Colors
  static const Color primary = Color(0xFF4F46E5); // Indigo
  static const Color primaryLight = Color(0xFF6366F1);
  static const Color primaryDark = Color(0xFF3730A3);

  // Secondary Colors
  static const Color secondary = Color(0xFF06B6D4); // Cyan
  static const Color secondaryLight = Color(0xFF22D3EE);
  static const Color secondaryDark = Color(0xFF0891B2);

  // Success, Warning, Error
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  // Neutral Colors - Light Mode
  static const Color white = Color(0xFFFFFFFF);
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF3F4F6);
  static const Color gray200 = Color(0xFFE5E7EB);
  static const Color gray300 = Color(0xFFD1D5DB);
  static const Color gray400 = Color(0xFF9CA3AF);
  static const Color gray500 = Color(0xFF6B7280);
  static const Color gray600 = Color(0xFF4B5563);
  static const Color gray700 = Color(0xFF374151);
  static const Color gray800 = Color(0xFF1F2937);
  static const Color gray900 = Color(0xFF111827);

  // Neutral Colors - Dark Mode
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkBgSecondary = Color(0xFF1E293B);
  static const Color darkBgTertiary = Color(0xFF334155);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkBorder = Color(0xFF475569);

  // Glass Morphism Colors
  static const Color glassLight = Color.fromARGB(15, 255, 255, 255);
  static const Color glassDark = Color.fromARGB(20, 15, 17, 42);
}

/// Typography System - Premium, modern typography
class AppTypography {
  static const String fontFamily = 'Inter';

  // Display Styles
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 42,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
  );

  // Heading Styles
  static const TextStyle headingXL = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.3,
    letterSpacing: -0.2,
  );

  static const TextStyle headingLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.35,
    letterSpacing: 0,
  );

  static const TextStyle headingMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.4,
    letterSpacing: 0.15,
  );

  static const TextStyle headingSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
    letterSpacing: 0.15,
  );

  // Body Styles
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.5,
    letterSpacing: 0.15,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.57,
    letterSpacing: 0.25,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.67,
    letterSpacing: 0.4,
  );

  // Label Styles
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
    letterSpacing: 0.1,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.67,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w600,
    height: 1.8,
    letterSpacing: 0.8,
  );

  // Caption
  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.67,
    letterSpacing: 0,
  );
}

/// Spacing System - Consistent spacing throughout the app
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;
  static const double huge = 40;
  static const double massive = 56;
}

/// Border Radius System - Modern rounded corners
class AppRadius {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double circle = 100;
}

/// Shadow System - Premium glassmorphism shadows
class AppShadows {
  static const BoxShadow xs = BoxShadow(
    color: Color.fromARGB(51, 0, 0, 0),
    blurRadius: 2,
    offset: Offset(0, 1),
  );

  static const BoxShadow sm = BoxShadow(
    color: Color.fromARGB(51, 0, 0, 0),
    blurRadius: 3,
    offset: Offset(0, 1),
  );

  static const BoxShadow md = BoxShadow(
    color: Color.fromARGB(76, 0, 0, 0),
    blurRadius: 6,
    offset: Offset(0, 4),
  );

  static const BoxShadow lg = BoxShadow(
    color: Color.fromARGB(89, 0, 0, 0),
    blurRadius: 12,
    offset: Offset(0, 8),
  );

  static const BoxShadow xl = BoxShadow(
    color: Color.fromARGB(102, 0, 0, 0),
    blurRadius: 16,
    offset: Offset(0, 12),
  );

  static const BoxShadow elevation = BoxShadow(
    color: Color.fromARGB(127, 0, 0, 0),
    blurRadius: 24,
    offset: Offset(0, 20),
  );

  // Glass morphism shadow (dark mode)
  static const BoxShadow glassGlow = BoxShadow(
    color: Color.fromARGB(76, 79, 70, 229, ),
    blurRadius: 20,
    offset: Offset(0, 8),
  );
}

/// Animation Durations
class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Curve constants
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeIn = Curves.easeIn;
  static const Curve springSmooth = Curves.elasticOut;
}

/// Gradient Presets - Premium gradients inspired by Apple and Stripe
class AppGradients {
  // Primary Gradient
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF6366F1),
      Color(0xFF4F46E5),
    ],
  );

  // Secondary Gradient
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF22D3EE),
      Color(0xFF06B6D4),
    ],
  );

  // Success Gradient
  static const LinearGradient successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF34D399),
      Color(0xFF10B981),
    ],
  );

  // Premium Glass Gradient
  static const LinearGradient glassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromARGB(76, 255, 255, 255),
      Color.fromARGB(13, 255, 255, 255),
    ],
  );

  // Dark Mode Glass Gradient
  static const LinearGradient darkGlassGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color.fromARGB(25, 255, 255, 255),
      Color.fromARGB(13, 255, 255, 255),
    ],
  );

  // Sunset Gradient (for special sections)
  static const LinearGradient sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
    ],
  );
}

/// Responsive Breakpoints
class AppBreakpoints {
  static const double mobile = 480;
  static const double tablet = 768;
  static const double desktop = 1024;
  static const double largeDesktop = 1440;
}

/// Z-Index Constants
class AppZIndex {
  static const int hidden = -1;
  static const int base = 0;
  static const int dropdown = 100;
  static const int sticky = 200;
  static const int fixed = 300;
  static const int floating = 400;
  static const int modal = 500;
  static const int tooltip = 600;
}
