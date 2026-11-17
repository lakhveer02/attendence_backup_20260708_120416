// 🏠 Modern Home Dashboard - Beautiful animated dashboard with stats
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/core/theme/modern_design_system.dart';
import 'package:attendence/core/utils/logger.dart';
import 'package:attendence/presentation/providers/auth_provider.dart';
import 'package:attendence/presentation/providers/dashboard_provider.dart';
import 'package:intl/intl.dart';

// Import new screens
import 'package:attendence/presentation/screens/leave/leave_management_screen.dart';
import 'package:attendence/presentation/screens/attendance/attendance_history_screen.dart';
import 'package:attendence/presentation/screens/profile/modern_profile_screen.dart';
import 'package:attendence/presentation/screens/attendance/modern_checkin_screen.dart';

class ModernHomeDashboard extends ConsumerStatefulWidget {
  const ModernHomeDashboard({super.key});

  @override
  ConsumerState<ModernHomeDashboard> createState() => _ModernHomeDashboardState();
}

class _ModernHomeDashboardState extends ConsumerState<ModernHomeDashboard>
    with TickerProviderStateMixin {
  late AnimationController _headerAnimationController;
  late AnimationController _cardAnimationController;
  late Animation<double> _headerAnimation;
  late List<Animation<Offset>> _cardSlideAnimations;

  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    
    // Fetch attendance data on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchAttendanceData();
    });
  }

  void _fetchAttendanceData() {
    final profile = ref.read(currentUserProvider);
    if (profile?.id != null) {
      AppLogger.info('📊 Employee Dashboard: Fetching attendance for user: ${profile!.id}');
      ref.read(attendanceSummaryProvider.notifier).fetchSummary(
            profileId: profile.id,
            startDate: DateTime.now().subtract(const Duration(days: 30)),
            endDate: DateTime.now(),
          );
    } else {
      AppLogger.warning('⚠️ Employee Dashboard: No user ID found');
    }
  }

  void _initializeAnimations() {
    // Header animation
    _headerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerAnimation = CurvedAnimation(
      parent: _headerAnimationController,
      curve: Curves.easeOut,
    );

    // Card animations
    _cardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Staggered card animations
    _cardSlideAnimations = List.generate(
      6,
      (index) => Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _cardAnimationController,
          curve: Interval(
            index * 0.1,
            0.6 + (index * 0.1),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    _headerAnimationController.forward();
    _cardAnimationController.forward();
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _cardAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(currentUserProvider);
    final attendanceState = profile != null 
        ? ref.watch(attendanceSummaryProvider)
        : const AttendanceSummaryInitial();

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
                    // Status card
                    _buildStatusCard(),

                    const SizedBox(height: 24),

                    // Quick actions
                    _buildQuickActions(),

                    const SizedBox(height: 24),

                    // Stats grid with real data
                    if (attendanceState is AttendanceSummaryLoading)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(40),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else if (attendanceState is AttendanceSummaryError)
                      _buildErrorWidget(attendanceState.message)
                    else if (attendanceState is AttendanceSummaryLoaded)
                      _buildStatsGrid(attendanceState.summary)
                    else
                      _buildStatsGrid(null),

                    const SizedBox(height: 24),

                    // Recent activity
                    _buildRecentActivity(),

                    const SizedBox(height: 24),

                    // Team section (if manager/admin)
                    _buildTeamSection(),

                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _buildBottomNavBar(),
    );
  }

  Widget _buildSliverAppBar(profile) {
    return SliverToBoxAdapter(
      child: FadeTransition(
        opacity: _headerAnimation,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Avatar with gradient border
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: ModernColors.primaryGradient,
                  boxShadow: ModernEffects.glowEffect(color: ModernColors.indigo),
                ),
                padding: const EdgeInsets.all(3),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: ClipOval(
                    child: profile?.profilePictureUrl != null
                        ? Image.network(
                            profile!.profilePictureUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, size: 32);
                            },
                          )
                        : const Icon(Icons.person, size: 32),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good ${_getGreeting()}!',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      profile?.fullName ?? 'Employee',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              // Notification button
              GlassCard(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  children: [
                    const Icon(
                      Icons.notifications_outlined,
                      color: Colors.black87,
                      size: 24,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: ModernColors.rose,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
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
            'Failed to load attendance data',
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
            onPressed: _fetchAttendanceData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return SlideTransition(
      position: _cardSlideAnimations[0],
      child: FadeTransition(
        opacity: _headerAnimation,
        child: GradientCard(
          gradient: ModernColors.oceanGradient,
          padding: const EdgeInsets.all(24),
          boxShadow: ModernEffects.glowEffect(color: ModernColors.blue),
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
                        'Attendance Status',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEEE, MMM dd').format(DateTime.now()),
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Checked In',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildTimeCard(
                      icon: Icons.login,
                      label: 'Check In',
                      time: '09:00 AM',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTimeCard(
                      icon: Icons.logout,
                      label: 'Check Out',
                      time: '--:--',
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

  Widget _buildTimeCard({
    required IconData icon,
    required String label,
    required String time,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.white, size: 24),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            time,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.fingerprint,
        label: 'Check In',
        gradient: ModernColors.successGradient,
        color: ModernColors.emerald,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ModernCheckInScreen()),
          );
        },
      ),
      _QuickAction(
        icon: Icons.calendar_today,
        label: 'Leave',
        gradient: ModernColors.warningGradient,
        color: ModernColors.amber,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const LeaveManagementScreen()),
          );
        },
      ),
      _QuickAction(
        icon: Icons.access_time,
        label: 'History',
        gradient: ModernColors.primaryGradient,
        color: ModernColors.indigo,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AttendanceHistoryScreen()),
          );
        },
      ),
      _QuickAction(
        icon: Icons.person,
        label: 'Profile',
        gradient: ModernColors.sunsetGradient,
        color: ModernColors.pink,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ModernProfileScreen()),
          );
        },
      ),
    ];

    return SlideTransition(
      position: _cardSlideAnimations[1],
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
            children: actions.map((action) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: _buildQuickActionCard(action),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionCard(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 72,
            decoration: BoxDecoration(
              gradient: action.gradient,
              borderRadius: BorderRadius.circular(20),
              boxShadow: ModernEffects.softShadow(color: action.color),
            ),
            child: Icon(
              action.icon,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            action.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(summary) {
    // Use real data if available, otherwise show placeholder
    final presentDays = summary?.presentDays ?? 0;
    final absentDays = summary?.absentDays ?? 0;
    final totalHours = summary?.totalHoursWorked ?? 0.0;
    final totalDays = summary?.totalDays ?? 1;
    final presentPercentage = totalDays > 0 ? (presentDays / totalDays) : 0.0;
    final absentPercentage = totalDays > 0 ? (absentDays / totalDays) : 0.0;
    
    return SlideTransition(
      position: _cardSlideAnimations[2],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Month',
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
                child: _buildStatCard(
                  icon: Icons.calendar_month,
                  label: 'Present Days',
                  value: '$presentDays',
                  gradient: ModernColors.successGradient,
                  percentage: presentPercentage,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.cancel,
                  label: 'Absent Days',
                  value: '$absentDays',
                  gradient: ModernColors.warningGradient,
                  percentage: absentPercentage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.access_time,
                  label: 'Total Hours',
                  value: '${totalHours.toStringAsFixed(0)}h',
                  gradient: ModernColors.oceanGradient,
                  percentage: totalHours > 0 ? (totalHours / 200).clamp(0.0, 1.0) : 0.0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.wb_sunny_outlined,
                  label: 'Attendance',
                  value: '${(summary?.attendancePercentage ?? 0).toStringAsFixed(0)}%',
                  gradient: ModernColors.sunsetGradient,
                  percentage: (summary?.attendancePercentage ?? 0) / 100,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Gradient gradient,
    required double percentage,
  }) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
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
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          GradientProgressBar(
            value: percentage,
            height: 4,
            gradient: gradient,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      _Activity(
        title: 'Checked In',
        time: 'Today at 9:00 AM',
        icon: Icons.login,
        color: ModernColors.emerald,
      ),
      _Activity(
        title: 'Leave Approved',
        time: 'Yesterday at 2:30 PM',
        icon: Icons.check_circle,
        color: ModernColors.blue,
      ),
      _Activity(
        title: 'Overtime Request',
        time: '2 days ago',
        icon: Icons.access_time,
        color: ModernColors.amber,
      ),
    ];

    return SlideTransition(
      position: _cardSlideAnimations[3],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Activity',
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
          ...activities.map((activity) => _buildActivityItem(activity)),
        ],
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
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: activity.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              activity.icon,
              color: activity.color,
              size: 24,
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
                const SizedBox(height: 4),
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
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection() {
    return SlideTransition(
      position: _cardSlideAnimations[4],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Team Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          GradientCard(
            gradient: ModernColors.forestGradient,
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildTeamStat('Present', '45', Icons.check_circle),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildTeamStat('Absent', '3', Icons.cancel),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildTeamStat('Leave', '2', Icons.wb_sunny_outlined),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 28),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        gradient: ModernColors.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: ModernEffects.glowEffect(color: ModernColors.indigo),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            // Navigate to check-in screen
          },
          borderRadius: BorderRadius.circular(35),
          child: const Icon(
            Icons.fingerprint_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() => _selectedIndex = index);
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: ModernColors.indigo,
        unselectedItemColor: Colors.grey.shade400,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          BottomNavigationBarItem(
            icon: SizedBox(width: 70), // Space for FAB
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Gradient gradient;
  final Color color;
  final VoidCallback? onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.color,
    this.onTap,
  });
}

class _Activity {
  final String title;
  final String time;
  final IconData icon;
  final Color color;

  _Activity({
    required this.title,
    required this.time,
    required this.icon,
    required this.color,
  });
}
