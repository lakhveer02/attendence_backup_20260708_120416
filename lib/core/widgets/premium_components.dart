/// Reusable UI Components - Glassmorphism with premium aesthetics
/// Production-ready components following design system

import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../theme/design_system.dart';

/// Glass Card - Premium floating card with glassmorphism
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final double? borderRadius;
  final Color? backgroundColor;
  final bool hasShadow;
  final double blur;

  const GlassCard({
    Key? key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.onTap,
    this.borderRadius = AppRadius.xl,
    this.backgroundColor,
    this.hasShadow = true,
    this.blur = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = borderRadius ?? AppRadius.xl;
    
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.1 : 0.2),
                  Colors.white.withValues(alpha: isDark ? 0.05 : 0.05),
                ],
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: isDark ? 0.15 : 0.25),
                width: 1.5,
              ),
              boxShadow: hasShadow
                  ? [
                      BoxShadow(
                        color: isDark
                            ? Colors.black.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.1),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : [],
            ),
            child: Padding(
              padding: padding,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium Button - Modern elevated button with gradient
class PremiumButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isDisabled;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double? width;
  final double height;
  final bool isOutlined;
  final bool isFilled;

  const PremiumButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isDisabled = false,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.width,
    this.height = 56,
    this.isOutlined = false,
    this.isFilled = true,
  }) : super(key: key);

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.fast,
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

  void _onPressDown(TapDownDetails event) {
    _controller.forward();
  }

  void _onPressUp(TapUpDetails event) {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOutlined) {
      return ScaleTransition(
        scale: _scaleAnimation,
        child: MouseRegion(
          onEnter: (_) => _controller.forward(),
          onExit: (_) => _controller.reverse(),
          child: GestureDetector(
            onTapDown: _onPressDown,
            onTapUp: _onPressUp,
            onTap: widget.isDisabled || widget.isLoading ? null : widget.onPressed,
            child: Container(
              width: widget.width ?? double.infinity,
              height: widget.height,
              decoration: BoxDecoration(
                border: Border.all(
                  color: widget.isDisabled
                      ? AppColors.gray300
                      : AppColors.primary,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null && !widget.isLoading)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.md),
                        child: Icon(widget.icon, size: 20),
                      ),
                    if (widget.isLoading)
                      Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.md),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(
                              widget.isDisabled ? AppColors.gray400 : AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    Text(
                      widget.label,
                      style: AppTypography.labelLarge.copyWith(
                        color: widget.isDisabled
                            ? AppColors.gray400
                            : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: MouseRegion(
        onEnter: (_) => _controller.forward(),
        onExit: (_) => _controller.reverse(),
        child: GestureDetector(
          onTapDown: _onPressDown,
          onTapUp: _onPressUp,
          onTap: widget.isDisabled || widget.isLoading ? null : widget.onPressed,
          child: Container(
            width: widget.width ?? double.infinity,
            height: widget.height,
            decoration: BoxDecoration(
              gradient: widget.isDisabled
                  ? LinearGradient(
                      colors: [
                        AppColors.gray300,
                        AppColors.gray300,
                      ],
                    )
                  : AppGradients.primaryGradient,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: widget.isDisabled
                  ? []
                  : [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null && !widget.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: Icon(
                        widget.icon,
                        size: 20,
                        color: widget.isDisabled ? AppColors.gray600 : AppColors.white,
                      ),
                    ),
                  if (widget.isLoading)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation(AppColors.white),
                        ),
                      ),
                    ),
                  Text(
                    widget.label,
                    style: AppTypography.labelLarge.copyWith(
                      color: widget.isDisabled ? AppColors.gray600 : AppColors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium Input Field
class PremiumTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixIconTap;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool isLoading;

  const PremiumTextField({
    Key? key,
    required this.label,
    required this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixIconTap,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.isLoading = false,
  }) : super(key: key);

  @override
  State<PremiumTextField> createState() => _PremiumTextFieldState();
}

class _PremiumTextFieldState extends State<PremiumTextField> {
  late FocusNode _focusNode;
  bool _isFocused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    setState(() {
      _isFocused = _focusNode.hasFocus;
    });
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: AppTypography.labelMedium.copyWith(
            color: _isFocused ? AppColors.primary : Theme.of(context).colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextFormField(
          controller: widget.controller,
          obscureText: widget.obscureText,
          keyboardType: widget.keyboardType,
          focusNode: _focusNode,
          onChanged: widget.onChanged,
          validator: widget.validator,
          maxLines: widget.maxLines,
          enabled: !widget.isLoading,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: AppColors.gray400)
                : null,
            suffixIcon: widget.suffixIcon != null
                ? GestureDetector(
                    onTap: widget.onSuffixIconTap,
                    child: Icon(widget.suffixIcon, color: AppColors.gray400),
                  )
                : null,
            suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          ),
        ),
      ],
    );
  }
}

/// Status Badge - Small status indicator
class StatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    Key? key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: backgroundColor.withValues(alpha: 0.1),
        border: Border.all(color: backgroundColor.withValues(alpha: 0.3), width: 1),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: Icon(icon, size: 14, color: backgroundColor),
            ),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: backgroundColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Statistics Card - Display metrics with animation
class StatisticsCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color accentColor;
  final String? trend;
  final bool isTrendPositive;

  const StatisticsCard({
    Key? key,
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.accentColor,
    this.trend,
    this.isTrendPositive = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  icon,
                  color: accentColor,
                  size: 24,
                ),
              ),
              if (trend != null)
                StatusBadge(
                  label: trend!,
                  backgroundColor: isTrendPositive ? AppColors.success : AppColors.error,
                  textColor: isTrendPositive ? AppColors.success : AppColors.error,
                  icon: isTrendPositive ? Icons.trending_up : Icons.trending_down,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            style: AppTypography.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: AppTypography.headingLarge.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: AppTypography.bodySmall.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium AppBar - Custom app bar with glassmorphism
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final bool showBackButton;
  final Color? backgroundColor;

  const PremiumAppBar({
    Key? key,
    required this.title,
    this.onBackPressed,
    this.actions,
    this.showBackButton = true,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      borderRadius: 0,
      child: Row(
        children: [
          if (showBackButton)
            GestureDetector(
              onTap: onBackPressed ?? () => Navigator.of(context).pop(),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          if (showBackButton) const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Text(
              title,
              style: AppTypography.headingLarge,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actions != null) ...[
            const SizedBox(width: AppSpacing.lg),
            ...actions!,
          ],
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(70);
}

/// Floating Action Button - Premium FAB with animation
class PremiumFAB extends StatefulWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? label;
  final Color? backgroundColor;

  const PremiumFAB({
    Key? key,
    required this.icon,
    required this.onPressed,
    this.label,
    this.backgroundColor,
  }) : super(key: key);

  @override
  State<PremiumFAB> createState() => _PremiumFABState();
}

class _PremiumFABState extends State<PremiumFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppAnimations.fast,
      vsync: this,
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
        widget.onPressed();
      },
      onTapCancel: () => _controller.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 0.9).animate(
          CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
        ),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppGradients.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.4),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: AppColors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
