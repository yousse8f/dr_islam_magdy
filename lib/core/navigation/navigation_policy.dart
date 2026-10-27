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
      await _launchExternal(uri);
      return false;
    }

    final host = uri.host.toLowerCase();

    // Strict domain check for wedietly.com to prevent lookalike domain bypasses
    final isWedietlyDomain =
        host == 'wedietly.com' ||
        host == 'www.wedietly.com' ||
        host.endsWith('.wedietly.com');

    if (isWedietlyDomain) {
      return true; // Load inside WebView
    }

    // External HTTPS sites (e.g. social media, payment gateways, external links)
    await _launchExternal(uri);
    return false;
  }

  static Future<void> _launchExternal(Uri uri) async {
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      // Graceful fallback if external app is not installed or scheme fails
    }
  }
}
