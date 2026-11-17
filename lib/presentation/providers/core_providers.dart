import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:attendence/data/datasources/remote/supabase_datasource.dart';
import 'package:attendence/data/datasources/remote/fastapi_datasource.dart';
import 'package:attendence/data/datasources/remote/attendance_remote_datasource.dart';
import 'package:attendence/data/repositories/fastapi_auth_repository_impl.dart';
import 'package:attendence/data/repositories/attendance_repository_impl.dart';
import 'package:attendence/domain/repositories/auth_repository.dart';
import 'package:attendence/domain/repositories/attendance_repository.dart';

// ==================== DATASOURCE PROVIDERS ====================

/// HTTP client provider
final httpClientProvider = Provider<http.Client>((ref) {
  return http.Client();
});

/// Supabase datasource provider
final supabaseDatasourceProvider = Provider<SupabaseDatasource>((ref) {
  return SupabaseDatasource();
});

/// FastAPI datasource provider
final fastApiDatasourceProvider = Provider<FastApiDatasource>((ref) {
  return FastApiDatasource();
});

// ==================== REPOSITORY PROVIDERS ====================

/// Auth repository provider - NOW USING FASTAPI
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final datasource = ref.watch(fastApiDatasourceProvider);
  return FastApiAuthRepositoryImpl(datasource);
});

/// Attendance repository provider
final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final remoteDataSource = AttendanceRemoteDataSource();
  return AttendanceRepositoryImpl(remoteDataSource: remoteDataSource);
});

// Import from auth_provider for currentUserProvider

// Additional repository providers will be added here as we implement them

