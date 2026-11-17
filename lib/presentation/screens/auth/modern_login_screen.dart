// 🔐 Modern Login Screen - Premium authentication experience
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/core/theme/modern_design_system.dart';
import 'package:attendence/core/services/biometric_service.dart';
import 'package:attendence/presentation/providers/auth_provider.dart';
import 'dart:ui';

class ModernLoginScreen extends ConsumerStatefulWidget {
  const ModernLoginScreen({super.key});

  @override
  ConsumerState<ModernLoginScreen> createState() => _ModernLoginScreenState();
}

class _ModernLoginScreenState extends ConsumerState<ModernLoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _rememberMe = false;
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Wait for state update
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // Check if login was successful
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        // Don't manually navigate - AuthGate will handle routing based on role
        // The AuthGate in main.dart listens to authProvider and routes automatically
      } else if (authState is AuthError) {
        _showErrorSnackBar(authState.message);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar(e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleBiometricLogin() async {
    final biometricService = BiometricService();
    
    try {
      final hasHardware = await biometricService.hasBiometricHardware();

      if (!hasHardware) {
        _showErrorSnackBar('Biometric authentication not available');
        return;
      }

      final result = await biometricService.authenticate(
        reason: 'Authenticate to login',
      );

      if (result.success && mounted) {
        // Load saved credentials and login
        // This is a simplified version - implement secure storage retrieval
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (result.errorMessage != null) {
        _showErrorSnackBar(result.errorMessage!);
      }
    } catch (e) {
      _showErrorSnackBar('Biometric authentication failed');
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ModernColors.rose,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: const BoxDecoration(
          gradient: ModernColors.oceanGradient,
        ),
        child: Stack(
          children: [
            // Animated background
            _buildAnimatedBackground(),
            
            // Main content
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 60),
                        
                        // Welcome text
                        _buildWelcomeSection(),
                        
                        const SizedBox(height: 50),
                        
                        // Login form
                        _buildLoginForm(),
                        
                        const SizedBox(height: 24),
                        
                        // Remember me and forgot password
                        _buildOptionsRow(),
                        
                        const SizedBox(height: 32),
                        
                        // Login button
                        _buildLoginButton(),
                        
                        const SizedBox(height: 24),
                        
                        // Divider with "OR"
                        _buildDivider(),
                        
                        const SizedBox(height: 24),
                        
                        // Biometric login
                        _buildBiometricButton(),
                        
                        const SizedBox(height: 32),
                        
                        // Sign up link
                        _buildSignUpLink(),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
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
          Positioned(
            bottom: -150,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.white.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome Back!',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Sign in to continue',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Email field
          _buildEmailField(),
          
          const SizedBox(height: 20),
          
          // Password field
          _buildPasswordField(),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Email Address',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(
            Icons.email_outlined,
            color: Colors.white.withOpacity(0.8),
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your email';
          }
          if (!value.contains('@')) {
            return 'Please enter a valid email';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildPasswordField() {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Password',
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Colors.white.withOpacity(0.8),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.white.withOpacity(0.8),
            ),
            onPressed: () {
              setState(() => _obscurePassword = !_obscurePassword);
            },
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter your password';
          }
          if (value.length < 6) {
            return 'Password must be at least 6 characters';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildOptionsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            AnimatedToggle(
              value: _rememberMe,
              onChanged: (value) {
                setState(() => _rememberMe = value);
              },
              width: 48,
              height: 26,
              activeGradient: const LinearGradient(
                colors: [Colors.white, Color(0xFFE0E0E0)],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Remember me',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        TextButton(
          onPressed: () {
            // Navigate to forgot password
          },
          child: Text(
            'Forgot Password?',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton() {
    return AnimatedGradientButton(
      text: 'Sign In',
      onPressed: _handleLogin,
      gradient: const LinearGradient(
        colors: [Colors.white, Color(0xFFE0E0E0)],
      ),
      width: double.infinity,
      height: 60,
      isLoading: _isLoading,
      borderRadius: BorderRadius.circular(20),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildBiometricButton() {
    return GlassCard(
      onTap: _handleBiometricLogin,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.fingerprint_rounded,
            color: Colors.white.withOpacity(0.9),
            size: 28,
          ),
          const SizedBox(width: 12),
          Text(
            'Sign in with Biometric',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pushNamed('/signup');
            },
            child: const Text(
              'Sign Up',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
