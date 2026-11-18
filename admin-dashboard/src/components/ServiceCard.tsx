import React, { useState, useEffect } from 'react';
import { ServiceItemState } from '../types/service';
import { validateServiceUrl } from '../utils/urlValidator';
import { Check, RotateCcw, AlertTriangle, ExternalLink, Globe, Key, FileCode, Info } from 'lucide-react';

interface ServiceCardProps {
  service: ServiceItemState;
  onSave: (id: string, newUrl: string) => Promise<void>;
  onRevert: (id: string) => Promise<void>;
}

export const ServiceCard: React.FC<ServiceCardProps> = ({
  service,
  onSave,
  onRevert,
}) => {
  const [inputUrl, setInputUrl] = useState(service.inputUrl);
  const [showRevertModal, setShowRevertModal] = useState(false);
  const [validationError, setValidationError] = useState<string | null>(null);
  const [validationWarning, setValidationWarning] = useState<string | null>(null);

  // Synchronize local input state if props change from external updates
  useEffect(() => {
    setInputUrl(service.inputUrl);
  }, [service.inputUrl]);

  // Handle URL change & live validation
  const handleUrlChange = (value: string) => {
    setInputUrl(value);
    const result = validateServiceUrl(value);

    if (!result.isValid) {
      setValidationError(result.error || 'رابط غير صالح');
      setValidationWarning(null);
    } else {
      setValidationError(null);
      setValidationWarning(result.warning || null);
    }
  };

  const hasUnsavedChanges = inputUrl.trim() !== service.currentUrl.trim();

  const handleSaveClick = async () => {
    const result = validateServiceUrl(inputUrl);
    if (!result.isValid) {
      setValidationError(result.error || 'الرابط غير صالح');
      return;
    }

    setValidationError(null);
    await onSave(service.id, inputUrl.trim());
  };

  const handleConfirmRevert = async () => {
    setShowRevertModal(false);
    await onRevert(service.id);
  };

  return (
    <div className={`bg-white rounded-2xl border transition-all duration-200 shadow-sm hover:shadow-md flex flex-col justify-between overflow-hidden ${
      service.isCustomized
        ? 'border-amber-300 ring-1 ring-amber-200'
        : 'border-slate-200'
    }`}>
      {/* Card Header */}
      <div className="p-5 pb-4 border-b border-slate-100">
        <div className="flex items-start justify-between gap-3 mb-2">
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-base font-bold text-slate-900">
                {service.titleAr}
              </h3>
              <span className="text-xs font-medium text-slate-500 dir-ltr">
                ({service.titleEn})
              </span>
            </div>
            <p className="text-xs text-slate-500 mt-1 leading-relaxed">
              {service.descriptionAr}
            </p>
          </div>

          {/* Status Badge */}
          {service.isCustomized ? (
            <span className="shrink-0 inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-900 border border-amber-300">
              <span className="w-2 h-2 rounded-full bg-amber-500 animate-pulse" />
              مخصص
            </span>
          ) : (
            <span className="shrink-0 inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-semibold bg-slate-100 text-slate-700 border border-slate-200">
              <span className="w-2 h-2 rounded-full bg-emerald-500" />
              افتراضي
            </span>
          )}
        </div>

        {/* Warning if service is not used in App UI */}
        {!service.isUsedInAppUI && (
          <div className="mt-2 bg-amber-50 border border-amber-200 p-2.5 rounded-xl flex items-start gap-2 text-amber-900 text-xs">
            <Info className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
            <span>ملاحظة: هذه الخدمة مسجلة في النظام البرمجي ولكن لا يوجد زر في واجهة التطبيق يفتحها (التطبيق يستخدم شاشة محلية).</span>
          </div>
        )}

        {/* Technical Key info */}
        <div className="mt-3 flex items-center gap-3 text-xs text-slate-600 bg-slate-50 p-2 rounded-lg border border-slate-200/70">
          <div className="flex items-center gap-1 text-slate-500 font-mono">
            <Key className="w-3.5 h-3.5 text-slate-400" />
            <span className="font-semibold text-slate-700">مفتاح Firestore:</span>
          </div>
          <code className="font-mono text-emerald-800 bg-emerald-50 px-2 py-0.5 rounded border border-emerald-200 font-bold">
            services_links.{service.id}.url
          </code>
        </div>
      </div>

      {/* Card Body */}
      <div className="p-5 space-y-4 flex-1">
        {/* Default URL Display */}
        <div className="space-y-1">
          <label className="text-xs font-bold text-slate-700 flex items-center gap-1.5">
            <FileCode className="w-3.5 h-3.5 text-slate-500" />
            الرابط الافتراضي للتطبيق (Fallback):
          </label>
          <div className="bg-slate-100/90 p-2.5 rounded-xl border border-slate-200 text-xs text-slate-700 font-mono break-all flex items-center justify-between gap-2">
            <span className="truncate">{service.defaultUrl}</span>
            <a
              href={service.defaultUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="text-slate-500 hover:text-emerald-700 shrink-0 p-1 rounded hover:bg-slate-200/80 transition-colors"
              title="فتح الرابط الافتراضي"
            >
              <ExternalLink className="w-3.5 h-3.5" />
            </a>
          </div>
        </div>

        {/* Current Active URL Display */}
        <div className="space-y-1">
          <label className="text-xs font-bold text-slate-700 flex items-center gap-1.5">
            <Globe className="w-3.5 h-3.5 text-slate-500" />
            الرابط النشط حالياً بالتطبيق:
          </label>
          <div className={`p-2.5 rounded-xl border text-xs font-mono break-all flex items-center justify-between gap-2 ${
            service.isCustomized
              ? 'bg-amber-50/70 border-amber-200 text-amber-950 font-semibold'
              : 'bg-emerald-50/70 border-emerald-200 text-emerald-950 font-semibold'
          }`}>
            <span className="truncate">{service.currentUrl}</span>
            <a
              href={service.currentUrl}
              target="_blank"
              rel="noopener noreferrer"
              className="text-slate-500 hover:text-emerald-700 shrink-0 p-1 rounded hover:bg-slate-200/80 transition-colors"
              title="اختبار الرابط النشط"
            >
              <ExternalLink className="w-3.5 h-3.5" />
            </a>
          </div>
        </div>

        {/* Edit URL Input */}
        <div className="space-y-1.5 pt-2">
          <div className="flex items-center justify-between">
            <label className="text-xs font-bold text-slate-800">
              تعديل رابط الخدمة:
            </label>
            {hasUnsavedChanges && (
              <span className="text-[11px] font-bold text-amber-600 bg-amber-50 border border-amber-200 px-2 py-0.5 rounded-md">
                تعديلات غير محفوظة
              </span>
            )}
          </div>
          <div className="relative">
            <input
              type="url"
              value={inputUrl}
              onChange={(e) => handleUrlChange(e.target.value)}
              placeholder="https://wedietly.com/app/..."
              dir="ltr"
              className={`w-full px-3 py-2 text-xs font-mono bg-white border rounded-xl focus:outline-none focus:ring-2 transition-all ${
                validationError
                  ? 'border-red-400 focus:ring-red-400 bg-red-50/30'
                  : hasUnsavedChanges
                  ? 'border-amber-400 focus:ring-amber-500'
                  : 'border-slate-300 focus:ring-emerald-600'
              }`}
            />
          </div>

          {/* Validation Messages */}
          {validationError && (
            <p className="text-xs text-red-600 flex items-center gap-1 font-medium mt-1">
              <AlertTriangle className="w-3.5 h-3.5 shrink-0" />
              {validationError}
            </p>
          )}

          {validationWarning && !validationError && (
            <p className="text-xs text-amber-700 bg-amber-50 border border-amber-200 p-2 rounded-lg flex items-start gap-1.5 mt-1">
              <AlertTriangle className="w-4 h-4 text-amber-600 shrink-0 mt-0.5" />
              <span>{validationWarning}</span>
            </p>
          )}
        </div>
      </div>

      {/* Card Footer Actions */}
      <div className="p-4 bg-slate-50 border-t border-slate-100 flex items-center gap-2 justify-between">
        {/* Revert Button */}
        <button
          type="button"
          disabled={!service.isCustomized || service.isReverting || service.isSaving}
          onClick={() => setShowRevertModal(true)}
          className="px-3 py-2 text-xs font-semibold rounded-xl text-slate-700 bg-white border border-slate-300 hover:bg-slate-100 hover:text-red-700 focus:outline-none focus:ring-2 focus:ring-slate-300 transition-all flex items-center gap-1.5 disabled:opacity-40 disabled:cursor-not-allowed shadow-sm"
          title="حذف القيمة المخصصة من Firestore وإعادة الرابط الافتراضي"
        >
          {service.isReverting ? (
            <div className="w-3.5 h-3.5 border-2 border-slate-500 border-t-transparent rounded-full animate-spin" />
          ) : (
            <RotateCcw className="w-3.5 h-3.5 text-slate-500" />
          )}
          <span>إزالة التخصيص</span>
        </button>

        {/* Save Button */}
        <button
          type="button"
          disabled={!hasUnsavedChanges || !!validationError || service.isSaving || service.isReverting}
          onClick={handleSaveClick}
          className="px-4 py-2 text-xs font-bold rounded-xl text-white bg-emerald-800 hover:bg-emerald-900 focus:outline-none focus:ring-2 focus:ring-emerald-600 transition-all flex items-center gap-1.5 disabled:opacity-40 disabled:cursor-not-allowed shadow-md"
        >
          {service.isSaving ? (
            <>
              <div className="w-3.5 h-3.5 border-2 border-white/40 border-t-white rounded-full animate-spin" />
              <span>جاري الحفظ...</span>
            </>
          ) : (
            <>
              <Check className="w-4 h-4" />
              <span>حفظ الرابط</span>
            </>
          )}
        </button>
      </div>

      {/* Confirmation Modal for Revert */}
      {showRevertModal && (
        <div className="fixed inset-0 bg-slate-900/60 backdrop-blur-sm z-50 flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in duration-150">
            <div className="flex items-center gap-3 text-red-600 mb-4">
              <div className="w-10 h-10 rounded-full bg-red-100 flex items-center justify-center shrink-0">
                <AlertTriangle className="w-5 h-5" />
              </div>
              <div>
                <h4 className="text-base font-bold text-slate-900">
                  تأكيد إزالة التخصيص
                </h4>
                <p className="text-xs text-slate-500">
                  خدمة: {service.titleAr}
                </p>
              </div>
            </div>

            <p className="text-xs text-slate-700 leading-relaxed bg-slate-50 p-3 rounded-xl border border-slate-200 mb-6">
              سيتم حذف حقل الرابط المخصص <code className="font-mono font-bold text-emerald-800">services_links.{service.id}</code> نهائياً من مستند Firestore، وسيعود تطبيق الهاتف لاستخدام الرابط الافتراضي:
              <br />
              <span className="font-mono text-emerald-900 font-bold block mt-1 dir-ltr text-right">
                {service.defaultUrl}
              </span>
            </p>

            <div className="flex items-center justify-end gap-3">
              <button
                type="button"
                onClick={() => setShowRevertModal(false)}
                className="px-4 py-2 text-xs font-semibold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-xl transition-colors"
              >
                إلغاء
              </button>
              <button
                type="button"
                onClick={handleConfirmRevert}
                className="px-4 py-2 text-xs font-bold text-white bg-red-600 hover:bg-red-700 rounded-xl shadow-md transition-colors flex items-center gap-1.5"
              >
                <RotateCcw className="w-3.5 h-3.5" />
                <span>تأكيد الإزالة والرجوع للافتراضي</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
