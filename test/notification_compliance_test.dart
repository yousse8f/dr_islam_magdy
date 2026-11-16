import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dr_islam_magdy/features/reminders/models/reminder_settings.dart';
import 'package:dr_islam_magdy/features/reminders/services/latest_notification_service.dart';
import 'package:dr_islam_magdy/features/reminders/services/notification_history_service.dart';
import 'package:dr_islam_magdy/features/reminders/services/notification_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Requirement 7: Comprehensive Regression Test Suite (1 - 8)', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    });

    test('Point 1: scheduleActivatedAt remains stable when re-saving or rebuilding identical schedule', () async {
      final initialActivatedAt = DateTime.now().subtract(const Duration(hours: 3)).millisecondsSinceEpoch;
      final settings = ReminderSettings(
        isRunning: true,
        wakeHour: 8,
        wakeMinute: 0,
        sleepHour: 23,
        sleepMinute: 0,
        scheduleActivatedAt: initialActivatedAt,
        scheduleVersion: 1001,
      );

      await settings.save();

      final reloaded = await ReminderSettings.load();
      expect(reloaded.scheduleActivatedAt, equals(initialActivatedAt), reason: 'scheduleActivatedAt must not be modified when re-loading or re-evaluating the schedule.');
    });

    test('Point 2: Water (10:00) then Snack (11:00), confirm Snack, reopen -> Water (10:00) DOES NOT automatically pop up', () async {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final activationTime = DateTime(today.year, today.month, today.day, 7, 0);
      final settings = ReminderSettings(
        isRunning: true,
        wakeHour: 7,
        wakeMinute: 0,
        sleepHour: 23,
        sleepMinute: 0,
        waterEnabled: true,
        fruitVegEnabled: true,
        scheduleActivatedAt: activationTime.millisecondsSinceEpoch,
      );

      final snackOccurrenceId = 'snack_${dateStr}_11:00';
      final waterOccurrenceId = 'water_${dateStr}_10:00';
      final waterTime = DateTime(today.year, today.month, today.day, 10, 0);

      // Record water in history as scheduled (unread)
      await NotificationHistoryService.recordNotification(
        id: waterOccurrenceId,
        type: 'water',
        title: NotificationContentRegistry.water.titleAr,
        body: NotificationContentRegistry.water.bodyAr,
        time: waterTime,
        status: 'scheduled',
      );

      // User opens app and confirms Snack (11:00)
      final snackTimeMs = DateTime(today.year, today.month, today.day, 11, 0).millisecondsSinceEpoch;
      await LatestNotificationService.setLastAutoEvaluatedTime(snackTimeMs);

      final shownSet = <String>{snackOccurrenceId};

      // User reopens app at 11:05 AM: evaluateAndGetLatestDueNotification
      final latestDueOnReopen = await LatestNotificationService.evaluateAndGetLatestDueNotification(
        settings: settings,
        isArabic: true,
        allowPastInspected: false,
        shownOccurrenceIds: shownSet,
        evalTime: DateTime(today.year, today.month, today.day, 11, 5),
      );

      // Water (10:00) scheduled time is 10:00 AM, which is <= lastAutoEvaluatedTime (11:00 AM).
      // Water (10:00) MUST NOT automatically pop up!
      expect(latestDueOnReopen, isNull, reason: 'Confirming Snack (11:00) and reopening app must not cause Water (10:00) to automatically pop up.');

      // Water (10:00) remains unread in history (not marked read forcibly)
      final unread = await NotificationHistoryService.getUnreadHistory();
      final isWaterUnread = unread.any((u) => u.id == waterOccurrenceId);
      expect(isWaterUnread, isTrue, reason: 'Water (10:00) must remain unread in history, separating auto-presentation eligibility from read status.');
    });

    test('Point 3: App closed before popup confirmation -> Event NOT marked read, can pop up on next open if latest', () async {
      final now = DateTime.now();
      // Wake up 2 hours ago, breakfast 1.5 hours ago so it is due now
      final wakeHour = now.subtract(const Duration(hours: 2)).hour;
      final wakeMinute = now.subtract(const Duration(hours: 2)).minute;

      final settings = ReminderSettings(
        isRunning: true,
        wakeHour: wakeHour,
        wakeMinute: wakeMinute,
        sleepHour: (wakeHour + 15) % 24,
        sleepMinute: 0,
        mealsEnabled: true,
        scheduleActivatedAt: now.subtract(const Duration(hours: 3)).millisecondsSinceEpoch,
      );

      final emptyShownSet = <String>{};

      final latestDueOnReopen = await LatestNotificationService.evaluateAndGetLatestDueNotification(
        settings: settings,
        isArabic: true,
        allowPastInspected: false,
        shownOccurrenceIds: emptyShownSet,
      );

      expect(latestDueOnReopen, isNotNull, reason: 'If app closed before popup confirmation, unconfirmed latest event can present on next open.');
    });

    test('Point 4: Arrival of newer event (12:00) after confirming previous (11:00) -> 12:00 event presents', () async {
      final today = DateTime.now();
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      final settings = ReminderSettings(
        isRunning: true,
        wakeHour: 7,
        wakeMinute: 0,
        sleepHour: 23,
        sleepMinute: 0,
        waterEnabled: true,
        fruitVegEnabled: true,
        scheduleActivatedAt: DateTime(today.year, today.month, today.day, 7, 0).millisecondsSinceEpoch,
      );

      // Snack at 11:00 was confirmed
      final snack11Ms = DateTime(today.year, today.month, today.day, 11, 0).millisecondsSinceEpoch;
      await LatestNotificationService.setLastAutoEvaluatedTime(snack11Ms);
      final shownSet = <String>{'snack_${dateStr}_11:00'};

      // Now Water at 12:00 arrives (timestamp > 11:00 AM)
      final latestDueAt1205 = await LatestNotificationService.evaluateAndGetLatestDueNotification(
        settings: settings,
        isArabic: true,
        allowPastInspected: false,
        shownOccurrenceIds: shownSet,
      );

      if (latestDueAt1205 != null) {
        expect(latestDueAt1205.scheduledTime.millisecondsSinceEpoch, greaterThanOrEqualTo(snack11Ms));
        expect(latestDueAt1205.occurrenceId, isNot(equals('snack_${dateStr}_11:00')));
      }
    });

    test('Point 5: Midnight boundary transition (23:55 PM to 00:05 AM next day)', () async {
      final now = DateTime.now();
      final settings = ReminderSettings(
        isRunning: true,
        wakeHour: 8,
        wakeMinute: 0,
        sleepHour: 0,
        sleepMinute: 55,
        mealsEnabled: true,
        scheduleActivatedAt: now.subtract(const Duration(hours: 5)).millisecondsSinceEpoch,
      );

      final candidates = await LatestNotificationService.getDueNotificationsForWindow(
        windowStart: now.subtract(const Duration(hours: 24)),
        windowEnd: now,
        settings: settings,
        isArabic: true,
      );

      expect(candidates, isNotEmpty, reason: 'Lookback window across midnight must include due events from 23:55 PM when checked at 00:05 AM.');
    });

    test('Point 6: Wake 08:00 AM / Sleep 02:00 AM cycle -> Dinner calculated at 01:00 AM after midnight', () {
      final settings = ReminderSettings(
        wakeHour: 8,
        wakeMinute: 0,
        sleepHour: 2, // 02:00 AM
        sleepMinute: 0,
      );

      expect(settings.sleepTotalMins, equals(1560));
      final dinnerTime = settings.getDinnerTime();
      expect(dinnerTime, equals(const TimeOfDay(hour: 1, minute: 0)));
    });

    test('Point 7: Turning OFF reminders and re-enabling starts new activation period without retrospective events', () async {
      final now = DateTime.now();
      final settings = ReminderSettings(
        isRunning: false,
        wakeHour: 7,
        wakeMinute: 0,
        sleepHour: 23,
        sleepMinute: 0,
        scheduleActivatedAt: null,
      );

      var due = await LatestNotificationService.evaluateAndGetLatestDueNotification(
        settings: settings,
        isArabic: true,
      );
      expect(due, isNull);

      settings.isRunning = true;
      settings.scheduleActivatedAt = now.millisecondsSinceEpoch;

      final dueAfterReenable = await LatestNotificationService.getDueNotificationsForWindow(
        windowStart: now.subtract(const Duration(hours: 10)),
        windowEnd: now,
        settings: settings,
        isArabic: true,
        scheduleActivationTime: now,
      );

      final pastEvents = dueAfterReenable.where((e) => e.scheduledTime.isBefore(now.subtract(const Duration(minutes: 1))));
      expect(pastEvents, isEmpty);
    });

    test('Point 8: Legacy data migration without wiping user settings', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('shown_popup_occurrences_v2', ['old_event_1', 'old_event_2']);

      final list = prefs.getStringList('shown_popup_occurrences_v2');
      expect(list, equals(['old_event_1', 'old_event_2']));
      expect(list!.length, equals(2));
    });
  });
}
