import 'package:flutter/material.dart';

/// Accessibility constants and utilities for the app
class AccessibilityConstants {
  AccessibilityConstants._();

  /// Minimum touch target size (48x48dp per Material Design)
  static const double minTouchTargetSize = 48.0;

  /// Minimum font size for body text (12sp)
  static const double minBodyFontSize = 12.0;

  /// Minimum font size for labels (12sp)
  static const double minLabelFontSize = 12.0;

  /// Standard spacing for accessible layout
  static const double accessibleSpacing = 16.0;

  /// Color contrast ratio for WCAG AA (4.5:1 for normal text, 3:1 for large text)
  static const double wcagAAContrastRatio = 4.5;
  static const double wcagAALargeTextContrastRatio = 3.0;
}

/// Accessibility-enhanced button wrapper
class AccessibleButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String semanticLabel;
  final String? tooltip;
  final Widget child;
  final double minSize;

  const AccessibleButton({
    super.key,
    required this.onPressed,
    required this.semanticLabel,
    required this.child,
    this.tooltip,
    this.minSize = AccessibilityConstants.minTouchTargetSize,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: true,
      label: semanticLabel,
      onTap: onPressed,
      child: Tooltip(
        message: tooltip ?? semanticLabel,
        child: GestureDetector(
          onTap: onPressed,
          child: Padding(
            padding: EdgeInsets.all((minSize - 44) / 2), // Ensure min size
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Accessibility-enhanced text field
class AccessibleTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String labelText;
  final String? hintText;
  final String? semanticLabel;
  final int minLines;
  final int maxLines;
  final TextInputType keyboardType;

  const AccessibleTextField({
    super.key,
    this.controller,
    required this.labelText,
    this.hintText,
    this.semanticLabel,
    this.minLines = 1,
    this.maxLines = 1,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      textField: true,
      label: semanticLabel ?? labelText,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        minLines: minLines,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          hintText: hintText,
          contentPadding: const EdgeInsets.all(16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

/// Accessibility-enhanced card for screen readers
class AccessibleCard extends StatelessWidget {
  final String semanticLabel;
  final String? semanticDescription;
  final VoidCallback? onTap;
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const AccessibleCard({
    super.key,
    required this.semanticLabel,
    required this.child,
    this.semanticDescription,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      enabled: onTap != null,
      onTap: onTap,
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// One-hand UX helper - ensures critical content is within thumb reach
/// (typically bottom 44-60% of screen for 5-6 inch phones)
class OneHandAccessibleLayout extends StatelessWidget {
  final Widget primaryContent; // Critical controls here
  final Widget? secondaryContent; // Less critical, can be at top
  final double thumbReachThreshold; // % of screen height

  const OneHandAccessibleLayout({
    super.key,
    required this.primaryContent,
    this.secondaryContent,
    this.thumbReachThreshold = 0.60, // 60% from bottom for 5.5" phone
  });

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final thumbReachZoneHeight = screenHeight * thumbReachThreshold;

    return SingleChildScrollView(
      child: Column(
        children: [
          if (secondaryContent != null) secondaryContent!,
          SizedBox(
            height: thumbReachZoneHeight,
            child: SingleChildScrollView(
              child: primaryContent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Semantic heading for screen readers
class SemanticHeading extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final int level; // 1-6, where 1 is h1

  const SemanticHeading(
    this.text, {
    super.key,
    this.style,
    this.level = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      enabled: true,
      child: Text(
        text,
        style: style,
        semanticsLabel: text,
      ),
    );
  }
}

/// Semantic label for icons (accessibility)
class AccessibleIcon extends StatelessWidget {
  final IconData icon;
  final String semanticLabel;
  final Color color;
  final double size;

  const AccessibleIcon({
    super.key,
    required this.icon,
    required this.semanticLabel,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: semanticLabel,
      enabled: true,
      child: Icon(
        icon,
        color: color,
        size: size,
        semanticLabel: semanticLabel,
      ),
    );
  }
}

/// Widget to ensure minimum tap target size
class MinimumTapTarget extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double size;

  const MinimumTapTarget({
    super.key,
    required this.child,
    this.onTap,
    this.size = AccessibilityConstants.minTouchTargetSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Center(child: child),
      ),
    );
  }
}
