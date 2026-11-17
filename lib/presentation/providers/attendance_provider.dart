import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:attendence/data/models/attendance_model.dart';
import 'package:attendence/core/constants/app_constants.dart';
import 'package:attendence/core/utils/logger.dart';
import 'package:attendence/presentation/providers/auth_provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

/// GPS Location model
class GPSLocation {
  final double latitude;
  final double longitude;
  final double? accuracy;

  const GPSLocation({
    required this.latitude,
    required this.longitude,
    this.accuracy,
  });

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        if (accuracy != null) 'accuracy': accuracy,
      };
}

/// Check-in request
class CheckInRequest {
  final String profileId;
  final GPSLocation checkInGps;
  final String verificationMethod;
  final String? deviceId;
  final String? deviceModel;
  final String? deviceOs;
  final bool isWfh;
  final String? wfhReason;
  final String? notes;
  final File? selfieImage;

  const CheckInRequest({
    required this.profileId,
    required this.checkInGps,
    required this.verificationMethod,
    this.deviceId,
    this.deviceModel,
    this.deviceOs,
    this.isWfh = false,
    this.wfhReason,
    this.notes,
    this.selfieImage,
  });
}

/// Check-out request
class CheckOutRequest {
  final String attendanceId;
  final GPSLocation checkOutGps;
  final String? notes;

  const CheckOutRequest({
    required this.attendanceId,
    required this.checkOutGps,
    this.notes,
  });
}

/// Today's attendance state
sealed class TodayAttendanceState {
  const TodayAttendanceState();
}

class TodayAttendanceInitial extends TodayAttendanceState {
  const TodayAttendanceInitial();
}

class TodayAttendanceLoading extends TodayAttendanceState {
  const TodayAttendanceLoading();
}

class TodayAttendanceLoaded extends TodayAttendanceState {
  final AttendanceModel? attendance;
  const TodayAttendanceLoaded(this.attendance);
}

class TodayAttendanceError extends TodayAttendanceState {
  final String message;
  const TodayAttendanceError(this.message);
}

/// Check-in/Check-out operation state
sealed class AttendanceOperationState {
  const AttendanceOperationState();
}

class AttendanceOperationIdle extends AttendanceOperationState {
  const AttendanceOperationIdle();
}

class AttendanceOperationInProgress extends AttendanceOperationState {
  const AttendanceOperationInProgress();
}

class AttendanceOperationSuccess extends AttendanceOperationState {
  final String message;
  const AttendanceOperationSuccess(this.message);
}

class AttendanceOperationError extends AttendanceOperationState {
  final String message;
  const AttendanceOperationError(this.message);
}

/// Today's attendance notifier
class TodayAttendanceNotifier extends StateNotifier<TodayAttendanceState> {
  final String? _baseUrl;

  TodayAttendanceNotifier(this._baseUrl) : super(const TodayAttendanceInitial());

  /// Fetch today's attendance
  Future<void> fetchTodayAttendance({required String profileId}) async {
    try {
      state = const TodayAttendanceLoading();
      AppLogger.info('📅 Fetching today\'s attendance for profile: $profileId');

      final baseUrl = _baseUrl ?? 'http://localhost:8000';
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/attendance/today/$profileId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data == null) {
          state = const TodayAttendanceLoaded(null);
          AppLogger.info('ℹ️ No attendance record for today');
        } else {
          final attendance = AttendanceModel.fromJson(data);
          state = TodayAttendanceLoaded(attendance);
          AppLogger.info('✅ Today\'s attendance loaded');
        }
      } else if (response.statusCode == 404) {
        state = const TodayAttendanceLoaded(null);
      } else {
        throw Exception('Failed to load today\'s attendance: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching today\'s attendance', e, stackTrace);
      state = TodayAttendanceError(e.toString());
    }
  }

  /// Refresh today's attendance
  Future<void> refresh({required String profileId}) async {
    await fetchTodayAttendance(profileId: profileId);
  }
}

/// Today's attendance provider
final todayAttendanceProvider = StateNotifierProvider.autoDispose<
    TodayAttendanceNotifier, TodayAttendanceState>((ref) {
  const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  return TodayAttendanceNotifier(baseUrl.isEmpty ? AppConstants.fastApiBaseUrl : baseUrl);
});

/// Attendance operation notifier
class AttendanceOperationNotifier extends StateNotifier<AttendanceOperationState> {
  final String? _baseUrl;
  final Ref _ref;

