// 🌟 Modern Splash Screen - Premium animated entry experience
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/core/theme/modern_design_system.dart';
import 'package:attendence/presentation/providers/auth_provider.dart';
import 'dart:math' as math;

class ModernSplashScreen extends ConsumerStatefulWidget {
  const ModernSplashScreen({super.key});

  @override
  ConsumerState<ModernSplashScreen> createState() => _ModernSplashScreenState();
}

class _ModernSplashScreenState extends ConsumerState<ModernSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _checkAuthAndNavigate();
  }

  void _initializeAnimations() {
    // Fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    // Scale animation with bounce
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleController,
        curve: Curves.elasticOut,
      ),
    );

    // Rotation animation
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    _rotationAnimation = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      _rotationController,
    );

    // Start animations
    _fadeController.forward();
    _scaleController.forward();
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2500));
    
    if (!mounted) return;
    
    // Check auth state from provider
    final authState = ref.read(authProvider);
    
    // Navigate based on auth state
    if (authState is AuthAuthenticated) {
      _navigateToHome();
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacementNamed('/home');
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: ModernColors.primaryGradient,
        ),
        child: Stack(
          children: [
            // Animated background circles
            _buildAnimatedBackground(),
            
            // Main content
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // App logo with glass effect
                      _buildLogoSection(),
                      
                      const SizedBox(height: 40),
                      
                      // App name with gradient
                      _buildAppNameSection(),
                      
                      const SizedBox(height: 16),
                      
                      // Tagline
                      _buildTaglineSection(),
                      
                      const SizedBox(height: 60),
                      
                      // Loading indicator
                      _buildLoadingIndicator(),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom version info
            _buildVersionInfo(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _rotationController,
      builder: (context, child) {
        return Stack(
          children: [
            Positioned(
              top: -100,
              right: -100,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -150,
              child: Transform.rotate(
                angle: -_rotationAnimation.value,
                child: Container(
                  width: 400,
                  height: 400,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withOpacity(0.08),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLogoSection() {
    return GlassCard(
      padding: const EdgeInsets.all(32),
      borderRadius: BorderRadius.circular(40),
      boxShadow: ModernEffects.glowEffect(color: Colors.white),
      child: const Icon(
        Icons.fingerprint_rounded,
        size: 100,
        color: Colors.white,
      ),
    );
  }

  Widget _buildAppNameSection() {
    return ShaderMask(
      shaderCallback: (bounds) => const LinearGradient(
        colors: [Colors.white, Color(0xFFE0E0E0)],
      ).createShader(bounds),
      child: const Text(
        'SquadMinds',
        style: TextStyle(
          fontSize: 42,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          letterSpacing: -1,
        ),
      ),
    );
  }

  Widget _buildTaglineSection() {
    return Text(
      'Smart Attendance System',
      style: TextStyle(
        fontSize: 16,
        color: Colors.white.withOpacity(0.9),
        fontWeight: FontWeight.w500,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 40,
      height: 40,
      child: CircularProgressIndicator(
        strokeWidth: 3,
        valueColor: AlwaysStoppedAnimation<Color>(
          Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildVersionInfo() {
    return Positioned(
      bottom: 40,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          'Version 1.0.0',
          style: TextStyle(
            color: Colors.white.withOpacity(0.7),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
