import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/core/constants/app_constants.dart';
import 'package:attendence/core/utils/logger.dart';
import 'package:attendence/core/theme/modern_design_system.dart';
import 'package:attendence/core/routing/modern_page_transitions.dart';
import 'package:attendence/domain/entities/profile.dart';
import 'package:attendence/presentation/providers/auth_provider.dart';
import 'package:attendence/presentation/screens/splash/modern_splash_screen.dart';
import 'package:attendence/presentation/screens/auth/modern_login_screen.dart';
import 'package:attendence/presentation/screens/auth/modern_signup_screen.dart';
import 'package:attendence/presentation/screens/home/modern_home_dashboard.dart';
import 'package:attendence/presentation/screens/admin/modern_admin_dashboard.dart';
import 'package:attendence/presentation/screens/hr/modern_hr_dashboard.dart';
import 'package:attendence/presentation/screens/super_admin/modern_super_admin_dashboard.dart';
import 'package:attendence/presentation/screens/attendance/modern_checkin_screen.dart';
import 'package:attendence/presentation/screens/profile/modern_profile_screen.dart';
import 'package:attendence/core/services/notification_service.dart';
import 'package:timezone/data/latest.dart' as tz;

/// Application entry point with proper initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize timezone data for notifications
  tz.initializeTimeZones();

  // Initialize notification service
  try {
    final notificationService = NotificationService();
    await notificationService.initialize();
    await notificationService.requestPermissions();
    
    // Schedule daily reminders (9:00 AM check-in, 6:00 PM check-out)
    await notificationService.scheduleDailyCheckInReminder(hour: 9, minute: 0);
    await notificationService.scheduleDailyCheckOutReminder(hour: 18, minute: 0);
    
    AppLogger.info('✅ Notification service initialized');
  } catch (e) {
    AppLogger.error('⚠️ Notification service initialization failed: $e');
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  AppLogger.info('🚀 Application initialized - Using FastAPI for authentication');

  runApp(
    const ProviderScope(
      child: MainApp(),
    ),
  );
}

/// Main application widget with Riverpod integration and navigation-based routing
class MainApp extends ConsumerWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        FocusManager.instance.primaryFocus?.unfocus();
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          colorScheme: const ColorScheme.light(
            primary: ModernColors.indigo,
            secondary: ModernColors.purple,
            surface: Colors.white,
          ),
          fontFamily: 'Inter',
        ),
        onGenerateRoute: _onGenerateRoute,
        navigatorObservers: [KeyboardDismissObserver()],
        home: const AuthGate(),
        builder: (context, child) {
          return GestureDetector(
            onTap: () {
              FocusManager.instance.primaryFocus?.unfocus();
            },
            child: child,
          );
        },
      ),
    );
  }

  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/login':
        return FadePageRoute(page: const ModernLoginScreen());
      case '/signup':
        return SlideUpPageRoute(page: const ModernSignupScreen());
      case '/home':
        return SharedAxisPageRoute(
          page: const ModernHomeDashboard(),
          transitionType: SharedAxisTransitionType.scaled,
        );
      case '/admin':
        return SharedAxisPageRoute(
          page: const ModernAdminDashboard(),
          transitionType: SharedAxisTransitionType.scaled,
        );
      case '/hr':
        return SharedAxisPageRoute(
          page: const ModernHRDashboard(),
          transitionType: SharedAxisTransitionType.scaled,
        );
      case '/superadmin':
        return SharedAxisPageRoute(
          page: const ModernSuperAdminDashboard(),
          transitionType: SharedAxisTransitionType.scaled,
        );
      case '/checkin':
        return SlideUpPageRoute(page: const ModernCheckInScreen());
      case '/profile':
        return SlideRightPageRoute(page: const ModernProfileScreen());
      default:
        return FadePageRoute(page: const ModernSplashScreen());
    }
  }
}

/// Navigator observer to dismiss keyboard on route changes
class KeyboardDismissObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

/// Auth gate that handles navigation based on auth state
class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    
    AppLogger.info('🎯 AuthGate rendering for state: ${authState.runtimeType}');
    
    Widget child;
    
    // Render based on current auth state
    if (authState is AuthInitial || authState is AuthLoading) {
      AppLogger.info('📱 Showing ModernSplashScreen');
      child = const ModernSplashScreen(key: ValueKey('splash'));
    } else if (authState is AuthAuthenticated) {
      final profile = authState.profile;
      final role = profile.role;
      
      AppLogger.info('📱 User role: ${role.name}, routing to appropriate dashboard');
      AppLogger.info('📱 Profile: ${profile.fullName}, Email: ${profile.email}');
      
      // Route based on specific user role
      switch (role) {
        case UserRole.superAdmin:
          AppLogger.info('🔐 Routing to Super Admin Dashboard');
          child = const ModernSuperAdminDashboard(key: ValueKey('superadmin'));
          break;
        case UserRole.companyAdmin:
          AppLogger.info('👔 Routing to Company Admin Dashboard');
          child = const ModernAdminDashboard(key: ValueKey('admin'));
          break;
        case UserRole.hrManager:
          AppLogger.info('👥 Routing to HR Manager Dashboard');
          child = const ModernHRDashboard(key: ValueKey('hr'));
          break;
        case UserRole.teamManager:
          AppLogger.info('📊 Routing to Team Manager Dashboard (using Admin Dashboard)');
          child = const ModernAdminDashboard(key: ValueKey('manager'));
          break;
        case UserRole.employee:
          AppLogger.info('👤 Routing to Employee Dashboard');
          child = const ModernHomeDashboard(key: ValueKey('employee'));
          break;
      }
    } else if (authState is AuthError) {
      // Show error but keep on login screen
      AppLogger.error('🔴 Auth error: ${authState.message}');
      child = const ModernLoginScreen(key: ValueKey('login'));
    } else {
      // AuthUnauthenticated - show login
      AppLogger.info('📱 Showing ModernLoginScreen (unauthenticated)');
      child = const ModernLoginScreen(key: ValueKey('login'));
    }
    
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(animation),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
 