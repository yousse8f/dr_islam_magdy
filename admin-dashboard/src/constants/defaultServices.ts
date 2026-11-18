import { AppRouteItem } from '../types/service';

/**
 * 10 Services matching AppRouteRegistry in the mobile app (lib/core/constants/app_routes.dart).
 * Firestore document path: app_config/services -> field: services_links.<id>
 * Note: calorieNeeds is registered in AppRouteRegistry but the mobile app uses a native local screen (CalorieCalculatorScreen)
 * instead of a WebView button, so it is marked accordingly.
 */
export const DEFAULT_SERVICES: AppRouteItem[] = [
  {
    id: 'book',
    defaultUrl: 'https://wedietly.com/app/book',
    titleAr: 'الحجز والخدمات',
    titleEn: 'Book Services',
    descriptionAr: 'رابط صفحة حجز المواعيد والاستشارات الطبية داخل التطبيق.',
    isUsedInAppUI: true,
  },
  {
    id: 'knowYourTurn',
    defaultUrl: 'https://wedietly.com/app/know-your-turn',
    titleAr: 'اعرف دورك',
    titleEn: 'Know Your Turn',
    descriptionAr: 'رابط متابعة حالة طابور الانتظار والدور بالعيادة.',
    isUsedInAppUI: true,
  },
  {
    id: 'followupChat',
    defaultUrl: 'https://wedietly.com/app/followup-chat',
    titleAr: 'المتابعة أونلاين',
    titleEn: 'Online Follow-up',
    descriptionAr: 'رابط شات المتابعة الطبية أونلاين للمرضى.',
    isUsedInAppUI: true,
  },
  {
    id: 'chatbot',
    defaultUrl: 'https://wedietly.com/app/chatbot',
    titleAr: 'الشات الذكي والمتابعة',
    titleEn: 'Smart Chatbot',
    descriptionAr: 'رابط المساعد الذكي الآلي للرد على استفسارات المشتركين.',
    isUsedInAppUI: true,
  },
  {
    id: 'maps',
    defaultUrl: 'https://wedietly.com/app/maps',
    titleAr: 'خرائط العيادة والفروع',
    titleEn: 'Clinic Locations & Maps',
    descriptionAr: 'رابط استعراض مواقع وفروع العيادات (المهندسين وإمبابة).',
    isUsedInAppUI: true,
  },
  {
    id: 'packages',
    defaultUrl: 'https://wedietly.com/app/packages',
    titleAr: 'باقات المتابعة',
    titleEn: 'Follow-up Packages',
    descriptionAr: 'رابط صفحة باقات الاشتراك والمتابعة الغذائية.',
    isUsedInAppUI: true,
  },
  {
    id: 'calorieNeeds',
    defaultUrl: 'https://wedietly.com/app/calorie-needs',
    titleAr: 'حساب الوزن والاحتياجات',
    titleEn: 'Calculate Calorie Needs',
    descriptionAr: 'ملاحظة: هذه الخدمة مسجلة في AppRouteRegistry ولكن تطبيق الهاتف يستخدم شاشة حاسبة محلية (Native) بدلاً من زر WebView.',
    isUsedInAppUI: false,
  },
  {
    id: 'offers',
    defaultUrl: 'https://wedietly.com/app/offers',
    titleAr: 'أحدث العروض',
    titleEn: 'Latest Offers',
    descriptionAr: 'رابط صفحة العروض والتخفيضات الخاصة بالعيادة.',
    isUsedInAppUI: true,
  },
  {
    id: 'articles',
    defaultUrl: 'https://wedietly.com/app/articles',
    titleAr: 'المقالات الطبية',
    titleEn: 'Medical Articles',
    descriptionAr: 'رابط مكتبة المقالات التثقيفية والتغذوية.',
    isUsedInAppUI: true,
  },
  {
    id: 'faq',
    defaultUrl: 'https://wedietly.com/app/faq',
    titleAr: 'الأسئلة الشائعة',
    titleEn: 'FAQ',
    descriptionAr: 'رابط صفحة الأسئلة الشائعة والإجابات عنها.',
    isUsedInAppUI: true,
  },
];
