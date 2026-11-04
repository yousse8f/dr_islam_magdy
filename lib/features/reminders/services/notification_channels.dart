import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationChannels {
  // Sound Resource Identifiers
  static const String mealSound = 'meal_sound';
  static const String snackSound = 'snack_sound';
  static const String waterSound = 'water_sound';
  static const String motivationSound = 'motivation_sound';
  static const String defaultSound = '';

  // Channel IDs - Versioned IDs to force Android OS sound settings migration
  static const String mealsChannelId = 'dr_islam_meals_channel_v5';
  static const String snackChannelId = 'dr_islam_snack_channel_v5';
  static const String waterChannelId = 'dr_islam_water_channel_v5';
  static const String motivationChannelId = 'dr_islam_motivation_channel_v5';
  static const String workoutChannelId = 'dr_islam_workout_channel_v3';
  static const String vitaminsChannelId = 'dr_islam_vitamins_channel_v3';
  static const String screenOffChannelId = 'dr_islam_screen_off_channel_v3';
  static const String eyeRestChannelId = 'dr_islam_eye_rest_channel_v3';

  /// Legacy channel IDs to clean up on Android update
  static const List<String> legacyChannelIds = [
    'dr_islam_breakfast_channel_v1',
    'dr_islam_meals_channel_v4',
    'dr_islam_meals_channel_v3',
    'dr_islam_meals_channel_v2',
    'dr_islam_meals_channel_v1',
    'dr_islam_snack_channel_v4',
    'dr_islam_snack_channel_v3',
    'dr_islam_snack_channel_v2',
    'dr_islam_water_channel_v4',
    'dr_islam_water_channel_v3',
    'dr_islam_water_channel_v2',
    'dr_islam_motivation_channel_v4',
    'dr_islam_motivation_channel_v3',
    'dr_islam_workout_channel_v2',
    'dr_islam_workout_channel_v1',
    'dr_islam_vitamins_channel_v2',
    'dr_islam_vitamins_channel_v1',
    'dr_islam_screen_off_channel_v2',
    'dr_islam_screen_off_channel_v1',
    'dr_islam_eye_rest_channel_v2',
    'dr_islam_eye_rest_channel_v1',
    'dr_islam_fcm_channel_v1',
  ];

  /// Deletes legacy Android channels and registers updated channels with exact sound mappings.
  static Future<void> registerAllChannels(
    FlutterLocalNotificationsPlugin notificationsPlugin,
  ) async {
    final androidPlugin = notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) return;

    try {
      // 0. Clean up legacy channels to prevent Android sound binding lock
      for (final legacyId in legacyChannelIds) {
        try {
          await androidPlugin.deleteNotificationChannel(legacyId);
        } catch (_) {}
      }

      // 1. Meals Channel (Breakfast, Lunch, Dinner -> meal_sound)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          mealsChannelId,
          'Meal Reminders',
          description: 'Reminders for breakfast, lunch, and dinner',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(mealSound),
          enableVibration: true,
          enableLights: true,
        ),
      );

      // 2. Snack Channel (Snack -> snack_sound)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          snackChannelId,
          'Snack Reminders',
          description: 'Reminders for light snacks and fruits',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(snackSound),
          enableVibration: true,
          enableLights: true,
        ),
      );

      // 3. Water Channel (Water -> water_sound)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          waterChannelId,
          'Water Hydration Reminders',
          description: 'Hourly reminders to stay hydrated',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(waterSound),
          enableVibration: true,
          enableLights: true,
        ),
      );

      // 4. Motivation Channel (Motivation -> motivation_sound)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          motivationChannelId,
          'Motivation & Support',
          description: 'Daily motivational messages and support',
          importance: Importance.max,
          playSound: true,
          sound: RawResourceAndroidNotificationSound(motivationSound),
          enableVibration: true,
          enableLights: true,
        ),
      );

      // 5. Workout Channel (System Default Sound)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          workoutChannelId,
          'Daily Workout Reminders',
          description: 'Reminders for daily physical workouts',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      );

      // 6. Vitamins Channel (System Default Sound)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          vitaminsChannelId,
          'Vitamins Reminders',
          description: 'Reminders for prescribed vitamins',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      );

      // 7. Screen Off Channel (System Default Sound)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          screenOffChannelId,
          'Bedtime & Screen Off',
          description: 'Reminders to turn off screens before sleep',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      );

      // 8. Eye Rest Channel (System Default Sound)
      await androidPlugin.createNotificationChannel(
        const AndroidNotificationChannel(
          eyeRestChannelId,
          'Eye Rest Reminders',
          description: 'Reminders to rest eyes from screens',
          importance: Importance.max,
          playSound: true,
          enableVibration: true,
          enableLights: true,
        ),
      );

      debugPrint('[NotificationChannels] All notification channels successfully migrated & registered.');
    } catch (e) {
      debugPrint('[NotificationChannels ERROR] Failed registering notification channels: $e');
    }
  }
}
