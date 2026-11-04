import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

class NavigationPolicyHandler {
  /// Determines whether a URL should be loaded internally in the WebView
  /// or launched in an external application (like WhatsApp, Phone, or External Browser).
  static Future<bool> shouldNavigateInternal(String urlString) async {
    final uri = Uri.tryParse(urlString);
    if (uri == null) return false;

    final scheme = uri.scheme.toLowerCase();

    // Handle non-web schemes (tel, mailto, whatsapp, intent, etc.)
    if (scheme != 'http' && scheme != 'https') {
      _launchExternal(uri);
      return false;
    }

    final host = uri.host.toLowerCase();

    // Strict domain check for wedietly.com and exact match for checkout.xpay.app
    final isWedietlyDomain =
        host == 'wedietly.com' ||
        host == 'www.wedietly.com' ||
        host.endsWith('.wedietly.com');

    final isXPayDomain = host == 'checkout.xpay.app';

    if (isWedietlyDomain || isXPayDomain) {
      return true; // Load inside WebView
    }

    // External HTTPS sites (e.g. social media, payment gateways, external links)
    _launchExternal(uri);
    return false;
  }

  static void _launchExternal(Uri uri) {
    debugPrint('[NavigationPolicy] External launch triggered -> scheme: ${uri.scheme}, host: ${uri.host}');
    unawaited(
      canLaunchUrl(uri).then((can) {
        if (can) {
          launchUrl(uri, mode: LaunchMode.externalApplication);
        }
      }).catchError((_) {}),
    );
  }
}
