import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:attendence/core/theme/unified_theme.dart';

/// Premium glassmorphic bottom navigation bar
class GlassBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<GlassNavItem> items;

  const GlassBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(AppBreakpoints.getScreenPadding(context) * 0.75),
      height: AppBreakpoints.responsive<double>(context, mobile: 70, tablet: 78, desktop: 88),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppBreakpoints.responsive<double>(context, mobile: 22, tablet: 26, desktop: 28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.2),
            blurRadius: AppBreakpoints.responsive<double>(context, mobile: 28, tablet: 34, desktop: 40),
            offset: Offset(0, AppBreakpoints.responsive<double>(context, mobile: 8, tablet: 9, desktop: 10)),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1.5,
              ),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0x1AFFFFFF),
                  Color(0x0DFFFFFF),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                items.length,
                (index) => _buildNavItem(
                  item: items[index],
                  isSelected: currentIndex == index,
                  onTap: () => onTap(index),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required GlassNavItem item,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.primary.withValues(alpha:0.1),
          highlightColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    // Glow effect when selected
                    if (isSelected)
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: RadialGradient(
                            colors: [
                              AppColors.primary.withValues(alpha:0.3),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    
                    // Icon container
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: isSelected ? 44 : 36,
                      height: isSelected ? 44 : 36,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? AppColors.primaryGradient
                            : null,
                        color: isSelected ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(isSelected ? 14 : 12),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha:0.4),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ]
                            : null,
                      ),
                      child: Icon(
                        isSelected ? item.selectedIcon : item.icon,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textTertiary,
                        size: isSelected ? 24 : 22,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Label
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  style: AppTypography.labelSmall.copyWith(
                    color: isSelected
                        ? AppColors.textPrimary
                        : AppColors.textTertiary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                  child: Text(item.label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Navigation item data class
class GlassNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const GlassNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

/// Floating app bar with glassmorphism
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBackButton;
  final VoidCallback? onBack;

  const GlassAppBar({
    super.key,
    this.title,
    this.leading,
    this.actions,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(80);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      padding: EdgeInsets.fromLTRB(
        AppBreakpoints.getScreenPadding(context) * 0.8,
        AppBreakpoints.responsive<double>(context, mobile: 16, tablet: 18, desktop: 20),
        AppBreakpoints.getScreenPadding(context) * 0.8,
        0,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppBreakpoints.responsive<double>(context, mobile: 20, tablet: 22, desktop: 24)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.glassBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.glassBorder,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                if (showBackButton)
                  IconButton(
                    onPressed: onBack ?? () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: AppColors.textPrimary,
                    ),
                  )
                else if (leading != null)
                  leading!,
                
                if (title != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title!,
                      style: AppTypography.headlineLarge,
                    ),
                  ),
                ] else
                  const Spacer(),
                
                if (actions != null) ...actions!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Floating action button with glassmorphism
class GlassFAB extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final Gradient? gradient;
  final bool showGlow;
  final String? label;

  const GlassFAB({
    super.key,
    required this.icon,
    required this.onPressed,
    this.gradient,
    this.showGlow = true,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveGradient = gradient ?? AppColors.primaryGradient;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        height: label != null ? 56 : 64,
        padding: label != null
            ? const EdgeInsets.symmetric(horizontal: 24, vertical: 16)
            : null,
        decoration: BoxDecoration(
          gradient: effectiveGradient,
          borderRadius: BorderRadius.circular(label != null ? 28 : 32),
          boxShadow: showGlow
              ? [
                  BoxShadow(
                    color: effectiveGradient.colors.first.withValues(alpha:0.4),
                    blurRadius: 30,
                    offset: const Offset(0, 10),
                  ),
                ]
              : null,
        ),
        child: label != null
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Text(
                    label!,
                    style: AppTypography.labelMedium.copyWith(
                      color: Colors.white,
                    ),
                  ),
                ],
              )
            : SizedBox(
                width: 64,
                height: 64,
                child: Icon(icon, color: Colors.white, size: 28),
              ),
      ),
    );
  }
}

/// Segmented control with glassmorphism
class GlassSegmentedControl extends StatelessWidget {
  final List<String> segments;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const GlassSegmentedControl({
    super.key,
    required this.segments,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.glassBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.glassBorder,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: List.generate(
              segments.length,
              (index) => Expanded(
                child: GestureDetector(
                  onTap: () => onChanged(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      gradient: selectedIndex == index
                          ? AppColors.primaryGradient
                          : null,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: selectedIndex == index
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha:0.3),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        segments[index],
                        style: AppTypography.labelMedium.copyWith(
                          color: selectedIndex == index
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight: selectedIndex == index
                              ? FontWeight.w600
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
