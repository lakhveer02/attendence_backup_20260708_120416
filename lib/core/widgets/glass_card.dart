import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:attendence/core/theme/unified_theme.dart';

/// Premium glassmorphism card with frosted glass effect
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Color? color;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? shadows;
  final Gradient? gradient;
  final VoidCallback? onTap;
  final bool enabled;
  final bool showShine;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 24.0,
    this.blur = 30.0,
    this.color,
    this.borderColor,
    this.borderWidth = 1.0,
    this.shadows,
    this.gradient,
    this.onTap,
    this.enabled = true,
    this.showShine = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppColors.glassBackground;
    final effectiveBorderColor = borderColor ?? AppColors.glassBorder;

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final effectiveWidth = width != null
        ? min(width!, screenWidth * 0.95)
        : null;
    final effectiveHeight = height != null
        ? min(height!, screenHeight * 0.95)
        : null;
    final effectivePadding = padding ?? EdgeInsets.all(AppBreakpoints.responsive<double>(context, mobile: 16, tablet: 20, desktop: 24));

    final cardContent = Container(
      width: effectiveWidth,
      height: effectiveHeight,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: shadows ?? _defaultShadows,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(
          children: [
            // Backdrop blur layer
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: Container(
                decoration: BoxDecoration(
                  color: effectiveColor,
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(borderRadius),
                  border: Border.all(
                    color: effectiveBorderColor,
                    width: borderWidth,
                  ),
                ),
              ),
            ),
            
            // Shine effect overlay
            if (showShine)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha:0.15),
                        Colors.white.withValues(alpha:0.0),
                      ],
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(borderRadius),
                      topRight: Radius.circular(borderRadius),
                    ),
                  ),
                ),
              ),
            
            // Content
            Padding(
              padding: effectivePadding,
              child: child,
            ),
          ],
        ),
      ),
    );

    if (onTap != null && enabled) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.primary.withValues(alpha:0.1),
          highlightColor: AppColors.primary.withValues(alpha:0.05),
          child: cardContent,
        ),
      );
    }

    return cardContent;
  }

  List<BoxShadow> get _defaultShadows => [
    BoxShadow(
      color: Colors.black.withValues(alpha:0.1),
      blurRadius: 20,
      offset: const Offset(0, 10),
    ),
    BoxShadow(
      color: AppColors.primary.withValues(alpha:0.05),
      blurRadius: 30,
      offset: const Offset(0, 5),
    ),
  ];
}

/// Glassmorphism container with gradient border
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final Gradient? borderGradient;
  final double borderWidth;
  final bool showGlow;
  final Color? glowColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 24.0,
    this.blur = 30.0,
    this.borderGradient,
    this.borderWidth = 2.0,
    this.showGlow = false,
    this.glowColor,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final effectiveWidth = width != null ? min(width!, screenWidth * 0.95) : null;
    final effectiveHeight = height != null ? min(height!, screenHeight * 0.95) : null;

    return Container(
      width: effectiveWidth,
      height: effectiveHeight,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: (glowColor ?? AppColors.primary).withValues(alpha:0.3),
                  blurRadius: 40,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: Stack(
        children: [
          // Gradient border
          Container(
            decoration: BoxDecoration(
              gradient: borderGradient ??
                  const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary,
              AppColors.accent,
            ],
          ),
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
          
          // Inner content with glass effect
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.all(borderWidth),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius - borderWidth),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.glassBackground,
                      borderRadius: BorderRadius.circular(borderRadius - borderWidth),
                    ),
                    padding: padding ?? const EdgeInsets.all(20),
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Floating glass button with glow effect
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final Gradient? gradient;
  final bool showGlow;
  final bool enabled;

  const GlassButton({
    super.key,
    required this.child,
    this.onPressed,
    this.width,
    this.height,
    this.padding,
    this.borderRadius = 16.0,
    this.gradient,
    this.showGlow = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = enabled && onPressed != null;

    return AnimatedOpacity(
      opacity: isEnabled ? 1.0 : 0.5,
      duration: const Duration(milliseconds: 200),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled ? onPressed : null,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              gradient: gradient ?? AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(borderRadius),
              boxShadow: showGlow && isEnabled
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha:0.4),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ]
                  : null,
            ),
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Center(child: child),
          ),
        ),
      ),
    );
  }
}
