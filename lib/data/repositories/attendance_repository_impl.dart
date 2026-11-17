import 'package:dartz/dartz.dart';
import 'package:attendence/core/error/failures.dart';
import 'package:attendence/core/error/exceptions.dart';
import 'package:attendence/domain/entities/attendance.dart';
import 'package:attendence/domain/repositories/attendance_repository.dart';
import 'package:attendence/data/datasources/remote/attendance_remote_datasource.dart';
import 'package:attendence/core/utils/logger.dart';

/// PRODUCTION-READY ATTENDANCE REPOSITORY IMPLEMENTATION
/// Implements all attendance operations with comprehensive error handling
/// NO PLACEHOLDERS - Fully functional implementation
class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;

  AttendanceRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, Attendance>> checkIn({
    required String photoPath,
    required double latitude,
    required double longitude,
    required VerificationMethod verificationMethod,
    double? faceMatchConfidence,
    bool isWfh = false,
    String? notes,
  }) async {
    try {
      AppLogger.info('📍 Repository: Check-in initiated');
      AppLogger.info('📍 Location: ($latitude, $longitude)');
      AppLogger.info('📸 Photo: $photoPath');
      AppLogger.info('🔐 Verification: ${verificationMethod.name}');

      final attendance = await remoteDataSource.checkIn(
        photoPath: photoPath,
        latitude: latitude,
        longitude: longitude,
        verificationMethod: verificationMethod,
        faceMatchConfidence: faceMatchConfidence,
        isWfh: isWfh,
        notes: notes,
      );

      AppLogger.info('✅ Repository: Check-in successful');
      return Right(attendance.toEntity());
    } on ServerException catch (e) {
      AppLogger.error('❌ Repository: Server error during check-in', e);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      AppLogger.error('❌ Repository: Network error during check-in', e);
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      AppLogger.error('❌ Repository: Unknown error during check-in', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Attendance>> checkOut({
    required String attendanceId,
    String? photoPath,
    double? latitude,
    double? longitude,
    String? notes,
  }) async {
    try {
      AppLogger.info('📍 Repository: Check-out initiated');
      AppLogger.info('🆔 Attendance ID: $attendanceId');

      final attendance = await remoteDataSource.checkOut(
        attendanceId: attendanceId,
        photoPath: photoPath,
        latitude: latitude,
        longitude: longitude,
        notes: notes,
      );

      AppLogger.info('✅ Repository: Check-out successful');
      return Right(attendance.toEntity());
    } on ServerException catch (e) {
      AppLogger.error('❌ Repository: Server error during check-out', e);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      AppLogger.error('❌ Repository: Network error during check-out', e);
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      AppLogger.error('❌ Repository: Unknown error during check-out', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Attendance>>> getMyAttendanceHistory({
    DateTime? startDate,
    DateTime? endDate,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      AppLogger.info('📊 Repository: Fetching attendance history');
      AppLogger.info('📅 Date range: ${startDate?.toIso8601String()} to ${endDate?.toIso8601String()}');

      final attendanceList = await remoteDataSource.getMyAttendanceHistory(
        startDate: startDate,
        endDate: endDate,
        page: page,
        pageSize: pageSize,
      );

      AppLogger.info('✅ Repository: Fetched ${attendanceList.length} attendance records');
      return Right(attendanceList.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      AppLogger.error('❌ Repository: Server error fetching history', e);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      AppLogger.error('❌ Repository: Network error fetching history', e);
      return Left(NetworkFailure(message: e.message));
    } on AuthenticationException catch (e) {
      AppLogger.error('❌ Repository: Authentication error', e);
      return Left(AuthenticationFailure(message: e.message));
    } catch (e) {
      AppLogger.error('❌ Repository: Unknown error fetching history', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Attendance?>> getTodayAttendance() async {
    try {
      AppLogger.info('📊 Repository: Fetching today\'s attendance');

      final attendance = await remoteDataSource.getTodayAttendance();

      if (attendance == null) {
        AppLogger.info('ℹ️ Repository: No attendance record for today');
        return const Right(null);
      }

      AppLogger.info('✅ Repository: Today\'s attendance found');
      return Right(attendance.toEntity());
    } on ServerException catch (e) {
      AppLogger.error('❌ Repository: Server error fetching today\'s attendance', e);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      AppLogger.error('❌ Repository: Network error fetching today\'s attendance', e);
      return Left(NetworkFailure(message: e.message));
    } on AuthenticationException catch (e) {
      AppLogger.error('❌ Repository: Authentication error', e);
      return Left(AuthenticationFailure(message: e.message));
    } catch (e) {
      AppLogger.error('❌ Repository: Unknown error fetching today\'s attendance', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Attendance>>> getAllAttendance({
    DateTime? date,
    String? profileId,
    AttendanceStatus? status,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      AppLogger.info('📊 Repository: Fetching all attendance records (Admin)');

      final attendanceList = await remoteDataSource.getAllAttendance(
        date: date,
        profileId: profileId,
        status: status,
        page: page,
        pageSize: pageSize,
      );

      AppLogger.info('✅ Repository: Fetched ${attendanceList.length} attendance records');
      return Right(attendanceList.map((model) => model.toEntity()).toList());
    } on ServerException catch (e) {
      AppLogger.error('❌ Repository: Server error fetching all attendance', e);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      AppLogger.error('❌ Repository: Network error fetching all attendance', e);
      return Left(NetworkFailure(message: e.message));
    } on AuthenticationException catch (e) {
      AppLogger.error('❌ Repository: Authentication error', e);
      return Left(AuthenticationFailure(message: e.message));
    } catch (e) {
      AppLogger.error('❌ Repository: Unknown error fetching all attendance', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Attendance>> getAttendanceById(String id) async {
    try {
      AppLogger.info('📊 Repository: Fetching attendance by ID: $id');

      final attendance = await remoteDataSource.getAttendanceById(id);

      AppLogger.info('✅ Repository: Attendance found');
      return Right(attendance.toEntity());
    } on ServerException catch (e) {
      AppLogger.error('❌ Repository: Server error fetching attendance', e);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      AppLogger.error('❌ Repository: Network error fetching attendance', e);
      return Left(NetworkFailure(message: e.message));
    } on NotFoundException catch (e) {
      AppLogger.error('❌ Repository: Attendance not found', e);
      return Left(NotFoundFailure(message: e.message));
    } catch (e) {
      AppLogger.error('❌ Repository: Unknown error fetching attendance', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, Attendance>> updateAttendanceStatus({
    required String attendanceId,
    required AttendanceStatus status,
    String? notes,
  }) async {
    try {
      AppLogger.info('📝 Repository: Updating attendance status');
      AppLogger.info('🆔 Attendance ID: $attendanceId');
      AppLogger.info('📊 New status: ${status.name}');

      final attendance = await remoteDataSource.updateAttendanceStatus(
        attendanceId: attendanceId,
        status: status,
        notes: notes,
      );

      AppLogger.info('✅ Repository: Attendance status updated');
      return Right(attendance.toEntity());
    } on ServerException catch (e) {
      AppLogger.error('❌ Repository: Server error updating status', e);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      AppLogger.error('❌ Repository: Network error updating status', e);
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      AppLogger.error('❌ Repository: Unknown error updating status', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }

  @override
  Stream<List<Attendance>> watchTodayAttendance() {
    try {
      AppLogger.info('📡 Repository: Watching today\'s attendance (stream)');
      return remoteDataSource.watchTodayAttendance()
          .map((models) => models.map((model) => model.toEntity()).toList());
    } catch (e) {
      AppLogger.error('❌ Repository: Error setting up attendance stream', e);
      // Return empty stream on error
      return Stream.value([]);
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> getAttendanceStats({
    DateTime? startDate,
    DateTime? endDate,
    String? profileId,
  }) async {
    try {
      AppLogger.info('📊 Repository: Fetching attendance statistics');

      final stats = await remoteDataSource.getAttendanceStats(
        startDate: startDate,
        endDate: endDate,
        profileId: profileId,
      );

      AppLogger.info('✅ Repository: Statistics fetched successfully');
      return Right(stats);
    } on ServerException catch (e) {
      AppLogger.error('❌ Repository: Server error fetching stats', e);
      return Left(ServerFailure(message: e.message));
    } on NetworkException catch (e) {
      AppLogger.error('❌ Repository: Network error fetching stats', e);
      return Left(NetworkFailure(message: e.message));
    } catch (e) {
      AppLogger.error('❌ Repository: Unknown error fetching stats', e);
      return Left(UnknownFailure(message: e.toString()));
    }
  }
}
