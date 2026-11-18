import React, { useState, useEffect, useCallback } from 'react';
import { db } from '../firebase';
import { doc, getDoc, setDoc, updateDoc, deleteField } from 'firebase/firestore';
import { DEFAULT_SERVICES } from '../constants/defaultServices';
import { ServiceItemState, Toast } from '../types/service';
import { ServiceCard } from './ServiceCard';
import {
  Search,
  RefreshCw,
  CheckCircle2,
  XCircle,
  AlertTriangle,
  Layers,
  Sparkles,
  Info,
  Server,
  Wifi,
  HelpCircle,
  X,
  PhoneCall,
  MessageSquare,
  MapPin,
  Share2
} from 'lucide-react';

interface DashboardProps {
  isHardcodedModalOpen?: boolean;
  onCloseHardcodedModal?: () => void;
}

export const Dashboard: React.FC<DashboardProps> = ({
  isHardcodedModalOpen = false,
  onCloseHardcodedModal,
}) => {
  const [services, setServices] = useState<ServiceItemState[]>([]);
  const [isLoading, setIsLoading] = useState(true);
  const [isRefreshing, setIsRefreshing] = useState(false);
  const [searchQuery, setSearchQuery] = useState('');
  const [filterMode, setFilterMode] = useState<'all' | 'customized' | 'default'>('all');
  const [isFromCache, setIsFromCache] = useState<boolean | null>(null);
  const [toasts, setToasts] = useState<Toast[]>([]);
  const [localShowHardcodedModal, setLocalShowHardcodedModal] = useState(false);
  const [docExists, setDocExists] = useState(true);

  const showModal = isHardcodedModalOpen || localShowHardcodedModal;

  const handleCloseModal = () => {
    setLocalShowHardcodedModal(false);
    if (onCloseHardcodedModal) onCloseHardcodedModal();
  };

  const addToast = useCallback((type: Toast['type'], message: string) => {
    const id = Math.random().toString(36).substring(2, 9);
    setToasts((prev) => [...prev, { id, type, message }]);
    setTimeout(() => {
      setToasts((prev) => prev.filter((t) => t.id !== id));
    }, 5000);
  }, []);

  const removeToast = (id: string) => {
    setToasts((prev) => prev.filter((t) => t.id !== id));
  };

  // Fetch Firestore app_config/services document
  const fetchServicesFromFirestore = useCallback(async (isManualRefresh = false) => {
    if (isManualRefresh) setIsRefreshing(true);
    else setIsLoading(true);

    try {
      const docRef = doc(db, 'app_config', 'services');
      const docSnap = await getDoc(docRef);

      setIsFromCache(docSnap.metadata.fromCache);
      setDocExists(docSnap.exists());

      const servicesLinksData = docSnap.exists() ? docSnap.data()?.services_links || {} : {};

      const initialStates: ServiceItemState[] = DEFAULT_SERVICES.map((def) => {
        const firestoreVal = servicesLinksData[def.id];
        let currentUrl = def.defaultUrl;
        let isCustomized = false;
        let customTitleAr: string | undefined = undefined;

        if (firestoreVal) {
          if (typeof firestoreVal === 'string' && firestoreVal.trim().length > 0) {
            currentUrl = firestoreVal.trim();
            isCustomized = true;
          } else if (typeof firestoreVal === 'object' && firestoreVal !== null && firestoreVal.url && firestoreVal.url.trim().length > 0) {
            currentUrl = firestoreVal.url.trim();
            customTitleAr = firestoreVal.title_ar || undefined;
            isCustomized = true;
          }
        }

        return {
          id: def.id,
          titleAr: def.titleAr,
          titleEn: def.titleEn,
          descriptionAr: def.descriptionAr,
          defaultUrl: def.defaultUrl,
          currentUrl,
          customTitleAr,
          isCustomized,
          isUsedInAppUI: def.isUsedInAppUI,
          inputUrl: currentUrl,
          inputTitleAr: customTitleAr || def.titleAr,
          isEditing: false,
          isSaving: false,
          isReverting: false,
          hasUnsavedChanges: false,
        };
      });

      setServices(initialStates);

      if (isManualRefresh) {
        addToast('success', docSnap.metadata.fromCache ? 'تم التحديث من ذاكرة التخزين المؤقت (Cache)' : 'تم تحديث البيانات المباشرة من الخادم (Server)');
      }
    } catch (err: any) {
      console.error('Error fetching Firestore document app_config/services:', err);
      const code = err?.code || '';
      if (code === 'permission-denied') {
        addToast('error', 'تم رفض الوصول: حسابك غير مسموح له بقراءة مستند الإعدادات من Firestore.');
      } else {
        addToast('error', `حدث خطأ أثناء تحميل البيانات من الخادم: ${err.message || 'خطأ في الاتصال'}`);
      }
    } finally {
      setIsLoading(false);
      setIsRefreshing(false);
    }
  }, [addToast]);

  useEffect(() => {
    fetchServicesFromFirestore();
  }, [fetchServicesFromFirestore]);

  // Handle Save Service Link using updateDoc with dot notation (services_links.<id>.url) to update ONLY the URL
  // without overwriting existing custom title_ar. Falls back to setDoc if document does not exist yet.
  const handleSaveService = async (id: string, newUrl: string) => {
    setServices((prev) =>
      prev.map((s) => (s.id === id ? { ...s, isSaving: true, error: undefined } : s))
    );

    try {
      const docRef = doc(db, 'app_config', 'services');
      const targetService = services.find((s) => s.id === id);

      try {
        // Update ONLY the URL field via dot-notation update, preserving existing title_ar
        await updateDoc(docRef, {
          [`services_links.${id}.url`]: newUrl,
        });
      } catch (updateErr: any) {
        // If document doesn't exist yet, initialize it with setDoc and merge: true
        if (updateErr.code === 'not-found' || !docExists) {
          await setDoc(
            docRef,
            {
              services_links: {
                [id]: {
                  url: newUrl,
                  title_ar: targetService?.titleAr || '',
                },
              },
            },
            { merge: true }
          );
          setDocExists(true);
        } else {
          throw updateErr;
        }
      }

      setServices((prev) =>
        prev.map((s) => {
          if (s.id === id) {
            return {
              ...s,
              currentUrl: newUrl,
              inputUrl: newUrl,
              isCustomized: true,
              isSaving: false,
              hasUnsavedChanges: false,
            };
          }
          return s;
        })
      );

      addToast('success', `تم حفظ وتحديث رابط خدمة (${services.find((s) => s.id === id)?.titleAr}) دون المساس بالعنوان.`);
    } catch (err: any) {
      console.error(`Error saving service ${id}:`, err);
      const code = err?.code || '';
      let errMsg = `فشل حفظ الرابط: ${err.message || 'خطأ غير معروف'}`;

      if (code === 'permission-denied') {
        errMsg = 'عفواً! ليس لديك صلاحية كتابة وتعديل القواعد في Firestore Security Rules.';
      }

      setServices((prev) =>
        prev.map((s) => (s.id === id ? { ...s, isSaving: false, error: errMsg } : s))
      );
      addToast('error', errMsg);
    }
  };

  // Handle Revert Service Customization to Default
  const handleRevertService = async (id: string) => {
    setServices((prev) =>
      prev.map((s) => (s.id === id ? { ...s, isReverting: true } : s))
    );

    try {
      const docRef = doc(db, 'app_config', 'services');

      // Use updateDoc with deleteField() to remove only services_links.<id> without deleting doc or other services
      await updateDoc(docRef, {
        [`services_links.${id}`]: deleteField(),
      });

      const targetDef = DEFAULT_SERVICES.find((d) => d.id === id)!;

      setServices((prev) =>
        prev.map((s) => {
          if (s.id === id) {
            return {
              ...s,
              currentUrl: targetDef.defaultUrl,
              inputUrl: targetDef.defaultUrl,
              isCustomized: false,
              isReverting: false,
              hasUnsavedChanges: false,
            };
          }
          return s;
        })
      );

      addToast('success', `تم إزالة التخصيص وإعادة الرابط الافتراضي لخدمة (${targetDef.titleAr}).`);
    } catch (err: any) {
      console.error(`Error reverting service ${id}:`, err);
      const code = err?.code || '';
      let errMsg = `فشل إزالة التخصيص: ${err.message || 'خطأ غير معروف'}`;

      if (code === 'permission-denied') {
        errMsg = 'عفواً! ليس لديك صلاحية كتابة وتعديل القواعد في Firestore Security Rules.';
      }

      setServices((prev) =>
        prev.map((s) => (s.id === id ? { ...s, isReverting: false } : s))
      );
      addToast('error', errMsg);
    }
  };

  // Filter & Search logic
  const filteredServices = services.filter((s) => {
    const matchesSearch =
      s.titleAr.includes(searchQuery) ||
      s.titleEn.toLowerCase().includes(searchQuery.toLowerCase()) ||
      s.id.toLowerCase().includes(searchQuery.toLowerCase()) ||
      s.currentUrl.toLowerCase().includes(searchQuery.toLowerCase());

    if (!matchesSearch) return false;

    if (filterMode === 'customized') return s.isCustomized;
    if (filterMode === 'default') return !s.isCustomized;
    return true;
  });

  const customizedCount = services.filter((s) => s.isCustomized).length;
  const defaultCount = services.filter((s) => !s.isCustomized).length;

  return (
    <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
      {/* Toast Notifications */}
      <div className="fixed top-20 left-4 z-50 space-y-2 max-w-sm w-full pointer-events-none">
        {toasts.map((toast) => (
          <div
            key={toast.id}
            className={`pointer-events-auto p-4 rounded-xl shadow-xl border flex items-start gap-3 transition-all animate-in slide-in-from-left duration-200 ${
              toast.type === 'success'
                ? 'bg-emerald-900 text-white border-emerald-700'
                : toast.type === 'error'
                ? 'bg-red-900 text-white border-red-700'
                : toast.type === 'warning'
                ? 'bg-amber-900 text-white border-amber-700'
                : 'bg-slate-900 text-white border-slate-700'
            }`}
          >
            {toast.type === 'success' && <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0 mt-0.5" />}
            {toast.type === 'error' && <XCircle className="w-5 h-5 text-red-400 shrink-0 mt-0.5" />}
            {toast.type === 'warning' && <AlertTriangle className="w-5 h-5 text-amber-400 shrink-0 mt-0.5" />}
            {toast.type === 'info' && <Info className="w-5 h-5 text-blue-400 shrink-0 mt-0.5" />}
            <span className="text-xs font-medium leading-relaxed flex-1">{toast.message}</span>
            <button
              onClick={() => removeToast(toast.id)}
              className="text-white/60 hover:text-white p-0.5 rounded"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        ))}
      </div>

      {/* Top Banner & Stats */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
        {/* Total Stats */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-emerald-50 text-emerald-800 flex items-center justify-center font-bold text-xl border border-emerald-100">
            <Layers className="w-6 h-6" />
          </div>
          <div>
            <p className="text-xs text-slate-500 font-bold">إجمالي الخدمات المتوفرة</p>
            <p className="text-2xl font-black text-slate-900">{services.length}</p>
          </div>
        </div>

        {/* Customized Stats */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-amber-50 text-amber-800 flex items-center justify-center font-bold text-xl border border-amber-100">
            <Sparkles className="w-6 h-6" />
          </div>
          <div>
            <p className="text-xs text-slate-500 font-bold">الخدمات المخصصة</p>
            <p className="text-2xl font-black text-amber-900">{customizedCount}</p>
          </div>
        </div>

        {/* Default Stats */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm flex items-center gap-4">
          <div className="w-12 h-12 rounded-xl bg-slate-100 text-slate-700 flex items-center justify-center font-bold text-xl border border-slate-200">
            <CheckCircle2 className="w-6 h-6" />
          </div>
          <div>
            <p className="text-xs text-slate-500 font-bold">الخدمات الافتراضية</p>
            <p className="text-2xl font-black text-slate-800">{defaultCount}</p>
          </div>
        </div>

        {/* Server Sync Status Card */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-sm flex items-center justify-between">
          <div>
            <p className="text-xs text-slate-500 font-bold mb-1">مصدر البيانات المستلمة</p>
            {isFromCache === true ? (
              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-900 border border-amber-200">
                <Wifi className="w-3.5 h-3.5" />
                الكاش (Offline Cache)
              </span>
            ) : isFromCache === false ? (
              <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-900 border border-emerald-200">
                <Server className="w-3.5 h-3.5" />
                خادم Firestore مباشر
              </span>
            ) : (
              <span className="text-xs text-slate-400">جاري التحقق...</span>
            )}
          </div>
          <button
            onClick={() => fetchServicesFromFirestore(true)}
            disabled={isRefreshing}
            className="p-2.5 rounded-xl bg-slate-100 hover:bg-slate-200 text-slate-700 transition-colors shadow-sm disabled:opacity-50"
            title="إعادة تحميل البيانات من Firestore"
          >
            <RefreshCw className={`w-5 h-5 ${isRefreshing ? 'animate-spin text-emerald-700' : ''}`} />
          </button>
        </div>
      </div>

      {!docExists && !isLoading && (
        <div className="bg-amber-50 border border-amber-300 rounded-2xl p-4 flex items-start gap-3 text-amber-900 text-xs sm:text-sm">
          <AlertTriangle className="w-5 h-5 text-amber-600 shrink-0 mt-0.5" />
          <div>
            <p className="font-bold">مستند الإعدادات app_config/services غير موجود حالياً في Firestore.</p>
            <p className="mt-1">جميع الخدمات تعمل على الروابط الافتراضية للتطبيق. عند حفظ أي رابط مخصص لأول مرة، سيتم إنشاء المستند وحقل <code className="font-mono bg-amber-100 px-1 rounded font-bold">services_links</code> كخريطة متداخلة تلقائياً.</p>
          </div>
        </div>
      )}

      {/* Control Bar: Search & Filter Tabs */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-sm flex flex-col sm:flex-row items-center justify-between gap-4">
        {/* Search Field */}
        <div className="relative w-full sm:w-80">
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="بحث باسم الخدمة أو الرابط..."
            className="w-full pr-10 pl-4 py-2 text-xs bg-slate-50 border border-slate-300 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-emerald-600 transition-all"
          />
          <Search className="w-4 h-4 text-slate-400 absolute right-3 top-2.5" />
        </div>

        {/* Filter Mode Tabs */}
        <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-xl w-full sm:w-auto">
          <button
            onClick={() => setFilterMode('all')}
            className={`flex-1 sm:flex-none px-4 py-1.5 text-xs font-bold rounded-lg transition-all ${
              filterMode === 'all'
                ? 'bg-white text-emerald-900 shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            الكل ({services.length})
          </button>
          <button
            onClick={() => setFilterMode('customized')}
            className={`flex-1 sm:flex-none px-4 py-1.5 text-xs font-bold rounded-lg transition-all ${
              filterMode === 'customized'
                ? 'bg-amber-500 text-white shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            المخصصة فقط ({customizedCount})
          </button>
          <button
            onClick={() => setFilterMode('default')}
            className={`flex-1 sm:flex-none px-4 py-1.5 text-xs font-bold rounded-lg transition-all ${
              filterMode === 'default'
                ? 'bg-emerald-800 text-white shadow-sm'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            الافتراضية فقط ({defaultCount})
          </button>
        </div>
      </div>

      {/* Services Cards Grid */}
      {isLoading ? (
        <div className="py-20 text-center space-y-4">
          <div className="w-10 h-10 border-4 border-emerald-800 border-t-transparent rounded-full animate-spin mx-auto" />
          <p className="text-sm font-bold text-slate-600">جاري تحميل خدمات التطبيق من Firestore...</p>
        </div>
      ) : filteredServices.length === 0 ? (
        <div className="bg-white rounded-2xl border border-slate-200 p-12 text-center space-y-3">
          <HelpCircle className="w-10 h-10 text-slate-300 mx-auto" />
          <p className="text-base font-bold text-slate-800">لا توجد خدمات تطابق البحث الحالي.</p>
          <p className="text-xs text-slate-500">جرب البحث بكلمة مختلفة أو اختر تصفية أخرى.</p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-2 gap-6">
          {filteredServices.map((service) => (
            <ServiceCard
              key={service.id}
              service={service}
              onSave={handleSaveService}
              onRevert={handleRevertService}
            />
          ))}
        </div>
      )}

      {/* Hardcoded Links Info Modal */}
      {showModal && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-2xl w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in duration-150 max-h-[90vh] overflow-y-auto">
            <div className="flex items-center justify-between pb-4 border-b border-slate-100 mb-4">
              <div className="flex items-center gap-2">
                <div className="w-9 h-9 rounded-xl bg-amber-100 text-amber-800 flex items-center justify-center">
                  <Info className="w-5 h-5" />
                </div>
                <div>
                  <h3 className="text-base font-bold text-slate-900">
                    تقرير الروابط الثابتة (Hardcoded Links)
                  </h3>
                  <p className="text-xs text-slate-500">
                    روابط مدمجة بكود التطبيق المباشر ولا تقرأ حالياً من Firestore
                  </p>
                </div>
              </div>
              <button
                onClick={handleCloseModal}
                className="text-slate-400 hover:text-slate-600 p-1 rounded-lg"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="space-y-4 text-xs text-slate-700">
              <div className="bg-amber-50 border border-amber-200 p-3.5 rounded-xl text-amber-950 font-medium leading-relaxed">
                ⚠️ <strong>تنبيه هائم:</strong> الروابط الموضحة أدناه مكتوبة مباشرة في أكواد واجهات التطبيق (<code className="font-mono bg-amber-100 px-1 rounded">about_us_screen.dart</code> & <code className="font-mono bg-amber-100 px-1 rounded">contact_us_screen.dart</code>). <strong>التحكم فيها ديناميكياً يتطلب تعديل كود تطبيق الهاتف وإصدار تحديث جديد في المتاجر.</strong>
              </div>

              <div className="space-y-2">
                <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 flex items-start gap-3">
                  <PhoneCall className="w-4 h-4 text-emerald-700 shrink-0 mt-0.5" />
                  <div>
                    <p className="font-bold text-slate-900">رابط الاتصال الهاتفي المباشر</p>
                    <code className="font-mono text-slate-600 dir-ltr text-right block mt-0.5">tel:01224817075</code>
                    <p className="text-[11px] text-slate-500 mt-0.5">موجود في شاشة "تواصل معنا" وشاشة "اعرفنا أكتر".</p>
                  </div>
                </div>

                <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 flex items-start gap-3">
                  <MessageSquare className="w-4 h-4 text-emerald-600 shrink-0 mt-0.5" />
                  <div>
                    <p className="font-bold text-slate-900">رابط محادثة الواتساب المباشرة</p>
                    <code className="font-mono text-slate-600 dir-ltr text-right block mt-0.5">https://wa.me/201224817075</code>
                    <p className="text-[11px] text-slate-500 mt-0.5">./ زر الواتساب لشاشة التحدث السريع.</p>
                  </div>
                </div>

                <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 flex items-start gap-3">
                  <MapPin className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
                  <div>
                    <p className="font-bold text-slate-900">خرائط جوجل المباشرة لفرعي العيادة</p>
                    <p className="text-[11px] text-slate-600">عيادة المهندسين: <code className="font-mono dir-ltr">https://maps.app.goo.gl/G79rF1xXAhxefqw59</code></p>
                    <p className="text-[11px] text-slate-600">عيادة إمبابة: <code className="font-mono dir-ltr">https://maps.app.goo.gl/Tozjov7rBtUo6xxaA</code></p>
                  </div>
                </div>

                <div className="p-3 bg-slate-50 rounded-xl border border-slate-200 flex items-start gap-3">
                  <Share2 className="w-4 h-4 text-blue-600 shrink-0 mt-0.5" />
                  <div>
                    <p className="font-bold text-slate-900">صفحات التواصل الاجتماعي والموقع</p>
                    <p className="text-[11px] text-slate-600">صفحة الفيسبوك، الانستجرام، لينكدإن، قناة الواتساب، والماسينجر.</p>
                  </div>
                </div>
              </div>

              <div className="pt-3 border-t border-slate-100 text-right">
                <button
                  type="button"
                  onClick={handleCloseModal}
                  className="px-4 py-2 bg-slate-800 text-white rounded-xl font-bold text-xs hover:bg-slate-900 transition-colors"
                >
                  إغلاق التقرير
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
