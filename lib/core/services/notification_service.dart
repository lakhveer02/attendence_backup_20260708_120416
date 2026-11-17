import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:logger/logger.dart';
import 'package:permission_handler/permission_handler.dart';

/// Comprehensive Local Notification Service
/// Handles all types of notifications with scheduling and channels
class NotificationService {
  final Logger _logger = Logger();
  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  // Notification channels
  static const String _attendanceChannelId = 'attendance_channel';
  static const String _leaveChannelId = 'leave_channel';
  static const String _alertChannelId = 'alert_channel';
  static const String _reminderChannelId = 'reminder_channel';

  // Singleton
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  /// Initialize notification service
  Future<bool> initialize() async {
    if (_initialized) return true;

    try {
      // Initialize timezone data
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Kolkata'));

      // Android initialization settings
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization settings
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      final settings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      // Initialize
      final initialized = await _notifications.initialize(
        settings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
        onDidReceiveBackgroundNotificationResponse: _onBackgroundNotificationTapped,
      );

      if (initialized == true) {
        _logger.i('✅ Notification service initialized');
        await _createNotificationChannels();
        _initialized = true;
        return true;
      }

      _logger.e('❌ Failed to initialize notifications');
      return false;
    } catch (e) {
      _logger.e('Error initializing notifications: $e');
      return false;
    }
  }

