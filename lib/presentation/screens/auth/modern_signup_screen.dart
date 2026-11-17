// 📝 Modern Signup Screen - Beautiful registration with company setup
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/core/theme/modern_design_system.dart';
import 'package:attendence/presentation/providers/auth_provider.dart';

class ModernSignupScreen extends ConsumerStatefulWidget {
  const ModernSignupScreen({super.key});

  @override
  ConsumerState<ModernSignupScreen> createState() => _ModernSignupScreenState();
}

class _ModernSignupScreenState extends ConsumerState<ModernSignupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyNameController = TextEditingController();
  
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _createCompany = false;
  String _selectedRole = 'employee';
  
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
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _companyNameController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ref.read(authProvider.notifier).signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        fullName: _nameController.text.trim(),
        role: _selectedRole,
        phoneNumber: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() 
            : null,
        createCompany: _createCompany,
        companyName: _createCompany ? _companyNameController.text.trim() : null,
      );

      // Wait for state update
      await Future.delayed(const Duration(milliseconds: 100));

      if (!mounted) return;

      // Check if signup was successful
      final authState = ref.read(authProvider);
      if (authState is AuthAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
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
          gradient: ModernColors.primaryGradient,
        ),
        child: Stack(
          children: [
            // Animated background
            _buildAnimatedBackground(),
            
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Back button
                  _buildBackButton(),
                  
                  // Scrollable form
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Welcome text
                              _buildWelcomeSection(),
                              
                              const SizedBox(height: 40),
                              
                              // Signup form
                              _buildSignupForm(),
                              
                              const SizedBox(height: 32),
                              
                              // Signup button
                              if (!_isLoading) _buildSignupButton(),
                              
                              // Loading indicator
                              if (_isLoading) _buildLoadingIndicator(),
                              
                              const SizedBox(height: 24),
                              
                              // Login link
                              _buildLoginLink(),
                              
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

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Align(
        alignment: Alignment.centerLeft,
        child: GlassCard(
          padding: const EdgeInsets.all(12),
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Create Account',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Join SquadMinds today',
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(0.8),
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          // Full Name
          _buildTextField(
            controller: _nameController,
            label: 'Full Name',
            icon: Icons.person_outline,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your name';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Email
          _buildTextField(
            controller: _emailController,
            label: 'Email Address',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
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
          
          const SizedBox(height: 16),
          
          // Phone (optional)
          _buildTextField(
            controller: _phoneController,
            label: 'Phone Number (Optional)',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          
          const SizedBox(height: 16),
          
          // Role Selector
          _buildRoleSelector(),
          
          const SizedBox(height: 16),
          
          // Company creation option
          if (_selectedRole == 'company_admin') _buildCompanyToggle(),
          
          // Company name field
          if (_createCompany && _selectedRole == 'company_admin') ...[
            const SizedBox(height: 16),
            _buildTextField(
              controller: _companyNameController,
              label: 'Company Name',
              icon: Icons.business_outlined,
              validator: (value) {
                if (_createCompany && (value == null || value.isEmpty)) {
                  return 'Please enter company name';
                }
                return null;
              },
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Password
          _buildPasswordField(
            controller: _passwordController,
            label: 'Password',
            obscure: _obscurePassword,
            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a password';
              }
              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }
              return null;
            },
          ),
          
          const SizedBox(height: 16),
          
          // Confirm Password
          _buildPasswordField(
            controller: _confirmPasswordController,
            label: 'Confirm Password',
            obscure: _obscureConfirmPassword,
            onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.8)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.6)),
          prefixIcon: Icon(
            Icons.lock_outline,
            color: Colors.white.withOpacity(0.8),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              obscure ? Icons.visibility_off : Icons.visibility,
              color: Colors.white.withOpacity(0.8),
            ),
            onPressed: onToggle,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
        ),
        validator: validator,
      ),
    );
  }

  Widget _buildRoleSelector() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Role',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildRoleChip('Employee', 'employee'),
              _buildRoleChip('Manager', 'manager'),
              _buildRoleChip('HR Manager', 'hr_manager'),
              _buildRoleChip('Company Admin', 'company_admin'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(String label, String value) {
    final isSelected = _selectedRole == value;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedRole = value;
          if (value != 'company_admin') {
            _createCompany = false;
          }
        });
      },
      child: AnimatedContainer(
        duration: ModernAnimations.normal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? const LinearGradient(
            colors: [Colors.white, Color(0xFFE0E0E0)],
          ) : null,
          color: isSelected ? null : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.white.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? ModernColors.indigo : Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyToggle() {
    return GlassCard(
      onTap: () {
        setState(() => _createCompany = !_createCompany);
      },
      child: Row(
        children: [
          Icon(
            Icons.business_outlined,
            color: Colors.white.withOpacity(0.9),
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create New Company',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Register your company',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          AnimatedToggle(
            value: _createCompany,
            onChanged: (value) {
              setState(() => _createCompany = value);
            },
            activeGradient: const LinearGradient(
              colors: [Colors.white, Color(0xFFE0E0E0)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupButton() {
    return AnimatedGradientButton(
      text: 'Create Account',
      onPressed: _handleSignup,
      gradient: const LinearGradient(
        colors: [Colors.white, Color(0xFFE0E0E0)],
      ),
      width: double.infinity,
      height: 60,
      icon: Icons.person_add_rounded,
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Creating your account...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 14,
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'Sign In',
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
