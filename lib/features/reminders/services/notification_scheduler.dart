import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/services/motivation_repository.dart';
import '../models/reminder_settings.dart';
import 'notification_channels.dart';
import 'notification_config.dart';

class NotificationScheduler {
  /// Cancels only legacy and auto-calculated system reminders (IDs 1000..8999, 9000..9999) atomically,
  /// while preserving user custom alarms and without calling cancelAll().
  static Future<void> cancelAutoReminders(
    FlutterLocalNotificationsPlugin notifications,
  ) async {
    try {
      final List<Future<void>> cancelFutures = [];
      try {
        final pending = await notifications.pendingNotificationRequests();
        for (var p in pending) {
          if ((p.id >= 1000 && p.id < 9000) || (p.id >= 9000 && p.id <= 9999)) {
            cancelFutures.add(notifications.cancel(p.id));
          }
        }
      } catch (e) {
        debugPrint('[NotificationScheduler Warning] pendingNotificationRequests query failed: $e');
      }

      // Explicit fallback loop for all known ID ranges to ensure clean removal across all Android releases
      // 1. Breakfast: 1000..1099
      for (int id = 1000; id <= 1099; id++) {
        cancelFutures.add(notifications.cancel(id));
      }
      // 2. Lunch: 1100..1199
      for (int id = 1100; id <= 1199; id++) {
        cancelFutures.add(notifications.cancel(id));
      }
      // 3. Dinner: 1200..1299
      for (int id = 1200; id <= 1299; id++) {
        cancelFutures.add(notifications.cancel(id));
      }
      // 4. Motivation: 1300..1399
      for (int id = 1300; id <= 1399; id++) {
        cancelFutures.add(notifications.cancel(id));
      }
      // 5. Water: 2000..2999
      for (int id = 2000; id <= 2999; id++) {
        cancelFutures.add(notifications.cancel(id));
      }
      // 6. Snack: 3000..3999
      for (int id = 3000; id <= 3999; id++) {
        cancelFutures.add(notifications.cancel(id));
      }
      // 7. Screen Off: 4000..4099
      for (int id = 4000; id <= 4099; id++) {
        cancelFutures.add(notifications.cancel(id));
      }
      // 8. Workout: 5000..5099
      for (int id = 5000; id <= 5099; id++) {
        cancelFutures.add(notifications.cancel(id));
      }
      // 9. Vitamins: 6000..6099
      for (int id = 6000; id <= 6099; id++) {
        cancelFutures.add(notifications.cancel(id));
      }
      // 10. Eye Rest: 7000..7099
      for (int id = 7000; id <= 7099; id++) {
        cancelFutures.add(notifications.cancel(id));
      }
      // 11. Test IDs: 9000..9999
      for (int id = 9000; id <= 9999; id++) {
        cancelFutures.add(notifications.cancel(id));
      }

      await Future.wait(cancelFutures);
      debugPrint('[NotificationScheduler] Atomic cancel completed for auto-reminder ranges.');
    } catch (e) {
      debugPrint('[NotificationScheduler ERROR] Error cancelling auto reminders: $e');
    }
  }

