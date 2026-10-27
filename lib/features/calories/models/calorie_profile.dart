import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class CalorieProfile {
  final double weight; // kg
  final double height; // cm
  final int age;
  final String gender; // 'male' or 'female'
  final String activityLevel; // 'sedentary', 'light', 'moderate', 'active'
  final String goal; // 'maintain', 'lose', 'gain'
  final int dailyTargetCalories;

  CalorieProfile({
    required this.weight,
    required this.height,
    required this.age,
    required this.gender,
    required this.activityLevel,
    required this.goal,
    required this.dailyTargetCalories,
  });

  Map<String, dynamic> toJson() => {
    'weight': weight,
    'height': height,
    'age': age,
    'gender': gender,
    'activityLevel': activityLevel,
    'goal': goal,
    'dailyTargetCalories': dailyTargetCalories,
  };

  factory CalorieProfile.fromJson(Map<String, dynamic> json) => CalorieProfile(
    weight: (json['weight'] as num).toDouble(),
    height: (json['height'] as num).toDouble(),
    age: (json['age'] as num).toInt(),
    gender: json['gender'] ?? 'male',
    activityLevel: json['activityLevel'] ?? 'sedentary',
    goal: json['goal'] ?? 'maintain',
    dailyTargetCalories: (json['dailyTargetCalories'] as num).toInt(),
  );

  static int calculateTarget({
    required double weight,
    required double height,
    required int age,
    required String gender,
    required String activityLevel,
    required String goal,
  }) {
    // Mifflin - St Jeor Equation for BMR
    double bmr;
    if (gender == 'male') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    }

    double multiplier = 1.2;
    switch (activityLevel) {
      case 'sedentary':
        multiplier = 1.2;
        break;
      case 'light':
        multiplier = 1.375;
        break;
      case 'moderate':
        multiplier = 1.55;
        break;
      case 'active':
        multiplier = 1.725;
        break;
    }

    double tdee = bmr * multiplier;

    double target = tdee;
    if (goal == 'lose') {
      target = tdee - 500; // safe deficit
    } else if (goal == 'gain') {
      target = tdee + 400; // safe surplus
    }

    return target.round().clamp(1200, 5000);
  }

  static const String _storageKey = 'calorie_profile_v1';

  static Future<CalorieProfile?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final String? str = prefs.getString(_storageKey);
    if (str == null) return null;
    try {
      return CalorieProfile.fromJson(jsonDecode(str));
    } catch (_) {
      return null;
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(toJson()));
  }
}
