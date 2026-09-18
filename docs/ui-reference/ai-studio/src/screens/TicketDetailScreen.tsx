import React, { useState } from 'react';
import { TicketOrder } from '../types';
import { QRModal } from '../components/QRModal';
import { handleImageError } from '../utils/format';

interface TicketDetailScreenProps {
  order: TicketOrder;
  onBack: () => void;
  onGoHome: () => void;
  onViewOrders?: () => void;
}

export const TicketDetailScreen: React.FC<TicketDetailScreenProps> = ({
  order,
  onGoHome,
  onViewOrders,
}) => {
  const [isQRZoomOpen, setIsQRZoomOpen] = useState(false);
  const [savedToWallet, setSavedToWallet] = useState(false);

  const handleSaveToWallet = () => {
    setSavedToWallet(true);
    setTimeout(() => alert('Đã thêm thẻ vé điện tử vào Apple / Google Wallet thành công!'), 300);
  };

  return (
    <div className="flex flex-col w-full text-[#D4D4D8] pb-24 p-4">
      {/* Success Congratulations Banner */}
      <div className="w-full max-w-md mx-auto mb-4 p-4 rounded-2xl bg-emerald-500/10 border border-emerald-500/30 flex items-center gap-3">
        <div className="w-10 h-10 rounded-full bg-emerald-500/20 text-emerald-400 flex items-center justify-center shrink-0">
          <span className="material-symbols-outlined text-[24px]">check_circle</span>
        </div>
        <div className="flex flex-col min-w-0">
          <span className="text-xs font-black text-emerald-400 uppercase tracking-wider">
            Đặt vé thành công!
          </span>
          <span className="text-[11px] text-[#A1A1AA] truncate">
            Mã vé đã được gửi đến email và lưu vào mục Vé của tôi
          </span>
        </div>
      </div>

      {/* Golden VIP E-Ticket Container */}
      <div className="relative w-full max-w-md mx-auto bg-[#171719] rounded-3xl overflow-hidden shadow-2xl border border-[#2B2B30]">
        {/* Top Header Card */}
        <div className="p-5 bg-[#202024] border-b border-[#2B2B30] relative">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-1 font-black text-sm tracking-wider">
              <span className="text-white">CINE</span>
              <span className="text-[#F5B800]">PREMIER</span>
            </div>
            <span className="px-2.5 py-0.5 rounded-full bg-[#F5B800] text-black text-[10px] font-black uppercase tracking-wider">
              Vé VIP Điện Tử
            </span>
          </div>

          <div className="flex gap-4 mt-4 items-center">
            <img
              src={order.moviePoster}
              alt={order.movieTitle}
              onError={(e) => handleImageError(e)}
              className="w-16 h-24 rounded-xl object-cover bg-black border border-[#2B2B30] shadow-md shrink-0"
              referrerPolicy="no-referrer"
            />
            <div className="flex flex-col min-w-0">
              <span className="text-[11px] text-[#F5B800] font-bold">{order.ageRating}</span>
              <h2 className="text-xl font-black text-white uppercase tracking-tight truncate">
                {order.movieTitle}
              </h2>
              <span className="text-xs text-[#ddb7ff] font-medium mt-0.5">{order.format}</span>
              <span className="text-xs text-[#A1A1AA] mt-1 truncate">{order.cinemaLocation}</span>
            </div>
          </div>
        </div>

        {/* Screening Details Grid */}
        <div className="p-5 grid grid-cols-2 gap-4 bg-[#171719] text-xs">
          <div className="flex flex-col">
            <span className="text-[10px] text-[#71717A] uppercase font-bold tracking-wider">
              Thời gian chiếu
            </span>
            <span className="font-extrabold text-sm text-white mt-0.5">
              {order.dateTimeStr}
            </span>
          </div>

          <div className="flex flex-col">
            <span className="text-[10px] text-[#71717A] uppercase font-bold tracking-wider">
              Phòng chiếu
            </span>
            <span className="font-extrabold text-sm text-[#F5B800] mt-0.5">
              {order.roomName}
            </span>
          </div>

          <div className="flex flex-col">
            <span className="text-[10px] text-[#71717A] uppercase font-bold tracking-wider">
              Vị trí ghế
            </span>
            <span className="font-black text-base text-[#F5B800] mt-0.5">
              {order.seats.join(', ')} ({order.seatsTypeLabel})
            </span>
          </div>

          <div className="flex flex-col">
            <span className="text-[10px] text-[#71717A] uppercase font-bold tracking-wider">
              Bắp nước (F&B)
            </span>
            <span className="font-medium text-xs text-[#D4D4D8] mt-0.5 truncate">
              {order.concessionsSummary}
            </span>
          </div>
        </div>

        {/* Perforated Divider with Side Cutout Notches */}
        <div className="relative w-full my-1 flex items-center">
          {/* Left Cutout */}
          <div className="w-6 h-6 rounded-full bg-[#0E0E0F] -ml-3 shadow-inner" />
          {/* Dashed Line */}
          <div className="flex-1 border-b-2 border-dashed border-[#2B2B30] mx-2" />
          {/* Right Cutout */}
          <div className="w-6 h-6 rounded-full bg-[#0E0E0F] -mr-3 shadow-inner" />
        </div>

        {/* Interactive QR Code Stub */}
        <div className="p-5 bg-[#171719] flex flex-col items-center text-center">
          <span className="text-[11px] font-bold text-[#A1A1AA] uppercase tracking-wider mb-2">
            Mã soát vé ra vào rạp
          </span>

          {/* QR Code Container with interactive zoom */}
          <div
            onClick={() => setIsQRZoomOpen(true)}
            className="group relative p-3 bg-white rounded-2xl cursor-pointer shadow-lg hover:scale-105 transition-transform"
            title="Bấm để phóng to mã QR"
          >
            {/* Custom SVG QR Code */}
            <svg
              className="w-36 h-36"
              viewBox="0 0 100 100"
              fill="none"
              xmlns="http://www.w3.org/2000/svg"
            >
              <rect width="100" height="100" fill="white" />
              {/* Top-Left Finder */}
              <rect x="10" y="10" width="24" height="24" rx="4" fill="#131313" />
              <rect x="14" y="14" width="16" height="16" rx="2" fill="white" />
              <rect x="18" y="18" width="8" height="8" rx="1" fill="#131313" />

              {/* Top-Right Finder */}
              <rect x="66" y="10" width="24" height="24" rx="4" fill="#131313" />
              <rect x="70" y="14" width="16" height="16" rx="2" fill="white" />
              <rect x="74" y="18" width="8" height="8" rx="1" fill="#131313" />

              {/* Bottom-Left Finder */}
              <rect x="10" y="66" width="24" height="24" rx="4" fill="#131313" />
              <rect x="14" y="70" width="16" height="16" rx="2" fill="white" />
              <rect x="18" y="74" width="8" height="8" rx="1" fill="#131313" />

              {/* QR Data Matrix Mock Elements */}
              <rect x="40" y="12" width="4" height="8" fill="#131313" />
              <rect x="48" y="16" width="8" height="4" fill="#131313" />
              <rect x="40" y="24" width="16" height="4" fill="#131313" />
              <rect x="12" y="42" width="8" height="8" fill="#131313" />
              <rect x="24" y="44" width="6" height="4" fill="#131313" />
              <rect x="36" y="36" width="8" height="8" fill="#131313" />
              <rect x="48" y="40" width="6" height="6" fill="#131313" />
              <rect x="60" y="38" width="8" height="4" fill="#131313" />
              <rect x="74" y="42" width="12" height="4" fill="#131313" />
              <rect x="40" y="52" width="8" height="6" fill="#131313" />
              <rect x="54" y="52" width="10" height="8" fill="#131313" />
              <rect x="70" y="54" width="16" height="6" fill="#131313" />
              <rect x="40" y="66" width="6" height="12" fill="#131313" />
              <rect x="52" y="70" width="12" height="6" fill="#131313" />
              <rect x="70" y="68" width="6" height="14" fill="#131313" />
              <rect x="80" y="76" width="8" height="8" fill="#131313" />
            </svg>

            {/* Hover hint */}
            <div className="absolute inset-0 bg-black/40 rounded-2xl flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
              <span className="text-[10px] font-bold text-white bg-black/70 px-2 py-1 rounded-full">
                Chạm để phóng to
              </span>
            </div>
          </div>

          {/* Ticket Code */}
          <span className="font-mono text-xs font-black text-[#F5B800] tracking-widest mt-3">
            MÃ VÉ: {order.ticketCode}
          </span>

          {/* Status countdown badge */}
          {order.countdownMinutes && (
            <div className="flex items-center gap-1.5 mt-2 px-3 py-1 rounded-full bg-[#242014] border border-[#4D3D0A] text-[#F5B800] text-xs font-bold">
              <span className="w-2 h-2 rounded-full bg-[#F5B800] animate-ping" />
              <span>Suất chiếu bắt đầu trong {order.countdownMinutes} phút</span>
            </div>
          )}

          <p className="text-[11px] text-[#71717A] mt-2 max-w-xs">
            Quét mã tại cổng kiểm soát tự động hoặc đưa nhân viên để nhận kính 3D / combo bắp nước.
          </p>
        </div>
      </div>

      {/* Ticket Management Actions */}
      <div className="w-full max-w-md mx-auto mt-4 flex flex-col gap-2.5">
        <button
          type="button"
          onClick={handleSaveToWallet}
          className="w-full h-12 rounded-2xl bg-[#202024] hover:bg-[#2B2B30] text-white text-xs font-bold flex items-center justify-center gap-2 border border-[#2B2B30] transition-colors"
        >
          <span className="material-symbols-outlined text-[20px] text-[#F5B800]">
            account_balance_wallet
          </span>
          <span>{savedToWallet ? '✓ Đã lưu vào Wallet' : 'Lưu vé vào Apple / Google Wallet'}</span>
        </button>

        <div className="grid grid-cols-2 gap-2">
          {onViewOrders ? (
            <button
              type="button"
              onClick={onViewOrders}
              className="h-11 rounded-xl bg-[#171719] hover:bg-[#202024] text-[#A1A1AA] hover:text-white text-xs font-semibold flex items-center justify-center gap-1.5 border border-[#2B2B30] transition-colors"
            >
              <span className="material-symbols-outlined text-[18px]">confirmation_number</span>
              Vé của tôi
            </button>
          ) : (
            <button
              type="button"
              onClick={() => {
                if (navigator.share) {
                  navigator.share({
                    title: `Vé xem phim ${order.movieTitle}`,
                    text: `Tôi vừa đặt vé ${order.movieTitle} suất ${order.dateTimeStr} tại CinePremier!`,
                  });
                } else {
                  alert('Đã sao chép thông tin vé!');
                }
              }}
              className="h-11 rounded-xl bg-[#171719] hover:bg-[#202024] text-[#A1A1AA] hover:text-white text-xs font-semibold flex items-center justify-center gap-1.5 border border-[#2B2B30] transition-colors"
            >
              <span className="material-symbols-outlined text-[18px]">share</span>
              Chia sẻ vé
            </button>
          )}

          <button
            type="button"
            onClick={onGoHome}
            className="h-11 rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] text-black text-xs font-bold flex items-center justify-center gap-1.5 shadow-sm active:scale-95 transition-all"
          >
            <span className="material-symbols-outlined text-[18px]">home</span>
            Về trang chủ
          </button>
        </div>
      </div>

      {/* QR Zoom Modal */}
      <QRModal
        isOpen={isQRZoomOpen}
        onClose={() => setIsQRZoomOpen(false)}
        title="Mã soát vé điện tử"
        subtitle={`${order.movieTitle} • Ghế ${order.seats.join(', ')}`}
        code={order.ticketCode}
        note="Đưa mã QR này trước máy quét tại cổng soát vé CinePremier"
      />
    </div>
  );
};
