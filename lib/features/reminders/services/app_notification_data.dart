import 'dart:convert';
import 'notification_config.dart';

class AppNotificationData {
  final String occurrenceId;
  final String type; // 'breakfast', 'lunch', 'dinner', 'water', 'snack', 'motivation', 'workout', 'vitamins', 'screen_off', 'eye_rest', 'custom'
  final String title;
  final String body;
  final DateTime scheduledTime;
  final String? payloadRaw;

  AppNotificationData({
    required this.occurrenceId,
    required this.type,
    required this.title,
    required this.body,
    required this.scheduledTime,
    this.payloadRaw,
  });

  Map<String, dynamic> toJson() => {
        'occurrenceId': occurrenceId,
        'type': type,
        'title': title,
        'body': body,
        'scheduledTime': scheduledTime.millisecondsSinceEpoch,
        'payloadRaw': payloadRaw,
      };

  factory AppNotificationData.fromJson(Map<String, dynamic> json) =>
      AppNotificationData(
        occurrenceId: json['occurrenceId'] ?? '',
        type: json['type'] ?? 'general',
        title: json['title'] ?? '',
        body: json['body'] ?? '',
        scheduledTime: json['scheduledTime'] != null
            ? DateTime.fromMillisecondsSinceEpoch(json['scheduledTime'])
            : DateTime.now(),
        payloadRaw: json['payloadRaw'],
      );

  /// Helper to create AppNotificationData from raw payload string (JSON or legacy format)
  static AppNotificationData parsePayload(String payload, {bool isArabic = true}) {
    if (payload.startsWith('{') && payload.endsWith('}')) {
      try {
        final Map<String, dynamic> map = jsonDecode(payload);
        return AppNotificationData.fromJson(map);
      } catch (_) {}
    }

    final now = DateTime.now();
    String type = 'general';
    String title = isArabic ? 'تنبيه صحي 🔔' : 'Health Reminder 🔔';
    String body = '';

    if (payload.startsWith('breakfast')) {
      type = 'breakfast';
      title = isArabic ? NotificationContentRegistry.breakfast.titleAr : NotificationContentRegistry.breakfast.titleEn;
      body = isArabic ? NotificationContentRegistry.breakfast.bodyAr : NotificationContentRegistry.breakfast.bodyEn;
    } else if (payload.startsWith('lunch')) {
      type = 'lunch';
      title = isArabic ? NotificationContentRegistry.lunch.titleAr : NotificationContentRegistry.lunch.titleEn;
      body = isArabic ? NotificationContentRegistry.lunch.bodyAr : NotificationContentRegistry.lunch.bodyEn;
    } else if (payload.startsWith('dinner')) {
      type = 'dinner';
      title = isArabic ? NotificationContentRegistry.dinner.titleAr : NotificationContentRegistry.dinner.titleEn;
      body = isArabic ? NotificationContentRegistry.dinner.bodyAr : NotificationContentRegistry.dinner.bodyEn;
    } else if (payload.startsWith('motivation')) {
      type = 'motivation';
      title = isArabic ? NotificationContentRegistry.motivation.titleAr : NotificationContentRegistry.motivation.titleEn;
      if (payload.startsWith('motivation:')) {
        body = payload.substring('motivation:'.length);
      } else {
        body = isArabic ? 'استمر في تحقيق هدفك! خطوة صغيرة يومياً تصنع فرقاً كبيراً 💪' : NotificationContentRegistry.motivation.bodyEn;
      }
    } else if (payload.startsWith('water')) {
      type = 'water';
      title = isArabic ? NotificationContentRegistry.water.titleAr : NotificationContentRegistry.water.titleEn;
      body = isArabic ? NotificationContentRegistry.water.bodyAr : NotificationContentRegistry.water.bodyEn;
    } else if (payload.startsWith('snack')) {
      type = 'snack';
      title = isArabic ? NotificationContentRegistry.snack.titleAr : NotificationContentRegistry.snack.titleEn;
      body = isArabic ? NotificationContentRegistry.snack.bodyAr : NotificationContentRegistry.snack.bodyEn;
    } else if (payload.startsWith('workout')) {
      type = 'workout';
      title = isArabic ? NotificationContentRegistry.workout.titleAr : NotificationContentRegistry.workout.titleEn;
      body = isArabic ? NotificationContentRegistry.workout.bodyAr : NotificationContentRegistry.workout.bodyEn;
    } else if (payload.startsWith('vitamins')) {
      type = 'vitamins';
      title = isArabic ? NotificationContentRegistry.vitamins.titleAr : NotificationContentRegistry.vitamins.titleEn;
      body = isArabic ? NotificationContentRegistry.vitamins.bodyAr : NotificationContentRegistry.vitamins.bodyEn;
    } else if (payload.startsWith('screen_off')) {
      type = 'screen_off';
      title = isArabic ? NotificationContentRegistry.screenOff.titleAr : NotificationContentRegistry.screenOff.titleEn;
      body = isArabic ? NotificationContentRegistry.screenOff.bodyAr : NotificationContentRegistry.screenOff.bodyEn;
    } else if (payload.startsWith('eye_rest')) {
      type = 'eye_rest';
      title = isArabic ? NotificationContentRegistry.eyeRest.titleAr : NotificationContentRegistry.eyeRest.titleEn;
      body = isArabic ? NotificationContentRegistry.eyeRest.bodyAr : NotificationContentRegistry.eyeRest.bodyEn;
    } else if (payload.startsWith('custom')) {
      type = 'custom';
      title = isArabic ? 'تنبيه مخصص ⏰' : 'Custom Reminder ⏰';
      body = payload;
    }

    final dateStr = '${now.year}-${now.month}-${now.day}_${now.hour}:${now.minute}';
    return AppNotificationData(
      occurrenceId: '${type}_$dateStr',
      type: type,
      title: title,
      body: body,
      scheduledTime: now,
      payloadRaw: payload,
    );
  }

  /// Encode payload as JSON string for notifications plugin
  String toPayloadString() {
    return jsonEncode(toJson());
  }
}
