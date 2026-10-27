import 'package:flutter/material.dart';

import '../../core/constants/app_routes.dart';
import '../about/about_us_screen.dart';
import '../contact/contact_us_screen.dart';
import '../home/home_screen.dart';
import '../services/services_screen.dart';
import '../webview/app_webview_screen.dart';
import 'persistent_bottom_nav.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isArabic = true;

  void _toggleLanguage() {
    setState(() {
      _isArabic = !_isArabic;
    });
  }

  void _onBottomNavTapped(int index) {
    if (index == 2) {
      // احجز خدماتك -> Booking WebView
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppWebViewScreen(
            routeItem: AppRouteRegistry.book,
            isArabic: _isArabic,
          ),
        ),
      );
      return;
    }

    if (index == 4) {
      // الأسئلة الشائعة -> FAQ WebView
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AppWebViewScreen(
            routeItem: AppRouteRegistry.faq,
            isArabic: _isArabic,
          ),
        ),
      );
      return;
    }

    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    int stackIndex = 0;
    if (_currentIndex == 1) {
      stackIndex = 1;
    } else if (_currentIndex == 3) {
      stackIndex = 2;
    } else if (_currentIndex == 5) {
      stackIndex = 3;
    }

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Stack(
          children: [
            // IndexedStack for Home, About, Services, Contact Us to keep navigation ultra smooth and stateful
            IndexedStack(
              index: stackIndex,
              children: [
                HomeScreen(
                  isArabic: _isArabic,
                  onToggleLanguage: _toggleLanguage,
                ),
                AboutUsScreen(
                  isArabic: _isArabic,
                  showBottomNav: false,
                ),
                ServicesScreen(
                  isArabic: _isArabic,
                  showBottomNav: false,
                ),
                ContactUsScreen(
                  isArabic: _isArabic,
                  showBottomNav: false,
                  onClose: () {
                    setState(() {
                      _currentIndex = 0;
                    });
                  },
                ),
              ],
            ),

            // Persistent Floating Bottom Navigation Bar
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: PersistentBottomNavBar(
                currentIndex: _currentIndex,
                onTap: _onBottomNavTapped,
                isArabic: _isArabic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
