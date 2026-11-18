import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/services/motivation_repository.dart';
import '../models/reminder_settings.dart';
import 'app_notification_data.dart';
import 'notification_channels.dart';
import 'notification_config.dart';

class SchedulingResult {
  final bool success;
  final int scheduledCount;
  final int failedCount;
  final bool isExact;
  final bool hitIosCeiling;
  final String messageAr;
  final String messageEn;
  final String? error;

  const SchedulingResult({
    required this.success,
    required this.scheduledCount,
    required this.failedCount,
    required this.isExact,
    required this.hitIosCeiling,
    required this.messageAr,
    required this.messageEn,
    this.error,
  });

  String getMessage(bool isArabic) => isArabic ? messageAr : messageEn;
}

class NotificationScheduler {
  /// Fast cancellation of auto reminders.
  static Future<void> cancelAutoReminders(
    FlutterLocalNotificationsPlugin notifications,
  ) async {
    try {
      await notifications.cancelAll();
      debugPrint('[NotificationScheduler] cancelAll completed successfully.');
    } catch (e) {
      debugPrint('[NotificationScheduler ERROR] Error cancelling reminders: $e');
    }
  }

  /// Schedules all active reminders instantly.
  static Future<SchedulingResult> scheduleAllReminders({
    required FlutterLocalNotificationsPlugin notifications,
    required ReminderSettings settings,
    required bool isArabic,
  }) async {
    try {
      await cancelAutoReminders(notifications);

      if (!settings.isRunning) {
        return SchedulingResult(
          success: true,
          scheduledCount: 0,
          failedCount: 0,
          isExact: true,
          hitIosCeiling: false,
          messageAr: isArabic ? 'التنبيه اتقفل' : 'Reminders Turned Off',
          messageEn: 'Reminders Turned Off',
        );
      }

      if (settings.scheduleActivatedAt == null) {
        settings.scheduleActivatedAt = DateTime.now().millisecondsSinceEpoch;
        await settings.save();
      }

      final now = tz.TZDateTime.now(tz.local);
      int scheduledCount = 0;
      int failedCount = 0;
      const maxIosCeiling = 64;

      Future<void> scheduleSingle({
        required int id,
        required String title,
        required String body,
        required int hour,
        required int minute,
        required String channelId,
        required String soundName,
        required String payload,
      }) async {
        if (scheduledCount >= maxIosCeiling) return;

        tz.TZDateTime scheduledDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
          hour,
          minute,
        );
        if (scheduledDate.isBefore(now)) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }

        final iosSoundFile = soundName.isEmpty || soundName == NotificationChannels.defaultSound
            ? ''
            : (soundName.endsWith('.wav') ? soundName : '$soundName.wav');

        AndroidNotificationDetails androidDetails;
        DarwinNotificationDetails iosDetails;

        if (soundName.isEmpty || soundName == NotificationChannels.defaultSound) {
          androidDetails = AndroidNotificationDetails(
            channelId,
            'System Reminder',
            importance: Importance.max,
            priority: Priority.high,
          );
          iosDetails = const DarwinNotificationDetails();
        } else {
          androidDetails = AndroidNotificationDetails(
            channelId,
            'Health Reminder',
            importance: Importance.max,
            priority: Priority.high,
            sound: RawResourceAndroidNotificationSound(soundName),
          );
          iosDetails = DarwinNotificationDetails(
            sound: iosSoundFile,
          );
        }

        final details = NotificationDetails(
          android: androidDetails,
          iOS: iosDetails,
        );

        final dateStr = '${scheduledDate.year}-${scheduledDate.month.toString().padLeft(2, '0')}-${scheduledDate.day.toString().padLeft(2, '0')}_${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
        final typePrefix = payload.split(':').first;
        final occurrenceId = '${typePrefix}_$dateStr';

        final appData = AppNotificationData(
          occurrenceId: occurrenceId,
          type: typePrefix.replaceAll(RegExp(r'_\d+$'), ''),
          title: title,
          body: body,
          scheduledTime: DateTime(scheduledDate.year, scheduledDate.month, scheduledDate.day, hour, minute),
          payloadRaw: payload,
        );

        final jsonPayload = appData.toPayloadString();

        try {
          await notifications.zonedSchedule(
            id,
            title,
            body,
            scheduledDate,
            details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
            matchDateTimeComponents: DateTimeComponents.time,
            payload: jsonPayload,
          );
          scheduledCount++;
        } catch (e) {
          try {
            await notifications.zonedSchedule(
              id,
              title,
              body,
              scheduledDate,
              details,
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              uiLocalNotificationDateInterpretation:
                  UILocalNotificationDateInterpretation.absoluteTime,
              matchDateTimeComponents: DateTimeComponents.time,
              payload: jsonPayload,
            );
            scheduledCount++;
          } catch (e2) {
            failedCount++;
            debugPrint('[Schedule ERROR] ID $id: $e2');
          }
        }
      }

