// Unified Theme System
// Single consistent color palette and design tokens for entire app
// No more different color combinations per screen!

// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:attendence/core/theme/app_text_styles.dart';

/// Unified Color Palette - Used across entire app
class AppColors {
  AppColors._();

  // Primary Brand Colors
  static const primary = Color(0xFF1E40AF); // Deep Royal Blue
  static const primaryDark = Color(0xFF172E8A);
  static const primaryLight = Color(0xFF3B82F6);
  
  // Accent Colors
  static const accent = Color(0xFF3B82F6); // Secondary Blue
  static const accentDark = Color(0xFF2563EB);
  static const accentLight = Color(0xFF60A5FA);
  
  // Status Colors
  static const success = Color(0xFF22C55E);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
  static const info = Color(0xFF3B82F6);
  
  // Neutral Colors (Light Theme defaults)
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const surfaceLight = Color(0xFFF1F5F9);
  
  // Text Colors (Light theme friendly)
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF334155);
  static const textTertiary = Color(0xFF64748B);
  static const textDisabled = Color(0xFF94A3B8);
  
  // Border & Divider
  static const border = Color(0xFFE6EEF8);
  static const divider = Color(0xFFE6EEF8);
  
  // Glass/Frosted Effect
  static const glassBorder = Color(0x1F1E40AF);
  static const glassBackground = Color(0x10FFFFFF);
  
  // Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );
  
  static const accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [accent, accentDark],
  );
  
  static const successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [success, Color(0xFF059669)],
  );
  
  static const warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [warning, Color(0xFFD97706)],
  );
  
  static const backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      primaryDark,
      primary,
    ],
  );
}

/// Unified Spacing System
class AppSpacing {
  AppSpacing._();
  
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;
  
  // Screen padding
  static const double screenPadding = 20.0;
  static const double cardPadding = 16.0;
  
  // Border radius
  static const double radiusSm = 8.0;
  static const double radiusMd = 16.0;
  static const double radiusLg = 24.0; // Cards
  static const double radiusXl = 28.0;
  static const double radiusButton = 18.0; // Buttons
  static const double radiusFull = 999.0;
}

/// Unified Typography
class AppTypography {
  AppTypography._();
  
  static TextStyle get displayLarge => AppTextStyles.inter(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  
  static TextStyle get displayMedium => AppTextStyles.inter(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: -0.5,
  );
  
  static TextStyle get displaySmall => AppTextStyles.inter(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get headlineLarge => AppTextStyles.inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get headlineMedium => AppTextStyles.inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get headlineSmall => AppTextStyles.inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get bodyLarge => AppTextStyles.inter(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static TextStyle get bodyMedium => AppTextStyles.inter(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );
  
  static TextStyle get bodySmall => AppTextStyles.inter(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
  );
  
  static TextStyle get labelLarge => AppTextStyles.inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
  
  static TextStyle get labelMedium => AppTextStyles.inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );
  
  static TextStyle get labelSmall => AppTextStyles.inter(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.textTertiary,
  );
}

/// Unified Shadows
class AppShadows {
  AppShadows._();
  
  static List<BoxShadow> get sm => [
    BoxShadow(
      color: Colors.black.withValues(alpha:0.1),
      blurRadius: 4,
      offset: const Offset(0, 2),
    ),
  ];
  
  static List<BoxShadow> get md => [
    BoxShadow(
      color: Colors.black.withValues(alpha:0.15),
      blurRadius: 8,
      offset: const Offset(0, 4),
    ),
  ];
  
  static List<BoxShadow> get lg => [
    BoxShadow(
      color: Colors.black.withValues(alpha:0.2),
      blurRadius: 16,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> get xl => [
    BoxShadow(
      color: Colors.black.withValues(alpha:0.25),
      blurRadius: 24,
      offset: const Offset(0, 12),
    ),
  ];
  
  // Glow effects
  static List<BoxShadow> primaryGlow = [
    BoxShadow(
      color: AppColors.primary.withValues(alpha:0.4),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
  
  static List<BoxShadow> accentGlow = [
    BoxShadow(
      color: AppColors.accent.withValues(alpha:0.4),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];
}

/// Responsive Breakpoints
class AppBreakpoints {
  AppBreakpoints._();
  
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;
  static const double largeDesktop = 1536;
  
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobile;
  
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobile &&
      MediaQuery.of(context).size.width < desktop;
  
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktop;
  
  // Get responsive value
  static T responsive<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    return mobile;
  }
  
  // Get responsive padding
  static double getScreenPadding(BuildContext context) {
    if (isDesktop(context)) return AppSpacing.xl;
    if (isTablet(context)) return AppSpacing.lg;
    return AppSpacing.screenPadding;
  }
}

/// Unified Theme Data
class UnifiedTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: AppColors.surface,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusButton)),
          textStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge.copyWith(color: AppColors.textPrimary),
        displayMedium: AppTypography.displayMedium.copyWith(color: AppColors.textPrimary),
        displaySmall: AppTypography.displaySmall.copyWith(color: AppColors.textPrimary),
        headlineLarge: AppTypography.headlineLarge.copyWith(color: AppColors.textPrimary),
        headlineMedium: AppTypography.headlineMedium.copyWith(color: AppColors.textPrimary),
        bodyLarge: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary),
        bodyMedium: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      
      scaffoldBackgroundColor: AppColors.surface,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.headlineMedium,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      
      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          textStyle: AppTypography.labelLarge.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        labelStyle: AppTypography.bodyMedium,
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.textDisabled,
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.md),
      ),
      
