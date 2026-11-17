import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/core/utils/logger.dart';
import 'package:attendence/core/error/failures.dart';
import 'package:attendence/domain/entities/profile.dart';
import 'package:attendence/presentation/providers/core_providers.dart';

/// Authentication state
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  final Profile profile;
  const AuthAuthenticated(this.profile);
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

/// Authentication state notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;

  AuthNotifier(this._ref) : super(const AuthInitial()) {
    _init();
  }

  Future<void> _init() async {
    try {
      AppLogger.info('🔐 Auth init started');
      final authRepo = _ref.read(authRepositoryProvider);
      final isAuth = await authRepo.isAuthenticated();
      AppLogger.info('📡 isAuth: $isAuth');
      
      if (isAuth) {
        final result = await authRepo.getCurrentUser();
        result.fold(
          (failure) {
            AppLogger.error('❌ Get user failed', failure.userMessage);
            state = const AuthUnauthenticated();
          },
          (profile) {
            if (profile != null) {
              AppLogger.info('✅ User: ${profile.email}');
              state = AuthAuthenticated(profile);
            } else {
              AppLogger.info('ℹ️ No profile');
              state = const AuthUnauthenticated();
            }
          },
        );
      } else {
        AppLogger.info('ℹ️ Not authenticated');
        state = const AuthUnauthenticated();
      }
      AppLogger.info('✅ Auth init complete: ${state.runtimeType}');
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing auth', e, stackTrace);
      state = const AuthUnauthenticated();
    }
  }

  /// Sign in with email and password
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    try {
      state = const AuthLoading();
      AppLogger.info('🔐 Attempting sign in for: $email');

      final authRepo = _ref.read(authRepositoryProvider);
      final result = await authRepo.signInWithEmail(
        email: email,
        password: password,
      );

      result.fold(
        (failure) {
          AppLogger.error('❌ Sign in failed: ${failure.userMessage}');
          state = AuthError(failure.userMessage);
          // DON'T reset to unauthenticated - let user see the error
        },
        (profile) {
          AppLogger.info('✅ Sign in successful!');
          AppLogger.info('   Email: ${profile.email}');
          AppLogger.info('   Name: ${profile.fullName}');
          AppLogger.info('   Role: ${profile.role.name}');
          AppLogger.info('   Company ID: ${profile.companyId}');
          state = AuthAuthenticated(profile);
          AppLogger.info('✅ Auth state updated to AuthAuthenticated');
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('💥 Unexpected error during sign in', e, stackTrace);
      state = AuthError(e.toString());
    }
  }

  /// Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phoneNumber,
    String? departmentId,
    bool createCompany = false,
    String? companyName,
  }) async {
    try {
      state = const AuthLoading();
      AppLogger.info('📝 Attempting sign up for: $email');

      // Convert string role to UserRole enum
      UserRole userRole;
      switch (role.toLowerCase()) {
        case 'super_admin':
          userRole = UserRole.superAdmin;
          break;
        case 'company_admin':
          userRole = UserRole.companyAdmin;
          break;
        case 'hr_manager':
          userRole = UserRole.hrManager;
          break;
        case 'manager':
        case 'team_manager':
          userRole = UserRole.teamManager;
          break;
        case 'employee':
        default:
          userRole = UserRole.employee;
          break;
      }

      final authRepo = _ref.read(authRepositoryProvider);
      final result = await authRepo.signUpWithEmail(
        email: email,
        password: password,
        fullName: fullName,
        role: userRole,
        phoneNumber: phoneNumber,
        departmentId: departmentId,
        createCompany: createCompany,
        companyName: companyName,
      );

      result.fold(
        (failure) {
          AppLogger.error('Sign up failed', failure.userMessage);
          state = AuthError(failure.userMessage);
          // Reset to unauthenticated after showing error
          Future.delayed(const Duration(seconds: 1), () {
            if (mounted) state = const AuthUnauthenticated();
          });
        },
        (profile) {
          AppLogger.info('✅ Sign up successful: ${profile.email}');
          state = AuthAuthenticated(profile);
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error during sign up', e, stackTrace);
      state = AuthError(e.toString());
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) state = const AuthUnauthenticated();
      });
    }
  }  /// Sign out
  Future<void> signOut() async {
    try {
      AppLogger.info('👋 Signing out...');
      final authRepo = _ref.read(authRepositoryProvider);
      await authRepo.signOut();
      state = const AuthUnauthenticated();
      AppLogger.info('✅ Sign out successful');
    } catch (e, stackTrace) {
      AppLogger.error('Error during sign out', e, stackTrace);
      // Force unauthenticated state even on error
      state = const AuthUnauthenticated();
    }
  }

  /// Reset password
  Future<bool> resetPassword(String email) async {
    try {
      AppLogger.info('🔄 Requesting password reset for: $email');
      final authRepo = _ref.read(authRepositoryProvider);
      final result = await authRepo.resetPassword(email: email);

      return result.fold(
        (failure) {
          AppLogger.error('Password reset failed', failure.userMessage);
          return false;
        },
        (_) {
          AppLogger.info('✅ Password reset email sent');
          return true;
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error during password reset', e, stackTrace);
      return false;
    }
  }

  /// Refresh current user profile
  Future<void> refreshProfile() async {
    try {
      final authRepo = _ref.read(authRepositoryProvider);
      final result = await authRepo.getCurrentUser();

      result.fold(
        (failure) {
          AppLogger.error('Failed to refresh profile', failure.userMessage);
        },
        (profile) {
          if (profile != null) {
            state = AuthAuthenticated(profile);
          }
        },
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error refreshing profile', e, stackTrace);
    }
  }
}

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});

/// Current user profile provider (convenience)
final currentUserProvider = Provider<Profile?>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthAuthenticated ? authState.profile : null;
});

/// Is authenticated provider (convenience)
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authProvider);
  return authState is AuthAuthenticated;
});

/// Current user role provider (convenience)
final currentUserRoleProvider = Provider<UserRole?>((ref) {
  final profile = ref.watch(currentUserProvider);
  return profile?.role;
});

/// Is admin provider (convenience) - Checks if user is any type of admin
final isAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role == UserRole.companyAdmin || 
         role == UserRole.hrManager ||
         role == UserRole.superAdmin;
});

/// Is super admin provider
final isSuperAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role == UserRole.superAdmin;
});

/// Is company admin provider
final isCompanyAdminProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role == UserRole.companyAdmin;
});

/// Is employee provider
final isEmployeeProvider = Provider<bool>((ref) {
  final role = ref.watch(currentUserRoleProvider);
  return role == UserRole.employee;
});
