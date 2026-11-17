/// Application-wide constants and configuration values
class AppConstants {
  AppConstants._();

  // App Information
  static const String appName = 'Workforce Attendance';
  static const String appVersion = '1.0.0';

  // API Configuration
  // Update this URL when your ngrok tunnel changes
  static const String supabaseUrl = 'https://zkwlkfplelpsfrvvlfka.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inprd2xrZnBsZWxwc2ZydnZsZmthIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODA1NjcyNDgsImV4cCI6MjA5NjE0MzI0OH0.gQQqM6sZ8MB0feZr3v22Udfsfcj1DwGVk2wjGowgjyo';
  
  // FastAPI Backend URL
  // Update this when your ngrok tunnel changes
  // Current ngrok URL: https://5ad9-223-181-23-60.ngrok-free.app
  static const String fastApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://5ad9-223-181-23-60.ngrok-free.app',
  );
  static const String apiVersion = 'v1';
  static String get fullApiUrl => '$fastApiBaseUrl/api/$apiVersion';

  // Geofencing Configuration (Office Premises)
  static const double officeLatitude = 28.6139; // Replace with your office latitude
  static const double officeLongitude = 77.2090; // Replace with your office longitude
  static const double geofenceRadiusMeters = 200.0; // 200 meters radius

  // Face Recognition Thresholds
  static const double faceMatchThreshold = 0.6; // 60% confidence
  static const double livenessThreshold = 0.7; // 70% liveness score

  // Session & Security
  static const Duration sessionTimeout = Duration(hours: 8);
  static const Duration tokenRefreshInterval = Duration(minutes: 50);
  static const int maxLoginAttempts = 5;
  static const Duration lockoutDuration = Duration(minutes: 30);

  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration splashScreenDuration = Duration(seconds: 2);
  
  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // Working Hours
  static const String workStartTime = '09:00';
  static const String workEndTime = '18:00';
  static const Duration lateThreshold = Duration(minutes: 15);
  static const Duration halfDayThreshold = Duration(hours: 4);
}
