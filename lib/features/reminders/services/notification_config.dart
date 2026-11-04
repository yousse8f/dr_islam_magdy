import 'notification_channels.dart';

/// Immutable type-safe container for notification content, sound, channel, and ID range specifications.
class NotificationTypeData {
  final String titleAr;
  final String titleEn;
  final String bodyAr;
  final String bodyEn;
  final String channelId;
  final String soundName;
  final int idRangeStart;
  final int idRangeEnd;

  const NotificationTypeData({
    required this.titleAr,
    required this.titleEn,
    required this.bodyAr,
    required this.bodyEn,
    required this.channelId,
    required this.soundName,
    required this.idRangeStart,
    required this.idRangeEnd,
  });
}

class NotificationContentRegistry {
  // 1. Breakfast (Meals sound, dedicated ID range: 1000..1099)
  static const breakfast = NotificationTypeData(
    titleAr: 'تنبيه الإفطار 🍳',
    titleEn: 'Breakfast Meal 🍳',
    bodyAr: 'ابدأ يومك بوجبة صحية ومفيدة',
    bodyEn: 'Start your day with a healthy and beneficial meal',
    channelId: NotificationChannels.mealsChannelId,
    soundName: NotificationChannels.mealSound,
    idRangeStart: 1000,
    idRangeEnd: 1099,
  );

  // 2. Lunch (Meals sound, dedicated ID range: 1100..1199)
  static const lunch = NotificationTypeData(
    titleAr: 'تنبيه الغداء 🥗',
    titleEn: 'Lunch Meal 🥗',
    bodyAr: 'جه وقت الغدا، متنساش تاكل وجبتك وتهتم بنفسك ❤️',
    bodyEn: 'Time for lunch to maintain your health and vitality.',
    channelId: NotificationChannels.mealsChannelId,
    soundName: NotificationChannels.mealSound,
    idRangeStart: 1100,
    idRangeEnd: 1199,
  );

  // 3. Dinner (Meals sound, dedicated ID range: 1200..1299)
  static const dinner = NotificationTypeData(
    titleAr: 'تنبيه العشاء 🍲',
    titleEn: 'Dinner Meal 🍲',
    bodyAr: 'يلا جه وقت العشا، خلي بالك من نفسك ومتنساش وجبتك.',
    bodyEn: 'Time for a light dinner before bedtime.',
    channelId: NotificationChannels.mealsChannelId,
    soundName: NotificationChannels.mealSound,
    idRangeStart: 1200,
    idRangeEnd: 1299,
  );

  // 4. Motivation (Motivation sound, dedicated ID range: 1300..1399)
  static const motivation = NotificationTypeData(
    titleAr: 'رسالة تحفيزية ✨',
    titleEn: 'Motivational Quote ✨',
    bodyAr: '', // Dynamic
    bodyEn: 'Keep striving towards your goals! Every small step counts 💪',
    channelId: NotificationChannels.motivationChannelId,
    soundName: NotificationChannels.motivationSound,
    idRangeStart: 1300,
    idRangeEnd: 1399,
  );

  // 5. Water (Water sound, dedicated ID range: 2000..2999)
  static const water = NotificationTypeData(
    titleAr: 'تنبيه المياه 💧',
    titleEn: 'Time for Water 💧',
    bodyAr: 'خدلك شوية مية، جسمك محتاجك تهتم بيه 💧',
    bodyEn: 'Drink a glass of water to stay active and hydrated.',
    channelId: NotificationChannels.waterChannelId,
    soundName: NotificationChannels.waterSound,
    idRangeStart: 2000,
    idRangeEnd: 2999,
  );

  // 6. Snack (Snack sound, dedicated ID range: 3000..3999)
  static const snack = NotificationTypeData(
    titleAr: 'تنبيه السناك 🍎',
    titleEn: 'Snack Reminder 🍎',
    bodyAr: 'جه وقت السناك، اختار حاجة خفيفة ومناسبة لنظامك.',
    bodyEn: 'Enjoy a fresh healthy snack to boost your vitamins and energy.',
    channelId: NotificationChannels.snackChannelId,
    soundName: NotificationChannels.snackSound,
    idRangeStart: 3000,
    idRangeEnd: 3999,
  );

  // 7. Screen Off (Default system sound, dedicated ID range: 4000..4099)
  static const screenOff = NotificationTypeData(
    titleAr: 'استعداد للنوم 🌙',
    titleEn: 'Screen Off & Bedtime 🌙',
    bodyAr: 'ارحم عينك شوية، خدلك استراحة بعيد عن الشاشة.',
    bodyEn: 'Time to turn off screens and rest your eyes before sleep.',
    channelId: NotificationChannels.screenOffChannelId,
    soundName: NotificationChannels.defaultSound,
    idRangeStart: 4000,
    idRangeEnd: 4099,
  );

  // 8. Workout (Default system sound, dedicated ID range: 5000..5099)
  static const workout = NotificationTypeData(
    titleAr: 'تنبيه التمارين 🏃‍♂️',
    titleEn: 'Daily Workout Reminder 🏃‍♂️',
    bodyAr: 'يلا خد وقتك في الحركة، جسمك هيشكرك 💪',
    bodyEn: 'Time for your daily workout! Stay active and healthy.',
    channelId: NotificationChannels.workoutChannelId,
    soundName: NotificationChannels.defaultSound,
    idRangeStart: 5000,
    idRangeEnd: 5099,
  );

  // 9. Vitamins (Default system sound, dedicated ID range: 6000..6099)
  static const vitamins = NotificationTypeData(
    titleAr: 'تنبيه الفيتامينات 💊',
    titleEn: 'Vitamins Reminder 💊',
    bodyAr: 'متنساش الفيتامينات بتاعتك لو معادها جه ❤️',
    bodyEn: 'Time to take your prescribed vitamins.',
    channelId: NotificationChannels.vitaminsChannelId,
    soundName: NotificationChannels.defaultSound,
    idRangeStart: 6000,
    idRangeEnd: 6099,
  );

  // 10. Eye Rest (Default system sound, dedicated ID range: 7000..7099)
  static const eyeRest = NotificationTypeData(
    titleAr: 'راحة للعين 👀',
    titleEn: 'Eye Rest from Screens 👀',
    bodyAr: 'ريح عينك دقيقتين بعيد عن الشاشات والتركيز.',
    bodyEn: 'Look away from the screen for 2 minutes and relax your eyes.',
    channelId: NotificationChannels.eyeRestChannelId,
    soundName: NotificationChannels.defaultSound,
    idRangeStart: 7000,
    idRangeEnd: 7099,
  );
}
