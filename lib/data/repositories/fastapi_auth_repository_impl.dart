import 'package:dartz/dartz.dart';
import 'package:attendence/core/error/exceptions.dart';
import 'package:attendence/core/error/failures.dart';
import 'package:attendence/core/utils/logger.dart';
import 'package:attendence/data/datasources/remote/fastapi_datasource.dart';
import 'package:attendence/domain/entities/profile.dart';
import 'package:attendence/domain/repositories/auth_repository.dart';

/// FastAPI implementation of auth repository
class FastApiAuthRepositoryImpl implements AuthRepository {
  final FastApiDatasource _datasource;

  FastApiAuthRepositoryImpl(this._datasource);

  @override
  Future<Either<Failure, Profile>> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phoneNumber,
    String? departmentId,
    bool createCompany = false,
    String? companyName,
  }) async {
    try {
      // Convert UserRole enum to API string format using @JsonValue annotations
      String roleString;
      switch (role) {
        case UserRole.superAdmin:
          roleString = 'super_admin';
          break;
        case UserRole.companyAdmin:
          roleString = 'company_admin';
          break;
        case UserRole.hrManager:
          roleString = 'hr_manager';
          break;
        case UserRole.teamManager:
          // Emit canonical backend role name for manager users.
          roleString = 'manager';
          break;
        case UserRole.employee:
          roleString = 'employee';
          break;
      }
      
      final profile = await _datasource.signUp(
        email: email,
        password: password,
        fullName: fullName,
        role: roleString,
        phoneNumber: phoneNumber,
        createCompany: createCompany,
        companyName: companyName,
      );

      return Right(profile.toEntity());
    } on AuthenticationException catch (e) {
      AppLogger.error('Sign up failed', e.message);
      return Left(Failure.authentication(message: e.message));
    } catch (e) {
      AppLogger.error('Sign up failed', e.toString());
      return Left(Failure.server(message: 'Sign up failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Profile>> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final profile = await _datasource.signIn(
        email: email,
        password: password,
      );

      return Right(profile.toEntity());
    } on AuthenticationException catch (e) {
      AppLogger.error('Sign in failed', e.message);
      return Left(Failure.authentication(message: e.message));
    } catch (e) {
      AppLogger.error('Sign in failed', e.toString());
      return Left(Failure.server(message: 'Sign in failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _datasource.signOut();
      return const Right(null);
    } catch (e) {
      AppLogger.error('Sign out failed', e.toString());
      return Left(Failure.server(message: 'Sign out failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Profile?>> getCurrentUser() async {
    try {
      final profile = await _datasource.restoreSession();
      return Right(profile?.toEntity());
    } catch (e) {
      AppLogger.error('Get current user failed', e.toString());
      return Left(Failure.server(message: 'Failed to get current user'));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    try {
      return await _datasource.isAuthenticated();
    } catch (e) {
      AppLogger.error('Check authentication failed', e.toString());
      return false;
    }
  }

  @override
  Stream<Profile?> get authStateChanges {
    // For FastAPI, we don't have real-time auth state changes
    // Return empty stream for now
    return Stream.value(null);
  }

  @override
  Future<Either<Failure, void>> resetPassword({required String email}) async {
    return Left(Failure.server(message: 'Password reset not implemented yet'));
  }

  @override
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    return Left(Failure.server(message: 'Password update not implemented yet'));
  }

  @override
  Future<Either<Failure, void>> refreshSession() async {
    return Left(Failure.server(message: 'Session refresh not implemented yet'));
  }
}
