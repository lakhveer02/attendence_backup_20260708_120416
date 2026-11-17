/**
 * TEMPORARY PASSWORD AUTHENTICATION PROVIDER
 * Admin-Provisioned Employee Authentication with Forced Password Reset
 * 
 * State Flow:
 * 1. initial → App starting
 * 2. unauthenticated → User needs to login
 * 3. authenticated → User logged in with permanent password
 * 4. forcePasswordReset → User logged in but must reset temporary password
 */

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:attendence/core/utils/logger.dart';
import 'package:attendence/core/constants/enums.dart';
import 'package:attendence/core/constants/app_constants.dart';

// ==================== AUTH STATUS ENUM ====================

/// Type-safe authentication status enum
enum AuthStatus {
  /// Initial state - App is starting, checking for stored session
  initial,
  
  /// User is not authenticated - show login screen
  unauthenticated,
  
  /// User is authenticated with permanent password - show main app
  authenticated,
  
  /// User logged in but has temporary password - force password reset
  forcePasswordReset,
}

// ==================== AUTH STATE CLASS ====================

/// Immutable authentication state
class AuthState {
  final AuthStatus status;
  final UserProfile? user;
  final String? accessToken;
  final String? refreshToken;
  final String? errorMessage;
  
  const AuthState({
    required this.status,
    this.user,
    this.accessToken,
    this.refreshToken,
    this.errorMessage,
  });
  
  /// Initial state
  factory AuthState.initial() {
    return const AuthState(status: AuthStatus.initial);
  }
  
  /// Unauthenticated state
  factory AuthState.unauthenticated({String? errorMessage}) {
    return AuthState(
      status: AuthStatus.unauthenticated,
      errorMessage: errorMessage,
    );
  }
  
