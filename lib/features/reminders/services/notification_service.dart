import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_settings.dart';
import 'notification_channels.dart';
import 'notification_history_service.dart';
import 'notification_scheduler.dart';

// Re-export NotificationContentRegistry and NotificationTypeData for external callers
export 'notification_config.dart' show NotificationContentRegistry, NotificationTypeData;

/// Unified Facade and Manager for local notifications, channels, timezone initialization, and FCM display.
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Channel ID Constant mappings for backward compatibility
  static const String mealsChannelId = NotificationChannels.mealsChannelId;
  static const String breakfastChannelId = NotificationChannels.mealsChannelId;
  static const String snackChannelId = NotificationChannels.snackChannelId;
  static const String waterChannelId = NotificationChannels.waterChannelId;
  static const String motivationChannelId = NotificationChannels.motivationChannelId;
  static const String workoutChannelId = NotificationChannels.workoutChannelId;
  static const String vitaminsChannelId = NotificationChannels.vitaminsChannelId;
  static const String screenOffChannelId = NotificationChannels.screenOffChannelId;
  static const String eyeRestChannelId = NotificationChannels.eyeRestChannelId;

  static VoidCallback? _onMotivationNotificationTapped;

  static void setOnMotivationNotificationTapped(VoidCallback callback) {
    _onMotivationNotificationTapped = callback;
  }

  /// Initializes timezone data, local notifications plugin, and registers channels safely.
  static Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      String timeZoneName = 'UTC';
      try {
        timeZoneName = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(timeZoneName));
        debugPrint('[NotificationService Timezone] Local timezone set: $timeZoneName');
      } catch (e) {
        debugPrint('[NotificationService Timezone Warning] Could not set local timezone: $e. Using UTC.');
        try {
          tz.setLocalLocation(tz.getLocation('UTC'));
        } catch (_) {}
      }
    } catch (e) {
      debugPrint('[NotificationService Timezone ERROR] $e');
    }

    try {
      const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('[Notification Response] id=${response.id}, payload=${response.payload}');
          if (response.id != null) {
            final id = response.id!;

            // Record confirmed user tap interaction in history
            NotificationHistoryService.recordUserInteraction(
              notificationId: id,
              title: response.notificationResponseType.name,
              body: response.payload ?? '',
            );

            // Check if motivation notification was tapped
            if (id == 1004 || (id >= 1300 && id <= 1399)) {
              _onMotivationNotificationTapped?.call();
            }
          }
        },
      );

      await NotificationChannels.registerAllChannels(_notifications);
    } catch (e) {
      debugPrint('[NotificationService Init ERROR] $e');
    }

    _initialized = true;
  }

  /// Requests runtime notification permissions on Android and iOS.
  static Future<bool> requestPermissions() async {
    try {
      await init();
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        if (granted == false) return false;
      }

      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        if (granted == false) return false;
      }

      return true;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return true;
    }
  }

  /// Cancels only auto-calculated local system notifications (1000..8999) without calling cancelAll() or touching FCM.
  static Future<void> cancelAutoReminders() async {
    await init();
    await NotificationScheduler.cancelAutoReminders(_notifications);
  }

  /// Cancels all notifications (Emergency method - not used during normal updates).
  static Future<void> cancelAll() async {
    try {
      await init();
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Error in cancelAll: $e');
    }
  }

  /// Schedules all user meal and optional health reminders based on ReminderSettings.
  static Future<bool> scheduleReminders(
    ReminderSettings settings,
    bool isArabic,
  ) async {
    await init();
    return NotificationScheduler.scheduleAllReminders(
      notifications: _notifications,
      settings: settings,
      isArabic: isArabic,
    );
  }

  /// Displays an in-app heads-up notification banner when an FCM message arrives in foreground.
  /// Uses a dedicated FCM ID range (9000+) and channel to prevent overwriting local scheduled alarms.
  static Future<void> showForegroundFcmNotification({
    required String title,
    required String body,
  }) async {
    try {
      await init();
      const androidDetails = AndroidNotificationDetails(
        NotificationChannels.fcmChannelId,
        'Dr. Islam App Notifications',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(NotificationChannels.mealSound),
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: DarwinNotificationDetails(),
      );
      final id = 9000 + (DateTime.now().millisecondsSinceEpoch % 100);
      await _notifications.show(id, title, body, details);
      debugPrint('[In-App FCM] Foreground notification $id displayed: "$title"');
    } catch (e) {
      debugPrint('Error displaying FCM foreground notification: $e');
    }
  }

  /// Plays motivation sound effect once using the motivation channel without leaving a persistent notification.
  static Future<void> playMotivationSoundEffect() async {
    try {
      await init();
      const androidDetails = AndroidNotificationDetails(
        NotificationChannels.motivationChannelId,
        'Motivation & Support',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(NotificationChannels.motivationSound),
      );
      const iosDetails = DarwinNotificationDetails(
        sound: 'motivation_sound.aac',
      );
      const details = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );
      const soundEffectId = 9999;
      await _notifications.show(
        soundEffectId,
        '',
        '',
        details,
      );
      await Future.delayed(const Duration(milliseconds: 150));
      await _notifications.cancel(soundEffectId);
    } catch (e) {
      debugPrint('Error playing motivation sound effect: $e');
    }
  }

  /// Diagnostic helper to log permissions and exact alarm status
  static Future<void> printRuntimePermissionsAndChannelStatus() async {
    try {
      await init();
      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final notificationsEnabled = await androidPlugin.areNotificationsEnabled();
        debugPrint('[Runtime Check] areNotificationsEnabled: $notificationsEnabled');
        try {
          final exactGranted = await androidPlugin.requestExactAlarmsPermission();
          debugPrint('[Runtime Check] requestExactAlarmsPermission granted: $exactGranted');
        } catch (e) {
          debugPrint('[Runtime Check exact alarm error]: $e');
        }
      }
    } catch (e) {
      debugPrint('[Runtime Check ERROR] $e');
    }
  }
}
