// 🎨 Modern Design System - World-Class UI Components
// Premium gradients, glassmorphism, neumorphism, and stunning animations

import 'package:flutter/material.dart';
import 'dart:ui';

/// 🌈 Modern Color Palette with Gradients
class ModernColors {
  ModernColors._();

  // Premium Gradients
  static const primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
  );

  static const successGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF10B981), Color(0xFF34D399)],
  );

  static const warningGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
  );

  static const dangerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
  );

  static const sunsetGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFEC4899), Color(0xFF8B5CF6)],
  );

  static const oceanGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0EA5E9), Color(0xFF3B82F6), Color(0xFF6366F1)],
  );

  static const forestGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF10B981), Color(0xFF34D399)],
  );

  // Glass effect colors
  static Color glassWhite = Colors.white.withOpacity(0.1);
  static Color glassBorder = Colors.white.withOpacity(0.2);
  static Color glassBlack = Colors.black.withOpacity(0.1);

  // Modern vibrant colors
  static const indigo = Color(0xFF6366F1);
  static const purple = Color(0xFF8B5CF6);
  static const violet = Color(0xFFA855F7);
  static const pink = Color(0xFFEC4899);
  static const rose = Color(0xFFF43F5E);
  static const orange = Color(0xFFFF6B35);
  static const amber = Color(0xFFF59E0B);
  static const lime = Color(0xFF84CC16);
  static const emerald = Color(0xFF10B981);
  static const teal = Color(0xFF14B8A6);
  static const cyan = Color(0xFF06B6D4);
  static const sky = Color(0xFF0EA5E9);
  static const blue = Color(0xFF3B82F6);
  
  // Background colors
  static const background = Color(0xFFF8FAFC);
  static const cardBackground = Color(0xFFFFFFFF);
  static const darkBackground = Color(0xFF1E293B);
}

/// ✨ Modern Shadows and Effects
class ModernEffects {
  ModernEffects._();

  // Soft shadow
  static List<BoxShadow> softShadow({Color? color}) => [
        BoxShadow(
          color: (color ?? Colors.black).withOpacity(0.08),
          blurRadius: 20,
          offset: const Offset(0, 4),
        ),
      ];

  // Medium shadow
  static List<BoxShadow> mediumShadow({Color? color}) => [
        BoxShadow(
          color: (color ?? Colors.black).withOpacity(0.12),
          blurRadius: 30,
          offset: const Offset(0, 8),
        ),
      ];

  // Strong shadow
  static List<BoxShadow> strongShadow({Color? color}) => [
        BoxShadow(
          color: (color ?? Colors.black).withOpacity(0.15),
          blurRadius: 40,
          offset: const Offset(0, 12),
        ),
      ];

  // Glow effect
  static List<BoxShadow> glowEffect({required Color color}) => [
        BoxShadow(
          color: color.withOpacity(0.3),
          blurRadius: 24,
          spreadRadius: 0,
        ),
        BoxShadow(
          color: color.withOpacity(0.1),
          blurRadius: 40,
          spreadRadius: 8,
        ),
      ];

  // Neumorphism light
  static List<BoxShadow> neumorphismLight() => [
        const BoxShadow(
          color: Color(0xFFFFFFFF),
          offset: Offset(-6, -6),
          blurRadius: 12,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          offset: const Offset(6, 6),
          blurRadius: 12,
        ),
      ];

  // Neumorphism dark
  static List<BoxShadow> neumorphismDark() => [
        BoxShadow(
          color: Colors.white.withOpacity(0.05),
          offset: const Offset(-6, -6),
          blurRadius: 12,
        ),
        const BoxShadow(
          color: Color(0xFF000000),
          offset: Offset(6, 6),
          blurRadius: 12,
        ),
      ];

  // Inner shadow effect
  static List<BoxShadow> innerShadow() => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          offset: const Offset(2, 2),
          blurRadius: 4,
          spreadRadius: -2,
        ),
      ];
}

/// 🎭 Animation Durations
class ModernAnimations {
  ModernAnimations._();

  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration verySlow = Duration(milliseconds: 800);

  // Curve presets
  static const Curve bounceIn = Curves.easeOutBack;
  static const Curve smoothIn = Curves.easeInOut;
  static const Curve elastic = Curves.elasticOut;
  static const Curve spring = Curves.easeOutCubic;
}

/// 🔮 Glassmorphism Widget
class GlassCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final double blur;
  final Color? color;
  final Border? border;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.blur = 10,
    this.color,
    this.border,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final widget = ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          padding: padding ?? const EdgeInsets.all(20),
          margin: margin,
          decoration: BoxDecoration(
            color: color ?? Colors.white.withOpacity(0.1),
            borderRadius: borderRadius ?? BorderRadius.circular(20),
            border: border ??
                Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
            boxShadow: boxShadow ?? ModernEffects.softShadow(),
          ),
          child: child,
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: widget,
      );
    }

    return widget;
  }
}

