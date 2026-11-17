import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:attendence/core/constants/app_constants.dart';
import 'package:attendence/core/error/exceptions.dart';
import 'package:attendence/core/utils/logger.dart';
import 'package:attendence/domain/entities/attendance.dart';
import 'package:attendence/data/models/attendance_model.dart';

/// PRODUCTION-READY ATTENDANCE REMOTE DATA SOURCE
/// Handles all HTTP communication with FastAPI backend
/// Implements multipart uploads, JWT authentication, and comprehensive error handling
class AttendanceRemoteDataSource {
  final Dio dio;
  final FlutterSecureStorage storage;

  AttendanceRemoteDataSource({
    Dio? dio,
    FlutterSecureStorage? storage,
  })  : dio = dio ?? _createDio(),
        storage = storage ?? const FlutterSecureStorage();

  /// Create configured Dio instance
  static Dio _createDio() {
    final dio = Dio(BaseOptions(
      baseUrl: AppConstants.fastApiBaseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(minutes: 2), // For file uploads
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Add interceptors
    dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      error: true,
      logPrint: (object) => AppLogger.debug(object.toString()),
    ));

    return dio;
  }

  /// Get authentication token
  Future<String> _getToken() async {
    final token = await storage.read(key: 'auth_token');
    if (token == null || token.isEmpty) {
      throw AuthenticationException('No authentication token found');
    }
    return token;
  }

  /// Get current user ID
  Future<String> _getUserId() async {
    final userId = await storage.read(key: 'user_id');
    if (userId == null || userId.isEmpty) {
      throw AuthenticationException('No user ID found');
    }
    return userId;
  }

  /// Add authorization header
  Future<Map<String, dynamic>> _getAuthHeaders() async {
    final token = await _getToken();
    return {
      'Authorization': 'Bearer $token',
    };
  }

  /// Handle API errors
  Never _handleError(dynamic error, [String? context]) {
    AppLogger.error('API Error${context != null ? " in $context" : ""}', error);

    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        throw NetworkException(
          'Connection timeout. Please check your internet connection.',
        );
      }

      if (error.type == DioExceptionType.connectionError) {
        throw NetworkException(
          'Cannot connect to server. Please check your connection.',
        );
      }

      if (error.response != null) {
        final statusCode = error.response!.statusCode;
        final data = error.response!.data;

        String message = 'An error occurred';
        if (data is Map<String, dynamic>) {
          message = data['detail'] ?? data['message'] ?? message;
        }

        if (statusCode == 401) {
          throw AuthenticationException(message);
        } else if (statusCode == 403) {
          throw PermissionException(message);
        } else if (statusCode == 404) {
          throw NotFoundException(message);
        } else if (statusCode == 400) {
          throw ValidationException(message);
        } else if (statusCode != null && statusCode >= 500) {
          throw ServerException('Server error: $message');
        }

        throw ServerException(message);
      }

