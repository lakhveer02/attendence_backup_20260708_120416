// 📊 Modern Admin Dashboard - Executive analytics with beautiful charts
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/core/theme/modern_design_system.dart';
import 'package:attendence/core/utils/logger.dart';
import 'package:attendence/presentation/providers/auth_provider.dart';
import 'package:attendence/presentation/providers/dashboard_provider.dart';
import 'package:fl_chart/fl_chart.dart';

// Import new screens
import 'package:attendence/presentation/screens/employees/employee_list_screen.dart';
import 'package:attendence/presentation/screens/leave/leave_management_screen.dart';
import 'package:attendence/presentation/screens/attendance/attendance_history_screen.dart';
import 'package:attendence/presentation/screens/settings/settings_screen.dart';

class ModernAdminDashboard extends ConsumerStatefulWidget {
  const ModernAdminDashboard({super.key});

  @override
  ConsumerState<ModernAdminDashboard> createState() => _ModernAdminDashboardState();
}

class _ModernAdminDashboardState extends ConsumerState<ModernAdminDashboard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  int _selectedPeriod = 0; // 0: Week, 1: Month, 2: Year

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
      AppLogger.info('📊 Admin Dashboard: Fetching stats for company: ${profile!.companyId}');
      ref.read(dashboardStatsProvider.notifier).fetchStats(companyId: profile.companyId!);
    } else {
      AppLogger.warning('⚠️ Admin Dashboard: No company ID found for user');
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
              ModernColors.purple.withOpacity(0.05),
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
                        // Admin Actions - Create Employee
                        _buildAdminActions(),

                        const SizedBox(height: 24),

                        // Leave Request Notifications (if any pending)
                        if (dashboardState.stats.pendingLeaveRequests > 0)
                          _buildLeaveNotifications(dashboardState.stats),

                        const SizedBox(height: 24),

                        // Period selector
                        _buildPeriodSelector(),

                        const SizedBox(height: 24),

                        // Key metrics
                        _buildKeyMetrics(dashboardState.stats),

                        const SizedBox(height: 24),

                        // Attendance chart
                        _buildAttendanceChart(dashboardState.stats),

                        const SizedBox(height: 24),

                        // Department breakdown
                        _buildDepartmentBreakdown(dashboardState.stats),

                        const SizedBox(height: 24),

                        // Recent activities
                        _buildRecentActivities(dashboardState.stats),

                        const SizedBox(height: 24),

                        // Team performance
                        _buildTeamPerformance(dashboardState.stats),

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
                      'Dashboard',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      profile?.companyName ?? 'Track team performance',
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
          const Text(
            'Failed to load dashboard',
            style: TextStyle(
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

  Widget _buildPeriodSelector() {
    final periods = ['Week', 'Month', 'Year'];

    return Row(
      children: List.generate(periods.length, (index) {
        final isSelected = _selectedPeriod == index;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _selectedPeriod = index);
            },
            child: AnimatedContainer(
              duration: ModernAnimations.normal,
              margin: EdgeInsets.only(
                right: index < periods.length - 1 ? 12 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: isSelected ? ModernColors.primaryGradient : null,
                color: isSelected ? null : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? ModernEffects.glowEffect(color: ModernColors.indigo)
                    : null,
              ),
              child: Text(
                periods[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildKeyMetrics(stats) {
    final attendanceRate = stats.totalEmployees > 0
        ? ((stats.presentToday / stats.totalEmployees) * 100).toInt()
        : 0;

    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            icon: Icons.people_rounded,
            label: 'Total Staff',
            value: '${stats.totalEmployees}',
            change: stats.totalEmployees > 0 ? '+${stats.totalEmployees}' : '0',
            isPositive: true,
            gradient: ModernColors.oceanGradient,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            icon: Icons.check_circle_rounded,
            label: 'Present Today',
            value: '${stats.presentToday}',
            change: '$attendanceRate%',
            isPositive: attendanceRate >= 80,
            gradient: ModernColors.successGradient,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String change,
    required bool isPositive,
    required Gradient gradient,
  }) {
    return GradientCard(
      gradient: gradient,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 32),
          const SizedBox(height: 16),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      change,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceChart(stats) {
    // Calculate weekly attendance trend (simplified - using attendance rate)
    final rate = stats.attendanceRateToday.toDouble();
    
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Flexible(
                child: Text(
                  'Attendance Trend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildLegendItem('Present', ModernColors.emerald),
                  const SizedBox(width: 16),
                  _buildLegendItem('Absent', ModernColors.rose),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: Colors.grey.shade200,
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 20,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 10,
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                        if (value.toInt() >= 0 && value.toInt() < days.length) {
                          return Text(
                            days[value.toInt()],
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 10,
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: 100,
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      FlSpot(0, rate),
                      FlSpot(1, rate - 3),
                      FlSpot(2, rate + 2),
                      FlSpot(3, rate - 1),
                      FlSpot(4, rate + 4),
                      FlSpot(5, rate + 1),
                      FlSpot(6, rate),
                    ],
                    isCurved: true,
                    gradient: ModernColors.successGradient,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          ModernColors.emerald.withOpacity(0.3),
                          ModernColors.emerald.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade700,
          ),
        ),
      ],
    );
  }

  Widget _buildDepartmentBreakdown(stats) {
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
            ...stats.departments.map((dept) {
              final percentage = dept.employeeCount > 0
                  ? ((dept.presentToday / dept.employeeCount) * 100).toInt()
                  : 0;
              final color = percentage >= 80
                  ? ModernColors.emerald
                  : percentage >= 60
                      ? ModernColors.amber
                      : ModernColors.rose;
              return _buildDepartmentItem(
                _Department(dept.name, percentage, color),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildDepartmentItem(_Department dept) {
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
                '${dept.percentage}%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: dept.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GradientProgressBar(
            value: dept.percentage / 100,
            height: 8,
            gradient: LinearGradient(
              colors: [dept.color, dept.color.withOpacity(0.6)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities(stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Activities',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            TextButton(
              onPressed: () {},
              child: const Text('View All'),
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
                  'No recent activities',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        else
          ...stats.recentCheckIns.take(4).map((activity) {
            final timeAgo = _getTimeAgo(activity.checkIn);
            final statusColor = activity.status == 'on_time'
                ? ModernColors.emerald
                : activity.status == 'late'
                    ? ModernColors.amber
                    : ModernColors.blue;
            return _buildActivityItem(
              _Activity(
                '${activity.profileName} checked in',
                timeAgo,
                Icons.login,
                statusColor,
              ),
            );
          }),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    }
  }

  Widget _buildAdminActions() {
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
                child: _buildActionButton(
                  icon: Icons.people_rounded,
                  label: 'Employees',
                  gradient: ModernColors.successGradient,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const EmployeeListScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.event_available_rounded,
                  label: 'Leave Approvals',
                  gradient: ModernColors.primaryGradient,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LeaveManagementScreen(isAdmin: true),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  icon: Icons.history_rounded,
                  label: 'Attendance',
                  gradient: ModernColors.warningGradient,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const AttendanceHistoryScreen()),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  gradient: ModernColors.dangerGradient,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const SettingsScreen()),
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

  Widget _buildActionButton({
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
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaveNotifications(stats) {
    return GestureDetector(
      onTap: () {
        // Navigate to leave requests screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Navigate to Leave Requests screen'),
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
                    '${stats.pendingLeaveRequests} Pending Leave Requests',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to review and approve',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(_Activity activity) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              activity.icon,
              color: activity.color,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  activity.time,
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

  Widget _buildTeamPerformance(stats) {
    // Filter recent check-ins to show top performers (those with on_time status)
    final topPerformers = stats.recentCheckIns
        .where((activity) => activity.status == 'on_time')
        .take(3)
        .toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Top Performers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          if (topPerformers.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No performance data available',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            )
          else
            ...topPerformers.asMap().entries.map((entry) {
              final index = entry.key;
              final activity = entry.value;
              return _buildTeamMemberItem(
                _TeamMember(
                  activity.profileName,
                  'Employee',
                  (100 - (index * 5)).toInt(), // Simple scoring
                  activity.profilePictureUrl ?? 'https://i.pravatar.cc/150?img=${index + 1}',
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTeamMemberItem(_TeamMember member) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: ModernColors.successGradient,
              boxShadow: ModernEffects.softShadow(color: ModernColors.emerald),
            ),
            padding: const EdgeInsets.all(2),
            child: CircleAvatar(
              radius: 24,
              backgroundColor: Colors.white,
              backgroundImage: NetworkImage(member.avatar),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  member.department,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          ModernBadge(
            text: '${member.score}%',
            gradient: ModernColors.successGradient,
          ),
        ],
      ),
    );
  }
}

class _Department {
  final String name;
  final int percentage;
  final Color color;

  _Department(this.name, this.percentage, this.color);
}

class _Activity {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  _Activity(this.title, this.time, this.icon, this.color);
}

class _TeamMember {
  final String name;
  final String department;
  final int score;
  final String avatar;

  _TeamMember(this.name, this.department, this.score, this.avatar);
}
