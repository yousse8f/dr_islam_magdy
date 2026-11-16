import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/reminder_settings.dart';
import 'app_notification_data.dart';
import 'notification_config.dart';

class LatestNotificationService {
  static const String _latestNotificationKey = 'latest_arrived_notification_v1';
  static const String _lastHandledTimestampKey = 'last_handled_due_timestamp_v1';

  /// Saves the latest notification data locally
  static Future<void> saveLatestNotification(AppNotificationData data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = await getLatestNotification();
      if (current != null && current.scheduledTime.isAfter(data.scheduledTime)) {
        debugPrint('[LatestNotificationService] Kept newer stored notification (${current.scheduledTime}) over (${data.scheduledTime})');
        return;
      }
      await prefs.setString(_latestNotificationKey, jsonEncode(data.toJson()));
      debugPrint('[LatestNotificationService] Saved latest notification: type=${data.type}, time=${data.scheduledTime}');
    } catch (e) {
      debugPrint('Error saving latest notification: $e');
    }
  }

  /// Retrieves the preserved latest notification
  static Future<AppNotificationData?> getLatestNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? str = prefs.getString(_latestNotificationKey);
      if (str == null || str.isEmpty) return null;
      return AppNotificationData.fromJson(jsonDecode(str));
    } catch (e) {
      debugPrint('Error getting latest notification: $e');
      return null;
    }
  }

  /// Clears stored latest notification (e.g., when reminders are disabled)
  static Future<void> clearLatestNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_latestNotificationKey);
      await prefs.remove(_lastHandledTimestampKey);
    } catch (e) {
      debugPrint('Error clearing latest notification: $e');
    }
  }

  /// Sets the last handled due notification timestamp to prevent cascading back to older unread events.
  static Future<void> setLastHandledTimestamp(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_lastHandledTimestampKey, time.millisecondsSinceEpoch);
      debugPrint('[LatestNotificationService] Set last handled timestamp: $time');
    } catch (e) {
      debugPrint('Error setting last handled timestamp: $e');
    }
  }

  /// Compatibility alias for setting last handled timestamp with milliseconds since epoch.
  static Future<void> setLastAutoEvaluatedTime(int millis) async {
    await setLastHandledTimestamp(DateTime.fromMillisecondsSinceEpoch(millis));
  }

  /// Gets the last handled due notification timestamp.
  static Future<DateTime?> getLastHandledTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final millis = prefs.getInt(_lastHandledTimestampKey);
      return millis != null ? DateTime.fromMillisecondsSinceEpoch(millis) : null;
    } catch (e) {
      debugPrint('Error getting last handled timestamp: $e');
      return null;
    }
  }

  /// Evaluates active schedule against time window `(windowStart, windowEnd]`.
  /// Returns ALL due notifications whose scheduled time falls within the window.
  static Future<List<AppNotificationData>> getDueNotificationsForWindow({
    required DateTime windowStart,
    required DateTime windowEnd,
    required ReminderSettings settings,
    required bool isArabic,
    DateTime? scheduleActivationTime,
    bool ignoreLastHandled = false,
  }) async {
    if (!settings.isRunning) {
      debugPrint('[LatestNotificationService] Skipped window evaluation: settings.isRunning = false');
      return [];
    }

    final List<AppNotificationData> dueCandidates = [];
    final Map<String, AppNotificationData> candidatesByOccurrenceId = {};

    final effectiveActivationTime = scheduleActivationTime ??
        (settings.scheduleActivatedAt != null
            ? DateTime.fromMillisecondsSinceEpoch(settings.scheduleActivatedAt!)
            : null);

    DateTime? lastHandledTime;
    if (!ignoreLastHandled) {
      lastHandledTime = await getLastHandledTimestamp();
    }

    final today = DateTime(windowEnd.year, windowEnd.month, windowEnd.day);
    final candidateBaseWakeDates = [
      today.subtract(const Duration(days: 1)),
      today,
    ];

    void addCandidateIfValid({
      required String type,
      required String titleAr,
      required String titleEn,
      required String bodyAr,
      required String bodyEn,
      required DateTime scheduledDateTime,
      String? customId,
    }) {
      final isAfterStart = scheduledDateTime.isAfter(windowStart);
      final isBeforeOrAtEnd = !scheduledDateTime.isAfter(windowEnd);

      bool isValidWithActivation = true;
      if (effectiveActivationTime != null) {
        final activationMinuteFloor = effectiveActivationTime.subtract(const Duration(minutes: 1));
        if (scheduledDateTime.isBefore(activationMinuteFloor)) {
          isValidWithActivation = false;
        }
      }

      bool isValidWithLastHandled = true;
      if (lastHandledTime != null) {
        if (!scheduledDateTime.isAfter(lastHandledTime)) {
          isValidWithLastHandled = false;
        }
      }

      if (isAfterStart && isBeforeOrAtEnd && isValidWithActivation && isValidWithLastHandled) {
        final dateStr = '${scheduledDateTime.year}-${scheduledDateTime.month.toString().padLeft(2, '0')}-${scheduledDateTime.day.toString().padLeft(2, '0')}_${scheduledDateTime.hour.toString().padLeft(2, '0')}:${scheduledDateTime.minute.toString().padLeft(2, '0')}';
        final typePrefix = customId != null ? 'custom_$customId' : type;
        final occurrenceId = '${typePrefix}_$dateStr';

        final candidate = AppNotificationData(
          occurrenceId: occurrenceId,
          type: type,
          title: isArabic ? titleAr : titleEn,
          body: isArabic ? bodyAr : bodyEn,
          scheduledTime: scheduledDateTime,
          payloadRaw: customId != null ? 'custom_$customId' : type,
        );

        candidatesByOccurrenceId[occurrenceId] = candidate;
      }
    }

    // Evaluate wake-cycle dependent reminders for each base wake date
    if (settings.hasSelectedWakeAndSleepTimes) {
      for (final baseWakeDate in candidateBaseWakeDates) {
        final baseMidnight = DateTime(baseWakeDate.year, baseWakeDate.month, baseWakeDate.day);

        // 1. Breakfast: 30 minutes after wake-up time
        if (settings.mealsEnabled) {
          final bMins = settings.wakeTotalMins + 30;
          final bSched = baseMidnight.add(Duration(minutes: bMins));
          addCandidateIfValid(
            type: 'breakfast',
            titleAr: NotificationContentRegistry.breakfast.titleAr,
            titleEn: NotificationContentRegistry.breakfast.titleEn,
            bodyAr: NotificationContentRegistry.breakfast.bodyAr,
            bodyEn: NotificationContentRegistry.breakfast.bodyEn,
            scheduledDateTime: bSched,
          );
        }

        // 2. Motivation: 1 hour after breakfast
        if (settings.motivationEnabled) {
          final mMins = settings.wakeTotalMins + 30 + 60;
          final mSched = baseMidnight.add(Duration(minutes: mMins));
          addCandidateIfValid(
            type: 'motivation',
            titleAr: NotificationContentRegistry.motivation.titleAr,
            titleEn: NotificationContentRegistry.motivation.titleEn,
            bodyAr: isArabic
                ? 'استمر في تحقيق هدفك! خطوة صغيرة يومياً تصنع فرقاً كبيراً 💪'
                : NotificationContentRegistry.motivation.bodyEn,
            bodyEn: NotificationContentRegistry.motivation.bodyEn,
            scheduledDateTime: mSched,
          );
        }

        // 3. Lunch: 7 hours after breakfast
        if (settings.mealsEnabled) {
          final lMins = settings.wakeTotalMins + 30 + 420;
          final lSched = baseMidnight.add(Duration(minutes: lMins));
          addCandidateIfValid(
            type: 'lunch',
            titleAr: NotificationContentRegistry.lunch.titleAr,
            titleEn: NotificationContentRegistry.lunch.titleEn,
            bodyAr: NotificationContentRegistry.lunch.bodyAr,
            bodyEn: NotificationContentRegistry.lunch.bodyEn,
            scheduledDateTime: lSched,
          );
        }

        // 4. Dinner: 1 hour before bedtime
        if (settings.mealsEnabled) {
          final dMins = settings.sleepTotalMins - 60;
          final dSched = baseMidnight.add(Duration(minutes: dMins));
          addCandidateIfValid(
            type: 'dinner',
            titleAr: NotificationContentRegistry.dinner.titleAr,
            titleEn: NotificationContentRegistry.dinner.titleEn,
            bodyAr: NotificationContentRegistry.dinner.bodyAr,
            bodyEn: NotificationContentRegistry.dinner.bodyEn,
            scheduledDateTime: dSched,
          );
        }

        // 5. Water: hourly interval from wake+interval to water Cutoff
        if (settings.waterEnabled) {
          final waterInterval = settings.waterIntervalHours < 1 ? 1 : settings.waterIntervalHours;
          final waterIntervalMins = waterInterval * 60;
          int currentMins = settings.wakeTotalMins + waterIntervalMins;
          int wIdx = 0;
          while (currentMins < settings.waterCutoffMins && wIdx < 12) {
            final wSched = baseMidnight.add(Duration(minutes: currentMins));
            addCandidateIfValid(
              type: 'water',
              titleAr: NotificationContentRegistry.water.titleAr,
              titleEn: NotificationContentRegistry.water.titleEn,
              bodyAr: NotificationContentRegistry.water.bodyAr,
              bodyEn: NotificationContentRegistry.water.bodyEn,
              scheduledDateTime: wSched,
            );
            currentMins += waterIntervalMins;
            wIdx++;
          }
        }

        // 6. Snack: interval from breakfast+interval to snack Cutoff
        if (settings.fruitVegEnabled) {
          final snackInterval = settings.fruitVegIntervalHours < 1 ? 2 : settings.fruitVegIntervalHours;
          final snackIntervalMins = snackInterval * 60;
          final minSnackMins = settings.wakeTotalMins + 90;
          final bMins = settings.wakeTotalMins + 30;

          int currentSnackMins = bMins + snackIntervalMins;
          while (currentSnackMins < minSnackMins) {
            currentSnackMins += snackIntervalMins;
          }

          int sIdx = 0;
          while (currentSnackMins < settings.snackCutoffMins && sIdx < 6) {
            final sSched = baseMidnight.add(Duration(minutes: currentSnackMins));
            addCandidateIfValid(
              type: 'snack',
              titleAr: NotificationContentRegistry.snack.titleAr,
              titleEn: NotificationContentRegistry.snack.titleEn,
              bodyAr: NotificationContentRegistry.snack.bodyAr,
              bodyEn: NotificationContentRegistry.snack.bodyEn,
              scheduledDateTime: sSched,
            );
            currentSnackMins += snackIntervalMins;
            sIdx++;
          }
        }
      }
    }

    // Evaluate standalone fixed-time reminders for candidate calendar dates
    final candidateCalendarDates = [
      today.subtract(const Duration(days: 1)),
      today,
      today.add(const Duration(days: 1)),
    ];

    for (final cDate in candidateCalendarDates) {
      // 7. Workout
      if (settings.workoutEnabled && settings.workoutHour != null && settings.workoutMinute != null) {
        final wSched = DateTime(cDate.year, cDate.month, cDate.day, settings.workoutHour!, settings.workoutMinute!);
        addCandidateIfValid(
          type: 'workout',
          titleAr: NotificationContentRegistry.workout.titleAr,
          titleEn: NotificationContentRegistry.workout.titleEn,
          bodyAr: NotificationContentRegistry.workout.bodyAr,
          bodyEn: NotificationContentRegistry.workout.bodyEn,
          scheduledDateTime: wSched,
        );
      }

      // 8. Screen Off
      if (settings.screenOffEnabled && settings.screenOffHour != null && settings.screenOffMinute != null) {
        final sSched = DateTime(cDate.year, cDate.month, cDate.day, settings.screenOffHour!, settings.screenOffMinute!);
        addCandidateIfValid(
          type: 'screen_off',
          titleAr: NotificationContentRegistry.screenOff.titleAr,
          titleEn: NotificationContentRegistry.screenOff.titleEn,
          bodyAr: NotificationContentRegistry.screenOff.bodyAr,
          bodyEn: NotificationContentRegistry.screenOff.bodyEn,
          scheduledDateTime: sSched,
        );
      }

      // 9. Vitamins
      if (settings.vitaminsEnabled && settings.vitaminsHour != null && settings.vitaminsMinute != null) {
        final vSched = DateTime(cDate.year, cDate.month, cDate.day, settings.vitaminsHour!, settings.vitaminsMinute!);
        addCandidateIfValid(
          type: 'vitamins',
          titleAr: NotificationContentRegistry.vitamins.titleAr,
          titleEn: NotificationContentRegistry.vitamins.titleEn,
          bodyAr: NotificationContentRegistry.vitamins.bodyAr,
          bodyEn: NotificationContentRegistry.vitamins.bodyEn,
          scheduledDateTime: vSched,
        );
      }

      // 10. Eye Rest
      if (settings.eyeRestEnabled && settings.eyeRestHour != null && settings.eyeRestMinute != null) {
        final eSched = DateTime(cDate.year, cDate.month, cDate.day, settings.eyeRestHour!, settings.eyeRestMinute!);
        addCandidateIfValid(
          type: 'eye_rest',
          titleAr: NotificationContentRegistry.eyeRest.titleAr,
          titleEn: NotificationContentRegistry.eyeRest.titleEn,
          bodyAr: NotificationContentRegistry.eyeRest.bodyAr,
          bodyEn: NotificationContentRegistry.eyeRest.bodyEn,
          scheduledDateTime: eSched,
        );
      }

      // 11. Custom Alarms
      for (final custom in settings.customAlarms) {
        if (custom.isEnabled) {
          final cSched = DateTime(cDate.year, cDate.month, cDate.day, custom.hour, custom.minute);
          addCandidateIfValid(
            type: 'custom',
            customId: custom.id,
            titleAr: custom.title.isNotEmpty ? custom.title : 'تنبيه مخصص ⏰',
            titleEn: custom.title.isNotEmpty ? custom.title : 'Custom Alarm ⏰',
            bodyAr: custom.title.isNotEmpty ? 'تنبيه مخصص: ${custom.title}' : (isArabic ? 'تنبيه مخصص ⏰' : 'Custom Alarm ⏰'),
            bodyEn: custom.title.isNotEmpty ? 'Custom reminder: ${custom.title}' : 'Custom Alarm ⏰',
            scheduledDateTime: cSched,
          );
        }
      }
    }

    dueCandidates.addAll(candidatesByOccurrenceId.values);

    // Sort candidates chronologically (earliest due first)
    dueCandidates.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));
    return dueCandidates;
  }

  /// Evaluates active schedule against current time `now` (or provided `evalTime`) and returns the single latest due notification.
  /// If `allowPastInspected` is true (for Home Bell manual inspection), ignores last handled timestamp and returns latest due notification.
  static Future<AppNotificationData?> evaluateAndGetLatestDueNotification({
    required ReminderSettings settings,
    required bool isArabic,
    bool allowPastInspected = false,
    Set<String>? shownOccurrenceIds,
    DateTime? evalTime,
  }) async {
    if (!settings.isRunning) {
      return null;
    }

    final now = evalTime ?? DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day, 0, 0, 0);

    final dueCandidates = await getDueNotificationsForWindow(
      windowStart: todayStart.subtract(const Duration(seconds: 1)),
      windowEnd: now,
      settings: settings,
      isArabic: isArabic,
      ignoreLastHandled: allowPastInspected,
    );

    if (dueCandidates.isEmpty) {
      return null;
    }

    // Sort descending to inspect newest due candidate first
    dueCandidates.sort((a, b) => b.scheduledTime.compareTo(a.scheduledTime));

    if (allowPastInspected) {
      final latest = dueCandidates.first;
      await saveLatestNotification(latest);
      return latest;
    }

    // If shownOccurrenceIds is provided, filter out already shown ones if desired, or pick newest unshown
    AppNotificationData? selected;
    for (final cand in dueCandidates) {
      if (shownOccurrenceIds == null || !shownOccurrenceIds.contains(cand.occurrenceId)) {
        selected = cand;
        break;
      }
    }

    if (selected != null) {
      await saveLatestNotification(selected);
    }
    return selected;
  }
}