/// 🌊 Gradient Card Widget
class GradientCard extends StatelessWidget {
  final Widget child;
  final Gradient gradient;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;

  const GradientCard({
    super.key,
    required this.child,
    required this.gradient,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.boxShadow,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: boxShadow ?? ModernEffects.mediumShadow(),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: widget,
      );
    }

    return widget;
  }
}

/// 💫 Animated Gradient Button
class AnimatedGradientButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final Gradient gradient;
  final double? width;
  final double height;
  final IconData? icon;
  final bool isLoading;
  final BorderRadius? borderRadius;

  const AnimatedGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.gradient,
    this.width,
    this.height = 56,
    this.icon,
    this.isLoading = false,
    this.borderRadius,
  });

  @override
  State<AnimatedGradientButton> createState() =>
      _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: ModernAnimations.fast,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        if (!widget.isLoading) {
          widget.onPressed();
        }
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
            boxShadow: ModernEffects.glowEffect(
              color: widget.gradient.colors.first,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
              onTap: widget.isLoading ? null : widget.onPressed,
              child: Center(
                child: widget.isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.icon != null) ...[
                            Icon(widget.icon, color: Colors.white, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            widget.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
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
}

/// 🎪 Shimmer Loading Effect
class ShimmerLoading extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Color? baseColor;
  final Color? highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    this.isLoading = true,
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ShimmerLoading> createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) return widget.child;

    final baseColor = widget.baseColor ?? Colors.grey.shade300;
    final highlightColor =
        widget.highlightColor ?? Colors.grey.shade100;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: [
                _controller.value - 0.3,
                _controller.value,
                _controller.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
            ).createShader(bounds);
          },
          child: widget.child,
        );
      },
    );
  }
}

/// 🎨 Neumorphic Container
class NeumorphicCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final BorderRadius? borderRadius;
  final Color? color;
  final bool isDark;
  final VoidCallback? onTap;

  const NeumorphicCard({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius,
    this.color,
    this.isDark = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final widget = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(20),
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade100),
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        boxShadow: isDark
            ? ModernEffects.neumorphismDark()
            : ModernEffects.neumorphismLight(),
      ),
      child: child,
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: widget,
      );
    }

    return widget;
  }
}

/// 🌟 Star Rating Widget
class StarRating extends StatelessWidget {
  final double rating;
  final double size;
  final Color? color;
  final int maxStars;

  const StarRating({
    super.key,
    required this.rating,
    this.size = 20,
    this.color,
    this.maxStars = 5,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(maxStars, (index) {
        if (index < rating.floor()) {
          return Icon(
            Icons.star_rounded,
            size: size,
            color: color ?? ModernColors.amber,
          );
        } else if (index < rating.ceil() && rating % 1 != 0) {
          return Icon(
            Icons.star_half_rounded,
            size: size,
            color: color ?? ModernColors.amber,
          );
        } else {
          return Icon(
            Icons.star_outline_rounded,
            size: size,
            color: color ?? Colors.grey.shade400,
          );
        }
      }),
    );
  }
}

/// 📊 Progress Bar with Gradient
class GradientProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Gradient? gradient;
  final Color? backgroundColor;
  final BorderRadius? borderRadius;

  const GradientProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.gradient,
    this.backgroundColor,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.grey.shade200,
        borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: value.clamp(0.0, 1.0),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient ?? ModernColors.primaryGradient,
            borderRadius: borderRadius ?? BorderRadius.circular(height / 2),
            boxShadow: ModernEffects.glowEffect(
              color: gradient?.colors.first ?? ModernColors.indigo,
            ),
          ),
        ),
      ),
    );
  }
}

/// 🎯 Badge Widget
class ModernBadge extends StatelessWidget {
  final String text;
  final Color? color;
  final Gradient? gradient;
  final EdgeInsetsGeometry? padding;
  final double? fontSize;

  const ModernBadge({
    super.key,
    required this.text,
    this.color,
    this.gradient,
    this.padding,
    this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: gradient == null ? (color ?? ModernColors.indigo) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(12),
        boxShadow: ModernEffects.softShadow(
          color: color ?? ModernColors.indigo,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

/// 🔘 Animated Toggle Button
class AnimatedToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;
  final Gradient? activeGradient;
  final Color? inactiveColor;

  const AnimatedToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 56,
    this.height = 32,
    this.activeGradient,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: ModernAnimations.normal,
        curve: Curves.easeInOut,
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: value ? (activeGradient ?? ModernColors.primaryGradient) : null,
          color: value ? null : (inactiveColor ?? Colors.grey.shade300),
          borderRadius: BorderRadius.circular(height / 2),
          boxShadow: value
              ? ModernEffects.glowEffect(
                  color: activeGradient?.colors.first ?? ModernColors.indigo,
                )
              : null,
        ),
        child: AnimatedAlign(
          duration: ModernAnimations.normal,
          curve: Curves.easeInOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: height - 4,
            height: height - 4,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: ModernEffects.softShadow(),
            ),
          ),
        ),
      ),
    );
  }
}
