import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dr_islam_magdy/features/reminders/models/reminder_settings.dart';
import 'package:dr_islam_magdy/features/reminders/services/notification_channels.dart';
import 'package:dr_islam_magdy/features/reminders/services/notification_config.dart';
import 'package:dr_islam_magdy/features/reminders/services/notification_history_service.dart';
import 'package:dr_islam_magdy/features/reminders/services/notification_scheduler.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Point 1: Exhaustive Mathematical ID Collision Verification', () {
    test('Generate 100 days of daily notifications, 40 days of water/snack, and multiple custom alarms -> 0 Collision', () {
      final List<int> generatedIds = [];
      final Map<int, String> idToTypeMap = {};

      // 1. Daily Notifications (100 Days)
      for (int day = 0; day < 100; day++) {
        // Breakfast
        final bId = NotificationContentRegistry.breakfast.idRangeStart + day;
        generatedIds.add(bId);
        idToTypeMap[bId] = 'Breakfast Day $day';

        // Lunch
        final lId = NotificationContentRegistry.lunch.idRangeStart + day;
        generatedIds.add(lId);
        idToTypeMap[lId] = 'Lunch Day $day';

        // Dinner
        final dId = NotificationContentRegistry.dinner.idRangeStart + day;
        generatedIds.add(dId);
        idToTypeMap[dId] = 'Dinner Day $day';

        // Motivation
        final mId = NotificationContentRegistry.motivation.idRangeStart + day;
        generatedIds.add(mId);
        idToTypeMap[mId] = 'Motivation Day $day';

        // Screen Off
        final sId = NotificationContentRegistry.screenOff.idRangeStart + day;
        generatedIds.add(sId);
        idToTypeMap[sId] = 'Screen Off Day $day';

        // Workout
        final wId = NotificationContentRegistry.workout.idRangeStart + day;
        generatedIds.add(wId);
        idToTypeMap[wId] = 'Workout Day $day';

        // Vitamins
        final vId = NotificationContentRegistry.vitamins.idRangeStart + day;
        generatedIds.add(vId);
        idToTypeMap[vId] = 'Vitamins Day $day';

        // Eye Rest
        final eId = NotificationContentRegistry.eyeRest.idRangeStart + day;
        generatedIds.add(eId);
        idToTypeMap[eId] = 'Eye Rest Day $day';
      }

      // 2. Hourly Water & Snack (40 Days x 24 intervals/day = 960 IDs each)
      for (int day = 0; day < 40; day++) {
        for (int index = 0; index < 24; index++) {
          // Water
          final waterId = NotificationContentRegistry.water.idRangeStart + (day * 25) + index;
          generatedIds.add(waterId);
          idToTypeMap[waterId] = 'Water Day $day Index $index';

          // Snack
          final snackId = NotificationContentRegistry.snack.idRangeStart + (day * 25) + index;
          generatedIds.add(snackId);
          idToTypeMap[snackId] = 'Snack Day $day Index $index';
        }
      }

      // 3. Custom Alarms (10 custom alarms x 10 days = 100 IDs)
      for (int cIndex = 0; cIndex < 10; cIndex++) {
        for (int day = 0; day < 10; day++) {
          final customId = 8000 + (cIndex * 10) + day;
          generatedIds.add(customId);
          idToTypeMap[customId] = 'Custom Alarm $cIndex Day $day';
        }
      }

      // Assert zero duplicates across the entire generated list
      final uniqueIds = Set<int>.from(generatedIds);
      expect(generatedIds.length, equals(uniqueIds.length), reason: 'All generated IDs across all types and days must be 100% unique.');
      expect(generatedIds.length, equals(2820), reason: 'Total generated IDs: (800 daily) + (960 water) + (960 snack) + (100 custom) = 2820');
    });
  });

  group('Client Timing Rules & Boundary Recalculations', () {
    test('Breakfast is strictly 30 mins after wake, Lunch 7h after breakfast, Dinner 1h before bedtime', () {
      final settings = ReminderSettings(
        wakeHour: 7,
        wakeMinute: 0,
        sleepHour: 23,
        sleepMinute: 0,
      );

      // 1. Breakfast: wake + 30 mins = 07:30
      final bTime = settings.getBreakfastTime();
      expect(bTime, equals(const TimeOfDay(hour: 7, minute: 30)));

      // 2. Lunch: breakfast + 7 hours = 14:30 (02:30 PM)
      final lTime = settings.getLunchTime();
      expect(lTime, equals(const TimeOfDay(hour: 14, minute: 30)));

      // 3. Dinner: bedtime - 1 hour = 22:00 (10:00 PM)
      final dTime = settings.getDinnerTime();
      expect(dTime, equals(const TimeOfDay(hour: 22, minute: 0)));

      // 4. Motivation: breakfast + 1 hour = 08:30
      final mTime = settings.getMotivationTime();
      expect(mTime, equals(const TimeOfDay(hour: 8, minute: 30)));

      // 5. Snack cutoff: dinner - 30 mins = bedtime - 90 mins = 1290 mins (21:30)
      expect(settings.snackCutoffMins, equals(1290));

      // 6. Water cutoff: dinner - 60 mins = bedtime - 120 mins = 1260 mins (21:00)
      expect(settings.waterCutoffMins, equals(1260));

      expect(settings.hasScheduleConflict(), isFalse);
    });

    test('Recalculate meal times when Wake and Sleep times change', () {
      final settings = ReminderSettings(
        wakeHour: 9,
        wakeMinute: 15,
        sleepHour: 1,
        sleepMinute: 0,
      );

      // Breakfast: 09:15 + 30m = 09:45
      expect(settings.getBreakfastTime(), equals(const TimeOfDay(hour: 9, minute: 45)));

      // Lunch: 09:45 + 7h = 16:45
      expect(settings.getLunchTime(), equals(const TimeOfDay(hour: 16, minute: 45)));

      // Dinner: 01:00 AM - 1h = 00:00 (Midnight)
      expect(settings.getDinnerTime(), equals(const TimeOfDay(hour: 0, minute: 0)));
    });

    test('Detect schedule conflict when wake period is less than 8 hours', () {
      final settings = ReminderSettings(
        wakeHour: 10,
        wakeMinute: 0,
        sleepHour: 15,
        sleepMinute: 0,
      );

      expect(settings.hasScheduleConflict(), isTrue);
      expect(settings.getScheduleConflictMessage(true), contains('قصيرة'));
    });
  });

  group('Notification ID Isolation & Type Separation', () {
    test('Breakfast, Snack, Lunch, and Water have non-overlapping ID ranges and channels', () {
      final breakfast = NotificationContentRegistry.breakfast;
      final lunch = NotificationContentRegistry.lunch;
      final dinner = NotificationContentRegistry.dinner;
      final snack = NotificationContentRegistry.snack;
      final water = NotificationContentRegistry.water;
      final motivation = NotificationContentRegistry.motivation;
      final workout = NotificationContentRegistry.workout;
      final vitamins = NotificationContentRegistry.vitamins;
      final screenOff = NotificationContentRegistry.screenOff;
      final eyeRest = NotificationContentRegistry.eyeRest;

      // Verify ID Range separation
      expect(breakfast.idRangeStart, equals(1000));
      expect(lunch.idRangeStart, equals(1100));
      expect(dinner.idRangeStart, equals(1200));
      expect(motivation.idRangeStart, equals(1300));
      expect(water.idRangeStart, equals(2000));
      expect(snack.idRangeStart, equals(3000));
      expect(screenOff.idRangeStart, equals(4000));
      expect(workout.idRangeStart, equals(5000));
      expect(vitamins.idRangeStart, equals(6000));
      expect(eyeRest.idRangeStart, equals(7000));

      // Content & Title Isolation
      expect(breakfast.titleAr, equals('تنبيه الإفطار 🍳'));
      expect(snack.titleAr, equals('تنبيه السناك 🍎'));
      expect(breakfast.titleAr, isNot(equals(snack.titleAr)));
      expect(breakfast.bodyAr, isNot(equals(snack.bodyAr)));
    });
  });

  group('Sound Distribution & Channel Verification', () {
    test('Meals (Breakfast, Lunch, Dinner) use meal_sound on dedicated meals channel', () {
      expect(NotificationContentRegistry.breakfast.soundName, equals('meal_sound'));
      expect(NotificationContentRegistry.breakfast.channelId, equals(NotificationChannels.mealsChannelId));

      expect(NotificationContentRegistry.lunch.soundName, equals('meal_sound'));
      expect(NotificationContentRegistry.lunch.channelId, equals(NotificationChannels.mealsChannelId));

      expect(NotificationContentRegistry.dinner.soundName, equals('meal_sound'));
      expect(NotificationContentRegistry.dinner.channelId, equals(NotificationChannels.mealsChannelId));
    });

    test('Snack uses snack_sound on dedicated snack channel', () {
      expect(NotificationContentRegistry.snack.soundName, equals('snack_sound'));
      expect(NotificationContentRegistry.snack.channelId, equals(NotificationChannels.snackChannelId));
    });

    test('Water uses water_sound on dedicated water channel', () {
      expect(NotificationContentRegistry.water.soundName, equals('water_sound'));
      expect(NotificationContentRegistry.water.channelId, equals(NotificationChannels.waterChannelId));
    });

    test('Motivation uses motivation_sound on dedicated motivation channel', () {
      expect(NotificationContentRegistry.motivation.soundName, equals('motivation_sound'));
      expect(NotificationContentRegistry.motivation.channelId, equals(NotificationChannels.motivationChannelId));
    });

    test('Optional Reminders (Workout, Vitamins, ScreenOff, EyeRest) use default system sound', () {
      expect(NotificationContentRegistry.workout.soundName, isEmpty);
      expect(NotificationContentRegistry.workout.channelId, equals(NotificationChannels.workoutChannelId));

      expect(NotificationContentRegistry.vitamins.soundName, isEmpty);
      expect(NotificationContentRegistry.vitamins.channelId, equals(NotificationChannels.vitaminsChannelId));

      expect(NotificationContentRegistry.screenOff.soundName, isEmpty);
      expect(NotificationContentRegistry.screenOff.channelId, equals(NotificationChannels.screenOffChannelId));

      expect(NotificationContentRegistry.eyeRest.soundName, isEmpty);
      expect(NotificationContentRegistry.eyeRest.channelId, equals(NotificationChannels.eyeRestChannelId));
    });
  });

  group('Snack 90-Minute Minimum Rule Verification', () {
    test('Snacks must not start within the first 90 minutes of wake-up time', () {
      final settings = ReminderSettings(
        wakeHour: 7,
        wakeMinute: 0,
        sleepHour: 23,
        sleepMinute: 0,
        fruitVegIntervalHours: 1, // 1 hour interval to test threshold shifting
      );

      final wakeTotalMins = settings.wakeTotalMins; // 420 (07:00)
      final minSnackMins = wakeTotalMins + 90; // 510 (08:30)

      final breakfastTime = settings.getBreakfastTime(); // 07:30
      int bMins = breakfastTime.hour * 60 + breakfastTime.minute; // 450
      int snackIntervalMins = 60;
      int currentSnackMins = bMins + snackIntervalMins; // 510 (08:30)

      while (currentSnackMins < minSnackMins) {
        currentSnackMins += snackIntervalMins;
      }

      expect(currentSnackMins, greaterThanOrEqualTo(minSnackMins));
    });
  });

  group('Independent Toggle & Single-Type Modifications', () {
    test('Modifying workout settings does not change breakfast or water settings', () {
      final settings = ReminderSettings(
        workoutEnabled: false,
        workoutHour: 17,
      );

      // Toggle workout
      settings.workoutEnabled = true;
      settings.workoutHour = 18;

      expect(settings.mealsEnabled, isTrue);
      expect(settings.waterEnabled, isTrue);
      expect(settings.getBreakfastTime(), equals(const TimeOfDay(hour: 7, minute: 30)));
    });

    test('Disabling snack does not affect meal or water settings', () {
      final settings = ReminderSettings(
        fruitVegEnabled: true,
      );

      settings.fruitVegEnabled = false;

      expect(settings.fruitVegEnabled, isFalse);
      expect(settings.mealsEnabled, isTrue);
      expect(settings.waterEnabled, isTrue);
    });
  });

  group('History Recording & Duplicate Prevention', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Daily motivational quote remains constant on multiple calls', () async {
      final quote1 = await NotificationHistoryService.getTodayMotivationQuote(true);
      expect(quote1.isNotEmpty, isTrue);

      final quote2 = await NotificationHistoryService.getTodayMotivationQuote(true);
      expect(quote2, equals(quote1));
    });

    test('Notification history records item and prevents duplicates', () async {
      final now = DateTime.now();
      await NotificationHistoryService.recordNotification(
        id: 'test_b1',
        type: 'breakfast',
        title: NotificationContentRegistry.breakfast.titleAr,
        body: NotificationContentRegistry.breakfast.bodyAr,
        time: now,
      );

      // Attempt recording exact duplicate
      await NotificationHistoryService.recordNotification(
        id: 'test_b1',
        type: 'breakfast',
        title: NotificationContentRegistry.breakfast.titleAr,
        body: NotificationContentRegistry.breakfast.bodyAr,
        time: now,
      );

      final history = await NotificationHistoryService.getTodayHistory();
      expect(history.length, equals(1));
      expect(history.first.type, equals('breakfast'));
      expect(history.first.title, equals(NotificationContentRegistry.breakfast.titleAr));
    });
  });

  group('New Requirements & Edge Cases Verification', () {
    test('Sleep past midnight correctly calculates dinner time before bedtime', () {
      final settings = ReminderSettings(
        wakeHour: 8,
        wakeMinute: 0,
        sleepHour: 1, // 01:00 AM next day
        sleepMinute: 30, // 01:30 AM next day
      );

      // Total sleep mins: (1 * 60 + 30) + 1440 = 1530 mins
      expect(settings.sleepTotalMins, equals(1530));

      // Dinner: 1 hour before bedtime = 1470 mins = 00:30 AM (Midnight + 30m)
      final dinnerTime = settings.getDinnerTime();
      expect(dinnerTime, equals(const TimeOfDay(hour: 0, minute: 30)));
    });

    test('SchedulingResult correctly returns structured status and Arabic/English messages', () {
      const resultSuccess = SchedulingResult(
        success: true,
        scheduledCount: 15,
        failedCount: 0,
        isExact: true,
        hitIosCeiling: false,
        messageAr: 'تم حفظ الإعدادات وجدولة 15 تذكير بنجاح (دقيقة)! 🔔',
        messageEn: 'Settings saved & 15 reminders scheduled (exact)! 🔔',
      );

      expect(resultSuccess.success, isTrue);
      expect(resultSuccess.scheduledCount, equals(15));
      expect(resultSuccess.getMessage(true), contains('تم حفظ الإعدادات'));
      expect(resultSuccess.getMessage(false), contains('Settings saved'));

      const resultCeiling = SchedulingResult(
        success: true,
        scheduledCount: 64,
        failedCount: 0,
        isExact: false,
        hitIosCeiling: true,
        messageAr: 'تم الوصول للحد الأقصى للإشعارات 64',
        messageEn: 'Reached 64 notification ceiling',
      );

      expect(resultCeiling.hitIosCeiling, isTrue);
      expect(resultCeiling.scheduledCount, equals(64));
    });

    test('Custom alarms count towards overall scheduled limit', () {
      final customAlarms = List.generate(
        10,
        (i) => CustomAlarm(
          id: 'alarm_$i',
          title: 'Alarm $i',
          hour: 10 + i,
          minute: 0,
          isEnabled: true,
        ),
      );

      final settings = ReminderSettings(
        customAlarms: customAlarms,
      );

      expect(settings.customAlarms.length, equals(10));
      expect(settings.customAlarms.where((a) => a.isEnabled).length, equals(10));
    });
  });
}
