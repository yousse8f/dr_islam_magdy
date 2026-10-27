import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class ReminderSettings {
  bool isRunning;
  int wakeHour;
  int wakeMinute;
  int sleepHour;
  int sleepMinute;

  // Meal
  bool mealEnabled;
  int mealIntervalHours;

  // Water
  bool waterEnabled;
  int waterIntervalHours;

  // Vegetables / Veggies
  bool veggiesEnabled;
  int veggiesIntervalHours;

  // Screen Off / Bedtime Eye Rest
  bool screenOffEnabled;
  int screenOffMinutesBeforeSleep;

  // Workout Reminder
  bool workoutEnabled;
  int workoutHour;
  int workoutMinute;

  // Vitamins Reminder
  bool vitaminsEnabled;
  int vitaminsHour;
  int vitaminsMinute;

  // Eye Strain / Periodic Screen Rest
  bool eyeRestEnabled;
  int eyeRestIntervalHours;

  ReminderSettings({
    this.isRunning = false,
    this.wakeHour = 7,
    this.wakeMinute = 0,
    this.sleepHour = 23,
    this.sleepMinute = 0,
    this.mealEnabled = true,
    this.mealIntervalHours = 1,
    this.waterEnabled = true,
    this.waterIntervalHours = 2,
    this.veggiesEnabled = false,
    this.veggiesIntervalHours = 3,
    this.screenOffEnabled = true,
    this.screenOffMinutesBeforeSleep = 30,
    this.workoutEnabled = true,
    this.workoutHour = 17,
    this.workoutMinute = 0,
    this.vitaminsEnabled = true,
    this.vitaminsHour = 9,
    this.vitaminsMinute = 0,
    this.eyeRestEnabled = true,
    this.eyeRestIntervalHours = 2,
  });

  Map<String, dynamic> toJson() => {
    'isRunning': isRunning,
    'wakeHour': wakeHour,
    'wakeMinute': wakeMinute,
    'sleepHour': sleepHour,
    'sleepMinute': sleepMinute,
    'mealEnabled': mealEnabled,
    'mealIntervalHours': mealIntervalHours,
    'waterEnabled': waterEnabled,
    'waterIntervalHours': waterIntervalHours,
    'veggiesEnabled': veggiesEnabled,
    'veggiesIntervalHours': veggiesIntervalHours,
    'screenOffEnabled': screenOffEnabled,
    'screenOffMinutesBeforeSleep': screenOffMinutesBeforeSleep,
    'workoutEnabled': workoutEnabled,
    'workoutHour': workoutHour,
    'workoutMinute': workoutMinute,
    'vitaminsEnabled': vitaminsEnabled,
    'vitaminsHour': vitaminsHour,
    'vitaminsMinute': vitaminsMinute,
    'eyeRestEnabled': eyeRestEnabled,
    'eyeRestIntervalHours': eyeRestIntervalHours,
  };

  factory ReminderSettings.fromJson(Map<String, dynamic> json) =>
      ReminderSettings(
        isRunning: json['isRunning'] ?? false,
        wakeHour: json['wakeHour'] ?? 7,
        wakeMinute: json['wakeMinute'] ?? 0,
        sleepHour: json['sleepHour'] ?? 23,
        sleepMinute: json['sleepMinute'] ?? 0,
        mealEnabled: json['mealEnabled'] ?? true,
        mealIntervalHours: json['mealIntervalHours'] ?? 1,
        waterEnabled: json['waterEnabled'] ?? true,
        waterIntervalHours: json['waterIntervalHours'] ?? 2,
        veggiesEnabled: json['veggiesEnabled'] ?? false,
        veggiesIntervalHours: json['veggiesIntervalHours'] ?? 3,
        screenOffEnabled: json['screenOffEnabled'] ?? true,
        screenOffMinutesBeforeSleep: json['screenOffMinutesBeforeSleep'] ?? 30,
        workoutEnabled: json['workoutEnabled'] ?? true,
        workoutHour: json['workoutHour'] ?? 17,
        workoutMinute: json['workoutMinute'] ?? 0,
        vitaminsEnabled: json['vitaminsEnabled'] ?? true,
        vitaminsHour: json['vitaminsHour'] ?? 9,
        vitaminsMinute: json['vitaminsMinute'] ?? 0,
        eyeRestEnabled: json['eyeRestEnabled'] ?? true,
        eyeRestIntervalHours: json['eyeRestIntervalHours'] ?? 2,
      );

  static const String _key = 'reminder_settings_v2';

  static Future<ReminderSettings> load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? str = prefs.getString(_key);
    if (str == null) return ReminderSettings();
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
