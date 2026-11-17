import 'package:flutter/material.dart';
import 'package:attendence/core/theme/unified_theme.dart';

/// Responsive Utilities for consistent responsive design across the app
class ResponsiveUtils {
  // Device type detection
  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < AppBreakpoints.mobile) {
      return DeviceType.mobile;
    } else if (width < AppBreakpoints.desktop) {
      return DeviceType.tablet;
    } else {
      return DeviceType.desktop;
    }
  }

  // Responsive font sizes
  static double getResponsiveFontSize(
    BuildContext context, {
    required double mobileSize,
    double? tabletSize,
    double? desktopSize,
  }) {
    return AppBreakpoints.responsive(
      context,
      mobile: mobileSize,
      tablet: tabletSize ?? mobileSize * 1.1,
      desktop: desktopSize ?? mobileSize * 1.2,
    );
  }

  // Responsive spacing
  static double getResponsiveSpacing(
    BuildContext context, {
    required double mobileSpacing,
    double? tabletSpacing,
    double? desktopSpacing,
  }) {
    return AppBreakpoints.responsive(
      context,
      mobile: mobileSpacing,
      tablet: tabletSpacing ?? mobileSpacing * 1.1,
      desktop: desktopSpacing ?? mobileSpacing * 1.2,
    );
  }

  // Responsive grid columns
  static int getGridColumns(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) {
      return 4;
    } else if (AppBreakpoints.isTablet(context)) {
      return 2;
    }
    return 1;
  }

  // Responsive card grid columns
  static int getCardGridColumns(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) {
      return 3;
    } else if (AppBreakpoints.isTablet(context)) {
      return 2;
    }
    return 1;
  }

  // Responsive list item layout
  static bool shouldUseCompactLayout(BuildContext context) {
    return AppBreakpoints.isMobile(context);
  }

  // Responsive modal/dialog width
  static double getDialogWidth(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) {
      return 600;
    } else if (AppBreakpoints.isTablet(context)) {
      return 500;
    }
    return double.infinity;
  }

  // Responsive bottom sheet height
  static double getBottomSheetHeight(BuildContext context) {
    return MediaQuery.of(context).size.height * 0.7;
  }

  // Responsive icon sizes
  static double getIconSize(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) {
      return 32;
    } else if (AppBreakpoints.isTablet(context)) {
      return 28;
    }
    return 24;
  }

  // Responsive button height
  static double getButtonHeight(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) {
      return 56;
    } else if (AppBreakpoints.isTablet(context)) {
      return 52;
    }
    return 48;
  }

  // Responsive card width for horizontal cards
  static double getCardWidth(BuildContext context) {
    final padding = AppBreakpoints.getScreenPadding(context);
    final screenWidth = MediaQuery.of(context).size.width;
    return screenWidth - (padding * 2);
  }

  // Responsive max width for content
  static double getMaxContentWidth(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) {
      return 1200;
    } else if (AppBreakpoints.isTablet(context)) {
      return 900;
    }
    return double.infinity;
  }

  // Responsive aspect ratio for images
  static double getImageAspectRatio(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) {
      return 16 / 9;
    } else if (AppBreakpoints.isTablet(context)) {
      return 4 / 3;
    }
    return 1 / 1;
  }

  // Responsive crossAxisCount for GridView in StaticGrid
  static int getResponsiveCrossAxisCount(
    BuildContext context, {
    int mobileCount = 1,
    int tabletCount = 2,
    int desktopCount = 3,
  }) {
    if (AppBreakpoints.isDesktop(context)) {
      return desktopCount;
    } else if (AppBreakpoints.isTablet(context)) {
      return tabletCount;
    }
    return mobileCount;
  }

  // Get responsive elevation
  static double getElevation(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) {
      return 4;
    } else if (AppBreakpoints.isTablet(context)) {
      return 2;
    }
    return 1;
  }

  // Get responsive border radius
  static double getResponsiveBorderRadius(BuildContext context) {
    if (AppBreakpoints.isDesktop(context)) {
      return AppSpacing.radiusLg;
    } else if (AppBreakpoints.isTablet(context)) {
      return AppSpacing.radiusMd;
    }
    return AppSpacing.radiusSm;
  }

  // Get responsive padding as EdgeInsets
  static EdgeInsets getResponsivePadding(BuildContext context) {
    final padding = AppBreakpoints.getScreenPadding(context);
    return EdgeInsets.all(padding);
  }

  // Get responsive horizontal padding
  static EdgeInsets getResponsiveHorizontalPadding(BuildContext context) {
    final padding = AppBreakpoints.getScreenPadding(context);
    return EdgeInsets.symmetric(horizontal: padding);
  }

  // Get responsive vertical padding
  static EdgeInsets getResponsiveVerticalPadding(BuildContext context) {
    final padding = AppBreakpoints.getScreenPadding(context);
    return EdgeInsets.symmetric(vertical: padding);
  }

  // Check if landscape
  static bool isLandscape(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.landscape;
  }

  // Check if portrait
  static bool isPortrait(BuildContext context) {
    return MediaQuery.of(context).orientation == Orientation.portrait;
  }

  // Responsive flex ratios for Row/Column
  static int getResponsiveFlex(BuildContext context, {
    int? mobile,
    int? tablet,
    int? desktop,
  }) {
    if (AppBreakpoints.isDesktop(context) && desktop != null) {
      return desktop;
    }
    if (AppBreakpoints.isTablet(context) && tablet != null) {
      return tablet;
    }
    return mobile ?? 1;
  }
}

/// Device type enumeration
enum DeviceType {
  mobile,
  tablet,
  desktop,
}
