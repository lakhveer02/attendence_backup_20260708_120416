import 'package:dartz/dartz.dart';
import 'package:attendence/core/error/failures.dart';
import 'package:attendence/domain/entities/profile.dart';

/// Authentication repository interface
/// Defines contracts for authentication operations
abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, Profile>> signInWithEmail({
    required String email,
    required String password,
  });

  /// Sign up new user (admin only)
  Future<Either<Failure, Profile>> signUpWithEmail({
    required String email,
    required String password,
    required String fullName,
    required UserRole role,
    String? phoneNumber,
    String? departmentId,
    bool createCompany = false,
    String? companyName,
  });

  /// Sign out current user
  Future<Either<Failure, void>> signOut();

  /// Get currently authenticated user
  Future<Either<Failure, Profile?>> getCurrentUser();

  /// Check if user is authenticated
  Future<bool> isAuthenticated();

  /// Reset password via email
  Future<Either<Failure, void>> resetPassword({
    required String email,
  });

  /// Update password
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Refresh session token
  Future<Either<Failure, void>> refreshSession();

  /// Stream of authentication state changes
  Stream<Profile?> get authStateChanges;
}
