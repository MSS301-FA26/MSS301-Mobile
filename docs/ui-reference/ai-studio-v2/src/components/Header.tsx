import React, { useState } from 'react';
import { ScreenName } from '../types';
import { Logo } from './Logo';
import { useAuth } from '../context/AuthContext';
import { CINEMA_CONFIG } from '../data/cinemaConfig';

export interface HeaderProps {
  currentScreen: ScreenName;
  onNavigate: (screen: ScreenName) => void;
  onBack?: () => void;
  title?: string;
  onOpenCinemaPicker?: () => void;
  onOpenCinemaInfo?: () => void;
  selectedCinemaName?: string;
}

export const Header: React.FC<HeaderProps> = ({
  currentScreen,
  onNavigate,
  onBack,
  title,
  onOpenCinemaPicker,
  onOpenCinemaInfo,
  selectedCinemaName = CINEMA_CONFIG.name,
}) => {
  const { user } = useAuth();
  const [isNotificationOpen, setIsNotificationOpen] = useState(false);
  const [hasUnreadNotification, setHasUnreadNotification] = useState(true);
  const handleCinemaClick = onOpenCinemaInfo || onOpenCinemaPicker;

  // The 5 main navigation tabs that share the primary 5-element Header:
  // 1. Trang chủ ('home')
  // 2. Khám phá ('discover')
  // 3. Lịch chiếu ('calendar')
  // 4. Tài khoản ('account')
  // 5. Đơn của tôi ('orders')
  const isMainTab = ['home', 'discover', 'calendar', 'account', 'orders'].includes(currentScreen);

  // Sub-screen Header with Back Button and Title (e.g. movie-detail, showtimes, seats, etc.)
  if (!isMainTab) {
    return (
      <header className="fixed top-0 left-0 right-0 w-full z-50 pt-safe bg-[#0E0E0F]/95 backdrop-blur-xl shadow-lg border-b border-[#2B2B30]">
        <div className="w-full max-w-7xl mx-auto h-16 px-2.5 sm:px-4 md:px-6 lg:px-8 flex items-center justify-between gap-2 box-border">
          <div className="flex items-center gap-1.5 min-w-0">
            <button
              type="button"
              aria-label="Quay lại"
              className="w-10 h-10 rounded-full flex items-center justify-center text-[#D4D4D8] hover:text-[#F5B800] hover:bg-white/5 active:scale-95 transition-all shrink-0 focus:outline-none"
              onClick={onBack ? onBack : () => onNavigate('home')}
            >
              <span className="material-symbols-outlined text-[24px]">arrow_back</span>
            </button>
            <h1 className="font-bold text-[16px] sm:text-[18px] text-white truncate max-w-[220px] sm:max-w-md">
              {title || 'CinePremier'}
            </h1>
          </div>

          <div className="flex items-center gap-1.5 shrink-0">
            <button
              type="button"
              aria-label="Chia sẻ"
              className="w-10 h-10 flex items-center justify-center rounded-full text-[#A1A1AA] hover:text-[#F5B800] hover:bg-white/5 transition-colors focus:outline-none"
              onClick={() => {
                if (navigator.share) {
                  navigator.share({ title: 'CinePremier', url: window.location.href });
                } else {
                  navigator.clipboard?.writeText(window.location.href);
                  alert('Đã sao chép liên kết chia sẻ!');
                }
              }}
            >
              <span className="material-symbols-outlined text-[22px]">share</span>
            </button>

            <button
              type="button"
              aria-label={user ? `Tài khoản ${user.name}` : 'Tài khoản hoặc đăng nhập'}
              className="w-10 h-10 rounded-full flex items-center justify-center hover:bg-white/5 transition-colors focus:outline-none"
              onClick={() => onNavigate('account')}
            >
              {user ? (
                <div className="w-8 h-8 rounded-full bg-[#F5B800] flex items-center justify-center text-black font-black text-xs shadow-sm">
                  {user.initials}
                </div>
              ) : (
                <div className="w-8 h-8 rounded-full bg-white/10 flex items-center justify-center text-[#D4D4D8] shadow-sm">
                  <span className="material-symbols-outlined text-[18px]">person</span>
                </div>
              )}
            </button>
          </div>
        </div>
      </header>
    );
  }

  // Primary Shared Header across Home, Discover, Calendar, Account, and Orders
  // Mobile (< 768px): [Logo CP] [Chọn cụm rạp] [Tìm kiếm] [Thông báo] [Tài khoản]
  // Desktop (>= 768px): [Logo CINEPREMIER] [khoảng trống linh hoạt] [Chọn rạp] [Tìm kiếm] [Thông báo] [Tài khoản]
  return (
    <>
      <header className="fixed top-0 left-0 right-0 w-full z-50 pt-safe bg-[#0E0E0F]/95 backdrop-blur-xl shadow-lg border-b border-[#2B2B30]">
        <div className="w-full max-w-7xl mx-auto h-16 px-2.5 sm:px-3.5 md:px-6 lg:px-8 flex items-center gap-1.5 sm:gap-2 md:gap-3 box-border">
          {/* 1. Brand Logo: Compact CP on mobile (<768px), Full CINEPREMIER on desktop/tablet (>=768px) */}
          <Logo
            variant="responsive"
            onClick={() => onNavigate('home')}
            className="shrink-0"
          />

          {/* 2. Cinema Info Badge/Button:
              - Mobile (<768px): flex-1 min-w-0 taking up remaining flexible space between logo and actions
              - Desktop (>=768px): md:flex-initial md:w-auto md:ml-auto md:max-w-xs (creates flexible space on left)
              - No dropdown arrow: displays static cinema identity, click opens "Thông tin rạp" bottom sheet
          */}
          <button
            type="button"
            onClick={handleCinemaClick}
            aria-label={`Xem thông tin rạp ${CINEMA_CONFIG.name}`}
            className="flex-1 min-w-0 md:flex-initial md:w-auto md:ml-auto md:max-w-xs h-10 px-2.5 sm:px-3.5 rounded-full bg-[#171719] hover:bg-[#202024] border border-[#2B2B30] hover:border-white/20 active:scale-95 transition-all flex items-center gap-1.5 text-[#D4D4D8] hover:text-white shrink min-h-[40px] focus:outline-none"
          >
            <span className="material-symbols-outlined text-[16px] text-[#F5B800] shrink-0">
              location_on
            </span>
            <span className="text-[11px] sm:text-xs font-semibold truncate text-left min-w-0 whitespace-nowrap overflow-hidden text-ellipsis">
              {CINEMA_CONFIG.name}
            </span>
          </button>

          {/* 3. Search Action Icon */}
          <button
            type="button"
            aria-label="Tìm kiếm phim và suất chiếu"
            className={`w-10 h-10 shrink-0 rounded-full flex items-center justify-center transition-all focus:outline-none active:scale-95 ${
              currentScreen === 'discover'
                ? 'text-[#F5B800] bg-white/5 font-bold'
                : 'text-[#D4D4D8] hover:text-[#F5B800] hover:bg-white/5'
            }`}
            onClick={() => onNavigate('discover')}
          >
            <span className="material-symbols-outlined text-[20px] sm:text-[22px]">search</span>
          </button>

          {/* 4. Notifications Action Icon with In-Bounds Badge */}
          <button
            type="button"
            aria-label="Thông báo hệ thống"
            className="w-10 h-10 shrink-0 rounded-full flex items-center justify-center text-[#D4D4D8] hover:text-[#F5B800] hover:bg-white/5 transition-all relative focus:outline-none active:scale-95"
            onClick={() => setIsNotificationOpen(true)}
          >
            <span className="material-symbols-outlined text-[20px] sm:text-[22px]">notifications</span>
            {hasUnreadNotification && (
              <span className="absolute top-2 right-2 w-2 h-2 rounded-full bg-[#F5B800] ring-2 ring-[#0E0E0F] pointer-events-none" />
            )}
          </button>

          {/* 5. Account / Avatar Button */}
          <button
            type="button"
            aria-label={user ? `Trang tài khoản ${user.name}` : 'Đăng nhập hoặc tài khoản'}
            className="w-10 h-10 shrink-0 rounded-full flex items-center justify-center hover:bg-white/5 transition-all focus:outline-none active:scale-95"
            onClick={() => onNavigate('account')}
          >
            {user ? (
              <div
                className={`w-8 h-8 rounded-full bg-[#F5B800] flex items-center justify-center text-black font-black text-xs shadow-sm transition-all ${
                  currentScreen === 'account'
                    ? 'ring-2 ring-[#F5B800] ring-offset-2 ring-offset-[#0E0E0F]'
                    : ''
                }`}
              >
                {user.initials}
              </div>
            ) : (
              <div
                className={`w-8 h-8 rounded-full bg-white/10 flex items-center justify-center text-[#D4D4D8] shadow-sm transition-all ${
                  currentScreen === 'account'
                    ? 'ring-2 ring-[#F5B800] ring-offset-2 ring-offset-[#0E0E0F] text-[#F5B800]'
                    : ''
                }`}
              >
                <span className="material-symbols-outlined text-[18px]">person</span>
              </div>
            )}
          </button>
        </div>
      </header>

      {/* Interactive Notifications Modal */}
      {isNotificationOpen && (
        <div
          role="dialog"
          aria-modal="true"
          aria-labelledby="notification-title"
          className="fixed inset-0 z-50 bg-black/70 backdrop-blur-sm flex items-start justify-center pt-20 px-4 animate-fade-in"
          onClick={() => setIsNotificationOpen(false)}
        >
          <div
            className="w-full max-w-sm bg-[#171719] border border-[#2B2B30] rounded-2xl p-4 shadow-2xl flex flex-col gap-3 text-[#D4D4D8]"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-2 border-b border-[#2B2B30]">
              <div className="flex items-center gap-2">
                <span className="material-symbols-outlined text-[#F5B800] text-[20px]">
                  notifications
                </span>
                <h3 id="notification-title" className="font-bold text-sm text-white">
                  Thông Báo
                </h3>
              </div>
              <button
                type="button"
                onClick={() => setIsNotificationOpen(false)}
                className="w-7 h-7 rounded-full flex items-center justify-center text-[#71717A] hover:text-white hover:bg-white/5"
              >
                <span className="material-symbols-outlined text-[18px]">close</span>
              </button>
            </div>

            <div className="flex flex-col gap-2.5">
              {/* Notification Item 1 */}
              <div className="p-3 rounded-xl bg-[#202024] border border-[#2B2B30] flex flex-col gap-1">
                <div className="flex items-center justify-between text-xs">
                  <span className="font-bold text-[#F5B800] flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#F5B800]" />
                    Suất chiếu sắp diễn ra
                  </span>
                  <span className="text-[10px] text-[#71717A]">30 phút trước</span>
                </div>
                <p className="text-xs text-[#A1A1AA] leading-relaxed">
                  Vé phim <strong className="text-white">INCEPTION</strong> của bạn sẽ chiếu lúc <strong className="text-white">20:30 hôm nay</strong> tại Phòng C ({selectedCinemaName}). Vui lòng có mặt sớm 15 phút.
                </p>
              </div>

              {/* Notification Item 2 */}
              <div className="p-3 rounded-xl bg-[#202024] border border-[#2B2B30] flex flex-col gap-1">
                <div className="flex items-center justify-between text-xs">
                  <span className="font-semibold text-white">Ưu đãi thành viên VIP</span>
                  <span className="text-[10px] text-[#71717A]">Hôm nay</span>
                </div>
                <p className="text-xs text-[#A1A1AA] leading-relaxed">
                  Nhập mã <strong className="text-[#F5B800]">VIPCINE</strong> để nhận ngay giảm 20.000 ₫ cho vé Standard/VIP tiếp theo.
                </p>
              </div>
            </div>

            <div className="pt-2 border-t border-[#2B2B30] flex items-center justify-between gap-2">
              <button
                type="button"
                onClick={() => {
                  setHasUnreadNotification(false);
                  setIsNotificationOpen(false);
                }}
                className="flex-1 h-9 rounded-xl bg-[#202024] hover:bg-[#2B2B30] text-xs font-semibold text-[#A1A1AA] hover:text-white transition-colors border border-[#2B2B30]"
              >
                Đánh dấu đã đọc
              </button>
              <button
                type="button"
                onClick={() => setIsNotificationOpen(false)}
                className="px-4 h-9 rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] text-xs font-bold text-black transition-colors"
              >
                Đóng
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
};
