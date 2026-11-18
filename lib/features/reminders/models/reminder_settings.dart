import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAlarm {
  final String id;
  String title;
  int hour;
  int minute;
  bool isEnabled;

  CustomAlarm({
    required this.id,
    required this.title,
    required this.hour,
    required this.minute,
    this.isEnabled = true,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'hour': hour,
        'minute': minute,
        'isEnabled': isEnabled,
      };

  factory CustomAlarm.fromJson(Map<String, dynamic> json) => CustomAlarm(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] ?? '',
        hour: json['hour'] ?? 12,
        minute: json['minute'] ?? 0,
        isEnabled: json['isEnabled'] ?? true,
      );
}

class ReminderSettings {
  bool isRunning;
  int? wakeHour;
  int? wakeMinute;
  int? sleepHour;
  int? sleepMinute;

  // Auto reminders toggles
  bool mealsEnabled;
  bool waterEnabled;
  int waterIntervalHours;
  bool fruitVegEnabled;
  int fruitVegIntervalHours;

  // Optional / Additional Reminders
  bool motivationEnabled;

  bool workoutEnabled;
  int? workoutHour;
  int? workoutMinute;

  bool screenOffEnabled;
  int? screenOffHour;
  int? screenOffMinute;

  bool vitaminsEnabled;
  int? vitaminsHour;
  int? vitaminsMinute;

  bool eyeRestEnabled;
  int? eyeRestHour;
  int? eyeRestMinute;

  // Custom User Alarms
  List<CustomAlarm> customAlarms;
  int? scheduleVersion;
  int? scheduleActivatedAt;

  ReminderSettings({
    this.isRunning = true, // Default ON
    this.wakeHour, // null by default for new install
    this.wakeMinute,
    this.sleepHour, // null by default for new install
    this.sleepMinute,
    this.mealsEnabled = true,
    this.waterEnabled = true,
    this.waterIntervalHours = 1,
    this.fruitVegEnabled = true,
    this.fruitVegIntervalHours = 2,
    this.motivationEnabled = true,
    this.workoutEnabled = false,
    this.workoutHour,
    this.workoutMinute,
    this.screenOffEnabled = false,
    this.screenOffHour,
    this.screenOffMinute,
    this.vitaminsEnabled = false,
    this.vitaminsHour,
    this.vitaminsMinute,
    this.eyeRestEnabled = false,
    this.eyeRestHour,
    this.eyeRestMinute,
    List<CustomAlarm>? customAlarms,
    this.scheduleVersion,
    this.scheduleActivatedAt,
  }) : customAlarms = customAlarms ?? [];

  bool get hasWakeTime => wakeHour != null && wakeMinute != null;
  bool get hasSleepTime => sleepHour != null && sleepMinute != null;
  bool get hasSelectedWakeAndSleepTimes => hasWakeTime && hasSleepTime;

  int get wakeTotalMins => (wakeHour ?? 0) * 60 + (wakeMinute ?? 0);

  int get sleepTotalMins {
    int mins = (sleepHour ?? 0) * 60 + (sleepMinute ?? 0);
    if (mins <= wakeTotalMins) {
      mins += 1440; // Handles sleep past midnight
    }
    return mins;
  }

  /// Morning Wake Water: 15 minutes after wake-up time.
  TimeOfDay? getWakeWaterTime() {
    if (!hasWakeTime) return null;
    int wMins = (wakeTotalMins + 15) % 1440;
    return TimeOfDay(hour: wMins ~/ 60, minute: wMins % 60);
  }

  /// 1. Breakfast: 30 minutes after wake-up time.
  TimeOfDay? getBreakfastTime() {
    if (!hasSelectedWakeAndSleepTimes) return null;
    int bMins = (wakeTotalMins + 30) % 1440;
    return TimeOfDay(hour: bMins ~/ 60, minute: bMins % 60);
  }

  /// 2. Lunch: 7 hours after calculated Breakfast time.
  TimeOfDay? getLunchTime() {
    final bTime = getBreakfastTime();
    if (bTime == null) return null;
    int bMins = bTime.hour * 60 + bTime.minute;
    int lMins = (bMins + 420) % 1440;
    return TimeOfDay(hour: lMins ~/ 60, minute: lMins % 60);
  }

  /// 3. Dinner: 1 hour before bedtime.
  TimeOfDay? getDinnerTime() {
    if (!hasSelectedWakeAndSleepTimes) return null;
    int dMinsFull = sleepTotalMins - 60;
    int dMins = dMinsFull % 1440;
    return TimeOfDay(hour: dMins ~/ 60, minute: dMins % 60);
  }

  /// 4. Motivation & Support: 1 hour after calculated Breakfast time.
  TimeOfDay? getMotivationTime() {
    final bTime = getBreakfastTime();
    if (bTime == null) return null;
    int bMins = bTime.hour * 60 + bTime.minute;
    int mMins = (bMins + 60) % 1440;
    return TimeOfDay(hour: mMins ~/ 60, minute: mMins % 60);
  }

  /// Snack Cutoff (in minutes from base wake date): 30 minutes before calculated Dinner time.
  int get snackCutoffMins => sleepTotalMins - 90;

  /// Water Cutoff (in minutes from base wake date): 1 hour before calculated Dinner time.
  int get waterCutoffMins => sleepTotalMins - 120;

