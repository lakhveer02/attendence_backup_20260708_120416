import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/data/models/dashboard_stats_model.dart';
import 'package:attendence/presentation/providers/auth_provider.dart';
import 'package:attendence/core/constants/app_constants.dart';
import 'package:attendence/core/utils/logger.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';

/// Dashboard stats state
sealed class DashboardStatsState {
  const DashboardStatsState();
}

class DashboardStatsInitial extends DashboardStatsState {
  const DashboardStatsInitial();
}

class DashboardStatsLoading extends DashboardStatsState {
  const DashboardStatsLoading();
}

class DashboardStatsLoaded extends DashboardStatsState {
  final DashboardStats stats;
  const DashboardStatsLoaded(this.stats);
}

class DashboardStatsError extends DashboardStatsState {
  final String message;
  const DashboardStatsError(this.message);
}

/// Dashboard stats notifier
class DashboardStatsNotifier extends StateNotifier<DashboardStatsState> {
  final String? _baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  DashboardStatsNotifier(Ref ref, this._baseUrl) : super(const DashboardStatsInitial());

  /// Get authentication token
  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Fetch dashboard statistics
  Future<void> fetchStats({required String companyId}) async {
    try {
      state = const DashboardStatsLoading();
      AppLogger.info('📊 Fetching dashboard stats for company: $companyId');

      final baseUrl = _baseUrl ?? AppConstants.fastApiBaseUrl;
      final token = await _getToken();
      
      // Debug: Log token (first 20 chars only for security)
      if (token != null && token.length > 20) {
        AppLogger.info('🔑 Token found: ${token.substring(0, 20)}...');
      } else {
        AppLogger.info('🔑 Token found: $token');
      }
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/dashboard/stats?company_id=$companyId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      AppLogger.info('📡 Response status: ${response.statusCode}');
      if (response.statusCode != 200) {
        AppLogger.info('📡 Response body: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stats = DashboardStats.fromJson(data);
        state = DashboardStatsLoaded(stats);
        AppLogger.info('✅ Dashboard stats loaded successfully');
      } else {
        throw Exception('Failed to load dashboard stats: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching dashboard stats', e, stackTrace);
      state = DashboardStatsError(e.toString());
    }
  }

  /// Refresh statistics
  Future<void> refresh({required String companyId}) async {
    await fetchStats(companyId: companyId);
  }
}

/// Dashboard stats provider
final dashboardStatsProvider = StateNotifierProvider.autoDispose<
    DashboardStatsNotifier, DashboardStatsState>((ref) {
  // Always use AppConstants.fastApiBaseUrl (supports ngrok for physical devices)
  return DashboardStatsNotifier(ref, null);
});

/// Super Admin dashboard stats state
sealed class SuperAdminStatsState {
  const SuperAdminStatsState();
}

class SuperAdminStatsInitial extends SuperAdminStatsState {
  const SuperAdminStatsInitial();
}

class SuperAdminStatsLoading extends SuperAdminStatsState {
  const SuperAdminStatsLoading();
}

class SuperAdminStatsLoaded extends SuperAdminStatsState {
  final SuperAdminDashboardStats stats;
  const SuperAdminStatsLoaded(this.stats);
}

class SuperAdminStatsError extends SuperAdminStatsState {
  final String message;
  const SuperAdminStatsError(this.message);
}

/// Super Admin dashboard stats notifier
class SuperAdminStatsNotifier extends StateNotifier<SuperAdminStatsState> {
  final String? _baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  SuperAdminStatsNotifier(Ref ref, this._baseUrl) : super(const SuperAdminStatsInitial());

  /// Get authentication token
  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Fetch super admin dashboard statistics
  Future<void> fetchStats() async {
    try {
      state = const SuperAdminStatsLoading();
      AppLogger.info('📊 Fetching super admin dashboard stats');

      final baseUrl = _baseUrl ?? AppConstants.fastApiBaseUrl;
      final token = await _getToken();
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/super-admin/stats'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stats = SuperAdminDashboardStats.fromJson(data);
        state = SuperAdminStatsLoaded(stats);
        AppLogger.info('✅ Super admin stats loaded successfully');
      } else {
        throw Exception('Failed to load super admin stats: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching super admin stats', e, stackTrace);
      state = SuperAdminStatsError(e.toString());
    }
  }

  /// Refresh statistics
  Future<void> refresh() async {
    await fetchStats();
  }
}

/// Super Admin dashboard stats provider
final superAdminStatsProvider = StateNotifierProvider.autoDispose<
    SuperAdminStatsNotifier, SuperAdminStatsState>((ref) {
  // Always use AppConstants.fastApiBaseUrl
  return SuperAdminStatsNotifier(ref, null);
});

/// Attendance summary state
sealed class AttendanceSummaryState {
  const AttendanceSummaryState();
}

class AttendanceSummaryInitial extends AttendanceSummaryState {
  const AttendanceSummaryInitial();
}

class AttendanceSummaryLoading extends AttendanceSummaryState {
  const AttendanceSummaryLoading();
}

class AttendanceSummaryLoaded extends AttendanceSummaryState {
  final AttendanceSummary summary;
  const AttendanceSummaryLoaded(this.summary);
}

class AttendanceSummaryError extends AttendanceSummaryState {
  final String message;
  const AttendanceSummaryError(this.message);
}

/// Attendance summary notifier
class AttendanceSummaryNotifier extends StateNotifier<AttendanceSummaryState> {
  final String? _baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AttendanceSummaryNotifier(Ref ref, this._baseUrl) : super(const AttendanceSummaryInitial());

  /// Get authentication token
  Future<String?> _getToken() async {
    return await _storage.read(key: 'auth_token');
  }

  /// Fetch attendance summary for a profile
  Future<void> fetchSummary({
    required String profileId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      state = const AttendanceSummaryLoading();
      AppLogger.info('📊 Fetching attendance summary for profile: $profileId');

      final baseUrl = _baseUrl ?? AppConstants.fastApiBaseUrl;
      final token = await _getToken();
      
      if (token == null) {
        throw Exception('Authentication token not found');
      }

      var url = '$baseUrl/api/v1/attendance/summary/$profileId';
      
      final queryParams = <String, String>{};
      if (startDate != null) {
        queryParams['start_date'] = startDate.toIso8601String().split('T')[0];
      }
      if (endDate != null) {
        queryParams['end_date'] = endDate.toIso8601String().split('T')[0];
      }
      
      if (queryParams.isNotEmpty) {
        url += '?${queryParams.entries.map((e) => '${e.key}=${e.value}').join('&')}';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary = AttendanceSummary.fromJson(data);
        state = AttendanceSummaryLoaded(summary);
        AppLogger.info('✅ Attendance summary loaded successfully');
      } else {
        throw Exception('Failed to load attendance summary: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching attendance summary', e, stackTrace);
      state = AttendanceSummaryError(e.toString());
    }
  }

  /// Refresh summary
  Future<void> refresh({
    required String profileId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await fetchSummary(
      profileId: profileId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

/// Attendance summary provider
final attendanceSummaryProvider = StateNotifierProvider.autoDispose<
    AttendanceSummaryNotifier, AttendanceSummaryState>((ref) {
  // Always use AppConstants.fastApiBaseUrl
  return AttendanceSummaryNotifier(ref, null);
});

/// Auto-fetch dashboard stats when user is authenticated
final autoDashboardStatsProvider = Provider<void>((ref) {
  final authState = ref.watch(authProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (authState is AuthAuthenticated && currentUser != null) {
    if (currentUser.companyId != null) {
      // Trigger dashboard stats fetch
      Future.microtask(() {
        ref.read(dashboardStatsProvider.notifier).fetchStats(
              companyId: currentUser.companyId!,
            );
      });
    }
  }
});
