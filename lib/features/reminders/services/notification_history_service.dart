import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/motivation_repository.dart';
import '../models/reminder_settings.dart';
import 'notification_config.dart';

class NotificationHistoryItem {
  final String id;
  final String type; // 'breakfast', 'lunch', 'dinner', 'snack', 'water', 'motivation', 'workout', 'screen_off', 'vitamins', 'eye_rest', 'custom'
  final String title;
  final String body;
  final String timeString; // e.g., '07:30'
  final int timestamp; // millis
  final String dateStr; // 'YYYY-MM-DD'
  final String status; // 'scheduled', 'tapped', 'read'
  final int? readAt;

  NotificationHistoryItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timeString,
    required this.timestamp,
    required this.dateStr,
    this.status = 'scheduled',
    this.readAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'title': title,
        'body': body,
        'timeString': timeString,
        'timestamp': timestamp,
        'dateStr': dateStr,
        'status': status,
        'readAt': readAt,
      };

  factory NotificationHistoryItem.fromJson(Map<String, dynamic> json) =>
      NotificationHistoryItem(
        id: json['id'] ?? '',
        type: json['type'] ?? '',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        timeString: json['timeString'] ?? '',
        timestamp: json['timestamp'] ?? 0,
        dateStr: json['dateStr'] ?? '',
        status: json['status'] ?? 'scheduled',
        readAt: json['readAt'],
      );
}

class NotificationHistoryService {
  static const String _historyKey = 'notification_history_list_v2';
  static const String _quoteDateKey = 'daily_quote_date_v2';
  static const String _quoteTextKey = 'daily_quote_text_v2';

  /// Gets today's fixed motivational quote, ensuring it remains constant throughout the day.
  /// If no quote is cached for today, picks one from MotivationRepository and caches it locally.
  static Future<String> getTodayMotivationQuote(bool isArabic) async {
    final prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month}-${now.day}';
    final savedDate = prefs.getString(_quoteDateKey);
    final savedQuote = prefs.getString(_quoteTextKey);

    if (savedDate == dateStr && savedQuote != null && savedQuote.isNotEmpty) {
      debugPrint('[Motivation Quote] Using cached quote for today ($dateStr): "$savedQuote"');
      return savedQuote;
    }

    String quote;
    try {
      quote = isArabic
          ? await MotivationRepository.getRandomQuote()
          : NotificationContentRegistry.motivation.bodyEn;
    } catch (_) {
      quote = isArabic
          ? 'استمر في تحقيق هدفك! خطوة صغيرة يومياً تصنع فرقاً كبيراً 💪'
          : NotificationContentRegistry.motivation.bodyEn;
    }

