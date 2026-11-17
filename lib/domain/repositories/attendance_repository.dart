import 'package:dartz/dartz.dart';
import 'package:attendence/core/error/failures.dart';
import 'package:attendence/domain/entities/attendance.dart';

/// Attendance repository interface
/// Defines contracts for attendance operations
abstract class AttendanceRepository {
  /// Mark check-in attendance
  Future<Either<Failure, Attendance>> checkIn({
    required String photoPath,
    required double latitude,
    required double longitude,
    required VerificationMethod verificationMethod,
    double? faceMatchConfidence,
    bool isWfh = false,
    String? notes,
  });

  /// Mark check-out attendance
  Future<Either<Failure, Attendance>> checkOut({
    required String attendanceId,
    String? photoPath,
    double? latitude,
    double? longitude,
    String? notes,
  });

  /// Get attendance history for current user
  Future<Either<Failure, List<Attendance>>> getMyAttendanceHistory({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 20,
  });

  /// Get today's attendance for current user
  Future<Either<Failure, Attendance?>> getTodayAttendance();

  /// Get all attendance records (admin only)
  Future<Either<Failure, List<Attendance>>> getAllAttendance({
    DateTime? date,
    String? profileId,
    AttendanceStatus? status,
    int page = 1,
    int pageSize = 20,
  });

  /// Get attendance by ID
  Future<Either<Failure, Attendance>> getAttendanceById(String id);

  /// Update attendance status (admin only)
  Future<Either<Failure, Attendance>> updateAttendanceStatus({
    required String attendanceId,
    required AttendanceStatus status,
    String? notes,
  });

  /// Stream of real-time attendance changes (admin dashboard)
  Stream<List<Attendance>> watchTodayAttendance();

  /// Get attendance statistics
  Future<Either<Failure, Map<String, dynamic>>> getAttendanceStats({
    DateTime? startDate,
    DateTime? endDate,
    String? profileId,
  });
}