  AttendanceOperationNotifier(this._ref, this._baseUrl) : super(const AttendanceOperationIdle());

  /// Check in
  Future<bool> checkIn(CheckInRequest request) async {
    try {
      state = const AttendanceOperationInProgress();
      AppLogger.info('✅ Checking in...');

      final baseUrl = _baseUrl ?? 'http://localhost:8000';
      
      // Prepare multipart request if selfie is provided
      if (request.selfieImage != null) {
        var multipartRequest = http.MultipartRequest(
          'POST',
          Uri.parse('$baseUrl/api/v1/attendance/check-in'),
        );

        // Add fields
        multipartRequest.fields['profile_id'] = request.profileId;
        multipartRequest.fields['verification_method'] = request.verificationMethod;
        multipartRequest.fields['is_wfh'] = request.isWfh.toString();
        multipartRequest.fields['check_in_gps'] = jsonEncode(request.checkInGps.toJson());
        
        if (request.deviceId != null) multipartRequest.fields['device_id'] = request.deviceId!;
        if (request.deviceModel != null) multipartRequest.fields['device_model'] = request.deviceModel!;
        if (request.deviceOs != null) multipartRequest.fields['device_os'] = request.deviceOs!;
        if (request.wfhReason != null) multipartRequest.fields['wfh_reason'] = request.wfhReason!;
        if (request.notes != null) multipartRequest.fields['notes'] = request.notes!;

        // Add selfie file
        multipartRequest.files.add(
          await http.MultipartFile.fromPath('selfie', request.selfieImage!.path),
        );

        final streamedResponse = await multipartRequest.send();
        final response = await http.Response.fromStream(streamedResponse);

        if (response.statusCode == 201) {
          state = const AttendanceOperationSuccess('Check-in successful!');
          AppLogger.info('✅ Check-in successful');
          
          // Refresh today's attendance
          final currentUser = _ref.read(currentUserProvider);
          if (currentUser != null) {
            await _ref.read(todayAttendanceProvider.notifier).refresh(profileId: currentUser.id);
          }
          
          // Reset to idle after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            state = const AttendanceOperationIdle();
          });
          
          return true;
        } else {
          final error = jsonDecode(response.body);
          throw Exception(error['detail'] ?? 'Check-in failed');
        }
      } else {
        // Regular JSON request without selfie
        final response = await http.post(
          Uri.parse('$baseUrl/api/v1/attendance/check-in'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'request': {
              'profile_id': request.profileId,
              'check_in_gps': request.checkInGps.toJson(),
              'verification_method': request.verificationMethod,
              'device_id': request.deviceId,
              'device_model': request.deviceModel,
              'device_os': request.deviceOs,
              'is_wfh': request.isWfh,
              'wfh_reason': request.wfhReason,
              'notes': request.notes,
            },
          }),
        );

        if (response.statusCode == 201) {
          state = const AttendanceOperationSuccess('Check-in successful!');
          AppLogger.info('✅ Check-in successful');
          
          // Refresh today's attendance
          final currentUser = _ref.read(currentUserProvider);
          if (currentUser != null) {
            await _ref.read(todayAttendanceProvider.notifier).refresh(profileId: currentUser.id);
          }
          
          // Reset to idle after 2 seconds
          Future.delayed(const Duration(seconds: 2), () {
            state = const AttendanceOperationIdle();
          });
          
          return true;
        } else {
          final error = jsonDecode(response.body);
          throw Exception(error['detail'] ?? 'Check-in failed');
        }
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error during check-in', e, stackTrace);
      state = AttendanceOperationError(e.toString());
      
      // Reset to idle after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        state = const AttendanceOperationIdle();
      });
      
      return false;
    }
  }

  /// Check out
  Future<bool> checkOut(CheckOutRequest request) async {
    try {
      state = const AttendanceOperationInProgress();
      AppLogger.info('👋 Checking out...');

      final baseUrl = _baseUrl ?? 'http://localhost:8000';
      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/attendance/check-out'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'attendance_id': request.attendanceId,
          'check_out_gps': request.checkOutGps.toJson(),
          'notes': request.notes,
        }),
      );

      if (response.statusCode == 200) {
        state = const AttendanceOperationSuccess('Check-out successful!');
        AppLogger.info('✅ Check-out successful');
        
        // Refresh today's attendance
        final currentUser = _ref.read(currentUserProvider);
        if (currentUser != null) {
          await _ref.read(todayAttendanceProvider.notifier).refresh(profileId: currentUser.id);
        }
        
        // Reset to idle after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          state = const AttendanceOperationIdle();
        });
        
        return true;
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['detail'] ?? 'Check-out failed');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error during check-out', e, stackTrace);
      state = AttendanceOperationError(e.toString());
      
      // Reset to idle after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        state = const AttendanceOperationIdle();
      });
      
      return false;
    }
  }

  /// Reset state
  void reset() {
    state = const AttendanceOperationIdle();
  }
}