      // 1. Meals
      if (settings.mealsEnabled && settings.hasSelectedWakeAndSleepTimes) {
        final bTime = settings.getBreakfastTime();
        if (bTime != null) {
          await scheduleSingle(
            id: 1000,
            title: isArabic ? NotificationContentRegistry.breakfast.titleAr : NotificationContentRegistry.breakfast.titleEn,
            body: isArabic ? NotificationContentRegistry.breakfast.bodyAr : NotificationContentRegistry.breakfast.bodyEn,
            hour: bTime.hour,
            minute: bTime.minute,
            channelId: NotificationContentRegistry.breakfast.channelId,
            soundName: NotificationContentRegistry.breakfast.soundName,
            payload: 'breakfast',
          );
        }

        final lTime = settings.getLunchTime();
        if (lTime != null) {
          await scheduleSingle(
            id: 1100,
            title: isArabic ? NotificationContentRegistry.lunch.titleAr : NotificationContentRegistry.lunch.titleEn,
            body: isArabic ? NotificationContentRegistry.lunch.bodyAr : NotificationContentRegistry.lunch.bodyEn,
            hour: lTime.hour,
            minute: lTime.minute,
            channelId: NotificationContentRegistry.lunch.channelId,
            soundName: NotificationContentRegistry.lunch.soundName,
            payload: 'lunch',
          );
        }

        final dTime = settings.getDinnerTime();
        if (dTime != null) {
          await scheduleSingle(
            id: 1200,
            title: isArabic ? NotificationContentRegistry.dinner.titleAr : NotificationContentRegistry.dinner.titleEn,
            body: isArabic ? NotificationContentRegistry.dinner.bodyAr : NotificationContentRegistry.dinner.bodyEn,
            hour: dTime.hour,
            minute: dTime.minute,
            channelId: NotificationContentRegistry.dinner.channelId,
            soundName: NotificationContentRegistry.dinner.soundName,
            payload: 'dinner',
          );
        }
      }

      // 2. Motivation
      if (settings.motivationEnabled && settings.hasSelectedWakeAndSleepTimes) {
        final quoteText = await MotivationRepository.getRandomQuote();
        final mTime = settings.getMotivationTime();
        if (mTime != null) {
          await scheduleSingle(
            id: 1300,
            title: isArabic ? NotificationContentRegistry.motivation.titleAr : NotificationContentRegistry.motivation.titleEn,
            body: quoteText,
            hour: mTime.hour,
            minute: mTime.minute,
            channelId: NotificationContentRegistry.motivation.channelId,
            soundName: NotificationContentRegistry.motivation.soundName,
            payload: 'motivation:$quoteText',
          );
        }
      }

