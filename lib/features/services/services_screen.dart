import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../webview/app_webview_screen.dart';

class ServicesScreen extends StatelessWidget {
  final bool isArabic;

  const ServicesScreen({
    super.key,
    required this.isArabic,
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

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isVerySmall = screenWidth < 360;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: AppColors.cream,
        appBar: AppBar(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: AppColors.white,
          toolbarHeight: 52,
          title: Text(
            isArabic ? 'خدماتنا الطبية' : 'Our Medical Services',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
          ),
          centerTitle: true,
        ),
        body: ListView(
          padding: EdgeInsets.fromLTRB(
            isVerySmall ? 10 : 16,
            14,
            isVerySmall ? 10 : 16,
            80 + MediaQuery.of(context).padding.bottom,
          ),
          children: [
            _buildServiceListItem(
              context,
              screenWidth: screenWidth,
              title: isArabic
                  ? 'علاج السمنة وتنسيق القوام'
                  : 'Obesity Treatment',
              subtitle: isArabic
                  ? 'برامج غذائية مخصصة للوصول للوزن المثالي'
                  : 'Customized nutrition programs for healthy weight',
              icon: Icons.scale_rounded,
              imagePath: 'assets/images/obesity_treatment.png',
            ),
            const SizedBox(height: 12),
            _buildServiceListItem(
              context,
              screenWidth: screenWidth,
              title: isArabic ? 'التغذية العلاجية' : 'Clinical Nutrition',
              subtitle: isArabic
                  ? 'خطط لحالات السكري والضغط وتكيس المبايض'
                  : 'Diets for diabetes, hypertension & PCOS',
              icon: Icons.favorite_rounded,
              imagePath: 'assets/images/clinical_nutrition.png',
            ),
            const SizedBox(height: 12),
            _buildServiceListItem(
              context,
              screenWidth: screenWidth,
              title: isArabic
                  ? 'جلسات إذابة الدهون وشد الترهلات'
                  : 'Fat Dissolving',
              subtitle: isArabic
                  ? 'تقنيات حديثة وآمنة لتنسيق القوام'
                  : 'Modern body contouring sessions',
              icon: Icons.spa_rounded,
              imagePath: 'assets/images/fat_dissolving.png',
            ),
            const SizedBox(height: 12),
            _buildServiceListItem(
              context,
              screenWidth: screenWidth,
              title: isArabic ? 'علاج النحافة' : 'Underweight Treatment',
              subtitle: isArabic
                  ? 'زيادة الوزن بشكل صحي وبناء الكتلة العضلية'
                  : 'Healthy weight gain & muscle support',
              icon: Icons.restaurant_rounded,
              imagePath: 'assets/images/underweight_treatment.png',
            ),
            const SizedBox(height: 12),
            _buildServiceListItem(
              context,
              screenWidth: screenWidth,
              title: isArabic ? 'العلاج الطبيعي' : 'Physical Therapy',
              subtitle: isArabic
                  ? 'لعلاج آلام الانزلاق الغضروفي والعمود الفقري'
                  : 'For herniated discs & spine care',
              icon: Icons.accessibility_new_rounded,
              imagePath: 'assets/images/physical_therapy.png',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceListItem(
    BuildContext context, {
    required double screenWidth,
    required String title,
    required String subtitle,
    required IconData icon,
    required String imagePath,
  }) {
    final isVerySmall = screenWidth < 360;

    return InkWell(
      onTap: () => _openBooking(context),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 96),
        padding: EdgeInsets.all(isVerySmall ? 6 : 8),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Service Image
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: isVerySmall ? 70 : 84,
                height: 84,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.forestGreen.withValues(alpha: 0.1),
                      child: Center(
                        child: Icon(
                          icon,
                          size: 26,
                          color: AppColors.forestGreen,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            SizedBox(width: isVerySmall ? 8 : 12),
            // Title & Subtitle
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isVerySmall ? 14 : 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isVerySmall ? 11.5 : 13,
                      color: AppColors.mutedText,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: isVerySmall ? 4 : 8),
            // Book Button
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isVerySmall ? 8 : 12,
                vertical: isVerySmall ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: AppColors.accentOrange,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                isArabic ? 'احجز' : 'Book',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: isVerySmall ? 11 : 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 2),
          ],
        ),
      ),
    );
  }
}
