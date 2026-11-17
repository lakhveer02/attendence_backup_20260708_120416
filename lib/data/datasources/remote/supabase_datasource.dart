import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendence/core/config/supabase_config.dart';
import 'package:attendence/core/error/exceptions.dart';
import 'package:attendence/core/utils/logger.dart';
import 'package:attendence/data/models/profile_model.dart';
import 'package:attendence/data/models/attendance_model.dart';

/// Supabase data source for database operations
class SupabaseDatasource {
  final SupabaseClient _client;

  SupabaseDatasource() : _client = SupabaseConfig.client;

  // ==================== AUTH OPERATIONS ====================

  /// Sign in with email and password
  Future<ProfileModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      AppLogger.info('🔐 Attempting sign in for: $email');

      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthenticationException('Sign in failed: No user returned');
      }

      // Fetch profile data
      final profile = await getProfile(response.user!.id);
      AppLogger.info('✅ Sign in successful for: $email');

      return profile;
    } on AuthException catch (e) {
      AppLogger.error('❌ Auth error during sign in', e);
      throw AuthenticationException(e.message);
    } catch (e) {
      AppLogger.error('❌ Unexpected error during sign in', e);
      throw AuthenticationException('Sign in failed: ${e.toString()}');
    }
  }

  /// Sign up new user
  Future<ProfileModel> signUp({
    required String email,
    required String password,
    required String fullName,
    required String role,
    String? phoneNumber,
    String? departmentId,
  }) async {
    try {
      AppLogger.info('📝 Attempting sign up for: $email');

      final response = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw AuthenticationException('Sign up failed: No user returned');
      }

      // Create profile
      final profileData = {
        'id': response.user!.id,
        'full_name': fullName,
        'email': email,
        'role': role,
        'phone_number': phoneNumber,
        'department_id': departmentId,
        'is_active': true,
      };

      await _client.from('profiles').insert(profileData);

      final profile = await getProfile(response.user!.id);
      AppLogger.info('✅ Sign up successful for: $email');

      return profile;
    } on AuthException catch (e) {
      AppLogger.error('❌ Auth error during sign up', e);
      throw AuthenticationException(e.message);
    } catch (e) {
      AppLogger.error('❌ Unexpected error during sign up', e);
      throw AuthenticationException('Sign up failed: ${e.toString()}');
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      AppLogger.info('👋 Signing out user');
      await _client.auth.signOut();
      AppLogger.info('✅ Sign out successful');
    } catch (e) {
      AppLogger.error('❌ Error during sign out', e);
      throw AuthenticationException('Sign out failed: ${e.toString()}');
    }
  }

  /// Get current user profile
  Future<ProfileModel?> getCurrentUserProfile() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;

      return await getProfile(user.id);
    } catch (e) {
      AppLogger.error('❌ Error getting current user profile', e);
      return null;
    }
  }

  /// Check if user is authenticated
  bool isAuthenticated() {
    return _client.auth.currentUser != null;
  }

  /// Reset password
  Future<void> resetPassword(String email) async {
    try {
      AppLogger.info('🔄 Sending password reset email to: $email');
      await _client.auth.resetPasswordForEmail(email);
      AppLogger.info('✅ Password reset email sent');
    } on AuthException catch (e) {
      AppLogger.error('❌ Auth error during password reset', e);
      throw AuthenticationException(e.message);
    } catch (e) {
      AppLogger.error('❌ Unexpected error during password reset', e);
      throw AuthenticationException('Password reset failed: ${e.toString()}');
    }
  }

  /// Update password
  Future<void> updatePassword(String newPassword) async {
    try {
      AppLogger.info('🔄 Updating password');
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
      AppLogger.info('✅ Password updated successfully');
    } on AuthException catch (e) {
      AppLogger.error('❌ Auth error during password update', e);
      throw AuthenticationException(e.message);
    } catch (e) {
      AppLogger.error('❌ Unexpected error during password update', e);
      throw AuthenticationException('Password update failed: ${e.toString()}');
    }
  }

  // ==================== PROFILE OPERATIONS ====================

  /// Get profile by ID
  Future<ProfileModel> getProfile(String profileId) async {
    try {
      final response = await _client
          .from('profiles')
          .select('''
            *,
            departments (
              id,
              name
            )
          ''')
          .eq('id', profileId)
          .single();

      // Map department name if exists
      if (response['departments'] != null) {
        response['department_name'] = response['departments']['name'];
      }

      return ProfileModel.fromJson(response);
    } catch (e) {
      AppLogger.error('❌ Error fetching profile', e);
      throw ServerException('Failed to fetch profile: ${e.toString()}');
    }
  }

  /// Update profile
  Future<ProfileModel> updateProfile({
    required String profileId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      AppLogger.info('🔄 Updating profile: $profileId');

      await _client
          .from('profiles')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', profileId);

      final profile = await getProfile(profileId);
      AppLogger.info('✅ Profile updated successfully');

      return profile;
    } catch (e) {
      AppLogger.error('❌ Error updating profile', e);
      throw ServerException('Failed to update profile: ${e.toString()}');
    }
  }

  /// Get all profiles (admin only)
  Future<List<ProfileModel>> getAllProfiles({
    String? departmentId,
    String? role,
  }) async {
    try {
      var query = _client.from('profiles').select('''
            *,
            departments (
              id,
              name
            )
          ''');

      if (departmentId != null) {
        query = query.eq('department_id', departmentId);
      }

      if (role != null) {
        query = query.eq('role', role);
      }

      final response = await query;

      return (response as List)
          .map((json) {
            if (json['departments'] != null) {
              json['department_name'] = json['departments']['name'];
            }
            return ProfileModel.fromJson(json);
          })
          .toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching profiles', e);
      throw ServerException('Failed to fetch profiles: ${e.toString()}');
    }
  }

  // ==================== ATTENDANCE OPERATIONS ====================

  /// Create attendance record
  Future<AttendanceModel> createAttendance({
    required Map<String, dynamic> attendanceData,
  }) async {
    try {
      AppLogger.info('📝 Creating attendance record');

      final response = await _client
          .from('attendance')
          .insert(attendanceData)
          .select()
          .single();

      AppLogger.info('✅ Attendance created successfully');
      return AttendanceModel.fromJson(response);
    } catch (e) {
      AppLogger.error('❌ Error creating attendance', e);
      throw ServerException('Failed to create attendance: ${e.toString()}');
    }
  }

  /// Update attendance record
  Future<AttendanceModel> updateAttendance({
    required String attendanceId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      AppLogger.info('🔄 Updating attendance: $attendanceId');

      final response = await _client
          .from('attendance')
          .update({...updates, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', attendanceId)
          .select()
          .single();

      AppLogger.info('✅ Attendance updated successfully');
      return AttendanceModel.fromJson(response);
    } catch (e) {
      AppLogger.error('❌ Error updating attendance', e);
      throw ServerException('Failed to update attendance: ${e.toString()}');
    }
  }

  /// Get attendance by ID
  Future<AttendanceModel> getAttendanceById(String attendanceId) async {
    try {
      final response = await _client
          .from('attendance')
          .select('''
            *,
            profiles (
              full_name,
              profile_picture_url
            )
          ''')
          .eq('id', attendanceId)
          .single();

      if (response['profiles'] != null) {
        response['profile_name'] = response['profiles']['full_name'];
        response['profile_picture_url'] =
            response['profiles']['profile_picture_url'];
      }

      return AttendanceModel.fromJson(response);
    } catch (e) {
      AppLogger.error('❌ Error fetching attendance', e);
      throw ServerException('Failed to fetch attendance: ${e.toString()}');
    }
  }

  /// Get attendance for a profile
  Future<List<AttendanceModel>> getAttendanceForProfile({
    required String profileId,
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      var queryBuilder = _client
          .from('attendance')
          .select('''
            *,
            profiles (
              full_name,
              profile_picture_url
            )
          ''')
          .eq('profile_id', profileId);

      if (startDate != null) {
        queryBuilder = queryBuilder.filter('check_in', 'gte', startDate.toIso8601String());
      }

      if (endDate != null) {
        queryBuilder = queryBuilder.filter('check_in', 'lte', endDate.toIso8601String());
      }

      // Order and pagination
      final offset = (page - 1) * pageSize;
      final response = await queryBuilder
          .order('check_in', ascending: false)
          .range(offset, offset + pageSize - 1);

      return (response as List).map((json) {
        if (json['profiles'] != null) {
          json['profile_name'] = json['profiles']['full_name'];
          json['profile_picture_url'] =
              json['profiles']['profile_picture_url'];
        }
        return AttendanceModel.fromJson(json);
      }).toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching attendance history', e);
      throw ServerException('Failed to fetch attendance history: ${e.toString()}');
    }
  }

  /// Get today's attendance for a profile
  Future<AttendanceModel?> getTodayAttendance(String profileId) async {
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final response = await _client
          .from('attendance')
          .select()
          .eq('profile_id', profileId)
          .gte('check_in', startOfDay.toIso8601String())
          .lt('check_in', endOfDay.toIso8601String())
          .maybeSingle();

      if (response == null) return null;

      return AttendanceModel.fromJson(response);
    } catch (e) {
      AppLogger.error('❌ Error fetching today attendance', e);
      throw ServerException('Failed to fetch today attendance: ${e.toString()}');
    }
  }

  /// Get all attendance (admin only)
  Future<List<AttendanceModel>> getAllAttendance({
    DateTime? date,
    String? profileId,
    String? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      var queryBuilder = _client.from('attendance').select('''
            *,
            profiles (
              full_name,
              profile_picture_url
            )
          ''');

      if (date != null) {
        final startOfDay = DateTime(date.year, date.month, date.day);
        final endOfDay = startOfDay.add(const Duration(days: 1));
        queryBuilder = queryBuilder.filter('check_in', 'gte', startOfDay.toIso8601String());
        queryBuilder = queryBuilder.filter('check_in', 'lt', endOfDay.toIso8601String());
      }

      if (profileId != null) {
        queryBuilder = queryBuilder.eq('profile_id', profileId);
      }

      if (status != null) {
        queryBuilder = queryBuilder.eq('status', status);
      }

      // Pagination
      final offset = (page - 1) * pageSize;
      final response = await queryBuilder
          .order('check_in', ascending: false)
          .range(offset, offset + pageSize - 1);

      return (response as List).map((json) {
        if (json['profiles'] != null) {
          json['profile_name'] = json['profiles']['full_name'];
          json['profile_picture_url'] =
              json['profiles']['profile_picture_url'];
        }
        return AttendanceModel.fromJson(json);
      }).toList();
    } catch (e) {
      AppLogger.error('❌ Error fetching all attendance', e);
      throw ServerException('Failed to fetch all attendance: ${e.toString()}');
    }
  }

  /// Watch today's attendance in real-time (admin dashboard)
  Stream<List<AttendanceModel>> watchTodayAttendance() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);

    return _client
        .from('attendance')
        .stream(primaryKey: ['id'])
        .gte('check_in', startOfDay.toIso8601String())
        .order('check_in', ascending: false)
        .map((data) => data.map((json) => AttendanceModel.fromJson(json)).toList());
  }

  // ==================== FILE STORAGE OPERATIONS ====================

  /// Upload file to Supabase Storage
  Future<String> uploadFile({
    required String bucket,
    required String path,
    required String filePath,
  }) async {
    try {
      AppLogger.info('📤 Uploading file to: $bucket/$path');

      await _client.storage.from(bucket).upload(
            path,
            File(filePath),
            fileOptions: const FileOptions(upsert: true),
          );

      final url = _client.storage.from(bucket).getPublicUrl(path);
      AppLogger.info('✅ File uploaded successfully');

      return url;
    } catch (e) {
      AppLogger.error('❌ Error uploading file', e);
      throw ServerException('Failed to upload file: ${e.toString()}');
    }
  }

  /// Delete file from Supabase Storage
  Future<void> deleteFile({
    required String bucket,
    required String path,
  }) async {
    try {
      AppLogger.info('🗑️ Deleting file: $bucket/$path');
      await _client.storage.from(bucket).remove([path]);
      AppLogger.info('✅ File deleted successfully');
    } catch (e) {
      AppLogger.error('❌ Error deleting file', e);
      throw ServerException('Failed to delete file: ${e.toString()}');
    }
  }
}
