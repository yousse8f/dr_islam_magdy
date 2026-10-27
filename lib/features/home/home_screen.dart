import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../calories/calorie_calculator_screen.dart';
import '../calories/food_log_screen.dart';
import '../calories/models/calorie_profile.dart';
import '../reminders/meal_reminders_screen.dart';
import '../services/services_screen.dart';
import '../webview/app_webview_screen.dart';

class HomeScreen extends StatelessWidget {
  final bool isArabic;
  final VoidCallback onToggleLanguage;

  const HomeScreen({
    super.key,
    required this.isArabic,
    required this.onToggleLanguage,
  });

  void _openRoute(BuildContext context, AppRouteItem routeItem) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            AppWebViewScreen(routeItem: routeItem, isArabic: isArabic),
      ),
    );
  }

  Future<void> _openCalorieFeature(BuildContext context) async {
    final profile = await CalorieProfile.load();
    if (!context.mounted) return;
    if (profile != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FoodLogScreen(isArabic: isArabic),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CalorieCalculatorScreen(isArabic: isArabic),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.forestGreen,
        foregroundColor: AppColors.white,
        elevation: 0,
        toolbarHeight: 52,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.forestGreen.withValues(alpha: 0.3),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.asset(
                  'assets/images/app_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              isArabic ? 'د. إسلام مجدي' : 'Dr. Islam Magdy',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.white,
              ),
            ),
          ],
        ),
        centerTitle: false,
        actions: [
          // Language Switcher
          InkWell(
            onTap: onToggleLanguage,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.white.withValues(alpha: 0.25),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language_rounded,
                    color: AppColors.white,
                    size: 13,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isArabic ? 'EN' : 'عربي',
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Notification Button with glowing badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, size: 21),
                color: const Color(0xFFFDE047),
                tooltip: isArabic ? 'الإشعارات' : 'Notifications',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        isArabic
                            ? 'لا توجد إشعارات جديدة حالياً'
                            : 'No new notifications',
                      ),
                      backgroundColor: AppColors.forestGreen,
                    ),
                  );
                },
              ),
              Positioned(
                top: 10,
                right: 12,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 75),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HERO CARD
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF13533C),
                    Color(0xFF0C3B2A),
                    Color(0xFF092C1F),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.forestGreen.withValues(alpha: 0.25),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: AppColors.forestGreen.withValues(alpha: 0.4),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                children: [
                  // Rectangular Animated Logo Banner (Harmonious and compact)
                  const AnimatedLogoBanner(),
                  const SizedBox(height: 32),
                  // Slogan
                  Text(
                    isArabic
                        ? 'تغذية بذكاء ... تخلى حياتك اجمل'
                        : 'Smart Nutrition ... Make Life Beautiful',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFFFACC15),
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Split CTA Buttons (Right Book, Left Online Follow-up Chat)
                  Row(
                    children: [
                      // Right: Book Appointment
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () =>
                                _openRoute(context, AppRouteRegistry.book),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFE57C23),
                              foregroundColor: AppColors.white,
                              elevation: 2,
                              shadowColor: Colors.black26,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.calendar_month_rounded,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    isArabic ? 'احجز ميعادك' : 'Book',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Left: Online Follow-up Chat
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: ElevatedButton(
                            onPressed: () => _openRoute(
                              context,
                              AppRouteRegistry.followupChat,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3B8675),
                              foregroundColor: AppColors.white,
                              elevation: 2,
                              shadowColor: Colors.black26,
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.22),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.chat_rounded,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Flexible(
                                  child: Text(
                                    isArabic ? 'شات المتابعة' : 'Follow-up',
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 2. QUICK ACCESS SECTION (خدماتنا أسرع)
            const Text(
              'خدماتنا أسرع',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF12382B),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // 1. Know Your Turn
                Expanded(
                  child: _buildQuickCard(
                    context,
                    title: isArabic ? 'اعرف\nدورك' : 'Know Your\nTurn',
                    icon: Icons.confirmation_number_rounded,
                    iconColor: const Color(0xFFD97706),
                    gradientColors: [
                      const Color(0xFFFFFBEB),
                      const Color(0xFFFEF3C7),
                    ],
                    onTap: () => _openRoute(
                      context,
                      AppRouteRegistry.knowYourTurn,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // 2. احسب سعراتك
                Expanded(
                  child: _buildQuickCard(
                    context,
                    title: isArabic ? 'احسب\nسعراتك' : 'Calculate\nCalories',
                    icon: Icons.local_fire_department_rounded,
                    iconColor: const Color(0xFF0284C7),
                    gradientColors: [
                      const Color(0xFFF0F9FF),
                      const Color(0xFFE0F2FE),
                    ],
                    onTap: () => _openCalorieFeature(context),
                  ),
                ),
                const SizedBox(width: 6),
                // 3. تنبيهات صحية
                Expanded(
                  child: _buildQuickCard(
                    context,
                    title: isArabic ? 'تنبيهات\nصحية' : 'Health\nReminders',
                    icon: Icons.notifications_active_rounded,
                    iconColor: const Color(0xFFD97706),
                    gradientColors: [
                      const Color(0xFFFFFBEB),
                      const Color(0xFFFEF3C7),
                    ],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MealRemindersScreen(isArabic: isArabic),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 6),
                // 4. خدماتنا
                Expanded(
                  child: _buildQuickCard(
                    context,
                    title: isArabic ? 'خدماتنا\nالطبية' : 'Medical\nServices',
                    icon: Icons.medical_services_rounded,
                    iconColor: AppColors.forestGreen,
                    gradientColors: [
                      const Color(0xFFECFDF5),
                      const Color(0xFFD1FAE5),
                    ],
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ServicesScreen(isArabic: isArabic),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 3. BRANCHES AND OFFERS SECTION (فروعنا والعروض)
            const Text(
              'فروعنا والعروض',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF12382B),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                // 1. عناوين فروعنا
                Expanded(
                  child: _buildQuickCard(
                    context,
                    title: isArabic ? 'عناوين\nفروعنا' : 'Clinic\nLocations',
                    icon: Icons.location_on_rounded,
                    iconColor: const Color(0xFF059669),
                    gradientColors: [
                      const Color(0xFFECFDF5),
                      const Color(0xFFA7F3D0),
                    ],
                    onTap: () => _openRoute(context, AppRouteRegistry.maps),
                  ),
                ),
                const SizedBox(width: 6),
                // 2. باقات المتابعة
                Expanded(
                  child: _buildQuickCard(
                    context,
                    title: isArabic ? 'باقات\nالمتابعة' : 'Follow-up\nPackages',
                    icon: Icons.card_giftcard_rounded,
                    iconColor: const Color(0xFFBE185D),
                    gradientColors: [
                      const Color(0xFFFDF2F8),
                      const Color(0xFFFCE7F3),
                    ],
                    onTap: () => _openRoute(context, AppRouteRegistry.packages),
                  ),
                ),
                const SizedBox(width: 6),
                // 3. أحدث العروض
                Expanded(
                  child: _buildQuickCard(
                    context,
                    title: isArabic ? 'أحدث\nالعروض' : 'Latest\nOffers',
                    icon: Icons.local_offer_rounded,
                    iconColor: const Color(0xFFD97706),
                    gradientColors: [
                      const Color(0xFFFFF7ED),
                      const Color(0xFFFFEDD5),
                    ],
                    onTap: () => _openRoute(context, AppRouteRegistry.offers),
                  ),
                ),
                const SizedBox(width: 6),
                // 4. المقالات الطبية
                Expanded(
                  child: _buildQuickCard(
                    context,
                    title: isArabic ? 'المقالات\nالطبية' : 'Medical\nArticles',
                    icon: Icons.menu_book_rounded,
                    iconColor: const Color(0xFF7E22CE),
                    gradientColors: [
                      const Color(0xFFFAF5FF),
                      const Color(0xFFF3E8FF),
                    ],
                    onTap: () => _openRoute(context, AppRouteRegistry.articles),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color iconColor,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    bool hasPulse = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 88,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12124634),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
          border: Border.all(color: iconColor.withValues(alpha: 0.15)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (hasPulse)
              Positioned(
                top: 2,
                right: 4,
                child: Container(
                  width: 7,
                  height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: gradientColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: iconColor.withValues(alpha: 0.2),
                        blurRadius: 4,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: iconColor, size: 18),
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1F2937),
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedLogoBanner extends StatefulWidget {
  const AnimatedLogoBanner({super.key});

  @override
  State<AnimatedLogoBanner> createState() => _AnimatedLogoBannerState();
}

class _AnimatedLogoBannerState extends State<AnimatedLogoBanner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Center(
        child: Container(
          width: 175, // Optimized harmonious width
          height: 62, // Optimized harmonious height
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.6),
              width: 2,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(
              'assets/images/app_icon.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}