/// Attendance operation provider
final attendanceOperationProvider = StateNotifierProvider<
    AttendanceOperationNotifier, AttendanceOperationState>((ref) {
  const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  return AttendanceOperationNotifier(ref, baseUrl.isEmpty ? AppConstants.fastApiBaseUrl : baseUrl);
});

/// Attendance history state
sealed class AttendanceHistoryState {
  const AttendanceHistoryState();
}

class AttendanceHistoryInitial extends AttendanceHistoryState {
  const AttendanceHistoryInitial();
}

class AttendanceHistoryLoading extends AttendanceHistoryState {
  const AttendanceHistoryLoading();
}

class AttendanceHistoryLoaded extends AttendanceHistoryState {
  final List<AttendanceModel> records;
  const AttendanceHistoryLoaded(this.records);
}

class AttendanceHistoryError extends AttendanceHistoryState {
  final String message;
  const AttendanceHistoryError(this.message);
}

/// Attendance history notifier
class AttendanceHistoryNotifier extends StateNotifier<AttendanceHistoryState> {
  final String? _baseUrl;

  AttendanceHistoryNotifier(this._baseUrl) : super(const AttendanceHistoryInitial());

  /// Fetch attendance history
  Future<void> fetchHistory({
    required String profileId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      state = const AttendanceHistoryLoading();
      AppLogger.info('📜 Fetching attendance history for profile: $profileId');

      final baseUrl = _baseUrl ?? 'http://localhost:8000';
      var url = '$baseUrl/api/v1/attendance/$profileId';
      
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
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final records = data
            .map((json) => AttendanceModel.fromJson(json as Map<String, dynamic>))
            .toList();
        
        state = AttendanceHistoryLoaded(records);
        AppLogger.info('✅ Loaded ${records.length} attendance records');
      } else {
        throw Exception('Failed to load attendance history: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error fetching attendance history', e, stackTrace);
      state = AttendanceHistoryError(e.toString());
    }
  }

  /// Refresh history
  Future<void> refresh({
    required String profileId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    await fetchHistory(
      profileId: profileId,
      startDate: startDate,
      endDate: endDate,
    );
  }
}

/// Attendance history provider
final attendanceHistoryProvider = StateNotifierProvider.autoDispose<
    AttendanceHistoryNotifier, AttendanceHistoryState>((ref) {
  const baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: '');
  return AttendanceHistoryNotifier(baseUrl.isEmpty ? AppConstants.fastApiBaseUrl : baseUrl);
});

/// Auto-fetch today's attendance when user is authenticated
final autoTodayAttendanceProvider = Provider<void>((ref) {
  final authState = ref.watch(authProvider);
  final currentUser = ref.watch(currentUserProvider);

  if (authState is AuthAuthenticated && currentUser != null) {
    // Trigger today's attendance fetch
    Future.microtask(() {
      ref.read(todayAttendanceProvider.notifier).fetchTodayAttendance(
            profileId: currentUser.id,
          );
    });
  }
});

/// Check if user is checked in today
final isCheckedInTodayProvider = Provider<bool>((ref) {
  final todayAttendanceState = ref.watch(todayAttendanceProvider);
  
  if (todayAttendanceState is TodayAttendanceLoaded) {
    return todayAttendanceState.attendance != null;
  }
  
  return false;
});

/// Check if user is checked out today
final isCheckedOutTodayProvider = Provider<bool>((ref) {
  final todayAttendanceState = ref.watch(todayAttendanceProvider);
  
  if (todayAttendanceState is TodayAttendanceLoaded) {
    return todayAttendanceState.attendance?.checkOut != null;
  }
  
  return false;
});

/// Get today's attendance record
final todayAttendanceRecordProvider = Provider<AttendanceModel?>((ref) {
  final todayAttendanceState = ref.watch(todayAttendanceProvider);
  
  if (todayAttendanceState is TodayAttendanceLoaded) {
    return todayAttendanceState.attendance;
  }
  
  return null;
});
