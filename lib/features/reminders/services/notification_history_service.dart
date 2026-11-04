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
  final String status; // 'scheduled' or 'tapped'

  NotificationHistoryItem({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.timeString,
    required this.timestamp,
    required this.dateStr,
    this.status = 'scheduled',
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

      final item = NotificationHistoryItem(
        id: id,
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
          h.id == id ||
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
      id: '${type}_$dateStr',
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
    if (!settings.isRunning) return;
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month}-${now.day}';
      final baseDate = DateTime(now.year, now.month, now.day);

      final wakeDateTime = baseDate.add(
        Duration(hours: settings.wakeHour, minutes: settings.wakeMinute),
      );
      final breakfastDateTime = wakeDateTime.add(const Duration(minutes: 30));
      final motivationDateTime = breakfastDateTime.add(const Duration(hours: 1));
      final lunchDateTime = breakfastDateTime.add(const Duration(hours: 7));

      int awakeDurationMins = settings.sleepTotalMins - settings.wakeTotalMins;
      final bedDateTime = wakeDateTime.add(
        Duration(minutes: awakeDurationMins),
      );
      final dinnerDateTime = bedDateTime.subtract(const Duration(hours: 1));

      // 1. Breakfast
      if (settings.mealsEnabled && !breakfastDateTime.isAfter(now)) {
        await recordNotification(
          id: 'breakfast_$dateStr',
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
        await recordNotification(
          id: 'motivation_$dateStr',
          type: 'motivation',
          title: isArabic ? NotificationContentRegistry.motivation.titleAr : NotificationContentRegistry.motivation.titleEn,
          body: quote,
          time: motivationDateTime,
          status: 'scheduled',
        );
      }

      // 3. Lunch
      if (settings.mealsEnabled && !lunchDateTime.isAfter(now)) {
        await recordNotification(
          id: 'lunch_$dateStr',
          type: 'lunch',
          title: isArabic ? NotificationContentRegistry.lunch.titleAr : NotificationContentRegistry.lunch.titleEn,
          body: isArabic ? NotificationContentRegistry.lunch.bodyAr : NotificationContentRegistry.lunch.bodyEn,
          time: lunchDateTime,
          status: 'scheduled',
        );
      }

      // 4. Dinner
      if (settings.mealsEnabled && !dinnerDateTime.isAfter(now)) {
        await recordNotification(
          id: 'dinner_$dateStr',
          type: 'dinner',
          title: isArabic ? NotificationContentRegistry.dinner.titleAr : NotificationContentRegistry.dinner.titleEn,
          body: isArabic ? NotificationContentRegistry.dinner.bodyAr : NotificationContentRegistry.dinner.bodyEn,
          time: dinnerDateTime,
          status: 'scheduled',
        );
      }

      // 5. Workout
      if (settings.workoutEnabled) {
        final wSched = DateTime(
          now.year,
          now.month,
          now.day,
          settings.workoutHour,
          settings.workoutMinute,
        );
        if (!wSched.isAfter(now)) {
          await recordNotification(
            id: 'workout_$dateStr',
            type: 'workout',
            title: isArabic ? NotificationContentRegistry.workout.titleAr : NotificationContentRegistry.workout.titleEn,
            body: isArabic ? NotificationContentRegistry.workout.bodyAr : NotificationContentRegistry.workout.bodyEn,
            time: wSched,
            status: 'scheduled',
          );
        }
      }

      // 6. Screen Off
      if (settings.screenOffEnabled) {
        final sSched = DateTime(
          now.year,
          now.month,
          now.day,
          settings.screenOffHour,
          settings.screenOffMinute,
        );
        if (!sSched.isAfter(now)) {
          await recordNotification(
            id: 'screenoff_$dateStr',
            type: 'screen_off',
            title: isArabic ? NotificationContentRegistry.screenOff.titleAr : NotificationContentRegistry.screenOff.titleEn,
            body: isArabic ? NotificationContentRegistry.screenOff.bodyAr : NotificationContentRegistry.screenOff.bodyEn,
            time: sSched,
            status: 'scheduled',
          );
        }
      }

      // 7. Vitamins
      if (settings.vitaminsEnabled) {
        final vSched = DateTime(
          now.year,
          now.month,
          now.day,
          settings.vitaminsHour,
          settings.vitaminsMinute,
        );
        if (!vSched.isAfter(now)) {
          await recordNotification(
            id: 'vitamins_$dateStr',
            type: 'vitamins',
            title: isArabic ? NotificationContentRegistry.vitamins.titleAr : NotificationContentRegistry.vitamins.titleEn,
            body: isArabic ? NotificationContentRegistry.vitamins.bodyAr : NotificationContentRegistry.vitamins.bodyEn,
            time: vSched,
            status: 'scheduled',
          );
        }
      }

      // 8. Eye Rest
      if (settings.eyeRestEnabled) {
        final eSched = DateTime(
          now.year,
          now.month,
          now.day,
          settings.eyeRestHour,
          settings.eyeRestMinute,
        );
        if (!eSched.isAfter(now)) {
          await recordNotification(
            id: 'eyerest_$dateStr',
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
}
