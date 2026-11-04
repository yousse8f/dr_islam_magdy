import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dr_islam_magdy/features/main/main_screen.dart';
import 'package:dr_islam_magdy/core/constants/app_routes.dart';
import 'package:dr_islam_magdy/core/navigation/navigation_policy.dart';
import 'package:dr_islam_magdy/core/services/app_config_service.dart';

void main() {
  testWidgets('App renders main screen without crashing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: MainScreen()));
    await tester.pump(const Duration(seconds: 1));

    expect(find.textContaining('إسلام مجدي'), findsWidgets);
  });

  test('AppRouteRegistry contains all approved website routes', () {
    expect(AppRouteRegistry.allRoutes.length, 10);

    expect(AppRouteRegistry.book.url, 'https://wedietly.com/app/book');
    expect(
      AppRouteRegistry.knowYourTurn.url,
      'https://wedietly.com/app/know-your-turn',
    );
    expect(
      AppRouteRegistry.followupChat.url,
      'https://wedietly.com/app/followup-chat',
    );
    expect(AppRouteRegistry.chatbot.url, 'https://wedietly.com/app/chatbot');
    expect(AppRouteRegistry.maps.url, 'https://wedietly.com/app/maps');
    expect(AppRouteRegistry.packages.url, 'https://wedietly.com/app/packages');
    expect(
      AppRouteRegistry.calorieNeeds.url,
      'https://wedietly.com/app/calorie-needs',
    );
    expect(AppRouteRegistry.offers.url, 'https://wedietly.com/app/offers');
    expect(AppRouteRegistry.articles.url, 'https://wedietly.com/app/articles');
    expect(AppRouteRegistry.faq.url, 'https://wedietly.com/app/faq');
  });

  test(
    'NavigationPolicyHandler identifies wedietly.com internal routes correctly',
    () async {
      expect(
        await NavigationPolicyHandler.shouldNavigateInternal(
          'https://wedietly.com/app/book',
        ),
        true,
      );
      expect(
        await NavigationPolicyHandler.shouldNavigateInternal(
          'https://www.wedietly.com/app/chatbot',
        ),
        true,
      );
      expect(
        await NavigationPolicyHandler.shouldNavigateInternal(
          'https://wedietly.com/app/maps',
        ),
        true,
      );
      expect(
        await NavigationPolicyHandler.shouldNavigateInternal(
          'https://wedietly.com.attacker.com',
        ),
        false,
      );
      expect(
        await NavigationPolicyHandler.shouldNavigateInternal(
          'https://checkout.xpay.app/some-payment-session',
        ),
        true,
      );
    },
  );

  test('AppConfigService returns correct fallback URLs and titles', () {
    final url = AppConfigService.getUrl(AppRouteRegistry.book);
    expect(url, 'https://wedietly.com/app/book');

    final titleAr = AppConfigService.getTitleAr(AppRouteRegistry.book);
    expect(titleAr, 'حجز الخدمات');
  });
}