      throw NetworkException('Network error occurred');
    }

    if (error is SocketException) {
      throw NetworkException('No internet connection');
    }

    throw ServerException(error.toString());
  }

  // ==================== CHECK-IN ====================

  Future<AttendanceModel> checkIn({
    required String photoPath,
    required double latitude,
    required double longitude,
    required VerificationMethod verificationMethod,
    double? faceMatchConfidence,
    bool isWfh = false,
    String? notes,
  }) async {
    try {
      AppLogger.info('🚀 Data Source: Initiating check-in request');

      final userId = await _getUserId();
      final headers = await _getAuthHeaders();

      // Prepare multipart form data
      final formData = FormData.fromMap({
        'profile_id': userId,
        'latitude': latitude,
        'longitude': longitude,
        'verification_method': verificationMethod.name,
        'is_wfh': isWfh.toString(),
        if (faceMatchConfidence != null)
          'face_match_confidence': faceMatchConfidence,
        if (notes != null) 'notes': notes,
      });

      // Add photo file
      if (photoPath.isNotEmpty) {
        final file = File(photoPath);
        if (await file.exists()) {
          formData.files.add(MapEntry(
            'selfie',
            await MultipartFile.fromFile(
              photoPath,
              filename: 'check_in_${DateTime.now().millisecondsSinceEpoch}.jpg',
            ),
          ));
          AppLogger.info('📸 Photo added to upload: ${file.path}');
        } else {
          AppLogger.warning('⚠️ Photo file does not exist: $photoPath');
        }
      }

      AppLogger.info('📤 Sending check-in request...');

      final response = await dio.post(
        '/attendance/check-in',
        data: formData,
        options: Options(headers: headers),
      );

      AppLogger.info('✅ Check-in response received: ${response.statusCode}');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        return AttendanceModel.fromJson(data);
      } else {
        throw ServerException(
          'Unexpected response: ${response.statusCode}',
        );
      }
    } catch (e) {
      _handleError(e, 'checkIn');
    }
  }

  // ==================== CHECK-OUT ====================

  Future<AttendanceModel> checkOut({
    required String attendanceId,
    String? photoPath,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      AppLogger.info('🚀 Data Source: Initiating check-out request');

      final headers = await _getAuthHeaders();

      // Prepare data
      final data = {
        'attendance_id': attendanceId,
        if (latitude != null && longitude != null)
          'check_out_gps': {
            'latitude': latitude,
            'longitude': longitude,
          },
        if (notes != null) 'notes': notes,
      };

      AppLogger.info('📤 Sending check-out request...');

      final response = await dio.put(
        '/attendance/check-out',
        data: data,
        options: Options(headers: headers),
      );

      AppLogger.info('✅ Check-out response received: ${response.statusCode}');

      if (response.statusCode == 200) {
        final responseData = response.data as Map<String, dynamic>;
        return AttendanceModel.fromJson(responseData);
      } else {
        throw ServerException(
          'Unexpected response: ${response.statusCode}',
        );
      }
    } catch (e) {
      _handleError(e, 'checkOut');
    }
  }

  // ==================== GET TODAY'S ATTENDANCE ====================

  Future<AttendanceModel?> getTodayAttendance() async {
    try {
      AppLogger.info('🚀 Data Source: Fetching today\'s attendance');

      final userId = await _getUserId();
      final headers = await _getAuthHeaders();

      final response = await dio.get(
        '/attendance/today/$userId',
        options: Options(headers: headers),
      );

      AppLogger.info('✅ Today\'s attendance response: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.data == null) {
          return null;
        }
        return AttendanceModel.fromJson(response.data as Map<String, dynamic>);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw ServerException(
          'Unexpected response: ${response.statusCode}',
        );
      }
    } catch (e) {
      if (e is NotFoundException) {
        return null;
      }
      _handleError(e, 'getTodayAttendance');
    }
  }

  // ==================== GET ATTENDANCE HISTORY ====================

  Future<List<AttendanceModel>> getMyAttendanceHistory({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      AppLogger.info('🚀 Data Source: Fetching attendance history');

      final userId = await _getUserId();
      final headers = await _getAuthHeaders();

      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final response = await dio.get(
        '/attendance/$userId',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      AppLogger.info('✅ Attendance history response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((json) => AttendanceModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          'Unexpected response: ${response.statusCode}',
        );
      }
    } catch (e) {
      _handleError(e, 'getMyAttendanceHistory');
    }
  }

  // ==================== GET ALL ATTENDANCE (ADMIN) ====================

  Future<List<AttendanceModel>> getAllAttendance({
    DateTime? date,
    String? profileId,
    AttendanceStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      AppLogger.info('🚀 Data Source: Fetching all attendance (Admin)');

      final headers = await _getAuthHeaders();

      final queryParams = <String, dynamic>{
        'page': page,
        'page_size': pageSize,
        if (date != null) 'date': date.toIso8601String(),
        if (profileId != null) 'profile_id': profileId,
        if (status != null) 'status': status.name,
      };

      final response = await dio.get(
        '/attendance/all',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      AppLogger.info('✅ All attendance response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data
            .map((json) => AttendanceModel.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ServerException(
          'Unexpected response: ${response.statusCode}',
        );
      }
    } catch (e) {
      _handleError(e, 'getAllAttendance');
    }
  }

  // ==================== GET ATTENDANCE BY ID ====================

  Future<AttendanceModel> getAttendanceById(String attendanceId) async {
    try {
      AppLogger.info('🚀 Data Source: Fetching attendance by ID');

      final headers = await _getAuthHeaders();

      final response = await dio.get(
        '/attendance/$attendanceId',
        options: Options(headers: headers),
      );

      AppLogger.info('✅ Attendance response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return AttendanceModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          'Unexpected response: ${response.statusCode}',
        );
      }
    } catch (e) {
      _handleError(e, 'getAttendanceById');
    }
  }

  // ==================== UPDATE ATTENDANCE STATUS (ADMIN) ====================

  Future<AttendanceModel> updateAttendanceStatus({
    required String attendanceId,
    required AttendanceStatus status,
    String? notes,
  }) async {
    try {
      AppLogger.info('🚀 Data Source: Updating attendance status');

      final headers = await _getAuthHeaders();

      final data = {
        'status': status.name,
        if (notes != null) 'notes': notes,
      };

      final response = await dio.put(
        '/attendance/$attendanceId/status',
        data: data,
        options: Options(headers: headers),
      );

      AppLogger.info('✅ Update status response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return AttendanceModel.fromJson(response.data as Map<String, dynamic>);
      } else {
        throw ServerException(
          'Unexpected response: ${response.statusCode}',
        );
      }
    } catch (e) {
      _handleError(e, 'updateAttendanceStatus');
    }
  }

  // ==================== WATCH TODAY'S ATTENDANCE (STREAM) ====================

  Stream<List<AttendanceModel>> watchTodayAttendance() async* {
    // For real-time updates, we can poll or use WebSockets
    // This implementation uses polling every 30 seconds
    while (true) {
      try {
        final userId = await _getUserId();
        final headers = await _getAuthHeaders();

        final response = await dio.get(
          '/attendance/$userId',
          queryParameters: {
            'start_date': DateTime.now().toIso8601String(),
            'page_size': 50,
          },
          options: Options(headers: headers),
        );

        if (response.statusCode == 200) {
          final List<dynamic> data = response.data as List<dynamic>;
          final attendanceList = data
              .map((json) => AttendanceModel.fromJson(json as Map<String, dynamic>))
              .toList();
          yield attendanceList;
        }
      } catch (e) {
        AppLogger.error('Error in attendance stream', e);
        yield [];
      }

      // Wait 30 seconds before next poll
      await Future.delayed(const Duration(seconds: 30));
    }
  }

  // ==================== GET ATTENDANCE STATISTICS ====================

  Future<Map<String, dynamic>> getAttendanceStats({
    DateTime? startDate,
    DateTime? endDate,
    String? profileId,
  }) async {
    try {
      AppLogger.info('🚀 Data Source: Fetching attendance statistics');

      final userId = profileId ?? await _getUserId();
      final headers = await _getAuthHeaders();

      final queryParams = <String, dynamic>{
        if (startDate != null) 'start_date': startDate.toIso8601String(),
        if (endDate != null) 'end_date': endDate.toIso8601String(),
      };

      final response = await dio.get(
        '/attendance/summary/$userId',
        queryParameters: queryParams,
        options: Options(headers: headers),
      );

      AppLogger.info('✅ Statistics response: ${response.statusCode}');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      } else {
        throw ServerException(
          'Unexpected response: ${response.statusCode}',
        );
      }
    } catch (e) {
      _handleError(e, 'getAttendanceStats');
    }
  }
}
