import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../../../core/services/motivation_repository.dart';
import '../models/reminder_settings.dart';
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
  static bool _isScheduling = false;
  static int _scheduleSeq = 0;

  /// Fast, atomic cancellation of only active system auto reminders (1000..9999) using pending requests.
  /// Eliminates the previous 3,800-loop IPC overhead that caused app freezing.
  static Future<void> cancelAutoReminders(
    FlutterLocalNotificationsPlugin notifications,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      final List<Future<void>> cancelFutures = [];
      try {
        final pending = await notifications.pendingNotificationRequests();
        for (var p in pending) {
          if (p.id >= 1000 && p.id <= 9999) {
            cancelFutures.add(notifications.cancel(p.id));
          }
        }
      } catch (e) {
        debugPrint('[NotificationScheduler Warning] pendingNotificationRequests query failed: $e');
      }

      await Future.wait(cancelFutures);
      debugPrint(
        '[NotificationScheduler] Fast cancel completed in ${stopwatch.elapsedMilliseconds} ms '
        'for ${cancelFutures.length} active notifications.',
      );
    } catch (e) {
      debugPrint('[NotificationScheduler ERROR] Error cancelling auto reminders: $e');
    }
  }

  /// Schedules all primary auto reminders (meals, water, snacks, motivation, optional) and custom user alarms.
  /// Uses system-level daily repeating schedules (`DateTimeComponents.time`) for persistent recurring alarms.
  static Future<SchedulingResult> scheduleAllReminders({
    required FlutterLocalNotificationsPlugin notifications,
    required ReminderSettings settings,
    required bool isArabic,
  }) async {
    final currentSeq = ++_scheduleSeq;

    if (_isScheduling) {
      debugPrint('[NotificationScheduler] Scheduling task already in progress. Waiting...');
      int attempts = 0;
      while (_isScheduling && attempts < 20) {
        await Future.delayed(const Duration(milliseconds: 50));
        attempts++;
      }
      if (currentSeq != _scheduleSeq) {
        debugPrint('[NotificationScheduler] Superseded by newer schedule request (seq $currentSeq < $_scheduleSeq). Aborting stale run.');
        return const SchedulingResult(
          success: true,
          scheduledCount: 0,
          failedCount: 0,
          isExact: true,
          hitIosCeiling: false,
          messageAr: 'تم التجاوز بواسطة طلب جديد',
          messageEn: 'Superseded by a newer request',
        );
      }
    }

    _isScheduling = true;
    final stopwatch = Stopwatch()..start();

    try {
      await cancelAutoReminders(notifications);

      if (!settings.isRunning) {
        debugPrint('[NotificationScheduler] Reminders disabled (isRunning = false). Skipping scheduling.');
        return SchedulingResult(
          success: true,
          scheduledCount: 0,
          failedCount: 0,
          isExact: true,
          hitIosCeiling: false,
          messageAr: isArabic ? 'تم إيقاف المنبهات بنجاح' : 'Reminders disabled successfully',
          messageEn: isArabic ? 'تم إيقاف المنبهات بنجاح' : 'Reminders disabled successfully',
        );
      }

      final now = tz.TZDateTime.now(tz.local);
      debugPrint('================ NOTIFICATION SCHEDULING LOG ================');
      debugPrint('Current Local Time: $now | Timezone: ${tz.local.name}');
      debugPrint('Wake Time: ${settings.wakeHour.toString().padLeft(2, '0')}:${settings.wakeMinute.toString().padLeft(2, '0')}');
      debugPrint('Bed Time: ${settings.sleepHour.toString().padLeft(2, '0')}:${settings.sleepMinute.toString().padLeft(2, '0')}');

      int scheduledCount = 0;
      int failedCount = 0;
      bool hitIosCeiling = false;
      final exactTracker = ValueNotifier<bool>(true);

      const maxIosCeiling = 64;

      Future<bool> scheduleItem({
        required int id,
        required String title,
        required String body,
        required int hour,
        required int minute,
        required String channelId,
        required String soundName,
        required String payload,
      }) async {
        if (scheduledCount >= maxIosCeiling) {
          hitIosCeiling = true;
          debugPrint('[NotificationScheduler Ceiling] Reached 64 notification limit. Skipping ID $id ($title).');
          return false;
        }

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

        final ok = await _scheduleZonedNotification(
          notifications: notifications,
          id: id,
          title: title,
          body: body,
          scheduledTime: scheduledDate,
          channelId: channelId,
          soundName: soundName,
          payload: payload,
          exactTracker: exactTracker,
        );

        if (ok) {
          scheduledCount++;
        } else {
          failedCount++;
        }
        return ok;
      }

      // 1. MEAL REMINDERS
      if (settings.mealsEnabled) {
        final bTime = settings.getBreakfastTime();
        await scheduleItem(
          id: NotificationContentRegistry.breakfast.idRangeStart,
          title: isArabic ? NotificationContentRegistry.breakfast.titleAr : NotificationContentRegistry.breakfast.titleEn,
          body: isArabic ? NotificationContentRegistry.breakfast.bodyAr : NotificationContentRegistry.breakfast.bodyEn,
          hour: bTime.hour,
          minute: bTime.minute,
          channelId: NotificationContentRegistry.breakfast.channelId,
          soundName: NotificationContentRegistry.breakfast.soundName,
          payload: 'breakfast',
        );

        final lTime = settings.getLunchTime();
        await scheduleItem(
          id: NotificationContentRegistry.lunch.idRangeStart,
          title: isArabic ? NotificationContentRegistry.lunch.titleAr : NotificationContentRegistry.lunch.titleEn,
          body: isArabic ? NotificationContentRegistry.lunch.bodyAr : NotificationContentRegistry.lunch.bodyEn,
          hour: lTime.hour,
          minute: lTime.minute,
          channelId: NotificationContentRegistry.lunch.channelId,
          soundName: NotificationContentRegistry.lunch.soundName,
          payload: 'lunch',
        );

        final dTime = settings.getDinnerTime();
        await scheduleItem(
          id: NotificationContentRegistry.dinner.idRangeStart,
          title: isArabic ? NotificationContentRegistry.dinner.titleAr : NotificationContentRegistry.dinner.titleEn,
          body: isArabic ? NotificationContentRegistry.dinner.bodyAr : NotificationContentRegistry.dinner.bodyEn,
          hour: dTime.hour,
          minute: dTime.minute,
          channelId: NotificationContentRegistry.dinner.channelId,
          soundName: NotificationContentRegistry.dinner.soundName,
          payload: 'dinner',
        );
      }

      // 2. MOTIVATION
      if (settings.motivationEnabled) {
        final mTime = settings.getMotivationTime();
        final quoteText = isArabic
            ? await MotivationRepository.getRandomQuote()
            : NotificationContentRegistry.motivation.bodyEn;

        await scheduleItem(
          id: NotificationContentRegistry.motivation.idRangeStart,
          title: isArabic ? NotificationContentRegistry.motivation.titleAr : NotificationContentRegistry.motivation.titleEn,
          body: quoteText,
          hour: mTime.hour,
          minute: mTime.minute,
          channelId: NotificationContentRegistry.motivation.channelId,
          soundName: NotificationContentRegistry.motivation.soundName,
          payload: 'motivation',
        );
      }

      // 3. HOURLY WATER REMINDERS
      final waterInterval = settings.waterIntervalHours < 1 ? 1 : settings.waterIntervalHours;
      if (settings.waterEnabled && waterInterval > 0) {
        final waterIntervalMins = waterInterval * 60;
        int currentWaterMins = settings.wakeTotalMins + waterIntervalMins;
        int waterIndex = 0;

        while (currentWaterMins < settings.waterCutoffMins && waterIndex < 24) {
          final h = (currentWaterMins ~/ 60) % 24;
          final m = currentWaterMins % 60;
          final waterId = NotificationContentRegistry.water.idRangeStart + waterIndex;

          await scheduleItem(
            id: waterId,
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

      // 4. SNACK REMINDERS
      final snackInterval = settings.fruitVegIntervalHours < 1 ? 2 : settings.fruitVegIntervalHours;
      if (settings.fruitVegEnabled && snackInterval > 0) {
        final snackIntervalMins = snackInterval * 60;
        final minSnackMins = settings.wakeTotalMins + 90;
        final bTime = settings.getBreakfastTime();
        int bMins = bTime.hour * 60 + bTime.minute;

        int currentSnackMins = bMins + snackIntervalMins;
        while (currentSnackMins < minSnackMins) {
          currentSnackMins += snackIntervalMins;
        }

        int snackIndex = 0;
        while (currentSnackMins < settings.snackCutoffMins && snackIndex < 24) {
          final h = (currentSnackMins ~/ 60) % 24;
          final m = currentSnackMins % 60;
          final snackId = NotificationContentRegistry.snack.idRangeStart + snackIndex;

          await scheduleItem(
            id: snackId,
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

      // 5. WORKOUT
      if (settings.workoutEnabled) {
        await scheduleItem(
          id: NotificationContentRegistry.workout.idRangeStart,
          title: isArabic ? NotificationContentRegistry.workout.titleAr : NotificationContentRegistry.workout.titleEn,
          body: isArabic ? NotificationContentRegistry.workout.bodyAr : NotificationContentRegistry.workout.bodyEn,
          hour: settings.workoutHour,
          minute: settings.workoutMinute,
          channelId: NotificationContentRegistry.workout.channelId,
          soundName: NotificationContentRegistry.workout.soundName,
          payload: 'workout',
        );
      }

      // 6. SCREEN OFF
      if (settings.screenOffEnabled) {
        await scheduleItem(
          id: NotificationContentRegistry.screenOff.idRangeStart,
          title: isArabic ? NotificationContentRegistry.screenOff.titleAr : NotificationContentRegistry.screenOff.titleEn,
          body: isArabic ? NotificationContentRegistry.screenOff.bodyAr : NotificationContentRegistry.screenOff.bodyEn,
          hour: settings.screenOffHour,
          minute: settings.screenOffMinute,
          channelId: NotificationContentRegistry.screenOff.channelId,
          soundName: NotificationContentRegistry.screenOff.soundName,
          payload: 'screen_off',
        );
      }

      // 7. VITAMINS
      if (settings.vitaminsEnabled) {
        await scheduleItem(
          id: NotificationContentRegistry.vitamins.idRangeStart,
          title: isArabic ? NotificationContentRegistry.vitamins.titleAr : NotificationContentRegistry.vitamins.titleEn,
          body: isArabic ? NotificationContentRegistry.vitamins.bodyAr : NotificationContentRegistry.vitamins.bodyEn,
          hour: settings.vitaminsHour,
          minute: settings.vitaminsMinute,
          channelId: NotificationContentRegistry.vitamins.channelId,
          soundName: NotificationContentRegistry.vitamins.soundName,
          payload: 'vitamins',
        );
      }

      // 8. EYE REST
      if (settings.eyeRestEnabled) {
        await scheduleItem(
          id: NotificationContentRegistry.eyeRest.idRangeStart,
          title: isArabic ? NotificationContentRegistry.eyeRest.titleAr : NotificationContentRegistry.eyeRest.titleEn,
          body: isArabic ? NotificationContentRegistry.eyeRest.bodyAr : NotificationContentRegistry.eyeRest.bodyEn,
          hour: settings.eyeRestHour,
          minute: settings.eyeRestMinute,
          channelId: NotificationContentRegistry.eyeRest.channelId,
          soundName: NotificationContentRegistry.eyeRest.soundName,
          payload: 'eye_rest',
        );
      }

      // 9. CUSTOM ALARMS
      for (int cIndex = 0; cIndex < settings.customAlarms.length; cIndex++) {
        final customAlarm = settings.customAlarms[cIndex];
        if (!customAlarm.isEnabled) continue;

        final notificationId = 8000 + cIndex;
        await scheduleItem(
          id: notificationId,
          title: customAlarm.title.isNotEmpty
              ? customAlarm.title
              : (isArabic ? 'تنبيه مخصص ⏰' : 'Custom Reminder ⏰'),
          body: isArabic
              ? 'تنبيه مخصص: ${customAlarm.title}'
              : 'Custom reminder: ${customAlarm.title}',
          hour: customAlarm.hour,
          minute: customAlarm.minute,
          channelId: NotificationChannels.mealsChannelId,
          soundName: NotificationChannels.mealSound,
          payload: 'custom_${customAlarm.id}',
        );
      }

      stopwatch.stop();
      debugPrint(
        '[NotificationScheduler] Completed scheduling $scheduledCount reminders '
        '(${exactTracker.value ? "Exact" : "Inexact"}) in ${stopwatch.elapsedMilliseconds} ms. Failed: $failedCount.',
      );

      final isExact = exactTracker.value;
      final modeTextAr = isExact ? 'دقيقة' : 'تقريبية (قد تتأخر قليلاً حسب نظام التشغيل)';
      final modeTextEn = isExact ? 'exact' : 'inexact';

      String msgAr = 'تم حفظ الإعدادات وجدولة $scheduledCount تذكير بنجاح ($modeTextAr)! 🔔';
      String msgEn = 'Settings saved & $scheduledCount reminders scheduled ($modeTextEn)! 🔔';

      if (hitIosCeiling) {
        msgAr += ' (تم الوصول للحد الأقصى للإشعارات 64، تم ترتيب الأولويات)';
        msgEn += ' (Reached 64 notification ceiling, prioritized)';
      }

      return SchedulingResult(
        success: failedCount == 0,
        scheduledCount: scheduledCount,
        failedCount: failedCount,
        isExact: isExact,
        hitIosCeiling: hitIosCeiling,
        messageAr: msgAr,
        messageEn: msgEn,
      );
    } catch (e) {
      debugPrint('[NotificationScheduler ERROR] Error scheduling reminders: $e');
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
    } finally {
      _isScheduling = false;
    }
  }

  static Future<bool> _scheduleZonedNotification({
    required FlutterLocalNotificationsPlugin notifications,
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
    required String channelId,
    required String soundName,
    required String payload,
    required ValueNotifier<bool> exactTracker,
  }) async {
    AndroidNotificationDetails androidDetails;
    DarwinNotificationDetails iosDetails;

    final String iosSoundFile = soundName.isEmpty || soundName == NotificationChannels.defaultSound
        ? ''
        : (soundName.endsWith('.wav') ? soundName : '$soundName.wav');

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
        sound: iosSoundFile,
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
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
      debugPrint('[Scheduled Exact] ID $id ("$title") set for $scheduledTime (daily repeat)');
      return true;
    } catch (e) {
      debugPrint('[Schedule Fallback] Exact schedule failed for ID $id: $e, trying inexact mode...');
      exactTracker.value = false;
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
          matchDateTimeComponents: DateTimeComponents.time,
          payload: payload,
        );
        debugPrint('[Scheduled Inexact] ID $id ("$title") set for $scheduledTime (daily repeat)');
        return true;
      } catch (e2) {
        debugPrint('[Schedule ERROR] Failed scheduling notification ID $id: $e2');
        return false;
      }
    }
  }
}
