// 👥 Modern HR Manager Dashboard - Employee management and leave requests
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/core/theme/modern_design_system.dart';
import 'package:attendence/core/utils/logger.dart';
import 'package:attendence/presentation/providers/auth_provider.dart';
import 'package:attendence/presentation/providers/dashboard_provider.dart';

class ModernHRDashboard extends ConsumerStatefulWidget {
  const ModernHRDashboard({super.key});

  @override
  ConsumerState<ModernHRDashboard> createState() => _ModernHRDashboardState();
}

class _ModernHRDashboardState extends ConsumerState<ModernHRDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();

    // Fetch dashboard stats on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDashboardData();
    });
  }

  void _fetchDashboardData() {
    final profile = ref.read(currentUserProvider);
    if (profile?.companyId != null) {
      AppLogger.info('📊 HR Dashboard: Fetching stats for company: ${profile!.companyId}');
      ref.read(dashboardStatsProvider.notifier).fetchStats(companyId: profile.companyId!);
    } else {
      AppLogger.warning('⚠️ HR Dashboard: No company ID found for user');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(dashboardStatsProvider);
    final profile = ref.watch(currentUserProvider);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              ModernColors.teal.withOpacity(0.05),
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
                // App bar
                _buildSliverAppBar(profile),

                // Main content
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Loading or error state
                      if (dashboardState is DashboardStatsLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (dashboardState is DashboardStatsError)
                        _buildErrorWidget(dashboardState.message)
                      else if (dashboardState is DashboardStatsLoaded) ...[
                        // HR Quick Actions - including Check-In
                        _buildHRQuickActions(),

                        const SizedBox(height: 24),

                        // Leave Request Notifications (if any pending)
                        if (dashboardState.stats.pendingLeaveRequests > 0)
                          _buildLeaveNotifications(dashboardState.stats),

                        const SizedBox(height: 24),

                        // Key metrics
                        _buildKeyMetrics(dashboardState.stats),

                        const SizedBox(height: 24),

                        // Leave requests section
                        _buildLeaveRequests(dashboardState.stats),

                        const SizedBox(height: 24),

                        // Department overview
                        _buildDepartmentOverview(dashboardState.stats),

                        const SizedBox(height: 24),

                        // All Employee Attendance View
                        _buildAllEmployeeAttendance(dashboardState.stats),

                        const SizedBox(height: 24),

                        // Quick actions
                        _buildQuickActions(),

                        const SizedBox(height: 100),
                      ],
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

  Widget _buildSliverAppBar(profile) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'HR Dashboard',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      profile?.companyName ?? 'Employee Management',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.black87),
                    onPressed: _fetchDashboardData,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String message) {
    return GlassCard(
      margin: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: ModernColors.rose,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load dashboard',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _fetchDashboardData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyMetrics(stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.people_rounded,
                label: 'Total Employees',
                value: '${stats.totalEmployees}',
                gradient: ModernColors.oceanGradient,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.check_circle_rounded,
                label: 'Present Today',
                value: '${stats.presentToday}',
                gradient: ModernColors.successGradient,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.pending_actions,
                label: 'Leave Requests',
                value: '${stats.pendingLeaveRequests}',
                gradient: ModernColors.warningGradient,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.schedule,
                label: 'Late Today',
                value: '${stats.lateToday}',
                gradient: ModernColors.sunsetGradient,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required Gradient gradient,
  }) {
    return GradientCard(
      gradient: gradient,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 28),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequests(stats) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pending Leave Requests',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              ModernBadge(
                text: '${stats.pendingLeaveRequests}',
                gradient: ModernColors.warningGradient,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (stats.pendingLeaveRequests > 0)
            _buildLeaveRequestItem(
              name: 'Review pending requests',
              type: 'Multiple requests awaiting approval',
              color: ModernColors.amber,
            )
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No pending leave requests',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLeaveRequestItem({
    required String name,
    required String type,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.event_note, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  type,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDepartmentOverview(stats) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Department Attendance',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          if (stats.departments.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No department data available',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...stats.departments.map((dept) => _buildDepartmentItem(dept)),
        ],
      ),
    );
  }

  Widget _buildDepartmentItem(dept) {
    final percentage = dept.employeeCount > 0
        ? ((dept.presentToday / dept.employeeCount) * 100).toInt()
        : 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dept.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${dept.presentToday}/${dept.employeeCount} (${percentage}%)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: percentage >= 80
                      ? ModernColors.emerald
                      : percentage >= 60
                          ? ModernColors.amber
                          : ModernColors.rose,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GradientProgressBar(
            value: percentage / 100,
            height: 8,
            gradient: LinearGradient(
              colors: percentage >= 80
                  ? [ModernColors.emerald, ModernColors.emerald.withOpacity(0.6)]
                  : percentage >= 60
                      ? [ModernColors.amber, ModernColors.amber.withOpacity(0.6)]
                      : [ModernColors.rose, ModernColors.rose.withOpacity(0.6)],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildHRQuickActions() {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
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
                child: _buildHRActionButton(
                  icon: Icons.fingerprint,
                  label: 'My Check-In',
                  gradient: ModernColors.successGradient,
                  onTap: () {
                    // Navigate to check-in screen
                    Navigator.of(context).pushNamed('/checkin');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildHRActionButton(
                  icon: Icons.people_rounded,
                  label: 'Add Employee',
                  gradient: ModernColors.primaryGradient,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Navigate to Add Employee screen'),
                        backgroundColor: ModernColors.indigo,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHRActionButton({
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: ModernEffects.softShadow(color: ModernColors.indigo),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAllEmployeeAttendance(stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'All Employee Attendance',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Navigate to Full Attendance Report'),
                    backgroundColor: ModernColors.indigo,
                  ),
                );
              },
              icon: const Icon(Icons.open_in_new, size: 16),
              label: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (stats.recentCheckIns.isEmpty)
          GlassCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No attendance records today',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        else
          ...stats.recentCheckIns.map((activity) => _buildEmployeeAttendanceCard(activity)),
      ],
    );
  }

  Widget _buildEmployeeAttendanceCard(activity) {
    final timeAgo = _getTimeAgo(activity.checkIn);
    final statusColor = activity.status == 'on_time'
        ? ModernColors.emerald
        : activity.status == 'late'
            ? ModernColors.amber
            : ModernColors.blue;
    
    final statusText = activity.status == 'on_time' 
        ? 'On Time'
        : activity.status == 'late'
            ? 'Late'
            : 'Checked In';

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: activity.profilePictureUrl != null
                ? NetworkImage(activity.profilePictureUrl!)
                : null,
            child: activity.profilePictureUrl == null
                ? Icon(Icons.person, color: Colors.grey.shade600)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.profileName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                    const SizedBox(width: 4),
                    Text(
                      timeAgo,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveNotifications(stats) {
    return GestureDetector(
      onTap: () {
        // Navigate to leave requests screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigate to Leave Requests Management'),
            backgroundColor: ModernColors.amber,
          ),
        );
      },
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: ModernColors.warningGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: ModernEffects.softShadow(color: ModernColors.amber),
              ),
              child: const Icon(
                Icons.notifications_active,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${stats.pendingLeaveRequests} New Leave Requests',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Requires your approval',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: ModernColors.rose,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${stats.pendingLeaveRequests}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildQuickActions() {
    final actions = [
      _ActionItem(
        icon: Icons.person_add,
        label: 'Add Employee',
        color: ModernColors.blue,
      ),
      _ActionItem(
        icon: Icons.event_note,
        label: 'Leave Management',
        color: ModernColors.purple,
      ),
      _ActionItem(
        icon: Icons.assessment,
        label: 'Reports',
        color: ModernColors.emerald,
      ),
      _ActionItem(
        icon: Icons.settings,
        label: 'Settings',
        color: ModernColors.amber,
      ),
    ];

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
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            return _buildActionCard(actions[index]);
          },
        ),
      ],
    );
  }

  Widget _buildActionCard(_ActionItem action) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: action.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(action.icon, color: action.color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            action.label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final Color color;

  _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
  });
}
