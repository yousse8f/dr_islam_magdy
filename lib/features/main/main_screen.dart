import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_routes.dart';
import '../about/about_us_screen.dart';
import '../contact/contact_us_screen.dart';
import '../home/home_screen.dart';
import '../services/services_screen.dart';
import '../webview/app_webview_screen.dart';
import '../reminders/services/notification_service.dart';
import '../reminders/widgets/motivation_popup.dart';
import '../reminders/models/reminder_settings.dart';
import 'persistent_bottom_nav.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  bool _isArabic = true;

  @override
  void initState() {
    super.initState();
    NotificationService.setOnMotivationNotificationTapped(() {
      if (mounted) {
        MotivationPopupManager.showMotivationPopup(context, isArabic: _isArabic);
      }
    });
    _checkForegroundMotivation();
  }

  Future<void> _checkForegroundMotivation() async {
    try {
      final settings = await ReminderSettings.load();
      if (!settings.isRunning || !settings.motivationEnabled) return;

      final now = DateTime.now();
      final motivationTime = settings.getMotivationTime();
      final motivationDateTime = DateTime(
        now.year,
        now.month,
        now.day,
        motivationTime.hour,
        motivationTime.minute,
      );

      if (now.isAfter(motivationDateTime)) {
        final prefs = await SharedPreferences.getInstance();
        final lastShownDate = prefs.getString('last_motivation_date');
        final todayStr = '${now.year}-${now.month}-${now.day}';

        if (lastShownDate != todayStr) {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            MotivationPopupManager.showMotivationPopup(context, isArabic: _isArabic);
          }
        }
      }
    } catch (e) {
      debugPrint('Error checking foreground motivation: $e');
    }
  }

  final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();

  void _toggleLanguage() {
    setState(() {
      _isArabic = !_isArabic;
    });
  }

  void _onBottomNavTapped(int index) {
    // If inner navigator has pushed screens, pop back to root first
    if (_shellNavigatorKey.currentState?.canPop() == true) {
      _shellNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    }

    setState(() {
      _currentIndex = index;
    });
  }

  Widget _buildTabRootScreen(int index) {
    switch (index) {
      case 0:
        return HomeScreen(
          isArabic: _isArabic,
          onToggleLanguage: _toggleLanguage,
        );
      case 1:
        return AboutUsScreen(
          isArabic: _isArabic,
        );
      case 2:
        return AppWebViewScreen(
          routeItem: AppRouteRegistry.book,
          isArabic: _isArabic,
          showBottomNav: false,
          onReturnToHome: () {
            _onBottomNavTapped(0);
          },
        );
      case 3:
        return ServicesScreen(
          isArabic: _isArabic,
        );
      case 4:
        return AppWebViewScreen(
          routeItem: AppRouteRegistry.faq,
          isArabic: _isArabic,
          showBottomNav: false,
          onReturnToHome: () {
            _onBottomNavTapped(0);
          },
        );
      case 5:
        return ContactUsScreen(
          isArabic: _isArabic,
          showBottomNav: false,
          onClose: () {
            _onBottomNavTapped(0);
          },
        );
      default:
        return HomeScreen(
          isArabic: _isArabic,
          onToggleLanguage: _toggleLanguage,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = 70.0 + MediaQuery.of(context).padding.bottom;

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) async {
          if (didPop) return;

          final navState = _shellNavigatorKey.currentState;
          if (navState != null && navState.canPop()) {
            navState.pop();
          } else if (_currentIndex != 0) {
            setState(() {
              _currentIndex = 0;
            });
          } else {
            SystemNavigator.pop();
          }
        },
        child: Scaffold(
          body: Stack(
            children: [
              // Shell Content Area with bottom inset for Persistent Bottom Nav
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: KeyedSubtree(
                    key: ValueKey('tab_$_currentIndex'),
                    child: Navigator(
                      key: _shellNavigatorKey,
                      onGenerateRoute: (settings) {
                        return MaterialPageRoute(
                          builder: (context) => _buildTabRootScreen(_currentIndex),
                          settings: settings,
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Persistent Floating Bottom Navigation Bar (Stays visible across ALL screens)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12 + MediaQuery.of(context).padding.bottom,
                child: PersistentBottomNavBar(
                  currentIndex: _currentIndex,
                  onTap: _onBottomNavTapped,
                  isArabic: _isArabic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
