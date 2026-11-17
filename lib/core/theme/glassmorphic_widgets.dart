import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:attendence/core/theme/unified_theme.dart';
import 'package:attendence/core/theme/role_based_colors.dart';
import 'package:attendence/core/utils/responsive_utils.dart';

/// Glassmorphism components for modern, elegant UI
/// Provides frosted glass effects with transparency and backdrop blur
class GlassmorphicWidgets {
  /// Base glassmorphic container with customizable blur and opacity
  static Widget glassmorphicContainer({
    required BuildContext context,
    required Widget child,
    Color? backgroundColor,
    double blurStrength = 10.0,
    double opacity = 0.1,
    EdgeInsets padding = const EdgeInsets.all(16),
    BorderRadius? borderRadius,
    double? height,
    double? width,
    BoxBorder? border,
  }) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        border: border ?? Border.all(
          color: Colors.white.withValues(alpha:0.2),
          width: 1.5,
        ),
        color: (backgroundColor ?? Colors.white).withValues(alpha:opacity),
      ),
      child: Stack(
        children: [
          // Glassmorphic blur effect (clip to container bounds to avoid full-screen blur)
          ClipRRect(
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blurStrength, sigmaY: blurStrength),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: borderRadius ?? BorderRadius.circular(16),
                  color: Colors.transparent,
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: padding,
            child: child,
          ),
        ],
      ),
    );
  }

  /// Role-specific glassmorphic card
  static Widget roleGlassmorphicCard({
    required BuildContext context,
    required String role,
    required Widget child,
    VoidCallback? onTap,
    double blurStrength = 10.0,
    EdgeInsets padding = const EdgeInsets.all(16),
  }) {
    final roleColor = RoleBasedColors.getRolePrimaryColor(role);

    return GestureDetector(
      onTap: onTap,
      child: glassmorphicContainer(
        context: context,
        backgroundColor: roleColor,
        opacity: 0.08,
        blurStrength: blurStrength,
        padding: padding,
        border: Border.all(
          color: roleColor.withValues(alpha:0.3),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context),
        ),
        child: child,
      ),
    );
  }

  /// Elevated glassmorphic button
  static Widget glassmorphicButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    Color? primaryColor,
    Color? textColor,
    double? width,
    bool isLoading = false,
    IconData? icon,
  }) {
    final color = primaryColor ?? AppColors.primary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getResponsiveBorderRadius(context),
        ),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getResponsiveBorderRadius(context),
          ),
          child: Container(
            width: width,
            height: ResponsiveUtils.getButtonHeight(context),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color, color.withValues(alpha:0.85)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha:0.2),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha:0.24),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Center(
                child: isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          valueColor:
                              AlwaysStoppedAnimation(textColor ?? Colors.white),
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (icon != null) ...[
                            Icon(
                              icon,
                              color: textColor ?? Colors.white,
                              size: ResponsiveUtils.getIconSize(context),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: TextStyle(
                              color: textColor ?? Colors.white,
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobileSize: 13,
                                tabletSize: 14,
                                desktopSize: 15,
                              ),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.25,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Glassmorphic header with gradient background
  static Widget glassmorphicHeader({
    required BuildContext context,
    required String title,
    String? subtitle,
    String? role,
    IconData? icon,
    VoidCallback? onBackPressed,
  }) {
    final gradient = role != null
        ? RoleBasedColors.getRoleGradient(role)
        : RoleBasedColors.getRoleGradient('employee');

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(24),
        bottomRight: Radius.circular(24),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: ResponsiveUtils.getResponsivePadding(context).left,
              vertical: 24,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha:0.08),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              border: Border(
                bottom: BorderSide(
                  color: Colors.white.withValues(alpha:0.15),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (onBackPressed != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: GestureDetector(
                      onTap: onBackPressed,
                      child: Container(
                        height: 40,
                        width: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.16),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha:0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    if (icon != null) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha:0.18),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha:0.2),
                          ),
                        ),
                        child: Icon(
                          icon,
                          color: Colors.white,
                          size: ResponsiveUtils.getIconSize(context),
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: ResponsiveUtils.getResponsiveFontSize(
                                context,
                                mobileSize: 24,
                                tabletSize: 28,
                                desktopSize: 32,
                              ),
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha:0.82),
                                fontSize: ResponsiveUtils.getResponsiveFontSize(
                                  context,
                                  mobileSize: 14,
                                  tabletSize: 16,
                                  desktopSize: 18,
                                ),
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Glassmorphic stat card showing key metrics
  static Widget glassmorphicStatCard({
    required BuildContext context,
    required String label,
    required String value,
    String? role,
    IconData? icon,
    Color? customColor,
    VoidCallback? onTap,
  }) {
    final color = customColor ??
        (role != null
            ? RoleBasedColors.getRolePrimaryColor(role)
            : AppColors.primary);

    return GestureDetector(
      onTap: onTap,
      child: glassmorphicContainer(
        context: context,
        backgroundColor: color,
        opacity: 0.08,
        padding: const EdgeInsets.all(16),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha:0.3),
          width: 1.5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha:0.7),
                            fontSize: ResponsiveUtils.getResponsiveFontSize(
                        context,
                        mobileSize: 12,
                        tabletSize: 13,
                        desktopSize: 14,
                      ),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                if (icon != null)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha:0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 20,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: ResponsiveUtils.getResponsiveFontSize(
                  context,
                  mobileSize: 28,
                  tabletSize: 32,
                  desktopSize: 36,
                ),
                fontWeight: FontWeight.w700,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Glassmorphic input field
  static Widget glassmorphicTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String hintText,
    String? role,
    IconData? prefixIcon,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    int maxLines = 1,
    FocusNode? focusNode,
    bool autofocus = false,
  }) {
    final color = role != null
        ? RoleBasedColors.getRolePrimaryColor(role)
        : AppColors.primary;

    return glassmorphicContainer(
      context: context,
      backgroundColor: color,
      opacity: 0.05,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      borderRadius: BorderRadius.circular(
        ResponsiveUtils.getResponsiveBorderRadius(context),
      ),
      border: Border.all(
        color: color.withValues(alpha:0.2),
        width: 1.5,
      ),
      child: Semantics(
        label: hintText,
        textField: true,
        child: TextField(
          focusNode: focusNode,
          autofocus: autofocus,
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: obscureText ? 1 : maxLines,
          cursorColor: Colors.white,
          style: TextStyle(
            color: Colors.white,
            fontSize: ResponsiveUtils.getResponsiveFontSize(
              context,
              mobileSize: 14,
              tabletSize: 16,
              desktopSize: 18,
            ),
            letterSpacing: 0.2,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.65),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context),
              ),
                  borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context),
              ),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.12), width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                ResponsiveUtils.getResponsiveBorderRadius(context),
              ),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.85), width: 2),
            ),
            prefixIcon: prefixIcon != null
                ? Icon(
                    prefixIcon,
                    color: Colors.white.withValues(alpha: 0.85),
                    size: ResponsiveUtils.getIconSize(context),
                  )
                : null,
            suffixIcon: suffixIcon != null
                ? GestureDetector(
                    onTap: onSuffixTap,
                    child: Icon(
                      suffixIcon,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: ResponsiveUtils.getIconSize(context),
                    ),
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
          ),
        ),
      ),
    );
  }

  /// Role-based badge with glassmorphic effect
  static Widget roleGlassmorphicBadge({
    required BuildContext context,
    required String role,
    required String label,
    bool showIcon = true,
  }) {
    final primaryColor = RoleBasedColors.getRolePrimaryColor(role);
    final accentColor = RoleBasedColors.getRoleAccentColor(role);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryColor.withValues(alpha:0.2), accentColor.withValues(alpha:0.1)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: primaryColor.withValues(alpha:0.3),
            width: 1,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showIcon) ...[
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: ResponsiveUtils.getResponsiveFontSize(
                      context,
                      mobileSize: 11,
                      tabletSize: 12,
                      desktopSize: 13,
                    ),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