  /// Authenticated state with permanent password
  factory AuthState.authenticated({
    required UserProfile user,
    required String accessToken,
    required String refreshToken,
  }) {
    return AuthState(
      status: AuthStatus.authenticated,
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
  
  /// Force password reset state (temporary password)
  factory AuthState.forcePasswordReset({
    required UserProfile user,
    required String accessToken,
    required String refreshToken,
  }) {
    return AuthState(
      status: AuthStatus.forcePasswordReset,
      user: user,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
  
  /// Copy with method for state updates
  AuthState copyWith({
    AuthStatus? status,
    UserProfile? user,
    String? accessToken,
    String? refreshToken,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ==================== USER PROFILE MODEL ====================

/// User profile model matching API response
class UserProfile {
  final String profileId;
  final String email;
  final String fullName;
  final String role;
  final String? companyId;
  final String? companyName;
  final bool isActive;
  final bool isVerified;
  final bool isTemporaryPassword; // CRITICAL FIELD
  final String? phoneNumber;
  final String? designation;
  final String? departmentId;
  
  const UserProfile({
    required this.profileId,
    required this.email,
    required this.fullName,
    required this.role,
    this.companyId,
    this.companyName,
    required this.isActive,
    required this.isVerified,
    required this.isTemporaryPassword,
    this.phoneNumber,
    this.designation,
    this.departmentId,
  });
  
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      profileId: json['profile_id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      role: json['role'] as String,
      companyId: json['company_id'] as String?,
      companyName: json['company_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      isTemporaryPassword: json['is_temporary_password'] as bool? ?? false,
      phoneNumber: json['phone_number'] as String?,
      designation: json['designation'] as String?,
      departmentId: json['department_id'] as String?,
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'profile_id': profileId,
      'email': email,
      'full_name': fullName,
      'role': role,
      'company_id': companyId,
      'company_name': companyName,
      'is_active': isActive,
      'is_verified': isVerified,
      'is_temporary_password': isTemporaryPassword,
      'phone_number': phoneNumber,
      'designation': designation,
      'department_id': departmentId,
    };
  }
  
  UserRole get userRole => UserRole.fromString(role);
}

// ==================== AUTH NOTIFIER ====================

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _secureStorage;
  final String _baseUrl;
  
  AuthNotifier({
    required String baseUrl,
  })  : _baseUrl = baseUrl,
        _secureStorage = const FlutterSecureStorage(),
        super(AuthState.initial()) {
    _initialize();
  }
  
  /// Initialize authentication state from stored session
  Future<void> _initialize() async {
    try {
      AppLogger.info('🔐 Initializing authentication...');
      
      // Check for stored tokens
      final accessToken = await _secureStorage.read(key: 'access_token');
      final refreshToken = await _secureStorage.read(key: 'refresh_token');
      final userJson = await _secureStorage.read(key: 'user_profile');
      
      if (accessToken != null && userJson != null) {
        try {
          final userMap = json.decode(userJson) as Map<String, dynamic>;
          final user = UserProfile.fromJson(userMap);
          
          // Check if token is still valid (optional - can add expiry check)
          // For now, trust stored session
          
          // Determine state based on is_temporary_password flag
          if (user.isTemporaryPassword) {
            AppLogger.info('⚠️ Temporary password detected - forcing reset');
            state = AuthState.forcePasswordReset(
              user: user,
              accessToken: accessToken,
              refreshToken: refreshToken ?? '',
            );
          } else {
            AppLogger.info('✅ Valid session restored for ${user.email}');
            state = AuthState.authenticated(
              user: user,
              accessToken: accessToken,
              refreshToken: refreshToken ?? '',
            );
          }
          return;
        } catch (e) {
          AppLogger.error('Failed to restore session', e);
        }
      }
      
      // No valid session found
      AppLogger.info('ℹ️ No valid session - user must login');
      state = AuthState.unauthenticated();
      
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing auth', e, stackTrace);
      state = AuthState.unauthenticated();
    }
  }
  
  /// Login with email and password
  Future<void> login({
    required String email,
    required String password,
    String? companyId,
    String? workspaceSlug,
    required String deviceId,
    String? deviceName,
  }) async {
    try {
      AppLogger.info('🔐 Attempting login for: $email');
      
      // Prepare request body
      final requestBody = {
        'email': email,
        'password': password,
        'device_id': deviceId,
        'device_name': deviceName ?? 'Flutter App',
        'device_os': 'iOS/Android',
        'device_model': 'Mobile',
      };
      
      if (companyId != null) {
        requestBody['company_id'] = companyId;
      }
      
      if (workspaceSlug != null) {
        requestBody['workspace_slug'] = workspaceSlug;
      }
      
      // Make API request
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/login'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(requestBody),
      );
      
      // Handle response
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        
        // Extract tokens and user
        final accessToken = responseData['access_token'] as String;
        final refreshToken = responseData['refresh_token'] as String;
        final userData = responseData['user'] as Map<String, dynamic>;
        
        final user = UserProfile.fromJson(userData);
        
        // Store tokens and user profile securely
        await _secureStorage.write(key: 'access_token', value: accessToken);
        await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        await _secureStorage.write(key: 'user_profile', value: json.encode(user.toJson()));
        await _secureStorage.write(key: 'device_id', value: deviceId);
        
        // CRITICAL: Check is_temporary_password flag
        if (user.isTemporaryPassword) {
          AppLogger.info('⚠️ Temporary password detected - redirecting to password reset');
          state = AuthState.forcePasswordReset(
            user: user,
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
        } else {
          AppLogger.info('✅ Login successful for ${user.email}');
          state = AuthState.authenticated(
            user: user,
            accessToken: accessToken,
            refreshToken: refreshToken,
          );
        }
      } else {
        // Handle error response
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['detail'] as String? ?? 'Login failed';
        
        AppLogger.error('Login failed', errorMessage);
        state = AuthState.unauthenticated(errorMessage: errorMessage);
      }
      
    } catch (e, stackTrace) {
      AppLogger.error('Login error', e, stackTrace);
      
      String errorMessage = 'Login failed. Please try again.';
      if (e.toString().contains('SocketException')) {
        errorMessage = 'Network error. Please check your internet connection.';
      }
      
      state = AuthState.unauthenticated(errorMessage: errorMessage);
    }
  }
  
  /// Reset temporary password to permanent password
  Future<bool> resetTemporaryPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      AppLogger.info('🔑 Resetting temporary password...');
      
      final currentState = state;
      if (currentState.accessToken == null) {
        throw Exception('Not authenticated');
      }
      
      // Make API request to change password
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${currentState.accessToken}',
        },
        body: json.encode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );
      
      if (response.statusCode == 200) {
        AppLogger.info('✅ Password reset successful');
        
        // Update user profile to mark password as permanent
        if (currentState.user != null) {
          // After successful password reset, is_temporary_password becomes false
          // The backend will have updated this, but we need to fetch fresh user data
          // For now, we'll just transition to authenticated state
          // The user will need to re-login with new password
          
          // Clear stored session to force fresh login
          await logout();
          
          return true;
        }
        
        return true;
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage = errorData['detail'] as String? ?? 'Password reset failed';
        AppLogger.error('Password reset failed', errorMessage);
        return false;
      }
      
    } catch (e, stackTrace) {
      AppLogger.error('Password reset error', e, stackTrace);
      return false;
    }
  }
  
  /// Logout from current device
  Future<void> logout() async {
    try {
      AppLogger.info('👋 Logging out...');
      
      final currentState = state;
      if (currentState.accessToken != null) {
        final deviceId = await _secureStorage.read(key: 'device_id');
        
        // Call logout endpoint (best effort - don't fail if it errors)
        try {
          await http.post(
            Uri.parse('$_baseUrl/api/v1/auth/logout'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${currentState.accessToken}',
            },
            body: json.encode({
              'device_id': deviceId ?? 'unknown',
            }),
          );
        } catch (e) {
          AppLogger.error('Logout API call failed (continuing anyway)', e);
        }
      }
      
      // Clear stored credentials
      await _clearStoredCredentials();
      
      state = AuthState.unauthenticated();
      AppLogger.info('✅ Logout successful');
      
    } catch (e, stackTrace) {
      AppLogger.error('Logout error', e, stackTrace);
      // Force logout even on error
      await _clearStoredCredentials();
      state = AuthState.unauthenticated();
    }
  }
  
  /// Clear all stored credentials
  Future<void> _clearStoredCredentials() async {
    await _secureStorage.delete(key: 'access_token');
    await _secureStorage.delete(key: 'refresh_token');
    await _secureStorage.delete(key: 'user_profile');
    await _secureStorage.delete(key: 'device_id');
  }
  
  /// Refresh access token
  Future<void> refreshToken() async {
    try {
      final currentState = state;
      final refreshToken = currentState.refreshToken;
      final deviceId = await _secureStorage.read(key: 'device_id');
      
      if (refreshToken == null || deviceId == null) {
        throw Exception('No refresh token available');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl/api/v1/auth/refresh'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'refresh_token': refreshToken,
          'device_id': deviceId,
        }),
      );
      
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body) as Map<String, dynamic>;
        
