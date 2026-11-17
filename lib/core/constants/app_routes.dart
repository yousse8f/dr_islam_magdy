class AppRouteItem {
  final String id;
  final String url;
  final String titleAr;
  final String titleEn;

  const AppRouteItem({
    required this.id,
    required this.url,
    required this.titleAr,
    required this.titleEn,
  });

  String getTitle(bool isArabic) => isArabic ? titleAr : titleEn;
}

class AppRouteRegistry {
  static const String baseUrl = 'https://wedietly.com';

  static const AppRouteItem book = AppRouteItem(
    id: 'book',
    url: 'https://wedietly.com/app/book',
    titleAr: 'الحجز والخدمات',
    titleEn: 'Book Services',
  );

  static const AppRouteItem knowYourTurn = AppRouteItem(
    id: 'knowYourTurn',
    url: 'https://wedietly.com/app/know-your-turn',
    titleAr: 'اعرف دورك',
    titleEn: 'Know Your Turn',
  );

  static const AppRouteItem followupChat = AppRouteItem(
    id: 'followupChat',
    url: 'https://wedietly.com/app/followup-chat',
    titleAr: 'المتابعة أونلاين',
    titleEn: 'Online Follow-up',
  );

  static const AppRouteItem chatbot = AppRouteItem(
    id: 'chatbot',
    url: 'https://wedietly.com/app/chatbot',
    titleAr: 'الشات الذكي والمتابعة',
    titleEn: 'Smart Chatbot',
  );

  static const AppRouteItem maps = AppRouteItem(
    id: 'maps',
    url: 'https://wedietly.com/app/maps',
    titleAr: 'خرائط العيادة والفروع',
    titleEn: 'Clinic Locations & Maps',
  );

  static const AppRouteItem packages = AppRouteItem(
    id: 'packages',
    url: 'https://wedietly.com/app/packages',
    titleAr: 'باقات المتابعة',
    titleEn: 'Follow-up Packages',
  );

  static const AppRouteItem calorieNeeds = AppRouteItem(
    id: 'calorieNeeds',
    url: 'https://wedietly.com/app/calorie-needs',
    titleAr: 'حساب الوزن والاحتياجات',
    titleEn: 'Calculate Calorie Needs',
  );

  static const AppRouteItem offers = AppRouteItem(
    id: 'offers',
    url: 'https://wedietly.com/app/offers',
    titleAr: 'أحدث العروض',
    titleEn: 'Latest Offers',
  );

  static const AppRouteItem articles = AppRouteItem(
    id: 'articles',
    url: 'https://wedietly.com/app/articles',
    titleAr: 'المقالات الطبية',
    titleEn: 'Medical Articles',
  );

  static const AppRouteItem faq = AppRouteItem(
    id: 'faq',
    url: 'https://wedietly.com/app/faq',
    titleAr: 'الأسئلة الشائعة',
    titleEn: 'FAQ',
  );

  static List<AppRouteItem> get allRoutes => [
    book,
    knowYourTurn,
    followupChat,
    chatbot,
    maps,
    packages,
    calorieNeeds,
    offers,
    articles,
    faq,
  ];

  static AppRouteItem? findById(String id) {
    try {
      return allRoutes.firstWhere((route) => route.id == id);
    } catch (_) {
      return null;
    }
  }

  static bool isApprovedInternalUrl(String urlString) {
    final uri = Uri.tryParse(urlString);
    if (uri == null) return false;

    final host = uri.host.toLowerCase();
    final isValidHost = host == 'wedietly.com' || host == 'www.wedietly.com';
    if (!isValidHost) return false;

    return true;
  }
}
