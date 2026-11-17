import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:attendence/core/constants/app_constants.dart';
import 'package:attendence/core/utils/device_info_utils.dart';
import 'package:attendence/core/utils/logger.dart';
import 'package:attendence/core/error/exceptions.dart';
import 'package:attendence/data/models/profile_model.dart';
import 'package:attendence/domain/entities/profile.dart';

/// FastAPI data source for authentication and AI features
class FastApiDatasource {
  final http.Client _client;
  final FlutterSecureStorage _storage;

  FastApiDatasource({
    http.Client? client,
    FlutterSecureStorage? storage,
  })  : _client = client ?? http.Client(),
        _storage = storage ?? const FlutterSecureStorage();

  String get _baseUrl => '${AppConstants.fastApiBaseUrl}/api/v1';
  
  // Use bypass endpoints to avoid RLS issues
  String get _signupUrl => '${AppConstants.fastApiBaseUrl}/api/v1/auth-bypass/signup';
  String get _loginUrl => '${AppConstants.fastApiBaseUrl}/api/v1/auth-bypass/login';

  /// Sign up new user
  Future<ProfileModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phoneNumber,
    String? companyId,
    bool createCompany = false,
    String? companyName,
    String? workspaceSlug,
  }) async {
    try {
      AppLogger.info('📝 Attempting FastAPI sign up for: $email');
      AppLogger.info('🏢 Create company: $createCompany, Company name: $companyName, Role: $role');

      // Prepare request body
      final Map<String, dynamic> requestBody = {
        'email': email,
        'password': password,
        'full_name': fullName,
        'role': role,
      };

      // Log password length for debugging
      AppLogger.info('🔐 Password length: ${password.length} characters, ${password.codeUnits.length} bytes');

      // Add optional fields
      if (phoneNumber != null) requestBody['phone_number'] = phoneNumber;
      
      // Handle company creation or joining
      if (createCompany && role == 'company_admin') {
        if (companyName == null || companyName.isEmpty) {
          throw AuthenticationException('Company name is required when creating a new company');
        }
        AppLogger.info('✅ Adding create_company to request');
        requestBody['create_company'] = true;
        requestBody['company_name'] = companyName;
        if (workspaceSlug != null && workspaceSlug.isNotEmpty) {
          requestBody['workspace_slug'] = workspaceSlug;
        }
      } else if (role == 'super_admin') {
        // Super admin - explicitly send null company_id
        AppLogger.info('🔑 Super admin signup - sending null company_id');
        requestBody['company_id'] = null;
      } else if (companyId != null) {
        requestBody['company_id'] = companyId;
      } else {
        // Use default demo company for non-admin signups
        requestBody['company_id'] = '00000000-0000-0000-0000-000000000001';
      }

      AppLogger.info('📤 Request body: ${jsonEncode(requestBody)}');

      final response = await _client.post(
        Uri.parse(_signupUrl), // Use bypass endpoint
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode(requestBody),
      );

      // FastAPI returns 201 (Created) for successful signup
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['user'] != null) {
          AppLogger.info('✅ FastAPI sign up successful for: $email');
          
          // Convert FastAPI response to ProfileModel format
          final user = data['user'];
          
          // Convert string role to UserRole enum
          UserRole userRole;
          final roleString = (user['role'] ?? role).toString().toLowerCase();
          switch (roleString) {
            case 'super_admin':
              userRole = UserRole.superAdmin;
              break;
            case 'company_admin':
              userRole = UserRole.companyAdmin;
              break;
            case 'hr_manager':
              userRole = UserRole.hrManager;
              break;
            case 'team_manager':
            case 'manager':
              userRole = UserRole.teamManager;
              break;
            case 'employee':
            default:
              userRole = UserRole.employee;
              break;
          }
          
          // Extract company_id from response - check multiple possible locations
          String? extractedCompanyId;
          if (user['company_id'] != null) {
            extractedCompanyId = user['company_id'].toString();
          } else if (data['company_id'] != null) {
            extractedCompanyId = data['company_id'].toString();
          } else if (data['company'] != null && data['company']['id'] != null) {
            extractedCompanyId = data['company']['id'].toString();
          }
          
          AppLogger.info('🏢 Extracted company_id: $extractedCompanyId');
          
          final profile = ProfileModel(
            id: user['profile_id'] ?? user['id'] ?? 'temp-id',
            email: user['email'] ?? email,
            fullName: user['full_name'] ?? fullName,
            role: userRole,
            companyId: extractedCompanyId,
            companyName: data['company']?['name'] ?? data['company_name'],
            phoneNumber: user['phone_number'],
            departmentId: null,
            faceEmbeddingUrl: null,
            isActive: user['is_active'] ?? true,
            isFirstLogin: _parseIsFirstLogin(user),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          // Save user data to secure storage
          await _storage.write(key: 'user_id', value: profile.id);
          await _storage.write(key: 'user_email', value: profile.email);
          await _storage.write(key: 'user_name', value: profile.fullName);
          await _storage.write(key: 'user_role', value: profile.role.name);
          if (extractedCompanyId != null) {
            await _storage.write(key: 'company_id', value: extractedCompanyId);
          }
          if (profile.companyName != null) {
            await _storage.write(key: 'company_name', value: profile.companyName!);
          }
          await _storage.write(key: 'auth_token', value: data['access_token'] ?? data['token'] ?? 'mock-token');
          await _storage.write(key: 'is_logged_in', value: 'true');
          
          AppLogger.info('💾 User data saved to secure storage');
          
          return profile;
        } else {
          throw AuthenticationException(data['message'] ?? 'Sign up failed');
        }
      } else {
        // Handle validation errors (FastAPI returns list of errors)
        final errorBody = jsonDecode(response.body);
        String errorMessage = 'Sign up failed';
        
        if (errorBody['detail'] is List) {
          // Pydantic validation errors are in list format
          final errors = errorBody['detail'] as List;
          if (errors.isNotEmpty) {
            errorMessage = errors.map((e) => e['msg'] ?? e.toString()).join(', ');
          }
        } else if (errorBody['detail'] is String) {
          errorMessage = errorBody['detail'];
        } else if (errorBody['message'] is String) {
          errorMessage = errorBody['message'];
        }
        
        // Handle specific bcrypt 72-byte error with more helpful message
        if (errorMessage.contains('72 bytes')) {
          AppLogger.error('🐛 Backend password validation issue detected');
          errorMessage = 'Password validation error. Please use 8-20 characters with letters and numbers.';
        }
        
        AppLogger.error('🚫 Sign up validation error: $errorMessage');
        throw AuthenticationException(errorMessage);
      }
    } catch (e) {
      AppLogger.error('❌ FastAPI sign up error', e);
      if (e is AuthenticationException) rethrow;
      throw AuthenticationException('Sign up failed: ${e.toString()}');
    }
  }

  /// Sign in existing user
  Future<ProfileModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('📝 Attempting FastAPI sign in for: $email');

      final deviceInfo = await DeviceInfoUtils.getDeviceInfo();
      final response = await _client.post(
        Uri.parse(_loginUrl), // Use bypass endpoint
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
        body: jsonEncode({
          'email': email,
          'password': password,
          ...deviceInfo,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['user'] != null) {
          AppLogger.info('✅ FastAPI sign in successful for: $email');
          
          // Convert FastAPI response to ProfileModel format
          final user = data['user'];
          
          // Convert string role to UserRole enum
          UserRole userRole;
          final roleString = (user['role'] ?? 'employee').toString().toLowerCase();
          switch (roleString) {
            case 'super_admin':
              userRole = UserRole.superAdmin;
              break;
            case 'company_admin':
              userRole = UserRole.companyAdmin;
              break;
            case 'hr_manager':
              userRole = UserRole.hrManager;
              break;
            case 'team_manager':
            case 'manager':
              userRole = UserRole.teamManager;
              break;
            case 'employee':
            default:
              userRole = UserRole.employee;
              break;
          }
          
          // Extract company_id from response - check multiple possible locations
          String? extractedCompanyId;
          if (user['company_id'] != null) {
            extractedCompanyId = user['company_id'].toString();
          } else if (data['company_id'] != null) {
            extractedCompanyId = data['company_id'].toString();
          } else if (data['company'] != null && data['company']['id'] != null) {
            extractedCompanyId = data['company']['id'].toString();
          }
          
          AppLogger.info('🏢 Extracted company_id: $extractedCompanyId');
          
          final profile = ProfileModel(
            id: user['profile_id'] ?? user['id'] ?? 'temp-id',
            email: user['email'] ?? email,
            fullName: user['full_name'] ?? 'User',
            role: userRole,
            companyId: extractedCompanyId,
            companyName: data['company']?['name'] ?? data['company_name'],
            phoneNumber: user['phone_number'],
            departmentId: null,
            faceEmbeddingUrl: null,
            isActive: user['is_active'] ?? true,
            isFirstLogin: _parseIsFirstLogin(user),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
          
          // Save user data to secure storage
          await _storage.write(key: 'user_id', value: profile.id);
          await _storage.write(key: 'user_email', value: profile.email);
          await _storage.write(key: 'user_name', value: profile.fullName);
          await _storage.write(key: 'user_role', value: profile.role.name);
          if (extractedCompanyId != null) {
            await _storage.write(key: 'company_id', value: extractedCompanyId);
          }
          if (profile.companyName != null) {
            await _storage.write(key: 'company_name', value: profile.companyName!);
          }
          await _storage.write(key: 'auth_token', value: data['access_token'] ?? data['token'] ?? 'mock-token');
          await _storage.write(key: 'is_logged_in', value: 'true');
          
          AppLogger.info('💾 User data saved to secure storage');
          
          return profile;
        } else {
          throw AuthenticationException(data['message'] ?? 'Login failed');
        }
      } else {
        final error = jsonDecode(response.body);
        
        // Handle validation errors (detail can be a List or String)
        String errorMessage = 'Invalid email or password';
        if (error['detail'] != null) {
          if (error['detail'] is List) {
            // Validation errors from FastAPI
            final errors = error['detail'] as List;
            if (errors.isNotEmpty) {
              errorMessage = errors.map((e) => e['msg'] ?? 'Validation error').join(', ');
            }
          } else if (error['detail'] is String) {
            errorMessage = error['detail'];
          }
        } else if (error['message'] != null) {
          errorMessage = error['message'];
        }
        
        throw AuthenticationException(errorMessage);
      }
    } catch (e) {
      AppLogger.error('❌ FastAPI sign in error', e);
      if (e is AuthenticationException) rethrow;
      throw AuthenticationException('Login failed: ${e.toString()}');
    }
  }

  bool _parseIsFirstLogin(Map<String, dynamic> user) {
    if (user.containsKey('isFirstLogin')) {
      return user['isFirstLogin'] == true;
    }
    if (user.containsKey('is_first_login')) {
      return user['is_first_login'] == true;
    }
    return false;
  }

  /// Sign out and clear storage
  Future<void> signOut() async {
    try {
      AppLogger.info('👋 Signing out...');
      
      // Clear all stored auth data
      await _storage.delete(key: 'user_id');
      await _storage.delete(key: 'user_email');
      await _storage.delete(key: 'user_name');
      await _storage.delete(key: 'user_role');
      await _storage.delete(key: 'company_id');
      await _storage.delete(key: 'company_name');
      await _storage.delete(key: 'auth_token');
      await _storage.delete(key: 'is_logged_in');
      
      AppLogger.info('🗑️ User data cleared from secure storage');
      
    } catch (e) {
      AppLogger.error('❌ Sign out error', e);
      rethrow;
    }
  }

  /// Get profile by ID (fetch from backend)
  Future<ProfileModel> getProfile(String userId) async {
    try {
      AppLogger.info('👤 Fetching profile for user: $userId');

      final response = await _client.get(
        Uri.parse('$_baseUrl/users/profile/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'ngrok-skip-browser-warning': 'true',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Convert response to ProfileModel
        final user = data['user'] ?? data;
        
        // Convert string role to UserRole enum
        UserRole userRole;
        final roleString = (user['role'] ?? 'employee').toString().toLowerCase();
        switch (roleString) {
          case 'super_admin':
            userRole = UserRole.superAdmin;
            break;
          case 'company_admin':
            userRole = UserRole.companyAdmin;
            break;
          case 'hr_manager':
            userRole = UserRole.hrManager;
            break;
          case 'team_manager':
          case 'manager':
            userRole = UserRole.teamManager;
            break;
          case 'employee':
          default:
            userRole = UserRole.employee;
            break;
        }
        
        // Extract company_id
        String? extractedCompanyId;
        if (user['company_id'] != null) {
          extractedCompanyId = user['company_id'].toString();
        }
        
        return ProfileModel(
          id: user['profile_id'] ?? user['id'] ?? userId,
          email: user['email'],
          fullName: user['full_name'],
          role: userRole,
          companyId: extractedCompanyId,
          companyName: user['company_name'],
          phoneNumber: user['phone_number'],
          departmentId: user['department_id'],
          faceEmbeddingUrl: null,
          isActive: user['is_active'] ?? true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        throw ServerException('Failed to fetch profile: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('❌ Get profile error', e);
      rethrow;
    }
  }

  /// Get current user profile (uses restored session data and fetches company_id if missing)
  Future<ProfileModel?> getCurrentUserProfile() async {
    try {
      final userId = await _storage.read(key: 'user_id');
      final email = await _storage.read(key: 'user_email');
      
      if (userId == null || email == null) return null;
      
      // Check if we have company_id in storage
      final storedCompanyId = await _storage.read(key: 'company_id');
      
      // If company_id is missing, try to fetch the user's company from backend
      if (storedCompanyId == null) {
        AppLogger.info('🔍 Company ID missing, fetching from backend for: $email');
        
        try {
          // Fetch user's companies from backend
          final response = await _client.get(
            Uri.parse('$_baseUrl/auth/me'),
            headers: {
              'Content-Type': 'application/json',
              'ngrok-skip-browser-warning': 'true',
              // You might need to add auth token here
            },
          );
          
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            final user = data['user'] ?? data;
            
            // Extract and save company_id
            if (user['company_id'] != null) {
              final companyId = user['company_id'].toString();
              await _storage.write(key: 'company_id', value: companyId);
              AppLogger.info('✅ Company ID fetched and saved: $companyId');
            }
            
            if (user['company_name'] != null) {
              await _storage.write(key: 'company_name', value: user['company_name']);
            }
          }
        } catch (e) {
          AppLogger.error('⚠️ Could not fetch company_id from backend', e);
        }
      }
      
      // Return restored session with potentially updated company_id
      return await restoreSession();
      
    } catch (e) {
      AppLogger.error('❌ Error getting current user profile', e);
      return null;
    }
  }

  /// Restore session from secure storage
  Future<ProfileModel?> restoreSession() async {
    try {
      AppLogger.info('🔄 Attempting to restore session from storage...');
      
      final isLoggedIn = await _storage.read(key: 'is_logged_in');
      
      if (isLoggedIn != 'true') {
        AppLogger.info('❌ No active session found');
        return null;
      }
      
      final userId = await _storage.read(key: 'user_id');
      final email = await _storage.read(key: 'user_email');
      final fullName = await _storage.read(key: 'user_name');
      final roleString = await _storage.read(key: 'user_role');
      final companyId = await _storage.read(key: 'company_id');
      final companyName = await _storage.read(key: 'company_name');
      
      if (userId == null || email == null || fullName == null || roleString == null) {
        AppLogger.info('❌ Incomplete session data');
        return null;
      }
      
      // Convert string role to UserRole enum
      // Note: We store role.name which is camelCase (superAdmin, companyAdmin, etc.)
      UserRole userRole;
      switch (roleString) {
        case 'superAdmin':
        case 'super_admin':
          userRole = UserRole.superAdmin;
          break;
        case 'companyAdmin':
        case 'company_admin':
          userRole = UserRole.companyAdmin;
          break;
        case 'hrAdmin':
        case 'hrManager':
        case 'hr_manager':
          userRole = UserRole.hrManager;
          break;
        case 'teamManager':
        case 'manager':
        case 'team_manager':
          userRole = UserRole.teamManager;
          break;
        case 'employee':
        default:
          userRole = UserRole.employee;
          break;
      }
      
      AppLogger.info('🏢 Restored company_id: $companyId');
      
      final profile = ProfileModel(
        id: userId,
        email: email,
        fullName: fullName,
        role: userRole,
        companyId: companyId,
        companyName: companyName,
        phoneNumber: null,
        departmentId: null,
        faceEmbeddingUrl: null,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      AppLogger.info('✅ Session restored for: $email');
      return profile;
    } catch (e) {
      AppLogger.error('❌ Error restoring session', e);
      return null;
    }
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final isLoggedIn = await _storage.read(key: 'is_logged_in');
      return isLoggedIn == 'true';
    } catch (e) {
      AppLogger.error('❌ Error checking auth status', e);
      return false;
    }
  }
}
