import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_colors.dart';
import '../webview/app_webview_screen.dart';

class ContactUsScreen extends StatelessWidget {
  final bool isArabic;
  final bool showBottomNav;
  final VoidCallback? onClose;

  const ContactUsScreen({
    super.key,
    required this.isArabic,
    this.showBottomNav = true,
    this.onClose,
  });

  Future<void> _launchUrlString(String urlString) async {
    final uri = Uri.parse(urlString);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
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
            isArabic ? 'تواصل معنا' : 'Contact Us',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          leading: showBottomNav
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () {
                    if (onClose != null) {
                      onClose!();
                    } else if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    }
                  },
                ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            _contactOptionTile(
              context,
              icon: Icons.phone_rounded,
              color: AppColors.forestGreen,
              title: isArabic ? 'كلمنا موبايل' : 'Call Mobile',
              subtitle: '01224817075',
              onTap: () => _launchUrlString('tel:01224817075'),
            ),
            const SizedBox(height: 12),
            _contactOptionTile(
              context,
              icon: Icons.chat_rounded,
              color: const Color(0xFF25D366),
              title: isArabic ? 'تواصل واتساب' : 'WhatsApp Chat',
              subtitle: '+20 122 481 7075',
              onTap: () => _launchUrlString(
                'https://api.whatsapp.com/send/?phone=201224817075&text&type=phone_number&app_absent=0',
              ),
            ),
            const SizedBox(height: 12),
            _contactOptionTile(
              context,
              icon: Icons.smart_toy_rounded,
              color: const Color(0xFF1E88E5),
              title: isArabic ? 'المساعد الذكي' : 'Smart Assistant',
              subtitle: isArabic
                  ? 'تحدث مع النظام والمساعد الذكي'
                  : 'Chat with smart assistant',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppWebViewScreen(
                      routeItem: AppRouteRegistry.chatbot,
                      isArabic: isArabic,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _contactOptionTile(
              context,
              icon: Icons.map_rounded,
              color: AppColors.accentOrange,
              title: isArabic ? 'لوكيشن العيادات' : 'Clinic Locations',
              subtitle: isArabic
                  ? 'عيادة المهندسين وإمبابة'
                  : 'Mohandessin & Imbaba branches',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AppWebViewScreen(
                      routeItem: AppRouteRegistry.maps,
                      isArabic: isArabic,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            _contactOptionTile(
              context,
              icon: Icons.language_rounded,
              color: const Color(0xFF00897B),
              title: isArabic ? 'الموقع الإلكتروني' : 'Website',
              subtitle: 'https://wedietly.com/welcome',
              onTap: () => _launchUrlString('https://wedietly.com/welcome'),
            ),
            const SizedBox(height: 12),
            _contactOptionTile(
              context,
              icon: Icons.facebook_rounded,
              color: const Color(0xFF1877F2),
              title: isArabic ? 'صفحة الفيسبوك' : 'Facebook Page',
              subtitle: 'facebook.com/drislammagdydiet',
              onTap: () => _launchUrlString(
                'https://www.facebook.com/drislammagdydiet',
              ),
            ),
            const SizedBox(height: 12),
            _contactOptionTile(
              context,
              icon: Icons.camera_alt_rounded,
              color: const Color(0xFFE1306C),
              title: isArabic ? 'صفحة الانستجرام' : 'Instagram Page',
              subtitle: 'instagram.com/drislammagdy',
              onTap: () => _launchUrlString(
                'https://www.instagram.com/drislammagdy',
              ),
            ),
            const SizedBox(height: 12),
            _contactOptionTile(
              context,
              icon: Icons.campaign_rounded,
              color: const Color(0xFF25D366),
              title: isArabic ? 'قناة الواتساب' : 'WhatsApp Channel',
              subtitle: 'WhatsApp Channel',
              onTap: () => _launchUrlString(
                'https://whatsapp.com/channel/0029Va5gYUhLtOj8WIcNq90r',
              ),
            ),
            const SizedBox(height: 12),
            _contactOptionTile(
              context,
              icon: Icons.messenger_rounded,
              color: const Color(0xFF0068FF),
              title: isArabic ? 'قناة الماسنجر' : 'Messenger',
              subtitle: 'Messenger',
              onTap: () => _launchUrlString(
                'https://m.me/drislammagdydiet',
              ),
            ),
            const SizedBox(height: 12),
            _contactOptionTile(
              context,
              icon: Icons.work_rounded,
              color: const Color(0xFF0A66C2),
              title: isArabic ? 'صفحة لينكدإن' : 'LinkedIn Page',
              subtitle: 'linkedin.com/company/dr-islam-magdy-clinic',
              onTap: () => _launchUrlString('https://www.linkedin.com/company/dr-islam-magdy-clinic/'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contactOptionTile(
    BuildContext context, {
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14.5,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }
}
