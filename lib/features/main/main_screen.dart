import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_routes.dart';
import '../about/about_us_screen.dart';
import '../contact/contact_us_screen.dart';
import '../home/home_screen.dart';
import '../webview/app_webview_screen.dart';
import '../reminders/services/app_notification_data.dart';
import '../reminders/services/latest_notification_service.dart';
import '../reminders/services/notification_popup_manager.dart';
import '../reminders/services/notification_service.dart';
import '../reminders/widgets/motivation_popup.dart';
import '../reminders/models/reminder_settings.dart';
import 'persistent_bottom_nav.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isArabic = true;
  final Set<int> _visitedTabs = {0};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    NotificationService.setOnAppNotificationTapped((data) {
      if (mounted) {
        NotificationPopupManager.showNotificationPopup(
          context,
          data: data,
          isArabic: _isArabic,
        );
      }
    });

    NotificationService.setOnMotivationNotificationTapped((quote) {
      if (mounted) {
        MotivationPopupManager.showMotivationPopup(
          context,
          isArabic: _isArabic,
          overrideQuote: quote.isNotEmpty ? quote : null,
        );
      }
    });

    _checkAppLaunchNotification();
    _checkForegroundMotivation();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      NotificationPopupManager.startForegroundWatcher(
        context,
        isArabic: _isArabic,
      );
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        await NotificationPopupManager.checkAndPresentLatestDuePopup(
          context,
          isArabic: _isArabic,
        );
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    NotificationPopupManager.stopForegroundWatcher();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[MainScreen Lifecycle] App state changed to ${state.name}');
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden ||
        state == AppLifecycleState.detached) {
      NotificationPopupManager.stopForegroundWatcher();
    }
  }

  Future<void> _onAppResumed() async {
    try {
      final settings = await ReminderSettings.load();
      await LatestNotificationService.evaluateAndGetLatestDueNotification(
        settings: settings,
        isArabic: _isArabic,
      );
      if (mounted) {
        NotificationPopupManager.startForegroundWatcher(
          context,
          isArabic: _isArabic,
        );
        await NotificationPopupManager.checkAndPresentLatestDuePopup(
          context,
          isArabic: _isArabic,
        );
      }
    } catch (e) {
      debugPrint('Error on app resumed schedule evaluation: $e');
    }
  }

  Future<void> _checkAppLaunchNotification() async {
    try {
      final launchDetails = await NotificationService.getAppLaunchNotificationDetails();
      if (launchDetails != null && launchDetails.payload != null) {
        final payload = launchDetails.payload!;
        final appData = AppNotificationData.parsePayload(payload, isArabic: _isArabic);

        await Future.delayed(const Duration(milliseconds: 700)); // wait for navigation ready
        if (mounted) {
          NotificationPopupManager.showNotificationPopup(
            context,
            data: appData,
            isArabic: _isArabic,
          );
        }
      }
    } catch (e) {
      debugPrint('Error checking app launch notification: $e');
    }
  }

  Future<void> _checkForegroundMotivation() async {
    try {
      final settings = await ReminderSettings.load();
      if (!settings.isRunning || !settings.motivationEnabled || !settings.hasSelectedWakeAndSleepTimes) return;

      final now = DateTime.now();
      final motivationTime = settings.getMotivationTime();
      if (motivationTime == null) return;
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

  final List<GlobalKey<NavigatorState>> _tabNavigatorKeys = List.generate(
    6,
    (_) => GlobalKey<NavigatorState>(),
  );

  void _toggleLanguage() {
    setState(() {
      _isArabic = !_isArabic;
    });
  }

  void _onBottomNavTapped(int index) {
    if (_currentIndex == index) {
      if (_tabNavigatorKeys[index].currentState?.canPop() == true) {
        _tabNavigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
      }
    } else {
      setState(() {
        _currentIndex = index;
        _visitedTabs.add(index);
      });
      if (index == 0) {
        if (_tabNavigatorKeys[0].currentState?.canPop() == true) {
          _tabNavigatorKeys[0].currentState?.popUntil((route) => route.isFirst);
        }
      }
    }
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
        return AppWebViewScreen(
          routeItem: AppRouteRegistry.faq,
          isArabic: _isArabic,
          showBottomNav: false,
          onReturnToHome: () {
            _onBottomNavTapped(0);
          },
        );
      case 4:
        return AppWebViewScreen(
          routeItem: AppRouteRegistry.maps,
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

          final currentNavState = _tabNavigatorKeys[_currentIndex].currentState;
          if (currentNavState != null && currentNavState.canPop()) {
            currentNavState.pop();
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
                  child: IndexedStack(
                    index: _currentIndex,
                    children: List.generate(6, (index) {
                      if (!_visitedTabs.contains(index)) {
                        return const SizedBox.shrink();
                      }
                      return Navigator(
                        key: _tabNavigatorKeys[index],
                        onGenerateRoute: (settings) {
                          return MaterialPageRoute(
                            builder: (context) => _buildTabRootScreen(index),
                            settings: settings,
                          );
                        },
                      );
                    }),
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
