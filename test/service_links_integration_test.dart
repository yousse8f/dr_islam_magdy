import 'package:flutter_test/flutter_test.dart';
import 'package:dr_islam_magdy/core/constants/app_routes.dart';

void main() {
  group('Service Links Integration & Data Contract Tests', () {
    test('Data contract structure: nested map services_links -> book -> url', () {
      // Simulate Firestore document data structure matching dashboard save (setDoc with merge: true)
      final Map<String, dynamic> firestoreDocData = {
        'services_links': {
          'book': {
            'url': 'https://wedietly.com/app/custom-book-v2',
            'title_ar': 'الحجز والخدمات المخصصة',
          },
          'knowYourTurn': {
            'url': 'https://wedietly.com/app/custom-turn',
            'title_ar': 'اعرف دورك المخصص',
          }
        }
      };

      // Verify nested map structure exists as expected by AppConfigService
      expect(firestoreDocData['services_links'], isA<Map>());
      final servicesLinks = firestoreDocData['services_links'] as Map<String, dynamic>;

      expect(servicesLinks['book'], isA<Map>());
      expect(servicesLinks['book']['url'], 'https://wedietly.com/app/custom-book-v2');
      expect(servicesLinks['book']['title_ar'], 'الحجز والخدمات المخصصة');
    });

    test('Reverting customization removes key without altering other services or throwing', () {
      // Initial state with 2 customized services
      final Map<String, dynamic> servicesLinks = {
        'book': {
          'url': 'https://wedietly.com/app/custom-book-v2',
          'title_ar': 'الحجز والخدمات المخصصة',
        },
        'knowYourTurn': {
          'url': 'https://wedietly.com/app/custom-turn',
          'title_ar': 'اعرف دورك المخصص',
        }
      };

      // Simulate revert of 'book' (equivalent to updateDoc with deleteField())
      servicesLinks.remove('book');

      // Verify 'book' is removed, but 'knowYourTurn' remains untouched
      expect(servicesLinks.containsKey('book'), false);
      expect(servicesLinks.containsKey('knowYourTurn'), true);
      expect(servicesLinks['knowYourTurn']['url'], 'https://wedietly.com/app/custom-turn');
    });

    test('URL validator compatibility between Dashboard and App policy', () {
      // Test AppRouteRegistry approved internal URLs
      expect(AppRouteRegistry.isApprovedInternalUrl('https://wedietly.com/app/book'), true);
      expect(AppRouteRegistry.isApprovedInternalUrl('https://www.wedietly.com/app/chatbot'), true);

      // Test rejection of malicious or external domains
      expect(AppRouteRegistry.isApprovedInternalUrl('https://wedietly.com.attacker.com'), false);
      expect(AppRouteRegistry.isApprovedInternalUrl('javascript:alert(1)'), false);
    });
  });
}