  /// Request notification permissions (iOS)
  Future<bool> requestPermissions() async {
    if (Platform.isAndroid) {
      // Android 13+ requires notification permission
      final androidInfo = await Permission.notification.status;
      if (!androidInfo.isGranted) {
        final result = await Permission.notification.request();
        return result.isGranted;
      }
      return true;
    } else if (Platform.isIOS) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return granted ?? false;
    }
    return true;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (Platform.isAndroid) {
      return await _notifications
              .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin>()
              ?.areNotificationsEnabled() ??
          false;
    } else if (Platform.isIOS) {
      final granted = await _notifications
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          );
      return granted ?? false;
    }
    return false;
  }

  /// Show immediate notification
  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    NotificationChannel channel = NotificationChannel.attendance,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      await _notifications.show(
        id,
        title,
        body,
        _getNotificationDetails(channel),
        payload: payload,
      );
      _logger.i('📬 Notification shown: $title');
    } catch (e) {
      _logger.e('Error showing notification: $e');
    }
  }

  /// Schedule notification for a specific time
  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
    NotificationChannel channel = NotificationChannel.reminder,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        _getNotificationDetails(channel),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      _logger.i('⏰ Notification scheduled: $title at $scheduledDate');
    } catch (e) {
      _logger.e('Error scheduling notification: $e');
    }
  }

  /// Schedule daily notification at specific time
  Future<void> scheduleDailyNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String? payload,
    NotificationChannel channel = NotificationChannel.reminder,
  }) async {
    if (!_initialized) {
      await initialize();
    }

    try {
      final now = DateTime.now();
      var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);
      
      // If time has passed today, schedule for tomorrow
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        _getNotificationDetails(channel),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
        matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      );
      _logger.i('📅 Daily notification scheduled: $title at $hour:$minute');
    } catch (e) {
      _logger.e('Error scheduling daily notification: $e');
    }
  }

  /// Cancel specific notification
  Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      _logger.i('🚫 Notification cancelled: $id');
    } catch (e) {
      _logger.e('Error cancelling notification: $e');
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      _logger.i('🚫 All notifications cancelled');
    } catch (e) {
      _logger.e('Error cancelling all notifications: $e');
    }
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } catch (e) {
      _logger.e('Error getting pending notifications: $e');
      return [];
    }
  }

  // Attendance-specific notifications

  Future<void> showCheckInReminder() async {
    await showNotification(
      id: 100,
      title: '⏰ Time to Check In',
      body: 'Don\'t forget to mark your attendance for today!',
      channel: NotificationChannel.reminder,
    );
  }

  Future<void> showCheckOutReminder() async {
    await showNotification(
      id: 101,
      title: '👋 Time to Check Out',
      body: 'Mark your check-out to complete today\'s attendance.',
      channel: NotificationChannel.reminder,
    );
  }

  Future<void> showLeaveApproved(String leaveDates) async {
    await showNotification(
      id: 200,
      title: '✅ Leave Approved',
      body: 'Your leave request for $leaveDates has been approved.',
      channel: NotificationChannel.leave,
    );
  }

  Future<void> showLeaveRejected(String leaveDates, String reason) async {
    await showNotification(
      id: 201,
      title: '❌ Leave Rejected',
      body: 'Your leave request for $leaveDates was rejected. Reason: $reason',
      channel: NotificationChannel.leave,
    );
  }

  Future<void> showAttendanceMarked(String time) async {
    await showNotification(
      id: 102,
      title: '✅ Attendance Marked',
      body: 'Successfully checked in at $time',
      channel: NotificationChannel.attendance,
    );
  }

  Future<void> showBiometricAuthFailed() async {
    await showNotification(
      id: 300,
      title: '🔐 Authentication Failed',
      body: 'Biometric authentication failed. Please try again.',
      channel: NotificationChannel.alert,
    );
  }

  Future<void> showLocationOutOfRange() async {
    await showNotification(
      id: 301,
      title: '📍 Location Alert',
      body: 'You are outside the office geofence area.',
      channel: NotificationChannel.alert,
    );
  }

  // Schedule daily reminders

  Future<void> scheduleDailyCheckInReminder({
    int hour = 9,
    int minute = 0,
  }) async {
    await scheduleDailyNotification(
      id: 1000,
      title: '⏰ Morning Check-in Reminder',
      body: 'Good morning! Don\'t forget to mark your attendance.',
      hour: hour,
      minute: minute,
      channel: NotificationChannel.reminder,
    );
  }

  Future<void> scheduleDailyCheckOutReminder({
    int hour = 18,
    int minute = 0,
  }) async {
    await scheduleDailyNotification(
      id: 1001,
      title: '👋 Evening Check-out Reminder',
      body: 'Time to mark your check-out for today.',
      hour: hour,
      minute: minute,
      channel: NotificationChannel.reminder,
    );
  }

  // Private helper methods

  NotificationDetails _getNotificationDetails(NotificationChannel channel) {
    return NotificationDetails(
      android: _getAndroidDetails(channel),
      iOS: _getiOSDetails(channel),
    );
  }

  AndroidNotificationDetails _getAndroidDetails(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.attendance:
        return AndroidNotificationDetails(
          _attendanceChannelId,
          'Attendance Notifications',
          channelDescription: 'Notifications for attendance check-in and check-out',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
        );
      case NotificationChannel.leave:
        return AndroidNotificationDetails(
          _leaveChannelId,
          'Leave Notifications',
          channelDescription: 'Notifications for leave approvals and rejections',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
        );
      case NotificationChannel.alert:
        return AndroidNotificationDetails(
          _alertChannelId,
          'Alert Notifications',
          channelDescription: 'Important alerts and warnings',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          playSound: true,
          enableVibration: true,
          enableLights: true,
        );
      case NotificationChannel.reminder:
        return AndroidNotificationDetails(
          _reminderChannelId,
          'Reminder Notifications',
          channelDescription: 'Daily reminders for attendance',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          icon: '@mipmap/ic_launcher',
          playSound: true,
        );
    }
  }

  DarwinNotificationDetails _getiOSDetails(NotificationChannel channel) {
    switch (channel) {
      case NotificationChannel.attendance:
      case NotificationChannel.leave:
      case NotificationChannel.alert:
        return const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.timeSensitive,
        );
      case NotificationChannel.reminder:
        return const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.active,
        );
    }
  }

  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      final plugin = _notifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      await plugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _attendanceChannelId,
          'Attendance Notifications',
          description: 'Notifications for attendance check-in and check-out',
          importance: Importance.high,
        ),
      );

      await plugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _leaveChannelId,
          'Leave Notifications',
          description: 'Notifications for leave approvals and rejections',
          importance: Importance.high,
        ),
      );

      await plugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _alertChannelId,
          'Alert Notifications',
          description: 'Important alerts and warnings',
          importance: Importance.max,
        ),
      );

      await plugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          _reminderChannelId,
          'Reminder Notifications',
          description: 'Daily reminders for attendance',
          importance: Importance.defaultImportance,
        ),
      );

      _logger.i('📱 Android notification channels created');
    }
  }

  void _onNotificationTapped(NotificationResponse response) {
    _logger.i('Notification tapped: ${response.payload}');
    // Handle notification tap - navigate to appropriate screen
  }

  @pragma('vm:entry-point')
  static void _onBackgroundNotificationTapped(NotificationResponse response) {
    // Handle background notification tap
  }
}

enum NotificationChannel {
  attendance,
  leave,
  alert,
  reminder,
}

// Notification IDs for easy management
class NotificationIds {
  static const int checkInReminder = 100;
  static const int checkOutReminder = 101;
  static const int attendanceMarked = 102;
  static const int leaveApproved = 200;
  static const int leaveRejected = 201;
  static const int leavePending = 202;
  static const int biometricFailed = 300;
  static const int locationAlert = 301;
  static const int permissionAlert = 302;
  static const int dailyCheckInReminder = 1000;
  static const int dailyCheckOutReminder = 1001;
}