  /// Schedules primary auto reminders (meals, water, snacks, motivation, optional) and custom user alarms for 3 days.
  /// Uses a collision-proof linear ID mapping:
  /// - Breakfast: 1000 + dayOffset (1000..1099)
  /// - Lunch: 1100 + dayOffset (1100..1199)
  /// - Dinner: 1200 + dayOffset (1200..1299)
  /// - Motivation: 1300 + dayOffset (1300..1399)
  /// - Water: 2000 + (dayOffset * 25) + waterIndex (2000..2999)
  /// - Snack: 3000 + (dayOffset * 25) + snackIndex (3000..3999)
  /// - Screen Off: 4000 + dayOffset (4000..4099)
  /// - Workout: 5000 + dayOffset (5000..5099)
  /// - Vitamins: 6000 + dayOffset (6000..6099)
  /// - Eye Rest: 7000 + dayOffset (7000..7099)
  /// - Custom Alarms: 8000 + (customIndex * 10) + dayOffset (8000..8999)
  static Future<bool> scheduleAllReminders({
    required FlutterLocalNotificationsPlugin notifications,
    required ReminderSettings settings,
    required bool isArabic,
  }) async {
    try {
      await cancelAutoReminders(notifications);

      if (!settings.isRunning) {
        debugPrint('[NotificationScheduler] Reminders disabled (isRunning = false). Skipping scheduling.');
        return true;
      }

      final now = tz.TZDateTime.now(tz.local);
      debugPrint('================ NOTIFICATION SCHEDULING LOG ================');
      debugPrint('Current Local Time: $now | Timezone: ${tz.local.name}');
      debugPrint('Wake Time: ${settings.wakeHour.toString().padLeft(2, '0')}:${settings.wakeMinute.toString().padLeft(2, '0')}');
      debugPrint('Bed Time: ${settings.sleepHour.toString().padLeft(2, '0')}:${settings.sleepMinute.toString().padLeft(2, '0')}');

      for (int dayOffset = 0; dayOffset < 3; dayOffset++) {
        final baseDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
        ).add(Duration(days: dayOffset));

        final wakeDateTime = tz.TZDateTime(
          tz.local,
          baseDate.year,
          baseDate.month,
          baseDate.day,
          settings.wakeHour,
          settings.wakeMinute,
        );

        // Client Rules:
        // 1. Breakfast: Wake + 30 mins
        final breakfastDateTime = wakeDateTime.add(const Duration(minutes: 30));
        // 2. Motivation: Breakfast + 1 hour
        final motivationDateTime = breakfastDateTime.add(const Duration(hours: 1));
        // 3. Lunch: Breakfast + 7 hours
        final lunchDateTime = breakfastDateTime.add(const Duration(hours: 7));

        int awakeDurationMins = settings.sleepTotalMins - settings.wakeTotalMins;
        final bedDateTime = wakeDateTime.add(Duration(minutes: awakeDurationMins));
        // 4. Dinner: Bedtime - 1 hour
        final dinnerDateTime = bedDateTime.subtract(const Duration(hours: 1));

        // Cutoffs
        final snackStopTime = dinnerDateTime.subtract(const Duration(minutes: 30));
        final waterStopTime = dinnerDateTime.subtract(const Duration(hours: 1));

        debugPrint('--- Day $dayOffset (${baseDate.year}-${baseDate.month.toString().padLeft(2, '0')}-${baseDate.day.toString().padLeft(2, '0')}) ---');
        debugPrint('Breakfast: $breakfastDateTime | Lunch: $lunchDateTime | Dinner: $dinnerDateTime');

        // 1. MEAL REMINDERS
        if (settings.mealsEnabled) {
          // A. Breakfast (Collision-Proof ID: 1000 + dayOffset)
          final breakfastId = NotificationContentRegistry.breakfast.idRangeStart + dayOffset;
          if (breakfastDateTime.isAfter(now)) {
            await _scheduleZonedNotification(
              notifications: notifications,
              id: breakfastId,
              title: isArabic ? NotificationContentRegistry.breakfast.titleAr : NotificationContentRegistry.breakfast.titleEn,
              body: isArabic ? NotificationContentRegistry.breakfast.bodyAr : NotificationContentRegistry.breakfast.bodyEn,
              scheduledTime: breakfastDateTime,
              channelId: NotificationContentRegistry.breakfast.channelId,
              soundName: NotificationContentRegistry.breakfast.soundName,
            );
          }

          // B. Lunch (Collision-Proof ID: 1100 + dayOffset)
          final lunchId = NotificationContentRegistry.lunch.idRangeStart + dayOffset;
          if (lunchDateTime.isAfter(now)) {
            await _scheduleZonedNotification(
              notifications: notifications,
              id: lunchId,
              title: isArabic ? NotificationContentRegistry.lunch.titleAr : NotificationContentRegistry.lunch.titleEn,
              body: isArabic ? NotificationContentRegistry.lunch.bodyAr : NotificationContentRegistry.lunch.bodyEn,
              scheduledTime: lunchDateTime,
              channelId: NotificationContentRegistry.lunch.channelId,
              soundName: NotificationContentRegistry.lunch.soundName,
            );
          }

          // C. Dinner (Collision-Proof ID: 1200 + dayOffset)
          final dinnerId = NotificationContentRegistry.dinner.idRangeStart + dayOffset;
          if (dinnerDateTime.isAfter(now)) {
            await _scheduleZonedNotification(
              notifications: notifications,
              id: dinnerId,
              title: isArabic ? NotificationContentRegistry.dinner.titleAr : NotificationContentRegistry.dinner.titleEn,
              body: isArabic ? NotificationContentRegistry.dinner.bodyAr : NotificationContentRegistry.dinner.bodyEn,
              scheduledTime: dinnerDateTime,
              channelId: NotificationContentRegistry.dinner.channelId,
              soundName: NotificationContentRegistry.dinner.soundName,
            );
          }
        }

        // 2. MOTIVATION (Collision-Proof ID: 1300 + dayOffset)
        if (settings.motivationEnabled) {
          final motivationId = NotificationContentRegistry.motivation.idRangeStart + dayOffset;
          if (motivationDateTime.isAfter(now)) {
            final quoteText = isArabic
                ? await MotivationRepository.getRandomQuote()
                : NotificationContentRegistry.motivation.bodyEn;

            await _scheduleZonedNotification(
              notifications: notifications,
              id: motivationId,
              title: isArabic ? NotificationContentRegistry.motivation.titleAr : NotificationContentRegistry.motivation.titleEn,
              body: quoteText,
              scheduledTime: motivationDateTime,
              channelId: NotificationContentRegistry.motivation.channelId,
              soundName: NotificationContentRegistry.motivation.soundName,
            );
          }
        }

        // 3. HOURLY WATER REMINDERS (Collision-Proof IDs: 2000 + (dayOffset * 25) + waterIndex)
        final waterInterval = settings.waterIntervalHours < 1 ? 1 : settings.waterIntervalHours;
        if (settings.waterEnabled && waterInterval > 0) {
          final waterIntervalMins = waterInterval * 60;
          var currentWaterTime = wakeDateTime.add(Duration(minutes: waterIntervalMins));
          int waterIndex = 0;

          while (true) {
            final waterId = NotificationContentRegistry.water.idRangeStart + (dayOffset * 25) + waterIndex;
            if (!currentWaterTime.isBefore(waterStopTime)) break;

            if (currentWaterTime.isAfter(now)) {
              await _scheduleZonedNotification(
                notifications: notifications,
                id: waterId,
                title: isArabic ? NotificationContentRegistry.water.titleAr : NotificationContentRegistry.water.titleEn,
                body: isArabic ? NotificationContentRegistry.water.bodyAr : NotificationContentRegistry.water.bodyEn,
                scheduledTime: currentWaterTime,
                channelId: NotificationContentRegistry.water.channelId,
                soundName: NotificationContentRegistry.water.soundName,
              );
            }
            currentWaterTime = currentWaterTime.add(Duration(minutes: waterIntervalMins));
            waterIndex++;
            if (waterIndex >= 24) break;
          }
        }

        // 4. SNACK REMINDERS (Collision-Proof IDs: 3000 + (dayOffset * 25) + snackIndex)
        // Rule: Every N hours after breakfast. Minimum time >= wakeDateTime + 90 minutes. Cutoff < dinner - 30 minutes.
        final snackInterval = settings.fruitVegIntervalHours < 1 ? 2 : settings.fruitVegIntervalHours;
        if (settings.fruitVegEnabled && snackInterval > 0) {
          final snackIntervalMins = snackInterval * 60;
          final minSnackTime = wakeDateTime.add(const Duration(minutes: 90));

          var currentSnackTime = breakfastDateTime.add(Duration(minutes: snackIntervalMins));
          while (currentSnackTime.isBefore(minSnackTime)) {
            currentSnackTime = currentSnackTime.add(Duration(minutes: snackIntervalMins));
          }

          int snackIndex = 0;
          while (true) {
            final snackId = NotificationContentRegistry.snack.idRangeStart + (dayOffset * 25) + snackIndex;
            if (!currentSnackTime.isBefore(snackStopTime)) break;

            if (currentSnackTime.isAfter(now)) {
              await _scheduleZonedNotification(
                notifications: notifications,
                id: snackId,
                title: isArabic ? NotificationContentRegistry.snack.titleAr : NotificationContentRegistry.snack.titleEn,
                body: isArabic ? NotificationContentRegistry.snack.bodyAr : NotificationContentRegistry.snack.bodyEn,
                scheduledTime: currentSnackTime,
                channelId: NotificationContentRegistry.snack.channelId,
                soundName: NotificationContentRegistry.snack.soundName,
              );
            }

            currentSnackTime = currentSnackTime.add(Duration(minutes: snackIntervalMins));
            snackIndex++;
            if (snackIndex >= 24) break;
          }
        }

        // 5. WORKOUT (Collision-Proof ID: 5000 + dayOffset)
        if (settings.workoutEnabled) {
          final wSched = tz.TZDateTime(
            tz.local,
            baseDate.year,
            baseDate.month,
            baseDate.day,
            settings.workoutHour,
            settings.workoutMinute,
          );
          final workoutId = NotificationContentRegistry.workout.idRangeStart + dayOffset;
          if (wSched.isAfter(now)) {
            await _scheduleZonedNotification(
              notifications: notifications,
              id: workoutId,
              title: isArabic ? NotificationContentRegistry.workout.titleAr : NotificationContentRegistry.workout.titleEn,
              body: isArabic ? NotificationContentRegistry.workout.bodyAr : NotificationContentRegistry.workout.bodyEn,
              scheduledTime: wSched,
              channelId: NotificationContentRegistry.workout.channelId,
              soundName: NotificationContentRegistry.workout.soundName,
            );
          }
        }

        // 6. SCREEN OFF (Collision-Proof ID: 4000 + dayOffset)
        if (settings.screenOffEnabled) {
          final sSched = tz.TZDateTime(
            tz.local,
            baseDate.year,
            baseDate.month,
            baseDate.day,
            settings.screenOffHour,
            settings.screenOffMinute,
          );
          final screenOffId = NotificationContentRegistry.screenOff.idRangeStart + dayOffset;
          if (sSched.isAfter(now)) {
            await _scheduleZonedNotification(
              notifications: notifications,
              id: screenOffId,
              title: isArabic ? NotificationContentRegistry.screenOff.titleAr : NotificationContentRegistry.screenOff.titleEn,
              body: isArabic ? NotificationContentRegistry.screenOff.bodyAr : NotificationContentRegistry.screenOff.bodyEn,
              scheduledTime: sSched,
              channelId: NotificationContentRegistry.screenOff.channelId,
              soundName: NotificationContentRegistry.screenOff.soundName,
            );
          }
        }

        // 7. VITAMINS (Collision-Proof ID: 6000 + dayOffset)
        if (settings.vitaminsEnabled) {
          final vSched = tz.TZDateTime(
            tz.local,
            baseDate.year,
            baseDate.month,
            baseDate.day,
            settings.vitaminsHour,
            settings.vitaminsMinute,
          );
          final vitaminsId = NotificationContentRegistry.vitamins.idRangeStart + dayOffset;
          if (vSched.isAfter(now)) {
            await _scheduleZonedNotification(
              notifications: notifications,
              id: vitaminsId,
              title: isArabic ? NotificationContentRegistry.vitamins.titleAr : NotificationContentRegistry.vitamins.titleEn,
              body: isArabic ? NotificationContentRegistry.vitamins.bodyAr : NotificationContentRegistry.vitamins.bodyEn,
              scheduledTime: vSched,
              channelId: NotificationContentRegistry.vitamins.channelId,
              soundName: NotificationContentRegistry.vitamins.soundName,
            );
          }
        }

        // 8. EYE REST (Collision-Proof ID: 7000 + dayOffset)
        if (settings.eyeRestEnabled) {
          final eSched = tz.TZDateTime(
            tz.local,
            baseDate.year,
            baseDate.month,
            baseDate.day,
            settings.eyeRestHour,
            settings.eyeRestMinute,
          );
          final eyeRestId = NotificationContentRegistry.eyeRest.idRangeStart + dayOffset;
          if (eSched.isAfter(now)) {
            await _scheduleZonedNotification(
              notifications: notifications,
              id: eyeRestId,
              title: isArabic ? NotificationContentRegistry.eyeRest.titleAr : NotificationContentRegistry.eyeRest.titleEn,
              body: isArabic ? NotificationContentRegistry.eyeRest.bodyAr : NotificationContentRegistry.eyeRest.bodyEn,
              scheduledTime: eSched,
              channelId: NotificationContentRegistry.eyeRest.channelId,
              soundName: NotificationContentRegistry.eyeRest.soundName,
            );
          }
        }

        // 9. CUSTOM USER ALARMS (Collision-Proof IDs: 8000 + (customIndex * 10) + dayOffset)
        for (int cIndex = 0; cIndex < settings.customAlarms.length; cIndex++) {
          final customAlarm = settings.customAlarms[cIndex];
          if (!customAlarm.isEnabled) continue;

          final cSched = tz.TZDateTime(
            tz.local,
            baseDate.year,
            baseDate.month,
            baseDate.day,
            customAlarm.hour,
            customAlarm.minute,
          );
          final notificationId = 8000 + (cIndex * 10) + dayOffset;

          if (cSched.isAfter(now)) {
            await _scheduleZonedNotification(
              notifications: notifications,
              id: notificationId,
              title: customAlarm.title.isNotEmpty
                  ? customAlarm.title
                  : (isArabic ? 'تنبيه مخصص ⏰' : 'Custom Reminder ⏰'),
              body: isArabic
                  ? 'تنبيه مخصص: ${customAlarm.title}'
                  : 'Custom reminder: ${customAlarm.title}',
              scheduledTime: cSched,
              channelId: NotificationChannels.mealsChannelId,
              soundName: NotificationChannels.mealSound,
            );
          }
        }
      }

      debugPrint('[NotificationScheduler] All reminders successfully scheduled with collision-proof IDs.');
      return true;
    } catch (e) {
      debugPrint('[NotificationScheduler ERROR] Error scheduling reminders: $e');
      return false;
    }
  }

  static Future<void> _scheduleZonedNotification({
    required FlutterLocalNotificationsPlugin notifications,
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
    required String channelId,
    required String soundName,
  }) async {
    AndroidNotificationDetails androidDetails;
    DarwinNotificationDetails iosDetails;

    if (soundName.isEmpty || soundName == NotificationChannels.defaultSound) {
      androidDetails = AndroidNotificationDetails(
        channelId,
        'System Reminder',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
      );
      iosDetails = const DarwinNotificationDetails();
    } else {
      androidDetails = AndroidNotificationDetails(
        channelId,
        'Health Reminder',
        importance: Importance.max,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(soundName),
        ticker: 'ticker',
      );
      iosDetails = DarwinNotificationDetails(
        sound: '$soundName.aac',
      );
    }

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
      debugPrint('[Scheduled] Zoned notification ID $id ("$title") set for $scheduledTime');
    } catch (e) {
      debugPrint('[Schedule Fallback] Exact schedule failed for ID $id: $e, trying inexact mode...');
      try {
        await notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledTime,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
        debugPrint('[Scheduled Inexact] Notification ID $id set for $scheduledTime');
      } catch (e2) {
        debugPrint('[Schedule ERROR] Failed scheduling zoned notification ID $id: $e2');
      }
    }
  }
}
