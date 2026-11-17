import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/core/theme/modern_design_system.dart';
import 'package:attendence/presentation/providers/auth_provider.dart';

/// Settings Screen - App preferences and account management
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _faceRecognitionEnabled = true;
  bool _biometricLoginEnabled = false;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ModernColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: ModernColors.indigo,
        elevation: 0,
      ),
      body: ListView(
        children: [
          _buildSection(
            'Account',
            [
              _buildProfileTile(),
              _buildListTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () => _showChangePasswordDialog(),
              ),
              _buildListTile(
                icon: Icons.email_outlined,
                title: 'Change Email',
                onTap: () => _showChangeEmailDialog(),
              ),
            ],
          ),
          _buildSection(
            'Preferences',
            [
              _buildSwitchTile(
                icon: Icons.notifications_outlined,
                title: 'Push Notifications',
                subtitle: 'Receive attendance reminders',
                value: _notificationsEnabled,
                onChanged: (value) {
                  setState(() => _notificationsEnabled = value);
                },
              ),
              _buildSwitchTile(
                icon: Icons.face,
                title: 'Face Recognition',
                subtitle: 'Use face for attendance',
                value: _faceRecognitionEnabled,
                onChanged: (value) {
                  setState(() => _faceRecognitionEnabled = value);
                },
              ),
              _buildSwitchTile(
                icon: Icons.fingerprint,
                title: 'Biometric Login',
                subtitle: 'Use fingerprint/face to login',
                value: _biometricLoginEnabled,
                onChanged: (value) {
                  setState(() => _biometricLoginEnabled = value);
                },
              ),
              _buildSwitchTile(
                icon: Icons.dark_mode_outlined,
                title: 'Dark Mode',
                subtitle: 'Use dark theme',
                value: _darkModeEnabled,
                onChanged: (value) {
                  setState(() => _darkModeEnabled = value);
                },
              ),
            ],
          ),
          _buildSection(
            'App Info',
            [
              _buildListTile(
                icon: Icons.info_outline,
                title: 'About',
                trailing: const Text('v1.0.0', style: TextStyle(color: Colors.grey)),
                onTap: () => _showAboutDialog(),
              ),
              _buildListTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                onTap: () {},
              ),
              _buildListTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                onTap: () {},
              ),
              _buildListTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {},
              ),
            ],
          ),
          _buildSection(
            'Danger Zone',
            [
              _buildListTile(
                icon: Icons.logout,
                title: 'Logout',
                titleColor: ModernColors.rose,
                onTap: () => _logout(),
              ),
              _buildListTile(
                icon: Icons.delete_forever,
                title: 'Delete Account',
                titleColor: ModernColors.rose,
                onTap: () => _showDeleteAccountDialog(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: ModernEffects.softShadow(),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildProfileTile() {
    final user = ref.watch(currentUserProvider);
    
    return ListTile(
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: ModernColors.indigo.withOpacity(0.1),
        child: Text(
          user?.fullName[0].toUpperCase() ?? 'U',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ModernColors.indigo,
          ),
        ),
      ),
      title: Text(
        user?.fullName ?? 'User',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(user?.email ?? ''),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        Navigator.pushNamed(context, '/profile');
      },
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    Color? titleColor,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: titleColor ?? ModernColors.indigo),
      title: Text(
        title,
        style: TextStyle(
          color: titleColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing: trailing ?? const Icon(Icons.chevron_right, size: 20),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      secondary: Icon(icon, color: ModernColors.indigo),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: subtitle != null ? Text(subtitle) : null,
      value: value,
      onChanged: onChanged,
      activeColor: ModernColors.emerald,
    );
  }

  void _showChangePasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Password changed successfully')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showChangeEmailDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Email'),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'New Email',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email changed successfully')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'Attendance Management',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: ModernColors.indigo,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.work,
          color: Colors.white,
          size: 32,
        ),
      ),
      children: [
        const SizedBox(height: 16),
        const Text('Modern attendance management system with face recognition and real-time tracking.'),
      ],
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement account deletion
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernColors.rose,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ref.read(authProvider.notifier).signOut();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ModernColors.rose,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
