import React from 'react';
import { UserAuth } from '../types/service';
import { LogOut, ShieldCheck, Link2, ExternalLink } from 'lucide-react';

interface NavbarProps {
  user: UserAuth;
  onLogout: () => void;
  onOpenHardcodedModal: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({ user, onLogout, onOpenHardcodedModal }) => {
  return (
    <header className="bg-emerald-900 text-white shadow-lg sticky top-0 z-30 border-b border-emerald-800">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-16 flex items-center justify-between">
        {/* Brand / Logo */}
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-emerald-700/80 border border-emerald-500/30 flex items-center justify-center shadow-inner">
            <Link2 className="w-5 h-5 text-emerald-300" />
          </div>
          <div>
            <h1 className="text-lg sm:text-xl font-bold tracking-tight text-white flex items-center gap-2">
              لوحة تحكم روابط الخدمات
              <span className="text-xs font-semibold px-2 py-0.5 rounded-full bg-emerald-800 text-emerald-200 border border-emerald-700">
                د. إسلام مجدي
              </span>
            </h1>
            <p className="text-xs text-emerald-300/80 hidden sm:block">
              إدارة مستند app_config/services في Cloud Firestore
            </p>
          </div>
        </div>

        {/* Right Action Items */}
        <div className="flex items-center gap-2 sm:gap-4">
          <button
            onClick={onOpenHardcodedModal}
            className="text-xs sm:text-sm bg-emerald-800/80 hover:bg-emerald-800 text-emerald-100 border border-emerald-700 px-3 py-1.5 rounded-lg flex items-center gap-1.5 transition-colors"
            title="عرض الروابط الثابتة بالتطبيق"
          >
            <ExternalLink className="w-4 h-4 text-emerald-400" />
            <span className="hidden md:inline">الروابط الثابتة بالتطبيق</span>
          </button>

          {/* User Badge */}
          <div className="flex items-center gap-2 bg-emerald-950/60 border border-emerald-800/80 px-3 py-1.5 rounded-lg">
            <ShieldCheck className="w-4 h-4 text-emerald-400 shrink-0" />
            <span className="text-xs sm:text-sm font-medium text-emerald-200 truncate max-w-[140px] sm:max-w-[200px]">
              {user.email}
            </span>
          </div>

          {/* Logout Button */}
          <button
            onClick={onLogout}
            className="bg-red-600/90 hover:bg-red-600 text-white text-xs sm:text-sm font-medium px-3 py-1.5 rounded-lg flex items-center gap-1.5 transition-colors shadow-sm"
          >
            <LogOut className="w-4 h-4" />
            <span className="hidden sm:inline">خروج</span>
          </button>
        </div>
      </div>
    </header>
  );
};