      // 3. Water (Sample main water reminders or interval)
      final waterInterval = settings.waterIntervalHours < 1 ? 1 : settings.waterIntervalHours;
      if (settings.waterEnabled && settings.hasSelectedWakeAndSleepTimes && waterInterval > 0) {
        final waterIntervalMins = waterInterval * 60;
        int currentWaterMins = settings.wakeTotalMins + waterIntervalMins;
        int waterIndex = 0;

        while (currentWaterMins < settings.waterCutoffMins && waterIndex < 12) {
          final h = (currentWaterMins ~/ 60) % 24;
          final m = currentWaterMins % 60;
          await scheduleSingle(
            id: 2000 + waterIndex,
            title: isArabic ? NotificationContentRegistry.water.titleAr : NotificationContentRegistry.water.titleEn,
            body: isArabic ? NotificationContentRegistry.water.bodyAr : NotificationContentRegistry.water.bodyEn,
            hour: h,
            minute: m,
            channelId: NotificationContentRegistry.water.channelId,
            soundName: NotificationContentRegistry.water.soundName,
            payload: 'water',
          );
          currentWaterMins += waterIntervalMins;
          waterIndex++;
        }
      }

      // 3b. Morning Wake Water (15 minutes after wake-up time)
      if (settings.waterEnabled && settings.hasWakeTime) {
        final wwTime = settings.getWakeWaterTime();
        if (wwTime != null) {
          await scheduleSingle(
            id: 2500,
            title: isArabic ? NotificationContentRegistry.wakeWater.titleAr : NotificationContentRegistry.wakeWater.titleEn,
            body: isArabic ? NotificationContentRegistry.wakeWater.bodyAr : NotificationContentRegistry.wakeWater.bodyEn,
            hour: wwTime.hour,
            minute: wwTime.minute,
            channelId: NotificationContentRegistry.wakeWater.channelId,
            soundName: NotificationContentRegistry.wakeWater.soundName,
            payload: 'water',
          );
        }
      }

      // 4. Snack
      final snackInterval = settings.fruitVegIntervalHours < 1 ? 2 : settings.fruitVegIntervalHours;
      if (settings.fruitVegEnabled && settings.hasSelectedWakeAndSleepTimes && snackInterval > 0) {
        final snackIntervalMins = snackInterval * 60;
        final minSnackMins = settings.wakeTotalMins + 90;
        final bTime = settings.getBreakfastTime();
        if (bTime != null) {
          int bMins = bTime.hour * 60 + bTime.minute;

          int currentSnackMins = bMins + snackIntervalMins;
          while (currentSnackMins < minSnackMins) {
            currentSnackMins += snackIntervalMins;
          }

          int snackIndex = 0;
          while (currentSnackMins < settings.snackCutoffMins && snackIndex < 6) {
            final h = (currentSnackMins ~/ 60) % 24;
            final m = currentSnackMins % 60;
            await scheduleSingle(
              id: 3000 + snackIndex,
              title: isArabic ? NotificationContentRegistry.snack.titleAr : NotificationContentRegistry.snack.titleEn,
              body: isArabic ? NotificationContentRegistry.snack.bodyAr : NotificationContentRegistry.snack.bodyEn,
              hour: h,
              minute: m,
              channelId: NotificationContentRegistry.snack.channelId,
              soundName: NotificationContentRegistry.snack.soundName,
              payload: 'snack',
            );
            currentSnackMins += snackIntervalMins;
            snackIndex++;
          }
        }
      }

      // 5. Workout
      if (settings.workoutEnabled && settings.workoutHour != null && settings.workoutMinute != null) {
        await scheduleSingle(
          id: 5000,
          title: isArabic ? NotificationContentRegistry.workout.titleAr : NotificationContentRegistry.workout.titleEn,
          body: isArabic ? NotificationContentRegistry.workout.bodyAr : NotificationContentRegistry.workout.bodyEn,
          hour: settings.workoutHour!,
          minute: settings.workoutMinute!,
          channelId: NotificationContentRegistry.workout.channelId,
          soundName: NotificationContentRegistry.workout.soundName,
          payload: 'workout',
        );
      }