        final newAccessToken = responseData['access_token'] as String;
        final newRefreshToken = responseData['refresh_token'] as String;
        final userData = responseData['user'] as Map<String, dynamic>;
        
        final user = UserProfile.fromJson(userData);
        
        // Update stored tokens
        await _secureStorage.write(key: 'access_token', value: newAccessToken);
        await _secureStorage.write(key: 'refresh_token', value: newRefreshToken);
        await _secureStorage.write(key: 'user_profile', value: json.encode(user.toJson()));
        
        // Update state
        if (user.isTemporaryPassword) {
          state = AuthState.forcePasswordReset(
            user: user,
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
        } else {
          state = AuthState.authenticated(
            user: user,
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
        }
        
        AppLogger.info('✅ Token refreshed successfully');
      } else {
        // Refresh failed - logout user
        await logout();
      }
      
    } catch (e, stackTrace) {
      AppLogger.error('Token refresh failed', e, stackTrace);
      await logout();
    }
  }
}

// ==================== PROVIDER ====================

/// Auth state provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  // Use the same backend base URL as the main auth flow.
  final baseUrl = AppConstants.fastApiBaseUrl;

  return AuthNotifier(baseUrl: baseUrl);
});

/// Convenience providers for easy access
final authStatusProvider = Provider<AuthStatus>((ref) {
  return ref.watch(authProvider).status;
});

final currentUserProvider = Provider<UserProfile?>((ref) {
  return ref.watch(authProvider).user;
});

final isAuthenticatedProvider = Provider<bool>((ref) {
  final status = ref.watch(authStatusProvider);
  return status == AuthStatus.authenticated;
});

final needsPasswordResetProvider = Provider<bool>((ref) {
  final status = ref.watch(authStatusProvider);
  return status == AuthStatus.forcePasswordReset;
});
