import React, { useState } from 'react';
import { ScreenName, Voucher } from '../types';
import { INITIAL_VOUCHERS } from '../data/vouchersData';

interface VouchersScreenProps {
  onNavigate: (screen: ScreenName) => void;
  onBack?: () => void;
  onSelectVoucher?: (voucher: Voucher) => void;
  onSelectVoucherDetail?: (voucher: Voucher) => void;
  onUseVoucher?: (voucher: Voucher) => void;
  onApplyVoucherForBooking?: (voucher: Voucher) => void;
}

export const VouchersScreen: React.FC<VouchersScreenProps> = ({
  onNavigate,
  onSelectVoucher,
  onSelectVoucherDetail,
  onUseVoucher,
  onApplyVoucherForBooking,
}) => {
  const [activeTab, setActiveTab] = useState<'available' | 'used' | 'expired'>('available');
  const [vouchers] = useState<Voucher[]>(INITIAL_VOUCHERS);
  const [copiedCode, setCopiedCode] = useState<string | null>(null);

  const availableCount = vouchers.filter((v) => v.status === 'available').length;
  const usedCount = vouchers.filter((v) => v.status === 'used').length;
  const expiredCount = vouchers.filter((v) => v.status === 'expired').length;

  const filteredVouchers = vouchers.filter((v) => v.status === activeTab);

  const handleCopyCode = (code: string, e: React.MouseEvent) => {
    e.stopPropagation();
    if (navigator.clipboard) {
      navigator.clipboard.writeText(code);
    }
    setCopiedCode(code);
    setTimeout(() => setCopiedCode(null), 2500);
  };

  const handleSelectCard = (voucher: Voucher) => {
    if (onSelectVoucher) onSelectVoucher(voucher);
    if (onSelectVoucherDetail) onSelectVoucherDetail(voucher);
  };

  const handleUseAction = (voucher: Voucher, e: React.MouseEvent) => {
    e.stopPropagation();
    if (onUseVoucher) onUseVoucher(voucher);
    if (onApplyVoucherForBooking) onApplyVoucherForBooking(voucher);
    // Navigate to showtimes or discover to pick a movie
    onNavigate('calendar');
  };

  return (
    <div className="w-full max-w-2xl mx-auto px-3.5 sm:px-6 py-6 flex flex-col text-[#D4D4D8]">
      {/* Overview Banner */}
      <div className="relative overflow-hidden rounded-3xl bg-[#171719] border border-[#2B2B30] p-5 mb-6 shadow-sm">
        <div className="relative z-10 flex items-center justify-between gap-4">
          <div className="flex flex-col">
            <span className="text-[11px] font-bold uppercase tracking-wider text-[#F5B800]">
              Ví Ưu Đãi Hội Viên
            </span>
            <h2 className="text-xl sm:text-2xl font-black text-white mt-0.5">
              Ưu đãi & Voucher cá nhân
            </h2>
            <p className="text-xs text-[#A1A1AA] mt-1">
              Bạn đang có{' '}
              <strong className="text-[#F5B800] font-black">{availableCount} voucher</strong> sẵn
              sàng sử dụng ngay.
            </p>
          </div>
          <div className="w-14 h-14 rounded-2xl bg-[#242014] border border-[#4D3D0A] flex items-center justify-center shrink-0">
            <span className="material-symbols-outlined text-[30px] text-[#F5B800]">
              confirmation_number
            </span>
          </div>
        </div>
      </div>

      {/* Filter Tabs */}
      <div className="flex items-center gap-1.5 p-1 bg-[#171719] border border-[#2B2B30] rounded-2xl mb-5">
        <button
          type="button"
          onClick={() => setActiveTab('available')}
          className={`flex-1 py-2.5 px-3 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 focus:outline-none ${
            activeTab === 'available'
              ? 'bg-[#F5B800] text-black shadow-sm'
              : 'text-[#A1A1AA] hover:text-white'
          }`}
        >
          <span>Khả dụng</span>
          <span
            className={`text-[10px] px-1.5 py-0.2 rounded-full font-black ${
              activeTab === 'available'
                ? 'bg-black/20 text-black'
                : 'bg-[#202024] text-[#A1A1AA]'
            }`}
          >
            {availableCount}
          </span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('used')}
          className={`flex-1 py-2.5 px-3 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 focus:outline-none ${
            activeTab === 'used'
              ? 'bg-[#F5B800] text-black shadow-sm'
              : 'text-[#A1A1AA] hover:text-white'
          }`}
        >
          <span>Đã sử dụng</span>
          <span
            className={`text-[10px] px-1.5 py-0.2 rounded-full font-black ${
              activeTab === 'used'
                ? 'bg-black/20 text-black'
                : 'bg-[#202024] text-[#A1A1AA]'
            }`}
          >
            {usedCount}
          </span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('expired')}
          className={`flex-1 py-2.5 px-3 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 focus:outline-none ${
            activeTab === 'expired'
              ? 'bg-[#F5B800] text-black shadow-sm'
              : 'text-[#A1A1AA] hover:text-white'
          }`}
        >
          <span>Hết hạn</span>
          <span
            className={`text-[10px] px-1.5 py-0.2 rounded-full font-black ${
              activeTab === 'expired'
                ? 'bg-black/20 text-black'
                : 'bg-[#202024] text-[#A1A1AA]'
            }`}
          >
            {expiredCount}
          </span>
        </button>
      </div>

      {/* Copy Toast Feedback */}
      {copiedCode && (
        <div className="fixed bottom-20 left-1/2 -translate-x-1/2 z-50 py-2.5 px-4 rounded-2xl bg-[#F5B800] text-black font-bold text-xs shadow-2xl flex items-center gap-2 animate-fade-in">
          <span className="material-symbols-outlined text-[18px]">check_circle</span>
          <span>Đã sao chép mã {copiedCode} vào bộ nhớ tạm!</span>
        </div>
      )}

      {/* Voucher Card List */}
      {filteredVouchers.length === 0 ? (
        <div className="py-16 flex flex-col items-center justify-center text-center bg-[#171719] border border-[#2B2B30] rounded-3xl p-6">
          <div className="w-16 h-16 rounded-full bg-[#202024] flex items-center justify-center mb-3">
            <span className="material-symbols-outlined text-[32px] text-[#71717A]">
              inventory_2
            </span>
          </div>
          <h3 className="text-sm font-bold text-white">Không có voucher trong mục này</h3>
          <p className="text-xs text-[#71717A] mt-1 max-w-xs">
            Hiện bạn không có voucher nào ở trạng thái {activeTab === 'available' ? 'khả dụng' : activeTab === 'used' ? 'đã sử dụng' : 'hết hạn'}.
          </p>
          {activeTab !== 'available' && (
            <button
              type="button"
              onClick={() => setActiveTab('available')}
              className="mt-4 px-4 py-2 rounded-xl bg-[#202024] hover:bg-[#2B2B30] text-xs font-semibold text-white border border-[#2B2B30]"
            >
              Xem voucher khả dụng
            </button>
          )}
        </div>
      ) : (
        <div className="flex flex-col gap-4">
          {filteredVouchers.map((voucher) => {
            const isAvailable = voucher.status === 'available';

            return (
              <div
                key={voucher.id}
                onClick={() => handleSelectCard(voucher)}
                className={`relative group bg-[#171719] border rounded-3xl p-4 sm:p-5 transition-all cursor-pointer ${
                  isAvailable
                    ? 'border-[#2B2B30] hover:border-[#3F3F46] shadow-sm'
                    : 'border-[#2B2B30]/50 opacity-60'
                }`}
              >
                <div className="flex items-start gap-3.5 sm:gap-4">
                  {/* Voucher Icon */}
                  <div
                    className={`w-12 h-12 sm:w-14 sm:h-14 rounded-2xl flex items-center justify-center shrink-0 ${
                      isAvailable
                        ? 'bg-[#242014] border border-[#4D3D0A] text-[#F5B800]'
                        : 'bg-[#202024] border border-[#2B2B30] text-[#71717A]'
                    }`}
                  >
                    <span className="material-symbols-outlined text-[26px] sm:text-[30px]">
                      {voucher.icon}
                    </span>
                  </div>

                  {/* Voucher Info */}
                  <div className="flex-1 min-w-0 flex flex-col">
                    <div className="flex items-center justify-between gap-2">
                      <div className="flex items-center gap-1.5 flex-wrap">
                        <span className="text-[11px] font-black px-2 py-0.5 rounded-lg bg-[#202024] border border-[#2B2B30] text-white tracking-wider">
                          {voucher.code}
                        </span>
                        {voucher.minOrderDisplay && (
                          <span className="text-[10px] text-[#A1A1AA] bg-[#202024] px-2 py-0.5 rounded-md">
                            {voucher.minOrderDisplay}
                          </span>
                        )}
                      </div>

                      {/* Status Badge */}
                      <span
                        className={`text-[10px] font-bold px-2 py-0.5 rounded-full shrink-0 ${
                          isAvailable
                            ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30'
                            : voucher.status === 'used'
                            ? 'bg-blue-500/15 text-blue-300 border border-blue-500/30'
                            : 'bg-zinc-500/15 text-zinc-400 border border-zinc-500/30'
                        }`}
                      >
                        {voucher.statusLabel}
                      </span>
                    </div>

                    <h3 className="text-sm sm:text-base font-bold text-white mt-1.5 line-clamp-1 group-hover:text-[#F5B800] transition-colors">
                      {voucher.title}
                    </h3>
                    <p className="text-xs text-[#A1A1AA] mt-0.5 line-clamp-2">
                      {voucher.shortDescription}
                    </p>

                    {/* Expiry & Actions */}
                    <div className="flex items-center justify-between gap-2 mt-3 pt-3 border-t border-[#2B2B30] flex-wrap">
                      <div className="flex items-center gap-1 text-[11px] text-[#71717A]">
                        <span className="material-symbols-outlined text-[14px]">event</span>
                        <span>HSD: {voucher.expiryDate}</span>
                      </div>

                      <div className="flex items-center gap-2">
                        {/* Copy Code Button */}
                        <button
                          type="button"
                          onClick={(e) => handleCopyCode(voucher.code, e)}
                          className="h-8 px-2.5 rounded-xl bg-[#202024] hover:bg-[#2B2B30] text-[11px] font-semibold text-[#A1A1AA] hover:text-white flex items-center gap-1 transition-colors border border-[#2B2B30]"
                          title="Sao chép mã voucher"
                        >
                          <span className="material-symbols-outlined text-[14px]">content_copy</span>
                          <span className="hidden sm:inline">Sao chép</span>
                        </button>

                        {/* View Detail Button */}
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            handleSelectCard(voucher);
                          }}
                          className="h-8 px-2.5 rounded-xl bg-[#202024] hover:bg-[#2B2B30] text-[11px] font-semibold text-[#D4D4D8] flex items-center gap-0.5 transition-colors border border-[#2B2B30]"
                        >
                          <span>Chi tiết</span>
                          <span className="material-symbols-outlined text-[14px]">chevron_right</span>
                        </button>

                        {/* Use Button (if available) */}
                        {isAvailable && (
                          <button
                            type="button"
                            onClick={(e) => handleUseAction(voucher, e)}
                            className="h-8 px-3 rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] text-black font-black text-xs flex items-center gap-1 shadow-sm transition-all active:scale-95"
                          >
                            <span>Dùng ngay</span>
                          </button>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
};
