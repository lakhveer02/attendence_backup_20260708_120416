// 🎬 Modern Page Transitions - Beautiful route animations
import 'package:flutter/material.dart';

/// Fade transition
class FadePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  FadePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: animation,
              child: child,
            );
          },
        );
}

/// Slide from right transition
class SlideRightPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideRightPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

/// Slide from bottom transition
class SlideUpPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  SlideUpPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0);
            const end = Offset.zero;
            const curve = Curves.easeOutCubic;

            var tween = Tween(begin: begin, end: end).chain(
              CurveTween(curve: curve),
            );

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        );
}

/// Scale transition
class ScalePageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  ScalePageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 400),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeOutCubic;

            var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            return ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// Rotation transition
class RotationPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  RotationPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 500),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOut;

            var rotationTween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            var scaleTween = Tween(begin: 0.8, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            return RotationTransition(
              turns: animation.drive(rotationTween),
              child: ScaleTransition(
                scale: animation.drive(scaleTween),
                child: child,
              ),
            );
          },
        );
}

/// Shared axis transition (Material Design)
class SharedAxisPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;
  final SharedAxisTransitionType transitionType;

  SharedAxisPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
    this.transitionType = SharedAxisTransitionType.scaled,
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return _buildSharedAxisTransition(
              animation,
              secondaryAnimation,
              child,
              transitionType,
            );
          },
        );

  static Widget _buildSharedAxisTransition(
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
    SharedAxisTransitionType transitionType,
  ) {
    switch (transitionType) {
      case SharedAxisTransitionType.horizontal:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.3, 0.0),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      case SharedAxisTransitionType.vertical:
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.3),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      case SharedAxisTransitionType.scaled:
        return ScaleTransition(
          scale: Tween<double>(begin: 0.8, end: 1.0).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          ),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
    }
  }
}

enum SharedAxisTransitionType {
  horizontal,
  vertical,
  scaled,
}

/// Hero-style fade through transition
class FadeThroughPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  FadeThroughPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          reverseTransitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                ),
              ),
              child: FadeTransition(
                opacity: Tween<double>(begin: 1.0, end: 0.0).animate(
                  CurvedAnimation(
                    parent: secondaryAnimation,
                    curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
                  ),
                ),
                child: child,
              ),
            );
          },
        );
}

/// Custom elastic transition
class ElasticPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  ElasticPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 800),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.elasticOut;

            var scaleTween = Tween(begin: 0.5, end: 1.0).chain(
              CurveTween(curve: curve),
            );

            var fadeTween = Tween(begin: 0.0, end: 1.0).chain(
              CurveTween(curve: Curves.easeOut),
            );

            return ScaleTransition(
              scale: animation.drive(scaleTween),
              child: FadeTransition(
                opacity: animation.drive(fadeTween),
                child: child,
              ),
            );
          },
        );
}

/// Zoom transition
class ZoomPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;
  final Duration duration;

  ZoomPageRoute({
    required this.page,
    this.duration = const Duration(milliseconds: 300),
  }) : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: duration,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return ScaleTransition(
              scale: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: Curves.fastOutSlowIn,
                ),
              ),
              child: child,
            );
          },
        );
}

/// Helper extension for easy navigation with transitions
extension NavigationExtension on BuildContext {
  Future<T?> pushWithFade<T>(Widget page) {
    return Navigator.of(this).push<T>(FadePageRoute(page: page));
  }

  Future<T?> pushWithSlideRight<T>(Widget page) {
    return Navigator.of(this).push<T>(SlideRightPageRoute(page: page));
  }

  Future<T?> pushWithSlideUp<T>(Widget page) {
    return Navigator.of(this).push<T>(SlideUpPageRoute(page: page));
  }

  Future<T?> pushWithScale<T>(Widget page) {
    return Navigator.of(this).push<T>(ScalePageRoute(page: page));
  }

  Future<T?> pushWithSharedAxis<T>(Widget page, {SharedAxisTransitionType? type}) {
    return Navigator.of(this).push<T>(
      SharedAxisPageRoute(
        page: page,
        transitionType: type ?? SharedAxisTransitionType.scaled,
      ),
    );
  }
}
