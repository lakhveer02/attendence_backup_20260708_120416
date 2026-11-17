import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:attendence/core/constants/app_constants.dart';
import 'package:attendence/core/utils/logger.dart';

/// Supabase configuration and initialization
class SupabaseConfig {
  SupabaseConfig._();

  static SupabaseClient? _client;

  /// Initialize Supabase
  static Future<void> initialize() async {
    try {
      AppLogger.info('🚀 Initializing Supabase...');
      
      await Supabase.initialize(
        url: AppConstants.supabaseUrl,
        // ignore: deprecated_member_use
        anonKey: AppConstants.supabaseAnonKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
        realtimeClientOptions: const RealtimeClientOptions(
          logLevel: RealtimeLogLevel.info,
        ),
        storageOptions: const StorageClientOptions(
          retryAttempts: 3,
        ),
      );

      _client = Supabase.instance.client;
      AppLogger.info('✅ Supabase initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('❌ Failed to initialize Supabase', e, stackTrace);
      rethrow;
    }
  }

  /// Get Supabase client instance
  static SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase not initialized. Call SupabaseConfig.initialize() first.');
    }
    return _client!;
  }

  /// Get current session
  static Session? get session => client.auth.currentSession;

  /// Get current user
  static User? get currentUser => client.auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => session != null;
}
