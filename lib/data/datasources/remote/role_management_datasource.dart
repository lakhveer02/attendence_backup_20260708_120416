import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:attendence/core/constants/app_constants.dart';
import 'package:attendence/core/utils/logger.dart';
import 'package:attendence/core/error/exceptions.dart';

/// Role Management Data Source
/// Handles role-based employee creation with hierarchy validation
class RoleManagementDatasource {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  RoleManagementDatasource({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  String get _baseUrl => '${AppConstants.fastApiBaseUrl}/api/v1/role-management';

  /// Get authorization header with token
  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'auth_token');
    return {
      'Content-Type': 'application/json',
      'ngrok-skip-browser-warning': 'true',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Get allowed roles for current user
  Future<Map<String, dynamic>> getAllowedRoles() async {
    try {
      AppLogger.info('📋 Fetching allowed roles for current user');

      final response = await _client.get(
        Uri.parse('$_baseUrl/allowed-roles'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info('✅ Allowed roles fetched: ${data['allowed_roles']}');
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(error['detail'] ?? 'Failed to fetch allowed roles');
      }
    } catch (e) {
      AppLogger.error('❌ Get allowed roles error', e);
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get allowed roles: ${e.toString()}');
    }
  }

  /// Create new employee with role-based validation
  Future<Map<String, dynamic>> createEmployee({
    required String email,
    required String fullName,
    required String role,
    String? phoneNumber,
    String? departmentId,
    String? designation,
    String? employeeId,
    bool sendInvitationEmail = true,
  }) async {
    try {
      AppLogger.info('👤 Creating employee: $email as $role');

      final requestBody = {
        'email': email,
        'full_name': fullName,
        'role': role,
        'send_invitation_email': sendInvitationEmail,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (departmentId != null) 'department_id': departmentId,
        if (designation != null) 'designation': designation,
        if (employeeId != null) 'employee_id': employeeId,
      };

      final response = await _client.post(
        Uri.parse('$_baseUrl/create-employee'),
        headers: await _getHeaders(),
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info('✅ Employee created successfully: $email');
        return data;
      } else {
        final error = jsonDecode(response.body);
        
        // Extract error message
        String errorMessage = 'Failed to create employee';
        if (error['detail'] is String) {
          errorMessage = error['detail'];
        } else if (error['detail'] is List) {
          final errors = error['detail'] as List;
          if (errors.isNotEmpty) {
            errorMessage = errors.map((e) => e['msg'] ?? e.toString()).join(', ');
          }
        }
        
        AppLogger.error('🚫 Employee creation failed: $errorMessage');
        throw ServerException(errorMessage);
      }
    } catch (e) {
      AppLogger.error('❌ Create employee error', e);
      if (e is ServerException) rethrow;
      throw ServerException('Failed to create employee: ${e.toString()}');
    }
  }

  /// Get list of employees with optional filters
  Future<Map<String, dynamic>> getEmployees({
    String? role,
    String? departmentId,
    bool? isActive,
  }) async {
    try {
      AppLogger.info('📋 Fetching employees list');

      // Build query parameters
      final queryParams = <String, String>{};
      if (role != null) queryParams['role'] = role;
      if (departmentId != null) queryParams['department_id'] = departmentId;
      if (isActive != null) queryParams['is_active'] = isActive.toString();

      final uri = Uri.parse('$_baseUrl/employees').replace(queryParameters: queryParams);

      final response = await _client.get(
        uri,
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info('✅ Employees fetched: ${data['count']} employees');
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(error['detail'] ?? 'Failed to fetch employees');
      }
    } catch (e) {
      AppLogger.error('❌ Get employees error', e);
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get employees: ${e.toString()}');
    }
  }

  /// Toggle employee status (activate/deactivate)
  Future<Map<String, dynamic>> toggleEmployeeStatus(String employeeId) async {
    try {
      AppLogger.info('🔄 Toggling status for employee: $employeeId');

      final response = await _client.put(
        Uri.parse('$_baseUrl/employees/$employeeId/toggle-status'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info('✅ Employee status toggled successfully');
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(error['detail'] ?? 'Failed to toggle employee status');
      }
    } catch (e) {
      AppLogger.error('❌ Toggle employee status error', e);
      if (e is ServerException) rethrow;
      throw ServerException('Failed to toggle employee status: ${e.toString()}');
    }
  }

  /// Get role hierarchy information
  Future<Map<String, dynamic>> getRoleHierarchy() async {
    try {
      AppLogger.info('📊 Fetching role hierarchy');

      final response = await _client.get(
        Uri.parse('$_baseUrl/role-hierarchy'),
        headers: await _getHeaders(),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        AppLogger.info('✅ Role hierarchy fetched');
        return data;
      } else {
        final error = jsonDecode(response.body);
        throw ServerException(error['detail'] ?? 'Failed to fetch role hierarchy');
      }
    } catch (e) {
      AppLogger.error('❌ Get role hierarchy error', e);
      if (e is ServerException) rethrow;
      throw ServerException('Failed to get role hierarchy: ${e.toString()}');
    }
  }
}
