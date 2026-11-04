import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../constants/app_routes.dart';

class AppConfigService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache in-memory so we don't fetch repeatedly
  static Map<String, String>? _cachedUrls;
  static Map<String, String>? _cachedTitlesAr;
  static bool _hasLoadedSuccessfully = false;

  /// Fetches service links from Firestore with timeout protection and limited retry for transient errors:
  /// Collection: app_config
  /// Document: services
  /// Field: services_links
  static Future<void> fetchServiceLinks({int maxRetries = 2}) async {
    int attempt = 0;
    while (attempt <= maxRetries) {
      try {
        final docSnapshot = await _firestore
            .collection('app_config')
            .doc('services')
            .get()
            .timeout(const Duration(seconds: 4));

        if (docSnapshot.exists && docSnapshot.data() != null) {
          final data = docSnapshot.data()!;
          if (data.containsKey('services_links')) {
            final servicesLinks = data['services_links'] as Map<dynamic, dynamic>?;
            if (servicesLinks != null) {
              final urls = <String, String>{};
              final titlesAr = <String, String>{};

              servicesLinks.forEach((key, value) {
                final serviceKey = key.toString();
                if (value is Map) {
                  final url = value['url']?.toString();
                  final titleAr = value['title_ar']?.toString();
                  if (url != null && url.isNotEmpty) {
                    if (AppRouteRegistry.isApprovedInternalUrl(url) || Uri.tryParse(url)?.hasAbsolutePath == true) {
                      urls[serviceKey] = url;
                    }
                  }
                  if (titleAr != null && titleAr.isNotEmpty) {
                    titlesAr[serviceKey] = titleAr;
                  }
                }
              });

              _cachedUrls = urls;
              _cachedTitlesAr = titlesAr;
              _hasLoadedSuccessfully = true;
              debugPrint('Successfully fetched and validated ${urls.length} service links from Firestore.');
              return;
            }
          }
          debugPrint('Firestore document app_config/services is missing "services_links" field. Using fallback defaults.');
        } else {
          debugPrint('Firestore document app_config/services does not exist. Using fallback defaults.');
        }
        return;
      } catch (e) {
        attempt++;
        final errorString = e.toString().toLowerCase();

        if (errorString.contains('unavailable') || errorString.contains('network') || errorString.contains('timeout')) {
          debugPrint('Firestore network/availability error on attempt $attempt (using fallback defaults): $e');
        } else if (errorString.contains('permission-denied') || errorString.contains('permissions')) {
          debugPrint('Firestore permission denied error (using fallback defaults): $e');
          break; // Do not retry permission errors
        } else {
          debugPrint('Firestore fetch error on attempt $attempt (using fallback defaults): $e');
        }

        if (attempt <= maxRetries) {
          final delay = Duration(seconds: attempt);
          await Future.delayed(delay);
        } else {
          debugPrint('Max retries reached for fetching service links from Firestore. Using static fallback defaults.');
        }
      }
    }
  }

  /// Gets the URL for a given route item, falling back to static AppRouteRegistry if Firestore hasn't loaded or is unavailable.
  static String getUrl(AppRouteItem routeItem) {
    if (_cachedUrls != null && _cachedUrls!.containsKey(routeItem.id)) {
      return _cachedUrls![routeItem.id]!;
    }
    return routeItem.url;
  }

  /// Gets the Arabic title for a given route item, falling back to static AppRouteRegistry if Firestore hasn't loaded or is unavailable.
  static String getTitleAr(AppRouteItem routeItem) {
    if (_cachedTitlesAr != null && _cachedTitlesAr!.containsKey(routeItem.id)) {
      return _cachedTitlesAr![routeItem.id]!;
    }
    return routeItem.titleAr;
  }

  static bool get hasLoadedSuccessfully => _hasLoadedSuccessfully;

  static List<String>? _cachedMotivationQuotes;

  static const List<String> defaultMotivationQuotes = [
    'استمر في تحقيق هدفك! خطوة صغيرة يومياً تصنع فرقاً كبيراً 💪',
    'صحتك هي أغلى ما تملك، حافظ عليها بكل وجبة صحية وقطرة ماء 🌿',
    'التزامك اليوم هو نجاحك وغدك المشرق! ✨',
    'كل يوم فرصة جديدة لبناء جسم صحي وقوي 🏃‍♂️',
    'نجاحك يتطلب الاستمرارية وليس الكمال، واصل التقدم! 🌟',
  ];

  /// Fetches active motivation quotes from Firestore (collection: app_config, doc: motivation).
  /// Safe fallback to local defaults if Firestore doc is missing, offline, or unconfigured.
  static Future<List<String>> fetchMotivationQuotes() async {
    if (_cachedMotivationQuotes != null && _cachedMotivationQuotes!.isNotEmpty) {
      return _cachedMotivationQuotes!;
    }

    try {
      final docSnapshot = await _firestore
          .collection('app_config')
          .doc('motivation')
          .get()
          .timeout(const Duration(seconds: 4));

      if (docSnapshot.exists && docSnapshot.data() != null) {
        final data = docSnapshot.data()!;
        final rawQuotes = data['quotes'] ?? data['motivation_quotes'];
        if (rawQuotes is List) {
          final quotes = <String>[];
          for (var item in rawQuotes) {
            if (item is String && item.trim().isNotEmpty) {
              quotes.add(item.trim());
            } else if (item is Map) {
              final text = item['text']?.toString() ?? item['quote']?.toString();
              final active = item['active'] ?? item['isEnabled'] ?? true;
              if (active == true && text != null && text.trim().isNotEmpty) {
                quotes.add(text.trim());
              }
            }
          }
          if (quotes.isNotEmpty) {
            _cachedMotivationQuotes = quotes;
            debugPrint('Successfully loaded ${quotes.length} motivation quotes from Firestore.');
            return quotes;
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching motivation quotes from Firestore (using fallbacks): $e');
    }

    _cachedMotivationQuotes = defaultMotivationQuotes;
    return defaultMotivationQuotes;
  }
}
