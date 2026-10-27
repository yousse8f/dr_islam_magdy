import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_settings.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    try {
      tz.initializeTimeZones();
      String timeZoneName = 'UTC';
      try {
        timeZoneName = await FlutterTimezone.getLocalTimezone();
      } catch (e) {
        debugPrint('Error getting local timezone: $e');
      }
      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    } catch (e) {
      debugPrint('Error initializing timezone: $e');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }

    try {
      const androidSettings = AndroidInitializationSettings(
        '@mipmap/ic_launcher',
      );
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );

      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(initSettings);

      final androidPlugin = _notifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        const channel = AndroidNotificationChannel(
          'dr_islam_meal_reminders_channel',
          'Meal & Health Reminders',
          description: 'Reminders for meals, water and healthy nutrition',
          importance: Importance.max,
        );
        await androidPlugin.createNotificationChannel(channel);
      }
    } catch (e) {
      debugPrint('Error initializing local notifications plugin: $e');
    }

    _initialized = true;
  }

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
      debugPrint('Error requesting notification permissions: $e');
      return false;
    }
  }

  static Future<void> cancelAll() async {
    try {
      await init();
      await _notifications.cancelAll();
    } catch (e) {
      debugPrint('Error cancelling notifications: $e');
    }
  }

  static Future<bool> scheduleReminders(
    ReminderSettings settings,
    bool isArabic,
  ) async {
    try {
      await init();
      // Cancel existing first
      await cancelAll();

      if (!settings.isRunning) return true;

      final now = tz.TZDateTime.now(tz.local);

      int mealIdBase = 1000;
      int waterIdBase = 2000;
      int veggiesIdBase = 3000;
      int screenOffIdBase = 4000;
      int workoutIdBase = 5000;
      int vitaminsIdBase = 6000;
      int eyeRestIdBase = 7000;

      int wakeTotalMins = settings.wakeHour * 60 + settings.wakeMinute;
      int sleepTotalMins = settings.sleepHour * 60 + settings.sleepMinute;

      bool crossesMidnight = sleepTotalMins <= wakeTotalMins;

      for (int dayOffset = 0; dayOffset < 3; dayOffset++) {
        final baseDate = tz.TZDateTime(
          tz.local,
          now.year,
          now.month,
          now.day,
        ).add(Duration(days: dayOffset));

        // 1. Meal Reminders
        if (settings.mealEnabled && settings.mealIntervalHours > 0) {
          int currentMins = wakeTotalMins;
          int index = 0;
          while (true) {
            if (!crossesMidnight && currentMins > sleepTotalMins) break;
            if (crossesMidnight &&
                currentMins > 1440 &&
                currentMins - 1440 > sleepTotalMins &&
                dayOffset > 0) {
              break;
            }

            int h = (currentMins ~/ 60) % 24;
            int m = currentMins % 60;
            int targetDayAdd = currentMins ~/ 1440;

            var scheduledTime = tz.TZDateTime(
              tz.local,
              baseDate.year,
              baseDate.month,
              baseDate.day,
              h,
              m,
            ).add(Duration(days: targetDayAdd));

            if (scheduledTime.isAfter(now)) {
              await _zonedScheduleNotification(
                id: mealIdBase + (dayOffset * 100) + index,
                title: isArabic
                    ? 'تنبيه وجبة صحية 🥗'
                    : 'Healthy Meal Reminder 🥗',
                body: isArabic
                    ? 'حان وقت تناول وجبتك الصحية والمحافظة على طاقتك!'
                    : 'Time for your healthy meal to keep your energy up!',
                scheduledTime: scheduledTime,
              );
            }

            currentMins += settings.mealIntervalHours * 60;
            index++;
            if (index > 24) break;
          }
        }

        // 2. Water Reminders
        if (settings.waterEnabled && settings.waterIntervalHours > 0) {
          int currentMins = wakeTotalMins;
          int index = 0;
          while (true) {
            if (!crossesMidnight && currentMins > sleepTotalMins) break;

            int h = (currentMins ~/ 60) % 24;
            int m = currentMins % 60;
            int targetDayAdd = currentMins ~/ 1440;

            var scheduledTime = tz.TZDateTime(
              tz.local,
              baseDate.year,
              baseDate.month,
              baseDate.day,
              h,
              m,
            ).add(Duration(days: targetDayAdd));

            if (scheduledTime.isAfter(now)) {
              await _zonedScheduleNotification(
                id: waterIdBase + (dayOffset * 100) + index,
                title: isArabic ? 'حان وقت الماء 💧' : 'Time for Water 💧',
                body: isArabic
                    ? 'اشرب كوباً من الماء لترطيب جسمك ونشاطك.'
                    : 'Drink a glass of water to stay hydrated and active.',
                scheduledTime: scheduledTime,
              );
            }

            currentMins += settings.waterIntervalHours * 60;
            index++;
            if (index > 24) break;
          }
        }

        // 3. Vegetables / Snack Reminders
        if (settings.veggiesEnabled && settings.veggiesIntervalHours > 0) {
          int currentMins = wakeTotalMins + 60;
          int index = 0;
          while (true) {
            if (!crossesMidnight && currentMins > sleepTotalMins) break;

            int h = (currentMins ~/ 60) % 24;
            int m = currentMins % 60;
            int targetDayAdd = currentMins ~/ 1440;

            var scheduledTime = tz.TZDateTime(
              tz.local,
              baseDate.year,
              baseDate.month,
              baseDate.day,
              h,
              m,
            ).add(Duration(days: targetDayAdd));

            if (scheduledTime.isAfter(now)) {
              await _zonedScheduleNotification(
                id: veggiesIdBase + (dayOffset * 100) + index,
                title: isArabic
                    ? 'تنبيه الخضروات والفيتامينات 🥒'
                    : 'Veggies & Snack Reminder 🥒',
                body: isArabic
                    ? 'تناول حصة من الخضروات الطازجة لتعزيز مناعتك وشبعك.'
                    : 'Have a serving of fresh vegetables to boost immunity.',
                scheduledTime: scheduledTime,
              );
            }

            currentMins += settings.veggiesIntervalHours * 60;
            index++;
            if (index > 24) break;
          }
        }

        // 4. Screen Off / Bedtime Eye Rest (قبل النوم / إيقاف الشاشات)
        if (settings.screenOffEnabled) {
          int screenOffMins =
              (settings.sleepHour * 60 + settings.sleepMinute) -
              settings.screenOffMinutesBeforeSleep;
          if (screenOffMins < 0) screenOffMins += 1440;
          int h = (screenOffMins ~/ 60) % 24;
          int m = screenOffMins % 60;

          var scheduledTime = tz.TZDateTime(
            tz.local,
            baseDate.year,
            baseDate.month,
            baseDate.day,
            h,
            m,
          ).add(Duration(days: screenOffMins >= 1440 ? 1 : 0));

          if (scheduledTime.isAfter(now)) {
            await _zonedScheduleNotification(
              id: screenOffIdBase + dayOffset,
              title: isArabic
                  ? 'إيقاف الشاشات - راحة للعين 🌙'
                  : 'Screen Off - Eye Rest 🌙',
              body: isArabic
                  ? 'حان وقت إيقاف الشاشات وإراحة عينيك قبل النوم لتحسين جودة نومك.'
                  : 'Time to turn off screens and rest your eyes before sleep.',
              scheduledTime: scheduledTime,
            );
          }
        }

        // 5. Workout Reminder (تنبيه التمارين)
        if (settings.workoutEnabled) {
          var scheduledTime = tz.TZDateTime(
            tz.local,
            baseDate.year,
            baseDate.month,
            baseDate.day,
            settings.workoutHour,
            settings.workoutMinute,
          );

          if (scheduledTime.isAfter(now)) {
            await _zonedScheduleNotification(
              id: workoutIdBase + dayOffset,
              title: isArabic
                  ? 'تنبيه التمرين اليومي 🏃‍♂️'
                  : 'Daily Workout Reminder 🏃‍♂️',
              body: isArabic
                  ? 'حان وقت التمرين الرياضي اليومي! حافظ على نشاطك وصحتك.'
                  : 'Time for your daily workout! Stay active and healthy.',
              scheduledTime: scheduledTime,
            );
          }
        }

        // 6. Vitamins Reminder (الفيتامينات)
        if (settings.vitaminsEnabled) {
          var scheduledTime = tz.TZDateTime(
            tz.local,
            baseDate.year,
            baseDate.month,
            baseDate.day,
            settings.vitaminsHour,
            settings.vitaminsMinute,
          );

          if (scheduledTime.isAfter(now)) {
            await _zonedScheduleNotification(
              id: vitaminsIdBase + dayOffset,
              title: isArabic
                  ? 'تذكير تناول الفيتامينات 💊'
                  : 'Vitamins Reminder 💊',
              body: isArabic
                  ? 'حان وقت تناول الفيتامينات الخاصة بك إن وصفت لك.'
                  : 'Time to take your prescribed vitamins.',
              scheduledTime: scheduledTime,
            );
          }
        }

        // 7. Eye Strain / Screen Rest (إجهاد العين / راحة للعين من الشاشات)
        if (settings.eyeRestEnabled && settings.eyeRestIntervalHours > 0) {
          int currentMins = wakeTotalMins + 90;
          int index = 0;
          while (true) {
            if (!crossesMidnight && currentMins > sleepTotalMins) break;

            int h = (currentMins ~/ 60) % 24;
            int m = currentMins % 60;
            int targetDayAdd = currentMins ~/ 1440;

            var scheduledTime = tz.TZDateTime(
              tz.local,
              baseDate.year,
              baseDate.month,
              baseDate.day,
              h,
              m,
            ).add(Duration(days: targetDayAdd));

            if (scheduledTime.isAfter(now)) {
              await _zonedScheduleNotification(
                id: eyeRestIdBase + (dayOffset * 100) + index,
                title: isArabic
                    ? 'راحة للعين من الشاشات 👀'
                    : 'Eye Rest from Screens 👀',
                body: isArabic
                    ? 'أبعد نظرك عن الشاشة لمدة دقيقتين وقم بإرخاء عينيك.'
                    : 'Look away from the screen for 2 minutes and relax your eyes.',
                scheduledTime: scheduledTime,
              );
            }

            currentMins += settings.eyeRestIntervalHours * 60;
            index++;
            if (index > 24) break;
          }
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error scheduling reminders: $e');
      return false;
    }
  }

  static Future<void> _zonedScheduleNotification({
    required int id,
    required String title,
    required String body,
    required tz.TZDateTime scheduledTime,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'dr_islam_meal_reminders_channel',
      'Meal & Health Reminders',
      channelDescription: 'Reminders for meals, water and healthy nutrition',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (e) {
      debugPrint('Error scheduling notification $id: $e');
    }
  }
}
