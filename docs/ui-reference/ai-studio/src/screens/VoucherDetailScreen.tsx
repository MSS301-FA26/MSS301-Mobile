import React, { useState } from 'react';
import { ScreenName, Voucher } from '../types';

interface VoucherDetailScreenProps {
  voucher: Voucher;
  onNavigate: (screen: ScreenName) => void;
  onBack: () => void;
  onApplyForBooking?: (voucher: Voucher) => void;
}

export const VoucherDetailScreen: React.FC<VoucherDetailScreenProps> = ({
  voucher,
  onNavigate,
  onBack,
  onApplyForBooking,
}) => {
  const [copied, setCopied] = useState(false);
  const isAvailable = voucher.status === 'available';

  const handleCopyCode = () => {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(voucher.code);
    }
    setCopied(true);
    setTimeout(() => setCopied(false), 2500);
  };

  const handleUseVoucher = () => {
    if (!isAvailable) return;
    if (onApplyForBooking) {
      onApplyForBooking(voucher);
    }
    onNavigate('calendar');
  };

  return (
    <div className="w-full max-w-xl mx-auto px-4 py-6 flex flex-col text-[#D4D4D8] pb-24">
      {/* Voucher Hero Card */}
      <div className="relative overflow-hidden rounded-3xl bg-[#171719] border border-[#2B2B30] p-6 shadow-sm">
        <div className="flex items-start justify-between gap-4">
          <div className="w-14 h-14 rounded-2xl bg-[#242014] border border-[#4D3D0A] flex items-center justify-center text-[#F5B800] shrink-0">
            <span className="material-symbols-outlined text-[32px]">{voucher.icon}</span>
          </div>

          <span
            className={`text-xs font-bold px-3 py-1 rounded-full ${
              isAvailable
                ? 'bg-emerald-500/20 text-emerald-400 border border-emerald-500/30'
                : voucher.status === 'used'
                ? 'bg-blue-500/20 text-blue-300 border border-blue-500/30'
                : 'bg-zinc-500/20 text-zinc-400 border border-zinc-500/30'
            }`}
          >
            {voucher.statusLabel}
          </span>
        </div>

        <h1 className="text-xl sm:text-2xl font-black text-white mt-4">{voucher.title}</h1>
        <p className="text-xs sm:text-sm text-[#A1A1AA] mt-1.5">{voucher.shortDescription}</p>

        {/* Voucher Code Box */}
        <div className="mt-5 p-3.5 rounded-2xl bg-[#202024] border border-[#2B2B30] flex items-center justify-between gap-3">
          <div className="flex flex-col">
            <span className="text-[10px] text-[#71717A] uppercase font-bold tracking-wider">
              Mã voucher ưu đãi
            </span>
            <span className="text-base sm:text-lg font-mono font-black text-[#F5B800] tracking-widest mt-0.5">
              {voucher.code}
            </span>
          </div>

          <button
            type="button"
            onClick={handleCopyCode}
            className={`h-9 px-3.5 rounded-xl font-bold text-xs flex items-center gap-1.5 transition-all active:scale-95 ${
              copied
                ? 'bg-[#F5B800] text-black'
                : 'bg-[#171719] hover:bg-[#2B2B30] text-white border border-[#2B2B30]'
            }`}
          >
            <span className="material-symbols-outlined text-[16px]">
              {copied ? 'check' : 'content_copy'}
            </span>
            <span>{copied ? 'Đã sao chép' : 'Sao chép mã'}</span>
          </button>
        </div>
      </div>

      {/* Detail Specifications */}
      <div className="mt-6 bg-[#171719] border border-[#2B2B30] rounded-3xl p-5 sm:p-6 shadow-sm flex flex-col gap-4">
        <h2 className="text-sm font-bold text-white uppercase tracking-wider flex items-center gap-2">
          <span className="material-symbols-outlined text-[18px] text-[#F5B800]">info</span>
          <span>Thông tin chi tiết voucher</span>
        </h2>

        <div className="grid grid-cols-1 sm:grid-cols-2 gap-3 text-xs">
          <div className="p-3 rounded-2xl bg-[#202024] border border-[#2B2B30] flex flex-col">
            <span className="text-[#71717A]">Mức giảm ưu đãi</span>
            <strong className="text-base font-black text-[#F5B800] mt-1">
              {voucher.discountDisplay}
            </strong>
          </div>

          <div className="p-3 rounded-2xl bg-[#202024] border border-[#2B2B30] flex flex-col">
            <span className="text-[#71717A]">Thời hạn áp dụng</span>
            <strong className="text-xs font-bold text-white mt-1">
              {voucher.startDate} – {voucher.expiryDate}
            </strong>
          </div>

          <div className="p-3 rounded-2xl bg-[#202024] border border-[#2B2B30] flex flex-col sm:col-span-2">
            <span className="text-[#71717A]">Phạm vi & Suất chiếu áp dụng</span>
            <span className="text-xs font-semibold text-[#D4D4D8] mt-1">
              {voucher.applicableTo}
            </span>
          </div>

          {voucher.minOrderDisplay && (
            <div className="p-3 rounded-2xl bg-[#202024] border border-[#2B2B30] flex flex-col">
              <span className="text-[#71717A]">Đơn hàng tối thiểu</span>
              <span className="text-xs font-semibold text-[#D4D4D8] mt-1">
                {voucher.minOrderDisplay}
              </span>
            </div>
          )}

          {voucher.usageLimit && (
            <div className="p-3 rounded-2xl bg-[#202024] border border-[#2B2B30] flex flex-col">
              <span className="text-[#71717A]">Giới hạn sử dụng</span>
              <span className="text-xs font-semibold text-[#D4D4D8] mt-1">
                {voucher.usageLimit}
              </span>
            </div>
          )}
        </div>

        {/* Instructions */}
        <div className="mt-2 pt-4 border-t border-[#2B2B30]">
          <h3 className="text-xs font-bold text-white uppercase tracking-wider flex items-center gap-1.5 mb-3">
            <span className="material-symbols-outlined text-[16px] text-[#F5B800]">
              checklist
            </span>
            <span>Hướng dẫn sử dụng</span>
          </h3>
          <ol className="list-decimal list-inside space-y-2 text-xs text-[#A1A1AA] leading-relaxed">
            {voucher.instructions.map((step, idx) => (
              <li key={idx} className="pl-1">
                <span>{step}</span>
              </li>
            ))}
          </ol>
        </div>

        {/* Terms */}
        <div className="mt-2 pt-4 border-t border-[#2B2B30]">
          <h3 className="text-xs font-bold text-white uppercase tracking-wider flex items-center gap-1.5 mb-3">
            <span className="material-symbols-outlined text-[16px] text-[#F5B800]">
              gavel
            </span>
            <span>Điều kiện & Điều khoản</span>
          </h3>
          <ul className="list-disc list-inside space-y-1.5 text-xs text-[#71717A] leading-relaxed">
            {voucher.terms.map((term, idx) => (
              <li key={idx} className="pl-1">
                <span>{term}</span>
              </li>
            ))}
          </ul>
        </div>
      </div>

      {/* Sticky Bottom Action Bar */}
      <div className="fixed bottom-0 left-0 right-0 z-40 bg-[#0E0E0F]/95 backdrop-blur-xl px-4 py-3 pb-safe shadow-[0_-4px_20px_rgba(0,0,0,0.5)] border-t border-[#2B2B30]">
        <div className="max-w-xl mx-auto flex items-center gap-3">
          <button
            type="button"
            onClick={onBack}
            className="py-3 px-4 rounded-2xl bg-[#202024] hover:bg-[#2B2B30] text-xs font-bold text-[#A1A1AA] hover:text-white transition-colors border border-[#2B2B30]"
          >
            Quay lại danh sách
          </button>

          {isAvailable ? (
            <button
              type="button"
              onClick={handleUseVoucher}
              className="flex-1 py-3 px-5 rounded-2xl bg-[#F5B800] hover:bg-[#E6AA00] active:scale-95 text-black font-black text-xs sm:text-sm shadow-sm transition-all flex items-center justify-center gap-2"
            >
              <span>Sử dụng voucher này ngay</span>
              <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
            </button>
          ) : (
            <button
              type="button"
              disabled
              className="flex-1 py-3 px-5 rounded-2xl bg-[#202024] text-[#71717A] font-bold text-xs cursor-not-allowed text-center border border-[#2B2B30]"
            >
              Voucher {voucher.status === 'used' ? 'đã được sử dụng' : 'đã hết hạn'}
            </button>
          )}
        </div>
      </div>
    </div>
  );
};
