export interface ValidationResult {
  isValid: boolean;
  error?: string;
  warning?: string;
  hostname?: string;
}

/**
 * Strict URL validation for service links:
 * 1. Checks that URL is not empty.
 * 2. Parses URL safely using `new URL()`.
 * 3. Enforces HTTPS scheme (`https:`).
 * 4. Inspects actual `hostname` (not string.contains).
 * 5. Returns warning if domain is outside approved app policy (`wedietly.com`, `www.wedietly.com`, `*.wedietly.com`, `checkout.xpay.app`).
 */
export function validateServiceUrl(urlStr: string): ValidationResult {
  const trimmed = urlStr.trim();
  if (!trimmed) {
    return {
      isValid: false,
      error: 'الرابط لا يمكن أن يكون فارغاً.',
    };
  }

  try {
    const parsed = new URL(trimmed);

    // 1. Check scheme
    if (parsed.protocol !== 'https:') {
      return {
        isValid: false,
        error: 'يجب أن يبدأ الرابط بـ HTTPS آمن (https://).',
      };
    }

    // 2. Check hostname accurately
    const hostname = parsed.hostname.toLowerCase();
    if (!hostname || hostname.length < 3) {
      return {
        isValid: false,
        error: 'اسم النطاق (Host) في الرابط غير صالح.',
      };
    }

    // 3. Check against app domain policy
    const isPrimaryDomain = hostname === 'wedietly.com' || hostname === 'www.wedietly.com';
    const isSubDomain = hostname.endsWith('.wedietly.com');
    const isXPay = hostname === 'checkout.xpay.app';

    let warning: string | undefined;

    if (!isPrimaryDomain && !isSubDomain && !isXPay) {
      warning = `تنبيه: النطاق (${hostname}) خارجي. قد يفتح في المتصفح الخارجي للهاتف بدلاً من عرض WebView الداخلي للتطبيق.`;
    }

    return {
      isValid: true,
      warning,
      hostname,
    };
  } catch (_) {
    return {
      isValid: false,
      error: 'صيغة الرابط غير صحيحة. يرجى إدخال رابط متكامل مثل: https://wedietly.com/app/book',
    };
  }
}
