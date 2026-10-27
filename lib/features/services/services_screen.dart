import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../about/about_us_screen.dart';
import '../main/persistent_bottom_nav.dart';
import '../webview/app_webview_screen.dart';

class ServicesScreen extends StatelessWidget {
  final bool isArabic;
  final bool showBottomNav;

  const ServicesScreen({
    super.key,
    required this.isArabic,
    this.showBottomNav = true,
  });

  void _openBooking(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppWebViewScreen(
          routeItem: AppRouteRegistry.book,
          isArabic: isArabic,
        ),
      ),
    );
  }

  void _onBottomNavTapped(int index, BuildContext context) {
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
    if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AboutUsScreen(isArabic: isArabic),
        ),
      );
      return;
    }
    if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AppWebViewScreen(
            routeItem: AppRouteRegistry.book,
            isArabic: isArabic,
          ),
        ),
      );
      return;
    }
    if (index == 3) {
      return; // Already on services
    }
    if (index == 4) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => AppWebViewScreen(
            routeItem: AppRouteRegistry.faq,
            isArabic: isArabic,
          ),
        ),
      );
      return;
    }
    if (index == 5) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.white,
          title: Text(
            isArabic ? 'خدماتنا الطبية' : 'Our Medical Services',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                // 1. Obesity Treatment (علاج السمنة)
                _buildMedicalServiceCard(
                  context,
                  title: isArabic
                      ? 'علاج السمنة وتنسيق القوام'
                      : 'Obesity Treatment',
                  description: isArabic
                      ? 'برامج غذائية متوازنة للمساعدة في الوصول إلى وزن صحي مع جلسات موجهة.'
                      : 'Balanced nutritional programs to help achieve a healthy weight.',
                  icon: Icons.scale_rounded,
                  imagePath: 'assets/images/obesity_treatment.png',
                ),

                // 2. Clinical Nutrition (التغذية العلاجية)
                _buildMedicalServiceCard(
                  context,
                  title: isArabic ? 'التغذية العلاجية' : 'Clinical Nutrition',
                  description: isArabic
                      ? 'خطط تغذية مخصصة لحالات السكري والضغط وأمراض الجهاز الهضمي والكبد وتكيس المبايض ومقاومة الإنسولين.'
                      : 'Customized nutrition plans for diabetes, hypertension, digestive & liver diseases, PCOS, and insulin resistance.',
                  icon: Icons.favorite_rounded,
                  imagePath: 'assets/images/clinical_nutrition.png',
                ),

                // 3. Fat Dissolving & Skin Tightening (جلسات إذابة الدهون وشد الترهلات)
                _buildMedicalServiceCard(
                  context,
                  title: isArabic
                      ? 'جلسات إذابة الدهون وشد الترهلات'
                      : 'Fat Dissolving & Skin Tightening',
                  description: isArabic
                      ? 'جلسات حديثة وآمنة لتنسيق القوام وشد الترهلات وفق تقييم الحالة.'
                      : 'Body contouring sessions according to condition evaluation.',
                  icon: Icons.spa_rounded,
                  imagePath: 'assets/images/fat_dissolving.png',
                ),

                // 4. Underweight Treatment (علاج النحافة)
                _buildMedicalServiceCard(
                  context,
                  title: isArabic ? 'علاج النحافة' : 'Underweight Treatment',
                  description: isArabic
                      ? 'برامج غذائية لزيادة الوزن بشكل صحي ودعم القوة البدنية والكتلة العضلية.'
                      : 'Nutritional programs for healthy weight gain and physical strength support.',
                  icon: Icons.restaurant_rounded,
                  imagePath: 'assets/images/underweight_treatment.png',
                ),

                // 5. Physical Therapy (العلاج الطبيعي)
                _buildMedicalServiceCard(
                  context,
                  title: isArabic ? 'العلاج الطبيعي' : 'Physical Therapy',
                  description: isArabic
                      ? 'لحالات الانزلاق الغضروفي وأمراض العمود الفقري وآلام أسفل الظهر وعرق النسا.'
                      : 'For herniated discs, spine diseases, lower back pain, and sciatica.',
                  icon: Icons.accessibility_new_rounded,
                  imagePath: 'assets/images/physical_therapy.png',
                ),
              ],
            ),

            // Persistent Bottom Navigation Bar
            if (showBottomNav)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: PersistentBottomNavBar(
                  currentIndex: 3,
                  onTap: (index) => _onBottomNavTapped(index, context),
                  isArabic: isArabic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalServiceCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required String imagePath,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Image.asset(
              imagePath,
              height: 160,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 160,
                  width: double.infinity,
                  color: AppColors.forestGreen.withValues(alpha: 0.1),
                  child: Center(
                    child: Icon(icon, size: 50, color: AppColors.forestGreen),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.forestGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: AppColors.forestGreen, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.mutedText,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: () => _openBooking(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.accentOrange,
                      foregroundColor: AppColors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.calendar_month_rounded, size: 18),
                    label: Text(
                      isArabic ? 'احجز الآن' : 'Book Now',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
