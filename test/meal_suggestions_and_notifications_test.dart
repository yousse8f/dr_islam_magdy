import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dr_islam_magdy/features/reminders/data/meal_suggestions_data.dart';
import 'package:dr_islam_magdy/features/reminders/models/reminder_settings.dart';
import 'package:dr_islam_magdy/features/reminders/services/app_notification_data.dart';
import 'package:dr_islam_magdy/features/reminders/services/latest_notification_service.dart';
import 'package:dr_islam_magdy/features/reminders/services/notification_history_service.dart';
import 'package:dr_islam_magdy/features/reminders/services/notification_channels.dart';
import 'package:dr_islam_magdy/features/reminders/services/notification_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Requirement 3: Meal Suggestions Verification', () {
    test('Total meal suggestions count is exactly 50', () {
      final all = MealSuggestionsData.allSuggestions;
      expect(all.length, equals(50));
    });

    test('Section "الفطار والعشاء" contains 25 meals', () {
      final bdList = MealSuggestionsData.getBreakfastAndDinnerSuggestions();
      expect(bdList.length, equals(25));
      for (final meal in bdList) {
        expect(meal.category, equals('breakfast_dinner'));
        expect(meal.ingredients, isNotEmpty);
        expect(meal.totalCalories, greaterThan(0));
      }
    });

    test('Section "الغداء" contains 25 meals', () {
      final lunchList = MealSuggestionsData.getLunchSuggestions();
      expect(lunchList.length, equals(25));
      for (final meal in lunchList) {
        expect(meal.category, equals('lunch'));
        expect(meal.ingredients, isNotEmpty);
        expect(meal.totalCalories, greaterThan(0));
      }
    });

    test('Calorie calculation equals sum of ingredients rounded', () {
      for (final meal in MealSuggestionsData.allSuggestions) {
        double calculatedSum = 0;
        for (final ing in meal.ingredients) {
          calculatedSum += (ing.weightGrams * ing.caloriesPer100g) / 100.0;
          expect(ing.sourceId, isNotEmpty);
          expect(ing.sourceUrl, startsWith('http'));
        }
        expect(meal.totalCalories, equals(calculatedSum.round()));
      }
    });
  });

  group('Requirement 1 & 2: Unified Notification & Latest Notification Service', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('AppNotificationData parses JSON payload and legacy payload correctly', () {
      final jsonPayload = '{"occurrenceId":"water_123","type":"water","title":"تنبيه المياه 💧","body":"خدلك شوية مية","scheduledTime":1700000000000}';
      final parsedJson = AppNotificationData.parsePayload(jsonPayload);
      expect(parsedJson.type, equals('water'));
      expect(parsedJson.title, equals('تنبيه المياه 💧'));
      expect(parsedJson.body, equals('خدلك شوية مية'));

      final legacyPayload = 'breakfast';
      final parsedLegacy = AppNotificationData.parsePayload(legacyPayload, isArabic: true);
      expect(parsedLegacy.type, equals('breakfast'));
      expect(parsedLegacy.title, contains('الإفطار'));
    });

    test('LatestNotificationService saves and preserves latest arrived notification', () async {
      final now = DateTime.now();
      final data1 = AppNotificationData(
        occurrenceId: 'water_1',
        type: 'water',
        title: 'تنبيه المياه 💧',
        body: 'اشرب مية',
        scheduledTime: now.subtract(const Duration(minutes: 30)),
      );

      final data2 = AppNotificationData(
        occurrenceId: 'snack_1',
        type: 'snack',
        title: 'تنبيه السناك 🍎',
        body: 'خد سناك صحي',
        scheduledTime: now.subtract(const Duration(minutes: 10)),
      );

      await LatestNotificationService.saveLatestNotification(data1);
      var stored = await LatestNotificationService.getLatestNotification();
      expect(stored?.type, equals('water'));

      await LatestNotificationService.saveLatestNotification(data2);
      stored = await LatestNotificationService.getLatestNotification();
      expect(stored?.type, equals('snack'));
    });

    test('evaluateAndGetLatestDueNotification correctly filters past due notifications up to current time', () async {
      final settings = ReminderSettings(
        isRunning: true,
        wakeHour: 0,
        wakeMinute: 0,
        sleepHour: 23,
        sleepMinute: 0,
        mealsEnabled: true,
        waterEnabled: true,
      );

      final latestDue = await LatestNotificationService.evaluateAndGetLatestDueNotification(
        settings: settings,
        isArabic: true,
      );

      // Unless it's earlier than 07:30 AM, latestDue will return the most recent active reminder up to now
      expect(latestDue, isNotNull);
    });

    test('NotificationHistoryService records notifications, gets unread history, and marks as read', () async {
      final now = DateTime.now();
      await NotificationHistoryService.recordNotification(
        id: 'water_test_1',
        type: 'water',
        title: 'تنبيه المياه 💧',
        body: 'اشرب مية',
        time: now.subtract(const Duration(minutes: 20)),
        status: 'scheduled',
      );

      await NotificationHistoryService.recordNotification(
        id: 'snack_test_2',
        type: 'snack',
        title: 'تنبيه السناك 🍎',
        body: 'خد سناك',
        time: now.subtract(const Duration(minutes: 10)),
        status: 'scheduled',
      );

      var unread = await NotificationHistoryService.getUnreadHistory();
      expect(unread.length, equals(2));
      // Chronological order: oldest first (water_test_1 then snack_test_2)
      expect(unread[0].type, equals('water'));
      expect(unread[1].type, equals('snack'));

      // Mark first as read
      await NotificationHistoryService.markAsRead(unread[0].id);

      unread = await NotificationHistoryService.getUnreadHistory();
      expect(unread.length, equals(1));
      expect(unread[0].type, equals('snack'));
    });

    test('Morning Wake Water reminder: timing, midnight crossover, content, and ID verification', () {
      // 1. Wake time 07:00 -> Wake water 07:15
      final settings1 = ReminderSettings(wakeHour: 7, wakeMinute: 0);
      final ww1 = settings1.getWakeWaterTime();
      expect(ww1?.hour, equals(7));
      expect(ww1?.minute, equals(15));

      // 2. Midnight crossover: Wake time 23:50 -> Wake water 00:05
      final settingsMidnight = ReminderSettings(wakeHour: 23, wakeMinute: 50);
      final wwMidnight = settingsMidnight.getWakeWaterTime();
      expect(wwMidnight?.hour, equals(0));
      expect(wwMidnight?.minute, equals(5));

      // 3. 00:00 valid wake time -> Wake water 00:15
      final settingsZero = ReminderSettings(wakeHour: 0, wakeMinute: 0);
      final wwZero = settingsZero.getWakeWaterTime();
      expect(wwZero?.hour, equals(0));
      expect(wwZero?.minute, equals(15));

      // 4. Missing wake time -> returns null (no wake water scheduled)
      final settingsNull = ReminderSettings();
      expect(settingsNull.getWakeWaterTime(), isNull);

      // 5. Verify literal body text and configuration
      expect(
        NotificationContentRegistry.wakeWater.bodyAr,
        equals('ابدا يومك بشرب المياه درجة حرارتها معتدلة مهمه للمعده و الكبد والكلى.'),
      );
      expect(NotificationContentRegistry.wakeWater.channelId, equals(NotificationChannels.waterChannelId));
      expect(NotificationContentRegistry.wakeWater.soundName, equals(NotificationChannels.waterSound));
      expect(NotificationContentRegistry.wakeWater.idRangeStart, equals(2500));
    });
  });
}
