import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_item.dart';

class CalorieStorage {
  static String _dayKey(String dateStr) => 'food_log_${dateStr}_v1';

  static String getTodayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static Future<List<LoggedFood>> getLogForDate(String dateStr) async {
    final prefs = await SharedPreferences.getInstance();
    final String? str = prefs.getString(_dayKey(dateStr));
    if (str == null) return [];
    try {
      final List<dynamic> decoded = jsonDecode(str);
      return decoded.map((item) => LoggedFood.fromJson(item)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveLogForDate(
    String dateStr,
    List<LoggedFood> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final String encoded = jsonEncode(items.map((i) => i.toJson()).toList());
    await prefs.setString(_dayKey(dateStr), encoded);
  }

  static Future<List<String>> getLoggedDates() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final List<String> dates = [];
    for (var key in keys) {
      if (key.startsWith('food_log_') && key.endsWith('_v1')) {
        final dateStr = key
            .replaceFirst('food_log_', '')
            .replaceFirst('_v1', '');
        dates.add(dateStr);
      }
    }
    dates.sort((a, b) => b.compareTo(a)); // Newest first
    return dates;
  }
}
