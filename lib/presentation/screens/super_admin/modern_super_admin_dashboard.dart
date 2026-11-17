// 🔐 Modern Super Admin Dashboard - System-wide management and analytics
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/core/theme/modern_design_system.dart';
import 'package:attendence/core/utils/logger.dart';
import 'package:attendence/presentation/providers/auth_provider.dart';
import 'package:attendence/presentation/providers/dashboard_provider.dart';

class ModernSuperAdminDashboard extends ConsumerStatefulWidget {
  const ModernSuperAdminDashboard({super.key});

  @override
  ConsumerState<ModernSuperAdminDashboard> createState() => _ModernSuperAdminDashboardState();
}

class _ModernSuperAdminDashboardState extends ConsumerState<ModernSuperAdminDashboard>
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

    // Fetch super admin stats on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchDashboardData();
    });
  }

  void _fetchDashboardData() {
    AppLogger.info('📊 Super Admin Dashboard: Fetching system stats');
    ref.read(superAdminStatsProvider.notifier).fetchStats();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(superAdminStatsProvider);
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
                      if (dashboardState is SuperAdminStatsLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(40),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (dashboardState is SuperAdminStatsError)
                        _buildErrorWidget(dashboardState.message)
                      else if (dashboardState is SuperAdminStatsLoaded) ...[
                        // System overview
                        _buildSystemOverview(dashboardState.stats),

                        const SizedBox(height: 24),

                        // Revenue metrics
                        _buildRevenueMetrics(dashboardState.stats),

                        const SizedBox(height: 24),

                        // Company status breakdown
                        _buildCompanyStatus(dashboardState.stats),

                        const SizedBox(height: 24),

                        // Top companies
                        _buildTopCompanies(dashboardState.stats),

                        const SizedBox(height: 24),

                        // Recent system activity
                        _buildSystemActivity(dashboardState.stats),

                        const SizedBox(height: 24),

                        // Admin actions
                        _buildAdminActions(),

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
                    Row(
                      children: [
                        const Text(
                          'Super Admin',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            gradient: ModernColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'SYSTEM',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'System Analytics & Management',
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

  Widget _buildSystemOverview(stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: Icons.business,
                label: 'Total Companies',
                value: '${stats.totalCompanies}',
                gradient: ModernColors.oceanGradient,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.people_rounded,
                label: 'Total Users',
                value: '${stats.totalUsers}',
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
                icon: Icons.verified,
                label: 'Active Companies',
                value: '${stats.activeCompanies}',
                gradient: ModernColors.primaryGradient,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: Icons.person_outline,
                label: 'Active Today',
                value: '${stats.activeUsersToday}',
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

  Widget _buildRevenueMetrics(stats) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildRevenueItem(
                  label: 'Total Revenue',
                  value: '\$${_formatNumber(stats.totalRevenue)}',
                  icon: Icons.attach_money,
                  color: ModernColors.emerald,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildRevenueItem(
                  label: 'Monthly Revenue',
                  value: '\$${_formatNumber(stats.monthlyRevenue)}',
                  icon: Icons.calendar_month,
                  color: ModernColors.blue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueItem({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompanyStatus(stats) {
    final statusData = [
      _StatusItem(
        label: 'Active',
        count: stats.activeCompanies,
        color: ModernColors.emerald,
        icon: Icons.check_circle,
      ),
      _StatusItem(
        label: 'Trial',
        count: stats.trialCompanies,
        color: ModernColors.amber,
        icon: Icons.timer,
      ),
      _StatusItem(
        label: 'Suspended',
        count: stats.suspendedCompanies,
        color: ModernColors.rose,
        icon: Icons.block,
      ),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Company Status',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 20),
          ...statusData.map((item) => _buildStatusItem(item)),
        ],
      ),
    );
  }

  Widget _buildStatusItem(_StatusItem item) {
    final dashboardState = ref.watch(superAdminStatsProvider);
    int total = 1; // Default to avoid division by zero
    
    if (dashboardState is SuperAdminStatsLoaded) {
      total = dashboardState.stats.totalCompanies;
    }
    
    final percentage = total > 0 ? (item.count / total) : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(item.icon, color: item.color, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    item.label,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
              Text(
                '${item.count} (${(percentage * 100).toStringAsFixed(0)}%)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: item.color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          GradientProgressBar(
            value: percentage,
            height: 8,
            gradient: LinearGradient(
              colors: [item.color, item.color.withOpacity(0.6)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopCompanies(stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Companies',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        if (stats.topCompanies.isEmpty)
          GlassCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No companies available',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        else
          ...stats.topCompanies.take(5).map((company) => _buildCompanyItem(company)),
      ],
    );
  }

  Widget _buildCompanyItem(company) {
    final statusColor = company.status == 'active'
        ? ModernColors.emerald
        : company.status == 'trial'
            ? ModernColors.amber
            : ModernColors.rose;

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: ModernColors.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.business, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  company.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${company.employeeCount} employees',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          ModernBadge(
            text: company.status.toUpperCase(),
            gradient: LinearGradient(
              colors: [statusColor, statusColor.withOpacity(0.8)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSystemActivity(stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'System Activity',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        if (stats.recentActivity.isEmpty)
          GlassCard(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No recent activity',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          )
        else
          ...stats.recentActivity.take(5).map((activity) => _buildActivityItem(activity)),
      ],
    );
  }

  Widget _buildActivityItem(activity) {
    final timeAgo = _getTimeAgo(activity.timestamp);
    final iconData = _getActivityIcon(activity.action);
    final color = _getActivityColor(activity.action);

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${activity.actorName ?? 'System'} • $timeAgo',
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

  Widget _buildAdminActions() {
    final actions = [
      _ActionItem(
        icon: Icons.business_center,
        label: 'Manage Companies',
        color: ModernColors.blue,
      ),
      _ActionItem(
        icon: Icons.group,
        label: 'User Management',
        color: ModernColors.purple,
      ),
      _ActionItem(
        icon: Icons.analytics,
        label: 'Analytics',
        color: ModernColors.emerald,
      ),
      _ActionItem(
        icon: Icons.settings,
        label: 'System Settings',
        color: ModernColors.amber,
      ),
      _ActionItem(
        icon: Icons.receipt_long,
        label: 'Billing & Plans',
        color: ModernColors.indigo,
      ),
      _ActionItem(
        icon: Icons.security,
        label: 'Security Logs',
        color: ModernColors.rose,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Admin Actions',
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

  String _formatNumber(double number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(0);
    }
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

  IconData _getActivityIcon(String action) {
    switch (action.toLowerCase()) {
      case 'company_created':
        return Icons.business;
      case 'user_created':
        return Icons.person_add;
      case 'user_deleted':
        return Icons.person_remove;
      case 'company_suspended':
        return Icons.block;
      case 'company_activated':
        return Icons.check_circle;
      default:
        return Icons.info;
    }
  }

  Color _getActivityColor(String action) {
    switch (action.toLowerCase()) {
      case 'company_created':
      case 'user_created':
      case 'company_activated':
        return ModernColors.emerald;
      case 'user_deleted':
      case 'company_suspended':
        return ModernColors.rose;
      default:
        return ModernColors.blue;
    }
  }
}

class _StatusItem {
  final String label;
  final int count;
  final Color color;
  final IconData icon;

  _StatusItem({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
  });
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