      // 6. Screen Off
      if (settings.screenOffEnabled && settings.screenOffHour != null && settings.screenOffMinute != null) {
        await scheduleSingle(
          id: 4000,
          title: isArabic ? NotificationContentRegistry.screenOff.titleAr : NotificationContentRegistry.screenOff.titleEn,
          body: isArabic ? NotificationContentRegistry.screenOff.bodyAr : NotificationContentRegistry.screenOff.bodyEn,
          hour: settings.screenOffHour!,
          minute: settings.screenOffMinute!,
          channelId: NotificationContentRegistry.screenOff.channelId,
          soundName: NotificationContentRegistry.screenOff.soundName,
          payload: 'screen_off',
        );
      }

      // 7. Vitamins
      if (settings.vitaminsEnabled && settings.vitaminsHour != null && settings.vitaminsMinute != null) {
        await scheduleSingle(
          id: 6000,
          title: isArabic ? NotificationContentRegistry.vitamins.titleAr : NotificationContentRegistry.vitamins.titleEn,
          body: isArabic ? NotificationContentRegistry.vitamins.bodyAr : NotificationContentRegistry.vitamins.bodyEn,
          hour: settings.vitaminsHour!,
          minute: settings.vitaminsMinute!,
          channelId: NotificationContentRegistry.vitamins.channelId,
          soundName: NotificationContentRegistry.vitamins.soundName,
          payload: 'vitamins',
        );
      }

      // 8. Eye Rest
      if (settings.eyeRestEnabled && settings.eyeRestHour != null && settings.eyeRestMinute != null) {
        await scheduleSingle(
          id: 7000,
          title: isArabic ? NotificationContentRegistry.eyeRest.titleAr : NotificationContentRegistry.eyeRest.titleEn,
          body: isArabic ? NotificationContentRegistry.eyeRest.bodyAr : NotificationContentRegistry.eyeRest.bodyEn,
          hour: settings.eyeRestHour!,
          minute: settings.eyeRestMinute!,
          channelId: NotificationContentRegistry.eyeRest.channelId,
          soundName: NotificationContentRegistry.eyeRest.soundName,
          payload: 'eye_rest',
        );
      }

      // 9. Custom Alarms
      for (int cIndex = 0; cIndex < settings.customAlarms.length; cIndex++) {
        final customAlarm = settings.customAlarms[cIndex];
        if (!customAlarm.isEnabled) continue;

        await scheduleSingle(
          id: 8000 + cIndex,
          title: customAlarm.title.isNotEmpty ? customAlarm.title : (isArabic ? 'تنبيه مخصص ⏰' : 'Custom Reminder ⏰'),
          body: isArabic ? 'تنبيه مخصص: ${customAlarm.title}' : 'Custom reminder: ${customAlarm.title}',
          hour: customAlarm.hour,
          minute: customAlarm.minute,
          channelId: NotificationChannels.mealsChannelId,
          soundName: NotificationChannels.defaultSound,
          payload: 'custom_${customAlarm.id}',
        );
      }

      return SchedulingResult(
        success: failedCount == 0,
        scheduledCount: scheduledCount,
        failedCount: failedCount,
        isExact: true,
        hitIosCeiling: false,
        messageAr: isArabic ? 'التنبيه شغّال' : 'Reminders Active',
        messageEn: 'Reminders Active',
      );
    } catch (e) {
      debugPrint('[NotificationScheduler ERROR] $e');
      return SchedulingResult(
        success: false,
        scheduledCount: 0,
        failedCount: 1,
        isExact: true,
        hitIosCeiling: false,
        messageAr: 'حدث خطأ أثناء جدولة المنبهات.',
        messageEn: 'Failed to schedule reminders.',
        error: e.toString(),
      );
    }
  }
}
