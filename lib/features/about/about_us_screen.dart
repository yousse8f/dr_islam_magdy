import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../main/persistent_bottom_nav.dart';
import '../services/services_screen.dart';
import '../webview/app_webview_screen.dart';

class AboutUsScreen extends StatelessWidget {
  final bool isArabic;
  final bool showBottomNav;

  const AboutUsScreen({
    super.key,
    required this.isArabic,
    this.showBottomNav = true,
  });

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    }
  }

  Future<void> _launchUrlString(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _onBottomNavTapped(int index, BuildContext context) {
    if (index == 0) {
      Navigator.popUntil(context, (route) => route.isFirst);
      return;
    }
    if (index == 1) {
      return; // Already on About Us
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
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ServicesScreen(isArabic: isArabic),
        ),
      );
      return;
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
            isArabic ? 'اعرفنا أكتر' : 'About Us',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 8),
                  // Doctor Image / Logo
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: AppColors.forestGreen.withValues(alpha: 0.2),
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Image.asset(
                          'assets/images/app_icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name & Specialty
                  Text(
                    isArabic ? 'د. إسلام مجدي' : 'Dr. Islam Magdy',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accentOrange.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isArabic
                          ? 'أخصائي التغذية وعلاج السمنة والنحافة'
                          : 'Clinical Nutrition & Obesity Specialist',
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: AppColors.accentOrange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Qualifications & Memberships Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                        Row(
                          children: [
                            const Icon(
                              Icons.school_rounded,
                              color: AppColors.forestGreen,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isArabic ? 'المؤهلات العلمية' : 'Qualifications',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _bulletItem(
                          isArabic
                              ? 'دكتوراه العلاج الطبيعي الإكلينيكية – جامعة القاهرة.'
                              : 'PhD in Clinical Physical Therapy - Cairo University.',
                        ),
                        _bulletItem(
                          isArabic ? 'ماجستير التغذية التخصصية – جامعة القاهرة.' : 'Master in Specialized Nutrition - Cairo University.',
                        ),
                        _bulletItem(
                          isArabic
                              ? 'دبلومة التغذية – جامعة القاهرة.'
                              : 'Diploma in Nutrition - Cairo University.',
                        ),
                        _bulletItem(
                          isArabic
                              ? 'دبلومة علاج السمنة والنحافة وتغذية الرياضيين – المعهد القومي للتغذية.'
                              : 'Diploma in Obesity, Underweight & Sports Nutrition - National Institute of Nutrition.',
                        ),
                        const Divider(height: 32),
                        Row(
                          children: [
                            const Icon(
                              Icons.card_membership_rounded,
                              color: AppColors.forestGreen,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isArabic ? 'العضويات' : 'Memberships',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _bulletItem(
                          isArabic
                              ? 'عضو الجمعية الأمريكية للسمنة.'
                              : 'Member of The Obesity Society (TOS, USA).',
                        ),
                        _bulletItem(
                          isArabic ? 'عضو الجمعية المصرية الطبية لدراسة السمنة.' : 'Member of the Egyptian Medical Association for the Study of Obesity.',
                        ),
                        _bulletItem(
                          isArabic ? 'عضو الجمعية المصرية للتغذية الطبية.' : 'Member of the Egyptian Medical Nutrition Association.',
                        ),
                        _bulletItem(
                          isArabic
                              ? 'عضو الجمعية المصرية للتغذية العلاجية والصحة العلاجية (EMSO).'
                              : 'Member of the Egyptian Medical Nutrition & Therapeutic Health Association (EMSO).',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Direct Call & WhatsApp Buttons Card (Split in half)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.forestGreen,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.cardShadow,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.white,
                              child: Icon(
                                Icons.phone_rounded,
                                color: AppColors.forestGreen,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    isArabic ? 'تواصل معنا مباشرة' : 'Contact Us Directly',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.white.withValues(alpha: 0.8),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    '01224817075',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.white,
                                      letterSpacing: 1.1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _makePhoneCall('01224817075'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentOrange,
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.call_rounded, size: 18),
                                label: Text(
                                  isArabic ? 'اتصل بنا' : 'Call Us',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _launchUrlString('https://wa.me/201224817075'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: AppColors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                icon: const Icon(Icons.chat_rounded, size: 18),
                                label: Text(
                                  isArabic ? 'واتساب' : 'WhatsApp',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Clinics Locations Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
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
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.accentOrange,
                              size: 22,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              isArabic ? 'فروع العيادات' : 'Clinic Locations',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _clinicItem(
                          name: isArabic ? 'عيادة المهندسين' : 'Mohandessin Clinic',
                          address: isArabic
                              ? '١٩ شارع البطل، أعلى كبدة جحا'
                              : '19 El Batal St., Above Kebdet Goha',
                          icon: Icons.local_hospital_rounded,
                          onMapPressed: () => _launchUrlString(
                            'https://www.google.com/maps/search/?api=1&query=19+شارع+البطل+المهندسين+الجيزة',
                          ),
                        ),
                        const Divider(height: 24),
                        _clinicItem(
                          name: isArabic ? 'عيادة إمبابة' : 'Imbaba Clinic',
                          address: isArabic ? '١٩ شارع بشتيل' : '19 Beshtil St.',
                          icon: Icons.local_hospital_rounded,
                          onMapPressed: () => _launchUrlString(
                            'https://www.google.com/maps/search/?api=1&query=19+شارع+بشتيل+إمبابة+الجيزة',
                          ),
                        ),
                        const Divider(height: 24),
                        _clinicItem(
                          name: isArabic ? 'عيادة الأونلاين' : 'Online Clinic',
                          address: isArabic
                              ? 'للتواصل وحجز الاستشارات عن بُعد.'
                              : 'For remote consultations and follow-ups.',
                          icon: Icons.wifi_rounded,
                          onMapPressed: () => _launchUrlString(
                            'https://wedietly.com/app/maps',
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

            // Persistent Bottom Navigation Bar
            if (showBottomNav)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: PersistentBottomNavBar(
                  currentIndex: 1,
                  onTap: (index) => _onBottomNavTapped(index, context),
                  isArabic: isArabic,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _bulletItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              color: AppColors.forestGreen,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textDark,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _clinicItem({
    required String name,
    required String address,
    required IconData icon,
    required VoidCallback onMapPressed,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.forestGreen.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.forestGreen, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedText,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: onMapPressed,
          icon: const Icon(Icons.map_rounded, color: AppColors.accentOrange),
          tooltip: isArabic ? 'فتح خريطة جوجل' : 'Open Google Maps',
        ),
      ],
    );
  }
}