    await prefs.setString(_quoteDateKey, dateStr);
    await prefs.setString(_quoteTextKey, quote);
    debugPrint('[Motivation Quote] Generated & cached new quote for today ($dateStr): "$quote"');
    return quote;
  }

  /// Records a notification item in local history, preventing duplicates.
  static Future<void> recordNotification({
    required String id,
    required String type,
    required String title,
    required String body,
    required DateTime time,
    String status = 'scheduled',
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateStr = '${time.year}-${time.month}-${time.day}';
      final hourStr = time.hour.toString().padLeft(2, '0');
      final minuteStr = time.minute.toString().padLeft(2, '0');
      final timeString = '$hourStr:$minuteStr';

      final uniqueId = id.contains(timeString) ? id : '${id}_${dateStr}_$timeString';

      final item = NotificationHistoryItem(
        id: uniqueId,
        type: type,
        title: title,
        body: body,
        timeString: timeString,
        timestamp: time.millisecondsSinceEpoch,
        dateStr: dateStr,
        status: status,
      );

      List<String> list = prefs.getStringList(_historyKey) ?? [];
      List<NotificationHistoryItem> history = list
          .map((str) {
            try {
              return NotificationHistoryItem.fromJson(jsonDecode(str));
            } catch (_) {
              return null;
            }
          })
          .whereType<NotificationHistoryItem>()
          .toList();

      int existingIndex = history.indexWhere((h) =>
          h.id == uniqueId ||
          (h.dateStr == dateStr && h.type == type && h.timeString == timeString));

      if (existingIndex >= 0) {
        // Update status if tapped
        if (status == 'tapped') {
          history[existingIndex] = item;
          await prefs.setStringList(
            _historyKey,
            history.map((h) => jsonEncode(h.toJson())).toList(),
          );
          debugPrint('[NotificationHistory] Updated notification status to tapped: type=$type');
        }
      } else {
        history.add(item);
        if (history.length > 150) {
          history.removeRange(0, history.length - 150);
        }
        await prefs.setStringList(
          _historyKey,
          history.map((h) => jsonEncode(h.toJson())).toList(),
        );
        debugPrint('[NotificationHistory] Recorded notification: type=$type, title="$title", time=$timeString, date=$dateStr, status=$status');
      }
    } catch (e) {
      debugPrint('Error recording notification history: $e');
    }
  }

  /// Records user tap interaction on a notification
  static Future<void> recordUserInteraction({
    required int notificationId,
    required String title,
    required String body,
  }) async {
    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month}-${now.day}';
    final hourStr = now.hour.toString().padLeft(2, '0');
    final minuteStr = now.minute.toString().padLeft(2, '0');
    final timeString = '$hourStr:$minuteStr';
    String type = 'general';

    if (notificationId >= 1000 && notificationId < 1100) {
      type = 'breakfast';
    } else if (notificationId >= 1100 && notificationId < 1200) {
      type = 'lunch';
    } else if (notificationId >= 1200 && notificationId < 1300) {
      type = 'dinner';
    } else if (notificationId >= 1300 && notificationId < 1400) {
      type = 'motivation';
    } else if (notificationId >= 2000 && notificationId < 3000) {
      type = 'water';
    } else if (notificationId >= 3000 && notificationId < 4000) {
      type = 'snack';
    } else if (notificationId >= 4000 && notificationId < 4100) {
      type = 'screen_off';
    } else if (notificationId >= 5000 && notificationId < 5100) {
      type = 'workout';
    } else if (notificationId >= 6000 && notificationId < 6100) {
      type = 'vitamins';
    } else if (notificationId >= 7000 && notificationId < 7100) {
      type = 'eye_rest';
    } else if (notificationId >= 8000 && notificationId < 9000) {
      type = 'custom';
    }

    await recordNotification(
      id: '${type}_${dateStr}_$timeString',
      type: type,
      title: title,
      body: body,
      time: now,
      status: 'tapped',
    );
  }

  /// Evaluates today's scheduled reminders and records past ones into history
  static Future<void> evaluateTodayScheduledReminders(
    ReminderSettings settings,
    bool isArabic,
  ) async {
    if (!settings.isRunning || !settings.hasSelectedWakeAndSleepTimes) return;
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month}-${now.day}';
      final baseDate = DateTime(now.year, now.month, now.day);

      final wakeDateTime = baseDate.add(
        Duration(hours: settings.wakeHour!, minutes: settings.wakeMinute!),
      );
      final breakfastTime = settings.getBreakfastTime();
      if (breakfastTime == null) return;

      final breakfastDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        breakfastTime.hour,
        breakfastTime.minute,
      );
      final motivationDateTime = breakfastDateTime.add(const Duration(hours: 1));

      final lunchTime = settings.getLunchTime();
      final lunchDateTime = lunchTime != null
          ? DateTime(now.year, now.month, now.day, lunchTime.hour, lunchTime.minute)
          : breakfastDateTime.add(const Duration(hours: 7));

      int awakeDurationMins = settings.sleepTotalMins - settings.wakeTotalMins;
      final bedDateTime = wakeDateTime.add(
        Duration(minutes: awakeDurationMins),
      );

      final dinnerTime = settings.getDinnerTime();
      final dinnerDateTime = dinnerTime != null
          ? DateTime(now.year, now.month, now.day, dinnerTime.hour, dinnerTime.minute)
          : bedDateTime.subtract(const Duration(hours: 1));

      // 1. Breakfast
      if (settings.mealsEnabled && !breakfastDateTime.isAfter(now)) {
        final hStr = breakfastDateTime.hour.toString().padLeft(2, '0');
        final mStr = breakfastDateTime.minute.toString().padLeft(2, '0');
        await recordNotification(
          id: 'breakfast_${dateStr}_$hStr:$mStr',
          type: 'breakfast',
          title: isArabic ? NotificationContentRegistry.breakfast.titleAr : NotificationContentRegistry.breakfast.titleEn,
          body: isArabic ? NotificationContentRegistry.breakfast.bodyAr : NotificationContentRegistry.breakfast.bodyEn,
          time: breakfastDateTime,
          status: 'scheduled',
        );
      }

      // 2. Motivation
      if (settings.motivationEnabled && !motivationDateTime.isAfter(now)) {
        final quote = await getTodayMotivationQuote(isArabic);
        final hStr = motivationDateTime.hour.toString().padLeft(2, '0');
        final mStr = motivationDateTime.minute.toString().padLeft(2, '0');
        await recordNotification(
          id: 'motivation_${dateStr}_$hStr:$mStr',
          type: 'motivation',
          title: isArabic ? NotificationContentRegistry.motivation.titleAr : NotificationContentRegistry.motivation.titleEn,
          body: quote,
          time: motivationDateTime,
          status: 'scheduled',
        );
      }

      // 3. Lunch
      if (settings.mealsEnabled && !lunchDateTime.isAfter(now)) {
        final hStr = lunchDateTime.hour.toString().padLeft(2, '0');
        final mStr = lunchDateTime.minute.toString().padLeft(2, '0');
        await recordNotification(
          id: 'lunch_${dateStr}_$hStr:$mStr',
          type: 'lunch',
          title: isArabic ? NotificationContentRegistry.lunch.titleAr : NotificationContentRegistry.lunch.titleEn,
          body: isArabic ? NotificationContentRegistry.lunch.bodyAr : NotificationContentRegistry.lunch.bodyEn,
          time: lunchDateTime,
          status: 'scheduled',
        );
      }

      // 4. Dinner
      if (settings.mealsEnabled && !dinnerDateTime.isAfter(now)) {
        final hStr = dinnerDateTime.hour.toString().padLeft(2, '0');
        final mStr = dinnerDateTime.minute.toString().padLeft(2, '0');
        await recordNotification(
          id: 'dinner_${dateStr}_$hStr:$mStr',
          type: 'dinner',
          title: isArabic ? NotificationContentRegistry.dinner.titleAr : NotificationContentRegistry.dinner.titleEn,
          body: isArabic ? NotificationContentRegistry.dinner.bodyAr : NotificationContentRegistry.dinner.bodyEn,
          time: dinnerDateTime,
          status: 'scheduled',
        );
      }

      // 5. Water
      if (settings.waterEnabled && settings.waterIntervalHours > 0) {
        final waterIntervalMins = settings.waterIntervalHours * 60;
        int currentWaterMins = settings.wakeTotalMins + waterIntervalMins;
        int waterIndex = 0;
        while (currentWaterMins < settings.waterCutoffMins && waterIndex < 12) {
          final h = (currentWaterMins ~/ 60) % 24;
          final m = currentWaterMins % 60;
          final waterSched = DateTime(now.year, now.month, now.day, h, m);
          if (!waterSched.isAfter(now)) {
            final hStr = h.toString().padLeft(2, '0');
            final mStr = m.toString().padLeft(2, '0');
            await recordNotification(
              id: 'water_${dateStr}_$hStr:$mStr',
              type: 'water',
              title: isArabic ? NotificationContentRegistry.water.titleAr : NotificationContentRegistry.water.titleEn,
              body: isArabic ? NotificationContentRegistry.water.bodyAr : NotificationContentRegistry.water.bodyEn,
              time: waterSched,
              status: 'scheduled',
            );
          }
          currentWaterMins += waterIntervalMins;
          waterIndex++;
        }
      }

      // 6. Snack
      if (settings.fruitVegEnabled && settings.fruitVegIntervalHours > 0) {
        final snackIntervalMins = settings.fruitVegIntervalHours * 60;
        final minSnackMins = settings.wakeTotalMins + 90;
        int bMins = breakfastTime.hour * 60 + breakfastTime.minute;
        int currentSnackMins = bMins + snackIntervalMins;
        while (currentSnackMins < minSnackMins) {
          currentSnackMins += snackIntervalMins;
        }
        int snackIndex = 0;
        while (currentSnackMins < settings.snackCutoffMins && snackIndex < 6) {
          final h = (currentSnackMins ~/ 60) % 24;
          final m = currentSnackMins % 60;
          final snackSched = DateTime(now.year, now.month, now.day, h, m);
          if (!snackSched.isAfter(now)) {
            final hStr = h.toString().padLeft(2, '0');
            final mStr = m.toString().padLeft(2, '0');
            await recordNotification(
              id: 'snack_${dateStr}_$hStr:$mStr',
              type: 'snack',
              title: isArabic ? NotificationContentRegistry.snack.titleAr : NotificationContentRegistry.snack.titleEn,
              body: isArabic ? NotificationContentRegistry.snack.bodyAr : NotificationContentRegistry.snack.bodyEn,
              time: snackSched,
              status: 'scheduled',
            );
          }
          currentSnackMins += snackIntervalMins;
          snackIndex++;
        }
      }

      // 7. Workout
      if (settings.workoutEnabled && settings.workoutHour != null && settings.workoutMinute != null) {
        final wSched = DateTime(
          now.year,
          now.month,
          now.day,
          settings.workoutHour!,
          settings.workoutMinute!,
        );
        if (!wSched.isAfter(now)) {
          final hStr = wSched.hour.toString().padLeft(2, '0');
          final mStr = wSched.minute.toString().padLeft(2, '0');
          await recordNotification(
            id: 'workout_${dateStr}_$hStr:$mStr',
            type: 'workout',
            title: isArabic ? NotificationContentRegistry.workout.titleAr : NotificationContentRegistry.workout.titleEn,
            body: isArabic ? NotificationContentRegistry.workout.bodyAr : NotificationContentRegistry.workout.bodyEn,
            time: wSched,
            status: 'scheduled',
          );
        }
      }

      // 8. Screen Off
      if (settings.screenOffEnabled && settings.screenOffHour != null && settings.screenOffMinute != null) {
        final sSched = DateTime(
          now.year,
          now.month,
          now.day,
          settings.screenOffHour!,
          settings.screenOffMinute!,
        );
        if (!sSched.isAfter(now)) {
          final hStr = sSched.hour.toString().padLeft(2, '0');
          final mStr = sSched.minute.toString().padLeft(2, '0');
          await recordNotification(
            id: 'screenoff_${dateStr}_$hStr:$mStr',
            type: 'screen_off',
            title: isArabic ? NotificationContentRegistry.screenOff.titleAr : NotificationContentRegistry.screenOff.titleEn,
            body: isArabic ? NotificationContentRegistry.screenOff.bodyAr : NotificationContentRegistry.screenOff.bodyEn,
            time: sSched,
            status: 'scheduled',
          );
        }
      }

      // 9. Vitamins
      if (settings.vitaminsEnabled && settings.vitaminsHour != null && settings.vitaminsMinute != null) {
        final vSched = DateTime(
          now.year,
          now.month,
          now.day,
          settings.vitaminsHour!,
          settings.vitaminsMinute!,
        );
        if (!vSched.isAfter(now)) {
          final hStr = vSched.hour.toString().padLeft(2, '0');
          final mStr = vSched.minute.toString().padLeft(2, '0');
          await recordNotification(
            id: 'vitamins_${dateStr}_$hStr:$mStr',
            type: 'vitamins',
            title: isArabic ? NotificationContentRegistry.vitamins.titleAr : NotificationContentRegistry.vitamins.titleEn,
            body: isArabic ? NotificationContentRegistry.vitamins.bodyAr : NotificationContentRegistry.vitamins.bodyEn,
            time: vSched,
            status: 'scheduled',
          );
        }
      }

      // 10. Eye Rest
      if (settings.eyeRestEnabled && settings.eyeRestHour != null && settings.eyeRestMinute != null) {
        final eSched = DateTime(
          now.year,
          now.month,
          now.day,
          settings.eyeRestHour!,
          settings.eyeRestMinute!,
        );
        if (!eSched.isAfter(now)) {
          final hStr = eSched.hour.toString().padLeft(2, '0');
          final mStr = eSched.minute.toString().padLeft(2, '0');
          await recordNotification(
            id: 'eyerest_${dateStr}_$hStr:$mStr',
            type: 'eye_rest',
            title: isArabic ? NotificationContentRegistry.eyeRest.titleAr : NotificationContentRegistry.eyeRest.titleEn,
            body: isArabic ? NotificationContentRegistry.eyeRest.bodyAr : NotificationContentRegistry.eyeRest.bodyEn,
            time: eSched,
            status: 'scheduled',
          );
        }
      }
    } catch (e) {
      debugPrint('Error evaluating today scheduled reminders: $e');
    }
  }

  /// Gets only today's notifications, sorted from newest to oldest.
  static Future<List<NotificationHistoryItem>> getTodayHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month}-${now.day}';

      List<String> list = prefs.getStringList(_historyKey) ?? [];
      List<NotificationHistoryItem> history = list
          .map((str) {
            try {
              return NotificationHistoryItem.fromJson(jsonDecode(str));
            } catch (_) {
              return null;
            }
          })
          .whereType<NotificationHistoryItem>()
          .where((h) => h.dateStr == dateStr)
          .toList();

      history.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return history;
    } catch (e) {
      debugPrint('Error getting today history: $e');
      return [];
    }
  }

  /// Marks a notification item as read (when user presses "تمام").
  static Future<void> markAsRead(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> list = prefs.getStringList(_historyKey) ?? [];
      List<NotificationHistoryItem> history = list
          .map((str) {
            try {
              return NotificationHistoryItem.fromJson(jsonDecode(str));
            } catch (_) {
              return null;
            }
          })
          .whereType<NotificationHistoryItem>()
          .toList();

      int index = history.indexWhere((h) => h.id == id);
      if (index >= 0) {
        final item = history[index];
        history[index] = NotificationHistoryItem(
          id: item.id,
          type: item.type,
          title: item.title,
          body: item.body,
          timeString: item.timeString,
          timestamp: item.timestamp,
          dateStr: item.dateStr,
          status: 'read',
          readAt: DateTime.now().millisecondsSinceEpoch,
        );
        await prefs.setStringList(
          _historyKey,
          history.map((h) => jsonEncode(h.toJson())).toList(),
        );
        debugPrint('[NotificationHistory] Marked notification as read: id=$id');
      }
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
    }
  }

  /// Gets all unread history items (where status != 'read'), sorted chronologically (oldest first).
  static Future<List<NotificationHistoryItem>> getUnreadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> list = prefs.getStringList(_historyKey) ?? [];
      List<NotificationHistoryItem> history = list
          .map((str) {
            try {
              return NotificationHistoryItem.fromJson(jsonDecode(str));
            } catch (_) {
              return null;
            }
          })
          .whereType<NotificationHistoryItem>()
          .where((h) => h.status != 'read')
          .toList();

      // Sort chronologically: oldest due first
      history.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      return history;
    } catch (e) {
      debugPrint('Error getting unread history: $e');
      return [];
    }
  }
}
