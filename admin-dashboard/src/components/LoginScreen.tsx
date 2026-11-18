import React, { useState } from 'react';
import { auth } from '../firebase';
import { signInWithEmailAndPassword } from 'firebase/auth';
import { Lock, Mail, AlertCircle, ShieldCheck, Stethoscope } from 'lucide-react';

interface LoginScreenProps {
  onLoginSuccess?: () => void;
}

export const LoginScreen: React.FC<LoginScreenProps> = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setErrorMessage(null);

    if (!email.trim() || !password.trim()) {
      setErrorMessage('يرجى إدخال البريد الإلكتروني وكلمة المرور.');
      return;
    }

    setIsLoading(true);

    try {
      await signInWithEmailAndPassword(auth, email.trim(), password.trim());
    } catch (err: any) {
      console.error('Login error:', err);
      const code = err?.code || '';

      if (code === 'auth/invalid-credential' || code === 'auth/user-not-found' || code === 'auth/wrong-password') {
        setErrorMessage('البريد الإلكتروني أو كلمة المرور غير صحيحة.');
      } else if (code === 'auth/too-many-requests') {
        setErrorMessage('تم تجاوز عدد محاولات الدخول المسموح بها. يرجى المحاولة لاحقاً.');
      } else if (code === 'auth/network-request-failed') {
        setErrorMessage('تعذر الاتصال بالخادم. يرجى التحقق من اتصال الإنترنت.');
      } else {
        setErrorMessage(`فشل تسجيل الدخول: ${err.message || 'حدث خطأ غير متوقع'}`);
      }
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#faf7f2] px-4 py-12">
      <div className="w-full max-w-md">
        {/* Header Branding */}
        <div className="text-center mb-8">
          <div className="inline-flex items-center justify-center w-16 h-16 rounded-2xl bg-emerald-900 text-amber-400 shadow-xl mb-4 border-2 border-emerald-700">
            <Stethoscope className="w-8 h-8" />
          </div>
          <h1 className="text-2xl font-extrabold text-slate-900">
            لوحة إدارة روابط خدمات التطبيق
          </h1>
          <p className="text-sm text-slate-600 mt-1">
            عيادة د. إسلام مجدي - Dr. Islam Magdy Clinic
          </p>
        </div>

        {/* Card */}
        <div className="bg-white rounded-2xl shadow-xl border border-slate-200/80 p-6 sm:p-8">
          <div className="flex items-center gap-2 mb-6 pb-4 border-b border-slate-100">
            <ShieldCheck className="w-5 h-5 text-emerald-700" />
            <h2 className="text-lg font-bold text-slate-800">
              تسجيل دخول المسؤول
            </h2>
          </div>

          {errorMessage && (
            <div className="mb-6 bg-red-50 border border-red-200 rounded-xl p-4 flex items-start gap-3 text-red-800 text-sm">
              <AlertCircle className="w-5 h-5 text-red-600 shrink-0 mt-0.5" />
              <span>{errorMessage}</span>
            </div>
          )}

          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Email Field */}
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1.5">
                البريد الإلكتروني للمسؤول
              </label>
              <div className="relative">
                <input
                  type="email"
                  required
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="admin@wedietly.com"
                  dir="ltr"
                  className="w-full pl-10 pr-4 py-2.5 text-sm bg-slate-50 border border-slate-300 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent transition-all"
                />
                <Mail className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
              </div>
            </div>

            {/* Password Field */}
            <div>
              <label className="block text-xs font-bold text-slate-700 mb-1.5">
                كلمة المرور
              </label>
              <div className="relative">
                <input
                  type="password"
                  required
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="••••••••"
                  dir="ltr"
                  className="w-full pl-10 pr-4 py-2.5 text-sm bg-slate-50 border border-slate-300 rounded-xl focus:bg-white focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:border-transparent transition-all"
                />
                <Lock className="w-4 h-4 text-slate-400 absolute left-3 top-3.5" />
              </div>
            </div>

            {/* Submit Button */}
            <button
              type="submit"
              disabled={isLoading}
              className="w-full py-3 px-4 bg-emerald-800 hover:bg-emerald-900 text-white font-bold rounded-xl shadow-md hover:shadow-lg focus:outline-none focus:ring-2 focus:ring-emerald-600 focus:ring-offset-2 transition-all flex items-center justify-center gap-2 disabled:opacity-60 disabled:cursor-not-allowed text-sm"
            >
              {isLoading ? (
                <>
                  <div className="w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  <span>جاري التسجيل...</span>
                </>
              ) : (
                <span>دخول اللوحة</span>
              )}
            </button>
          </form>

          {/* Restriction Note */}
          <div className="mt-6 pt-4 border-t border-slate-100 text-center">
            <p className="text-xs text-slate-500 bg-slate-50 p-3 rounded-lg border border-slate-200/60 leading-relaxed">
              🔒 الدخول مقتصر على حساب المسؤول المعتمد. التسجيل العام غير متاح لدواعي الأمان.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};