  /// Checks if wake and sleep settings produce a timing conflict.
  bool hasScheduleConflict() {
    if (!hasSelectedWakeAndSleepTimes) return false;
    int awakeDuration = sleepTotalMins - wakeTotalMins;
    if (awakeDuration < 480) return true; // Less than 8 hours awake
    int bMinsFull = wakeTotalMins + 30;
    int lMinsFull = bMinsFull + 420; // 7 hours after breakfast
    int dMinsFull = sleepTotalMins - 60; // 1 hour before bedtime
    if (bMinsFull >= lMinsFull || lMinsFull >= dMinsFull || dMinsFull <= bMinsFull) {
      return true;
    }
    return false;
  }

  String? getScheduleConflictMessage(bool isArabic) {
    if (!hasSelectedWakeAndSleepTimes) return null;
    if (!hasScheduleConflict()) return null;
    int awakeDuration = sleepTotalMins - wakeTotalMins;
    if (awakeDuration < 480) {
      return isArabic
          ? 'تنبيه: فترة الاستيقاظ قصيرة جداً (أقل من ٨ ساعات). قد تتقارب مواعيد الوجبات بصورة غير منطقية.'
          : 'Warning: Wake period is too short (less than 8 hours). Meal times may overlap.';
    }
    return isArabic
        ? 'تنبيه: يوجد تعارض في الجدول الزمني للوجبات مع موعد النوم.'
        : 'Warning: Schedule conflict detected between meal times and bedtime.';
  }

  Map<String, dynamic> toJson() => {
        'isRunning': isRunning,
        'wakeHour': wakeHour,
        'wakeMinute': wakeMinute,
        'sleepHour': sleepHour,
        'sleepMinute': sleepMinute,
        'mealsEnabled': mealsEnabled,
        'waterEnabled': waterEnabled,
        'waterIntervalHours': waterIntervalHours,
        'fruitVegEnabled': fruitVegEnabled,
        'fruitVegIntervalHours': fruitVegIntervalHours,
        'motivationEnabled': motivationEnabled,
        'workoutEnabled': workoutEnabled,
        'workoutHour': workoutHour,
        'workoutMinute': workoutMinute,
        'screenOffEnabled': screenOffEnabled,
        'screenOffHour': screenOffHour,
        'screenOffMinute': screenOffMinute,
        'vitaminsEnabled': vitaminsEnabled,
        'vitaminsHour': vitaminsHour,
        'vitaminsMinute': vitaminsMinute,
        'eyeRestEnabled': eyeRestEnabled,
        'eyeRestHour': eyeRestHour,
        'eyeRestMinute': eyeRestMinute,
        'customAlarms': customAlarms.map((a) => a.toJson()).toList(),
        'scheduleVersion': scheduleVersion,
        'scheduleActivatedAt': scheduleActivatedAt,
      };

  factory ReminderSettings.fromJson(Map<String, dynamic> json) {
    List<CustomAlarm> loadedCustoms = [];
    if (json['customAlarms'] != null && json['customAlarms'] is List) {
      loadedCustoms = (json['customAlarms'] as List)
          .map((item) => CustomAlarm.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    return ReminderSettings(
      isRunning: json['isRunning'] ?? true,
      wakeHour: json['wakeHour'] as int?,
      wakeMinute: json['wakeMinute'] as int?,
      sleepHour: json['sleepHour'] as int?,
      sleepMinute: json['sleepMinute'] as int?,
      mealsEnabled: json['mealsEnabled'] ?? true,
      waterEnabled: json['waterEnabled'] ?? true,
      waterIntervalHours: json['waterIntervalHours'] ?? 1,
      fruitVegEnabled: json['fruitVegEnabled'] ?? true,
      fruitVegIntervalHours: json['fruitVegIntervalHours'] ?? 2,
      motivationEnabled: json['motivationEnabled'] ?? true,
      workoutEnabled: json['workoutEnabled'] ?? false,
      workoutHour: json['workoutHour'] as int?,
      workoutMinute: json['workoutMinute'] as int?,
      screenOffEnabled: json['screenOffEnabled'] ?? false,
      screenOffHour: json['screenOffHour'] as int?,
      screenOffMinute: json['screenOffMinute'] as int?,
      vitaminsEnabled: json['vitaminsEnabled'] ?? false,
      vitaminsHour: json['vitaminsHour'] as int?,
      vitaminsMinute: json['vitaminsMinute'] as int?,
      eyeRestEnabled: json['eyeRestEnabled'] ?? false,
      eyeRestHour: json['eyeRestHour'] as int?,
      eyeRestMinute: json['eyeRestMinute'] as int?,
      customAlarms: loadedCustoms,
      scheduleVersion: json['scheduleVersion'] as int?,
      scheduleActivatedAt: json['scheduleActivatedAt'] as int?,
    );
  }

  static const String _key = 'reminder_settings_v4';

  static Future<ReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? str = prefs.getString(_key);
    if (str == null) return ReminderSettings(); // Returns default fresh install settings (isRunning: true, wake/sleep: null)
    try {
      return ReminderSettings.fromJson(jsonDecode(str));
    } catch (_) {
      return ReminderSettings();
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(toJson()));
  }
}
