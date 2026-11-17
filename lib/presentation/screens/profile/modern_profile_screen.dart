// 👤 Modern Profile Screen - Beautiful user profile with settings
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/core/theme/modern_design_system.dart';

class ModernProfileScreen extends ConsumerStatefulWidget {
  const ModernProfileScreen({super.key});

  @override
  ConsumerState<ModernProfileScreen> createState() => _ModernProfileScreenState();
}

class _ModernProfileScreenState extends ConsumerState<ModernProfileScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _notificationsEnabled = true;
  bool _biometricsEnabled = true;

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
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ModernColors.indigo.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Profile header
                _buildProfileHeader(),

                // Content
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Stats cards
                      _buildStatsCards(),

                      const SizedBox(height: 24),

                      // Quick actions
                      _buildQuickActions(),

                      const SizedBox(height: 24),

                      // Settings section
                      _buildSettingsSection(),

                      const SizedBox(height: 24),

                      // Account section
                      _buildAccountSection(),

                      const SizedBox(height: 24),

                      // Logout button
                      _buildLogoutButton(),

                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return SliverToBoxAdapter(
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Avatar with gradient border
              Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: ModernColors.primaryGradient,
                      boxShadow: ModernEffects.glowEffect(
                        color: ModernColors.indigo,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.white,
                      child: ClipOval(
                        child: Image.network(
                          'https://i.pravatar.cc/150?img=12',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.person, size: 60);
                          },
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: GestureDetector(
                      onTap: () {
                        // Edit profile picture
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: ModernColors.primaryGradient,
                          shape: BoxShape.circle,
                          boxShadow: ModernEffects.softShadow(),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Name
              const Text(
                'John Doe',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 4),

              // Email
              Text(
                'john.doe@company.com',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 8),

              // Role badge
              ModernBadge(
                text: 'Senior Developer',
                gradient: ModernColors.primaryGradient,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: ModernColors.indigo,
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  '22',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Days Present',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                const Icon(
                  Icons.access_time_rounded,
                  color: ModernColors.purple,
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  '176h',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Total Hours',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            child: Column(
              children: [
                const Icon(
                  Icons.wb_sunny_outlined,
                  color: ModernColors.amber,
                  size: 32,
                ),
                const SizedBox(height: 12),
                const Text(
                  '8',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  'Leave Balance',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                icon: Icons.person_outline,
                label: 'Edit Profile',
                gradient: ModernColors.oceanGradient,
                onTap: () {},
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                icon: Icons.history,
                label: 'History',
                gradient: ModernColors.successGradient,
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GradientCard(
        gradient: gradient,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildSettingItem(
                icon: Icons.notifications_outlined,
                title: 'Notifications',
                subtitle: 'Receive push notifications',
                trailing: AnimatedToggle(
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() => _notificationsEnabled = value);
                  },
                ),
              ),
              const Divider(height: 1),
              _buildSettingItem(
                icon: Icons.fingerprint_rounded,
                title: 'Biometric Login',
                subtitle: 'Use fingerprint or face ID',
                trailing: AnimatedToggle(
                  value: _biometricsEnabled,
                  onChanged: (value) {
                    setState(() => _biometricsEnabled = value);
                  },
                ),
              ),
              const Divider(height: 1),
              _buildSettingItem(
                icon: Icons.language_rounded,
                title: 'Language',
                subtitle: 'English (US)',
                trailing: Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
                onTap: () {},
              ),
              const Divider(height: 1),
              _buildSettingItem(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'System default',
                trailing: Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _buildSettingItem(
                icon: Icons.lock_outline,
                title: 'Change Password',
                subtitle: 'Update your password',
                trailing: Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
                onTap: () {},
              ),
              const Divider(height: 1),
              _buildSettingItem(
                icon: Icons.shield_outlined,
                title: 'Privacy',
                subtitle: 'Manage your privacy settings',
                trailing: Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
                onTap: () {},
              ),
              const Divider(height: 1),
              _buildSettingItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                subtitle: 'Get help or contact support',
                trailing: Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
                onTap: () {},
              ),
              const Divider(height: 1),
              _buildSettingItem(
                icon: Icons.info_outline,
                title: 'About',
                subtitle: 'Version 1.0.0',
                trailing: Icon(
                  Icons.chevron_right,
                  color: Colors.grey.shade400,
                ),
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: ModernColors.indigo.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: ModernColors.indigo,
          size: 24,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey.shade600,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }

  Widget _buildLogoutButton() {
    return AnimatedGradientButton(
      text: 'Logout',
      onPressed: () {
        _showLogoutDialog();
      },
      gradient: const LinearGradient(
        colors: [ModernColors.rose, Color(0xFFDC2626)],
      ),
      width: double.infinity,
      height: 56,
      icon: Icons.logout_rounded,
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: GlassCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: ModernColors.rose.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  size: 48,
                  color: ModernColors.rose,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Logout',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to logout?',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        backgroundColor: Colors.grey.shade100,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AnimatedGradientButton(
                      text: 'Logout',
                      onPressed: () {
                        Navigator.of(context).pop();
                        // Perform logout
                      },
                      gradient: const LinearGradient(
                        colors: [ModernColors.rose, Color(0xFFDC2626)],
                      ),
                      height: 48,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
