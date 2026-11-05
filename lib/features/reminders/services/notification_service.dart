import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_settings.dart';
import 'notification_channels.dart';
import 'notification_history_service.dart';
import 'notification_scheduler.dart';

// Re-export NotificationContentRegistry, NotificationTypeData, and SchedulingResult for external callers
export 'notification_config.dart' show NotificationContentRegistry, NotificationTypeData;
export 'notification_scheduler.dart' show SchedulingResult;

/// Unified Facade and Manager for local notifications, channels, permissions, and timezone initialization.
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

  static ValueChanged<String>? _onMotivationNotificationTappedWithQuote;

  static void setOnMotivationNotificationTapped(ValueChanged<String> callback) {
    _onMotivationNotificationTappedWithQuote = callback;
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
            final payload = response.payload ?? '';

            // Record confirmed user tap interaction in history
            NotificationHistoryService.recordUserInteraction(
              notificationId: id,
              title: response.notificationResponseType.name,
              body: payload,
            );

            // Check if motivation notification was tapped
            if (id == 1004 || (id >= 1300 && id <= 1399) || payload.startsWith('motivation')) {
              String quote = '';
              if (payload.startsWith('motivation:')) {
                quote = payload.substring('motivation:'.length);
              }
              _onMotivationNotificationTappedWithQuote?.call(quote);
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

  /// Checks if launch payload comes from notification tap on cold boot
  static Future<NotificationResponse?> getAppLaunchNotificationDetails() async {
    await init();
    final details = await _notifications.getNotificationAppLaunchDetails();
    if (details?.didNotificationLaunchApp == true) {
      return details?.notificationResponse;
    }
    return null;
  }

  /// Requests runtime notification permissions on Android and iOS.
  static Future<bool> requestPermissions() async {
    try {
      await init();
      bool granted = true;

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final notifGranted = await androidPlugin.requestNotificationsPermission();
        if (notifGranted == false) granted = false;

        try {
          await androidPlugin.requestExactAlarmsPermission();
        } catch (e) {
          debugPrint('[NotificationService Permission] Exact alarm permission request error: $e');
        }
      }

      final iosPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (iosPlugin != null) {
        final iosGranted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        if (iosGranted == false) granted = false;
      }

      return granted;
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return true;
    }
  }

  /// Checks whether exact alarm permission is granted on Android
  static Future<bool> checkExactAlarmPermission() async {
    try {
      await init();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final androidPlugin = _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        if (androidPlugin != null) {
          final exactGranted = await androidPlugin.canScheduleExactNotifications();
          return exactGranted ?? true;
        }
      }
      return true;
    } catch (e) {
      debugPrint('[Exact Alarm Check ERROR] $e');
      return true;
    }
  }

  /// Cancels only auto-calculated local system notifications (1000..9999) without calling cancelAll().
  static Future<void> cancelAutoReminders() async {
    await init();
    await NotificationScheduler.cancelAutoReminders(_notifications);
  }

  /// Cancels all notifications (Emergency method).
  static Future<void> cancelAll() async {
    try {
      await init();
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Error in cancelAll: $e');
    }
  }

  /// Schedules all user meal and optional health reminders based on ReminderSettings.
  static Future<SchedulingResult> scheduleReminders(
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
        sound: 'motivation_sound.wav',
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
          final exactGranted = await androidPlugin.canScheduleExactNotifications();
          debugPrint('[Runtime Check] exactGranted: $exactGranted');
        } catch (e) {
          debugPrint('[Runtime Check exact alarm error]: $e');
        }
      }
    } catch (e) {
      debugPrint('[Runtime Check ERROR] $e');
    }
  }
}
