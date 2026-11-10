import React, { useState } from 'react';
import { ScreenName } from '../types';
import { useAuth } from '../context/AuthContext';
import { INITIAL_VOUCHERS } from '../data/vouchersData';
import { QRModal } from '../components/QRModal';

interface AccountScreenProps {
  onNavigate: (screen: ScreenName) => void;
  onOpenCinemaPicker?: () => void;
  onOpenCinemaInfo?: () => void;
}

export const AccountScreen: React.FC<AccountScreenProps> = ({
  onNavigate,
  onOpenCinemaPicker,
  onOpenCinemaInfo,
}) => {
  const { user, isAuthenticated, logout } = useAuth();
  const [isVIPQRModalOpen, setIsVIPQRModalOpen] = useState(false);
  const [isLogoutConfirmOpen, setIsLogoutConfirmOpen] = useState(false);
  const handleOpenCinemaInfo = onOpenCinemaInfo || onOpenCinemaPicker;

  // Dynamic voucher count from centralized source of truth
  const availableVouchersCount = INITIAL_VOUCHERS.filter(
    (v) => v.status === 'available'
  ).length;

  const handleProtectedNavigation = (targetScreen: ScreenName) => {
    if (isAuthenticated) {
      onNavigate(targetScreen);
    } else {
      onNavigate('login');
    }
  };

  const handleConfirmLogout = () => {
    logout();
    setIsLogoutConfirmOpen(false);
  };

  // --- GUEST STATE UI (Chưa đăng nhập) ---
  if (!user) {
    return (
      <div className="flex flex-col w-full text-[#D4D4D8] pb-8 p-4 gap-4 max-w-2xl mx-auto">
        {/* Guest Welcome Header Card */}
        <div className="flex flex-col p-5 sm:p-6 rounded-3xl bg-[#171719] border border-[#2B2B30] shadow-sm relative overflow-hidden">
          <div className="flex items-center gap-3.5 sm:gap-4 relative z-10">
            <div className="w-14 h-14 rounded-full bg-[#202024] border border-[#2B2B30] flex items-center justify-center text-[#A1A1AA] shrink-0">
              <span className="material-symbols-outlined text-[32px]">person</span>
            </div>
            <div>
              <h2 className="text-lg sm:text-xl font-black text-white">Chào bạn!</h2>
              <p className="text-xs text-[#A1A1AA] mt-0.5">
                Đăng nhập tài khoản để nhận ưu đãi, quản lý vé và tích lũy điểm CinePoints.
              </p>
            </div>
          </div>

          {/* Quick Auth Action Buttons */}
          <div className="grid grid-cols-2 gap-2.5 mt-5 relative z-10">
            <button
              type="button"
              onClick={() => onNavigate('login')}
              className="py-3 px-4 rounded-2xl bg-[#F5B800] hover:bg-[#E6AA00] text-black font-black text-xs sm:text-sm shadow-sm transition-all active:scale-95 flex items-center justify-center gap-1.5"
            >
              <span className="material-symbols-outlined text-[18px]">login</span>
              <span>Đăng nhập</span>
            </button>

            <button
              type="button"
              onClick={() => onNavigate('register')}
              className="py-3 px-4 rounded-2xl bg-[#202024] hover:bg-[#2B2B30] text-white font-bold text-xs sm:text-sm border border-[#2B2B30] transition-all active:scale-95 flex items-center justify-center gap-1.5"
            >
              <span className="material-symbols-outlined text-[18px]">how_to_reg</span>
              <span>Đăng ký</span>
            </button>
          </div>
        </div>

        {/* Member Benefits Overview */}
        <div className="p-5 rounded-3xl bg-[#171719] border border-[#2B2B30] flex flex-col gap-3">
          <span className="text-xs font-bold text-white uppercase tracking-wider flex items-center gap-1.5">
            <span className="material-symbols-outlined text-[16px] text-[#F5B800]">stars</span>
            <span>Đặc quyền hội viên CinePremier</span>
          </span>

          <div className="grid grid-cols-1 sm:grid-cols-3 gap-2.5 pt-1">
            <div className="p-3 rounded-2xl bg-[#0E0E0F] border border-[#2B2B30] flex items-start gap-2.5">
              <span className="material-symbols-outlined text-[20px] text-[#F5B800] shrink-0">
                loyalty
              </span>
              <div className="flex flex-col">
                <span className="text-xs font-bold text-white">Tích điểm CinePoints</span>
                <span className="text-[11px] text-[#71717A] mt-0.5">Tích lũy đến 10% mỗi vé</span>
              </div>
            </div>

            <div className="p-3 rounded-2xl bg-[#0E0E0F] border border-[#2B2B30] flex items-start gap-2.5">
              <span className="material-symbols-outlined text-[20px] text-[#F5B800] shrink-0">
                local_activity
              </span>
              <div className="flex flex-col">
                <span className="text-xs font-bold text-white">Ví Voucher Cá Nhân</span>
                <span className="text-[11px] text-[#71717A] mt-0.5">Voucher sinh nhật & giảm giá</span>
              </div>
            </div>

            <div className="p-3 rounded-2xl bg-[#0E0E0F] border border-[#2B2B30] flex items-start gap-2.5">
              <span className="material-symbols-outlined text-[20px] text-blue-400 shrink-0">
                history_edu
              </span>
              <div className="flex flex-col">
                <span className="text-xs font-bold text-white">Lưu Vé & Đổi Hoàn</span>
                <span className="text-[11px] text-[#71717A] mt-0.5">Đổi vé & hoàn tiền 100%</span>
              </div>
            </div>
          </div>
        </div>

        {/* Menu Navigation */}
        <div className="rounded-2xl bg-[#171719] border border-[#2B2B30] overflow-hidden flex flex-col divide-y divide-[#2B2B30]">
          <button
            type="button"
            onClick={() => handleProtectedNavigation('orders')}
            className="p-4 flex items-center justify-between hover:bg-[#202024] transition-colors text-left"
          >
            <div className="flex items-center gap-3">
              <span className="material-symbols-outlined text-[#F5B800] text-[20px]">
                confirmation_number
              </span>
              <span className="text-sm font-semibold text-white">Vé xem phim của tôi</span>
            </div>
            <div className="flex items-center gap-1.5 text-xs text-[#71717A]">
              <span className="text-[11px]">Đăng nhập để xem</span>
              <span className="material-symbols-outlined text-[18px]">chevron_right</span>
            </div>
          </button>

          <button
            type="button"
            onClick={() => handleProtectedNavigation('wallet')}
            className="p-4 flex items-center justify-between hover:bg-[#202024] transition-colors text-left"
          >
            <div className="flex items-center gap-3">
              <span className="material-symbols-outlined text-[#F5B800] text-[20px]">
                account_balance_wallet
              </span>
              <span className="text-sm font-semibold text-white">Ví CineWallet</span>
            </div>
            <div className="flex items-center gap-1.5 text-xs text-[#71717A]">
              <span className="text-[11px]">Đăng nhập để xem</span>
              <span className="material-symbols-outlined text-[18px]">chevron_right</span>
            </div>
          </button>

          <button
            type="button"
            onClick={() => handleProtectedNavigation('vouchers')}
            className="p-4 flex items-center justify-between hover:bg-[#202024] transition-colors text-left"
          >
            <div className="flex items-center gap-3">
              <span className="material-symbols-outlined text-[#F5B800] text-[20px]">
                local_activity
              </span>
              <span className="text-sm font-semibold text-white">Ưu đãi & Voucher cá nhân</span>
            </div>
            <div className="flex items-center gap-1 text-[#F5B800] text-xs font-bold">
              <span>{availableVouchersCount} mã</span>
              <span className="material-symbols-outlined text-[18px]">chevron_right</span>
            </div>
          </button>

          <button
            type="button"
            onClick={() => onNavigate('popbot')}
            className="p-4 flex items-center justify-between hover:bg-[#202024] transition-colors text-left"
          >
            <div className="flex items-center gap-3">
              <span className="material-symbols-outlined text-[#ddb7ff] text-[20px]">smart_toy</span>
              <span className="text-sm font-semibold text-white">Trợ lý điện ảnh PopBot AI</span>
            </div>
            <span className="material-symbols-outlined text-[18px] text-[#71717A]">chevron_right</span>
          </button>

          <button
            type="button"
            id="btn-account-cinema-info"
            onClick={handleOpenCinemaInfo}
            className="p-4 flex items-center justify-between hover:bg-[#202024] transition-colors text-left"
          >
            <div className="flex items-center gap-3">
              <span className="material-symbols-outlined text-[#A1A1AA] text-[20px]">apartment</span>
              <span className="text-sm font-semibold text-white">Thông tin rạp</span>
            </div>
            <span className="material-symbols-outlined text-[18px] text-[#71717A]">chevron_right</span>
          </button>

          <button
            type="button"
            onClick={() => onNavigate('help')}
            className="p-4 flex items-center justify-between hover:bg-[#202024] transition-colors text-left"
          >
            <div className="flex items-center gap-3">
              <span className="material-symbols-outlined text-[#A1A1AA] text-[20px]">
                support_agent
              </span>
              <span className="text-sm font-semibold text-white">Trung tâm trợ giúp & CSKH</span>
            </div>
            <span className="material-symbols-outlined text-[18px] text-[#71717A]">chevron_right</span>
          </button>
        </div>

        <div className="text-center text-xs text-[#71717A] pt-2">
          Phiên bản 3.4.0 • Bản quyền CinePremier & PopBot AI
        </div>
      </div>
    );
  }

  // --- LOGGED-IN STATE UI (Đã đăng nhập) ---
  return (
    <div className="flex flex-col w-full text-[#D4D4D8] pb-8 p-4 gap-4 max-w-2xl mx-auto">
      {/* Profile Info Header */}
      <div className="flex items-center gap-4 p-4 rounded-3xl bg-[#171719] border border-[#2B2B30]">
        <div className="relative">
          <div className="w-16 h-16 rounded-full bg-[#242014] flex items-center justify-center text-[#F5B800] font-black text-2xl shadow-sm border-2 border-[#F5B800]">
            {user.initials}
          </div>
          <span className="absolute bottom-0 right-0 w-5 h-5 rounded-full bg-[#F5B800] flex items-center justify-center text-black">
            <span className="material-symbols-outlined text-[14px] icon-filled">stars</span>
          </span>
        </div>

        <div className="flex flex-col min-w-0">
          <div className="flex items-center gap-2">
            <h2 className="font-extrabold text-lg text-white truncate">{user.name}</h2>
            <span className="px-2 py-0.5 rounded-full bg-[#242014] border border-[#4D3D0A] text-[#F5B800] text-[10px] font-extrabold uppercase">
              {user.membershipTier}
            </span>
          </div>
          <span className="text-xs text-[#A1A1AA] truncate">{user.email}</span>
          <span className="text-[11px] text-[#71717A] mt-0.5">
            Thành viên CinePremier từ {user.joinDate}
          </span>
        </div>
      </div>

      {/* Luxury VIP Membership Card */}
      <div className="relative w-full rounded-3xl overflow-hidden p-5 bg-[#1B1B1E] border border-[#3F3F46] shadow-sm flex flex-col justify-between h-52">
        <div className="flex items-center justify-between relative z-10">
          <div className="flex items-center gap-1.5 font-black text-sm tracking-wider">
            <span className="text-white">CINE</span>
            <span className="text-[#F5B800]">PREMIER</span>
            <span className="text-[10px] px-1.5 py-0.2 rounded bg-white/10 text-white/80 ml-1">
              {user.membershipTier.toUpperCase()}
            </span>
          </div>
          <button
            type="button"
            onClick={() => setIsVIPQRModalOpen(true)}
            className="flex items-center gap-1 px-2.5 py-1 rounded-full bg-white/10 hover:bg-white/20 backdrop-blur-md text-[#F5B800] text-xs font-semibold transition-colors"
          >
            <span className="material-symbols-outlined text-[16px]">qr_code</span>
            <span>Mã VIP</span>
          </button>
        </div>

        <div className="relative z-10 my-auto">
          <span className="text-[10px] text-[#71717A] uppercase tracking-wider font-bold">
            Điểm tích lũy CinePoints
          </span>
          <div className="flex items-baseline gap-2">
            <span className="text-3xl font-black text-[#F5B800] tracking-tight">
              {user.points.toLocaleString('vi-VN')}
            </span>
            <span className="text-xs text-[#A1A1AA] font-bold">
              pts (~{(user.points * 10).toLocaleString('vi-VN')}₫)
            </span>
          </div>
        </div>

        <div className="flex items-center justify-between relative z-10 pt-2 border-t border-white/10 text-xs">
          <div>
            <div className="text-[10px] text-[#71717A] uppercase">Chủ thẻ</div>
            <div className="font-bold text-white tracking-wider">{user.name.toUpperCase()}</div>
          </div>
          <div className="text-right">
            <div className="text-[10px] text-[#71717A] uppercase">Mã hội viên</div>
            <div className="font-mono font-bold text-[#F5B800]">{user.memberCode}</div>
          </div>
        </div>
      </div>

      {/* CineWallet Quick Section */}
      <div className="p-4 rounded-2xl bg-[#171719] border border-[#2B2B30] flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-11 h-11 rounded-xl bg-[#242014] border border-[#4D3D0A] flex items-center justify-center text-[#F5B800]">
            <span className="material-symbols-outlined text-[24px]">account_balance_wallet</span>
          </div>
          <div className="flex flex-col">
            <span className="text-xs text-[#A1A1AA]">Số dư ví CineWallet</span>
            <span className="text-base font-black text-white">
              {user.walletBalance.toLocaleString('vi-VN')} ₫
            </span>
          </div>
        </div>

        <button
          type="button"
          onClick={() => onNavigate('wallet')}
          className="px-4 py-2 rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] text-black font-bold text-xs shadow-sm transition-all"
        >
          Quản lý ví
        </button>
      </div>

      {/* Menu List */}
      <div className="rounded-2xl bg-[#171719] border border-[#2B2B30] overflow-hidden flex flex-col divide-y divide-[#2B2B30]">
        <button
          type="button"
          onClick={() => onNavigate('orders')}
          className="p-4 flex items-center justify-between hover:bg-[#202024] transition-colors text-left"
        >
          <div className="flex items-center gap-3">
            <span className="material-symbols-outlined text-[#F5B800] text-[20px]">
              confirmation_number
            </span>
            <span className="text-sm font-semibold text-white">Vé xem phim của tôi</span>
          </div>
          <span className="material-symbols-outlined text-[18px] text-[#71717A]">chevron_right</span>
        </button>

        <button
          type="button"
          onClick={() => onNavigate('popbot')}
          className="p-4 flex items-center justify-between hover:bg-[#202024] transition-colors text-left"
        >
          <div className="flex items-center gap-3">
            <span className="material-symbols-outlined text-[#ddb7ff] text-[20px]">smart_toy</span>
            <span className="text-sm font-semibold text-white">Trợ lý điện ảnh PopBot AI</span>
          </div>
          <span className="material-symbols-outlined text-[18px] text-[#71717A]">chevron_right</span>
        </button>

        <button
          type="button"
          onClick={() => onNavigate('vouchers')}
          className="p-4 flex items-center justify-between hover:bg-[#202024] transition-colors text-left"
        >
          <div className="flex items-center gap-3">
            <span className="material-symbols-outlined text-[#F5B800] text-[20px]">
              local_activity
            </span>
            <span className="text-sm font-semibold text-white">Ưu đãi & Voucher cá nhân</span>
          </div>
          <div className="flex items-center gap-1 text-[#F5B800] text-xs font-bold">
            <span>{availableVouchersCount} mã</span>
            <span className="material-symbols-outlined text-[18px]">chevron_right</span>
          </div>
        </button>

        <button
          type="button"
          id="btn-guest-cinema-info"
          onClick={handleOpenCinemaInfo}
          className="p-4 flex items-center justify-between hover:bg-[#202024] transition-colors text-left"
        >
          <div className="flex items-center gap-3">
            <span className="material-symbols-outlined text-[#A1A1AA] text-[20px]">apartment</span>
            <span className="text-sm font-semibold text-white">Thông tin rạp</span>
          </div>
          <span className="material-symbols-outlined text-[18px] text-[#71717A]">chevron_right</span>
        </button>

        <button
          type="button"
          onClick={() => onNavigate('help')}
          className="p-4 flex items-center justify-between hover:bg-[#202024] transition-colors text-left"
        >
          <div className="flex items-center gap-3">
            <span className="material-symbols-outlined text-[#A1A1AA] text-[20px]">
              support_agent
            </span>
            <span className="text-sm font-semibold text-white">Trung tâm trợ giúp & CSKH</span>
          </div>
          <span className="material-symbols-outlined text-[18px] text-[#71717A]">chevron_right</span>
        </button>
      </div>

      {/* Logout Action Button (Bổ sung nút Đăng xuất ở cuối trang Tài khoản) */}
      <button
        type="button"
        onClick={() => setIsLogoutConfirmOpen(true)}
        className="w-full py-3.5 px-4 rounded-2xl bg-[#171719] hover:bg-rose-500/10 border border-[#2B2B30] hover:border-rose-500/30 text-[#D4D4D8] hover:text-rose-400 font-bold text-xs sm:text-sm flex items-center justify-center gap-2 transition-all active:scale-[0.99]"
      >
        <span className="material-symbols-outlined text-[18px]">logout</span>
        <span>Đăng xuất tài khoản</span>
      </button>

      <div className="text-center text-xs text-[#71717A] pt-1">
        Phiên bản 3.4.0 • Bản quyền CinePremier & PopBot AI
      </div>

      {/* VIP QR Modal */}
      <QRModal
        isOpen={isVIPQRModalOpen}
        onClose={() => setIsVIPQRModalOpen(false)}
        title={`Thẻ ${user.membershipTier} CinePremier`}
        subtitle={`${user.name} • No. ${user.memberCode}`}
        code={`CP-VIP-${user.memberCode}`}
        note="Đưa mã QR cho nhân viên tại quầy để tích điểm CinePoints và áp dụng ưu đãi VIP"
      />

      {/* Logout Confirmation Modal */}
      {isLogoutConfirmOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4"
          onClick={() => setIsLogoutConfirmOpen(false)}
        >
          <div
            className="w-full max-w-sm bg-[#171719] border border-[#2B2B30] rounded-3xl p-5 shadow-2xl flex flex-col gap-4 text-[#D4D4D8]"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-2xl bg-rose-500/15 border border-rose-500/30 flex items-center justify-center text-rose-400 shrink-0">
                <span className="material-symbols-outlined text-[22px]">logout</span>
              </div>
              <h3 className="font-bold text-sm text-white">Xác nhận đăng xuất</h3>
            </div>

            <p className="text-xs text-[#A1A1AA] leading-relaxed">
              Bạn có chắc chắn muốn đăng xuất khỏi tài khoản <strong>{user.name}</strong> không?
            </p>

            <div className="flex gap-2 pt-2">
              <button
                type="button"
                onClick={() => setIsLogoutConfirmOpen(false)}
                className="flex-1 py-2.5 rounded-xl bg-[#202024] hover:bg-[#2B2B30] border border-[#2B2B30] text-xs font-semibold text-[#A1A1AA] transition-colors"
              >
                Giữ đăng nhập
              </button>
              <button
                type="button"
                onClick={handleConfirmLogout}
                className="flex-1 py-2.5 rounded-xl bg-rose-500 hover:bg-rose-600 text-white text-xs font-bold shadow-md transition-colors"
              >
                Đăng xuất
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