      // Dialog Theme
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        ),
        titleTextStyle: AppTypography.headlineMedium,
        contentTextStyle: AppTypography.bodyMedium,
      ),
      
      // Bottom Sheet Theme
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppSpacing.radiusLg),
          ),
        ),
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        space: 1,
        thickness: 1,
      ),
      
      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.textSecondary,
        size: 24,
      ),
      
      // Typography
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      ),
    );
  }
}

/// Responsive Helper Widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints) builder;
  
  const ResponsiveBuilder({super.key, required this.builder});
  
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: builder);
  }
}

/// Responsive Padding Widget
class ResponsivePadding extends StatelessWidget {
  final Widget child;
  
  const ResponsivePadding({super.key, required this.child});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(AppBreakpoints.getScreenPadding(context)),
      child: child,
    );
  }
}

/// Responsive Container (constrains max width on large screens)
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 1200,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Responsive Grid Layout
class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double spacing;
  
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 1,
    this.tabletColumns = 2,
    this.desktopColumns = 3,
    this.spacing = 16,
  });
  
  @override
  Widget build(BuildContext context) {
    final columns = AppBreakpoints.responsive(
      context,
      mobile: mobileColumns,
      tablet: tabletColumns,
      desktop: desktopColumns,
    );
    
    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: spacing,
      crossAxisSpacing: spacing,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: children,
    );
  }
}

/// Responsive Row (switches to column on mobile)
class ResponsiveRow extends StatelessWidget {
  final List<Widget> children;
  final MainAxisAlignment mainAxisAlignment;
  final CrossAxisAlignment crossAxisAlignment;
  final double spacing;
  
  const ResponsiveRow({
    super.key,
    required this.children,
    this.mainAxisAlignment = MainAxisAlignment.start,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.spacing = 16,
  });
  
  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isMobile(context)) {
      return Column(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1) SizedBox(height: spacing),
          ],
        ],
      );
    }
    
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (int i = 0; i < children.length; i++) ...[
          Expanded(child: children[i]),
          if (i < children.length - 1) SizedBox(width: spacing),
        ],
      ],
    );
  }
}

/// Responsive Text with adaptive font size
class ResponsiveText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final double mobileSize;
  final double? tabletSize;
  final double? desktopSize;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  
  const ResponsiveText(
    this.text, {
    super.key,
    this.style,
    this.mobileSize = 14,
    this.tabletSize,
    this.desktopSize,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
  });
  
  @override
  Widget build(BuildContext context) {
    final fontSize = AppBreakpoints.responsive(
      context,
      mobile: mobileSize,
      tablet: tabletSize ?? mobileSize * 1.1,
      desktop: desktopSize ?? mobileSize * 1.2,
    );
    
    return Text(
      text,
      style: (style ?? AppTypography.bodyMedium).copyWith(fontSize: fontSize),
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}

/// Responsive Icon
class ResponsiveIcon extends StatelessWidget {
  final IconData icon;
  final double mobileSize;
  final double? tabletSize;
  final double? desktopSize;
  final Color color;
  
  const ResponsiveIcon(
    this.icon, {
    super.key,
    this.mobileSize = 24,
    this.tabletSize,
    this.desktopSize,
    this.color = AppColors.textSecondary,
  });
  
  @override
  Widget build(BuildContext context) {
    final size = AppBreakpoints.responsive(
      context,
      mobile: mobileSize,
      tablet: tabletSize ?? mobileSize * 1.2,
      desktop: desktopSize ?? mobileSize * 1.5,
    );
    
    return Icon(icon, size: size, color: color);
  }
}

/// Responsive Spacing Helper
class ResponsiveSpace extends StatelessWidget {
  final bool vertical;
  final double mobileFactor;
  final double? tabletFactor;
  final double? desktopFactor;
  
  const ResponsiveSpace.vertical({
    super.key,
    this.mobileFactor = 1,
    this.tabletFactor,
    this.desktopFactor,
  }) : vertical = true;
  
  const ResponsiveSpace.horizontal({
    super.key,
    this.mobileFactor = 1,
    this.tabletFactor,
    this.desktopFactor,
  }) : vertical = false;
  
  @override
  Widget build(BuildContext context) {
    final baseFactor = AppBreakpoints.responsive(
      context,
      mobile: mobileFactor,
      tablet: tabletFactor ?? mobileFactor,
      desktop: desktopFactor ?? mobileFactor,
    );
    
    final space = AppSpacing.md * baseFactor;
    
    return vertical
        ? SizedBox(height: space)
        : SizedBox(width: space);
  }
}

/// Adaptive Layout Builder
class AdaptiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const AdaptiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isDesktop(context) && desktop != null) {
      return desktop!;
    }
    if (AppBreakpoints.isTablet(context) && tablet != null) {
      return tablet!;
    }
    return mobile;
  }
}

/// Enhanced Breakpoints with additional helpers
extension AppBreakpointsExtension on AppBreakpoints {
  static double getResponsiveHeight(BuildContext context, {
    required double mobile,
    double? tablet,
    double? desktop,
  }) {
    return AppBreakpoints.responsive(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
  
  static EdgeInsets getResponsiveInsets(BuildContext context, {
    required EdgeInsets mobile,
    EdgeInsets? tablet,
    EdgeInsets? desktop,
  }) {
    return AppBreakpoints.responsive(
      context,
      mobile: mobile,
      tablet: tablet,
      desktop: desktop,
    );
  }
  
  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppBreakpoints.largeDesktop;
}
