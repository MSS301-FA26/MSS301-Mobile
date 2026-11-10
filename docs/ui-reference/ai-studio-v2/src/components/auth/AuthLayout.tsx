import React from 'react';
import { Logo } from '../Logo';

interface AuthLayoutProps {
  children: React.ReactNode;
  activeTab: 'login' | 'register';
  onTabChange: (tab: 'login' | 'register') => void;
  onBack: () => void;
  title: string;
  description: string;
  maxWidthClass?: string;
}

export const AuthLayout: React.FC<AuthLayoutProps> = ({
  children,
  activeTab,
  onTabChange,
  onBack,
  title,
  description,
  maxWidthClass = 'max-w-[480px]',
}) => {
  return (
    <div className="min-h-screen w-full bg-[#0E0E0F] text-white flex flex-col justify-between">
      {/* Top Bar */}
      <header className="w-full border-b border-[#2B2B30] bg-[#0E0E0F]/95 backdrop-blur-md sticky top-0 z-30">
        <div className="w-full max-w-4xl mx-auto h-16 px-5 sm:px-6 flex items-center justify-between">
          {/* Brand compact logo + name */}
          <div className="flex items-center gap-3">
            <Logo variant="compact" onClick={onBack} />
            <span className="font-bold text-white text-base sm:text-lg tracking-tight select-none">
              CinePremier
            </span>
          </div>

          {/* Close/Back Button */}
          <button
            type="button"
            onClick={onBack}
            aria-label="Đóng và quay lại"
            className="w-11 h-11 rounded-full bg-[#171719] border border-[#2B2B30] hover:border-white/20 text-[#D4D4D8] hover:text-white hover:bg-white/5 active:scale-95 flex items-center justify-center transition-all focus:outline-none"
          >
            <span className="material-symbols-outlined text-[22px]">close</span>
          </button>
        </div>
      </header>

      {/* Main Content Area */}
      <main className="flex-1 w-full flex flex-col items-center justify-center px-5 py-6 sm:py-10">
        <div className={`w-full ${maxWidthClass} mx-auto flex flex-col items-center`}>
          {/* Segmented Auth Tabs */}
          <div
            role="tablist"
            aria-label="Tùy chọn xác thực"
            className="w-full p-1 bg-[#171719] border border-[#2B2B30] rounded-2xl grid grid-cols-2 gap-1 mb-6 select-none"
          >
            <button
              type="button"
              role="tab"
              aria-selected={activeTab === 'login'}
              aria-current={activeTab === 'login' ? 'page' : undefined}
              onClick={() => onTabChange('login')}
              className={`h-10 rounded-xl font-bold text-sm transition-all flex items-center justify-center ${
                activeTab === 'login'
                  ? 'bg-[#202024] text-white border border-[#F5B800]/50 shadow-sm'
                  : 'text-[#A1A1AA] hover:text-white hover:bg-white/5'
              }`}
            >
              Đăng nhập
            </button>
            <button
              type="button"
              role="tab"
              aria-selected={activeTab === 'register'}
              aria-current={activeTab === 'register' ? 'page' : undefined}
              onClick={() => onTabChange('register')}
              className={`h-10 rounded-xl font-bold text-sm transition-all flex items-center justify-center ${
                activeTab === 'register'
                  ? 'bg-[#202024] text-white border border-[#F5B800]/50 shadow-sm'
                  : 'text-[#A1A1AA] hover:text-white hover:bg-white/5'
              }`}
            >
              Đăng ký
            </button>
          </div>

          {/* Heading */}
          <div className="text-center mb-6">
            <h1 className="text-2xl sm:text-[26px] font-bold text-white tracking-tight">
              {title}
            </h1>
            <p className="text-xs sm:text-sm text-[#A1A1AA] mt-1.5 max-w-sm leading-relaxed mx-auto">
              {description}
            </p>
          </div>

          {/* Content Card */}
          <div className="w-full bg-[#171719] border border-[#2B2B30] rounded-2xl p-5 sm:p-7 shadow-xl">
            {children}
          </div>
        </div>
      </main>

      {/* Footer */}
      <footer className="w-full border-t border-[#2B2B30] py-4 px-5 text-center">
        <div className="flex items-center justify-center gap-1.5 text-xs text-[#71717A]">
          <span className="material-symbols-outlined text-[16px] text-[#F5B800]">
            verified_user
          </span>
          <span>Bảo mật thông tin bởi CinePremier</span>
        </div>
      </footer>
    </div>
  );
};
