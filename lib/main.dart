import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:firebase_core/firebase_core.dart';

import 'core/services/app_config_service.dart';
import 'core/theme/app_colors.dart';
import 'features/splash/splash_screen.dart';
import 'features/reminders/models/reminder_settings.dart';
import 'features/reminders/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catch Flutter framework errors (e.g. layout/widget errors)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exception}');
  };

  // Catch unhandled asynchronous errors to prevent process crash/closure in Release mode
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Global Async Error caught: $error\n$stack');
    return true; // Handled, prevents app process crash
  };

  try {
    tz.initializeTimeZones();
  } catch (e) {
    debugPrint('Error initializing timezones: $e');
  }

  // Initialize local notifications early & offline
  try {
    await NotificationService.init();
  } catch (e) {
    debugPrint('Error initializing NotificationService: $e');
  }

  try {
    await Firebase.initializeApp();
    if (Firebase.apps.isNotEmpty) {
      // Fetch service links in background without blocking app startup UI
      AppConfigService.fetchServiceLinks().catchError((e) {
        debugPrint('Background service links fetch error: $e');
      });
    }
  } catch (e) {
    debugPrint('Error initializing Firebase: $e');
  }

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.forestGreen,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const DrIslamApp());
}

class DrIslamApp extends StatefulWidget {
  const DrIslamApp({super.key});

  @override
  State<DrIslamApp> createState() => _DrIslamAppState();
}

class _DrIslamAppState extends State<DrIslamApp> {
  @override
  void initState() {
    super.initState();
    _initRemindersOnStartup();
  }

  Future<void> _initRemindersOnStartup() async {
    try {
      final settings = await ReminderSettings.load();
      if (settings.isRunning) {
        debugPrint('[Startup] Reminders are active. Rescheduling on app startup...');
        await NotificationService.scheduleReminders(settings, true);
      }
    } catch (e) {
      debugPrint('[Startup ERROR] Error initializing reminders on startup: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'د. إسلام مجدي - Dr. Islam Magdy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.forestGreen,
        scaffoldBackgroundColor: AppColors.cream,
        textTheme: GoogleFonts.cairoTextTheme(ThemeData.light().textTheme),
        fontFamily: GoogleFonts.cairo().fontFamily,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.forestGreen,
          primary: AppColors.forestGreen,
          secondary: AppColors.accentOrange,
          surface: Colors.white,
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.forestGreen,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
