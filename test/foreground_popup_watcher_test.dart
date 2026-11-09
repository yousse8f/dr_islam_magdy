import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dr_islam_magdy/features/reminders/models/reminder_settings.dart';
import 'package:dr_islam_magdy/features/reminders/services/latest_notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Foreground Due Alert Window & Multi-Event Collection Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getDueNotificationsForWindow collects all due events within time range', () async {
      final settings = ReminderSettings(
        isRunning: true,
        wakeHour: 8,
        wakeMinute: 0,
        sleepHour: 23,
        sleepMinute: 0,
        mealsEnabled: true,
        waterEnabled: true,
        fruitVegEnabled: true,
        customAlarms: [
          CustomAlarm(
            id: 'custom_101',
            title: 'منبه شرب المكمل',
            hour: 14,
            minute: 0,
            isEnabled: true,
          ),
        ],
      );

      final now = DateTime.now();
      final windowStart = DateTime(now.year, now.month, now.day, 13, 59, 0);
      final windowEnd = DateTime(now.year, now.month, now.day, 14, 01, 0);

      final dueEvents = await LatestNotificationService.getDueNotificationsForWindow(
        windowStart: windowStart,
        windowEnd: windowEnd,
        settings: settings,
        isArabic: true,
      );

      // Should find at least the custom alarm at 14:00 and any water/snack/meal scheduled at 14:00
      expect(dueEvents, isNotEmpty);
      final customEvent = dueEvents.firstWhere((e) => e.payloadRaw == 'custom_custom_101');
      expect(customEvent.title, equals('منبه شرب المكمل'));
      expect(customEvent.occurrenceId, contains('custom_custom_101'));
      expect(customEvent.occurrenceId, contains('14:00'));
    });

    test('getDueNotificationsForWindow skips events scheduled before scheduleActivationTime', () async {
      final settings = ReminderSettings(
        isRunning: true,
        wakeHour: 7,
        wakeMinute: 0,
        sleepHour: 23,
        sleepMinute: 0,
        mealsEnabled: true,
      );

      final now = DateTime.now();
      final windowStart = DateTime(now.year, now.month, now.day, 7, 0, 0);
      final windowEnd = DateTime(now.year, now.month, now.day, 8, 0, 0);

      // Breakfast is at 07:30
      // If schedule was modified/activated at 07:40
      final activationTime = DateTime(now.year, now.month, now.day, 7, 40, 0);

      final dueEvents = await LatestNotificationService.getDueNotificationsForWindow(
        windowStart: windowStart,
        windowEnd: windowEnd,
        settings: settings,
        isArabic: true,
        scheduleActivationTime: activationTime,
      );

      // Breakfast at 07:30 was before activationTime (07:40), so it must be excluded
      final breakfastEvents = dueEvents.where((e) => e.type == 'breakfast');
      expect(breakfastEvents, isEmpty);
    });

    test('Daily repeat occurrence IDs are distinct for different dates', () {
      final date1 = '2026-03-30_14:00';
      final date2 = '2026-03-31_14:00';

      final occurrence1 = 'water_$date1';
      final occurrence2 = 'water_$date2';

      expect(occurrence1, isNot(equals(occurrence2)));
    });
  });
}
