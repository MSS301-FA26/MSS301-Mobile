import React, { useState, useEffect } from 'react';
import { BookingState, TicketOrder } from '../types';
import { formatCurrency, handleImageError } from '../utils/format';
import { CINEMA_CONFIG } from '../data/cinemaConfig';

interface PaymentScreenProps {
  booking: BookingState;
  onPaymentSuccess: (order: TicketOrder) => void;
  onBack: () => void;
}

export const PaymentScreen: React.FC<PaymentScreenProps> = ({
  booking,
  onPaymentSuccess,
}) => {
  const [timeLeft, setTimeLeft] = useState(599); // 09:59 countdown
  const [selectedMethod, setSelectedMethod] = useState<
    'cinewallet' | 'vietqr' | 'momo' | 'zalopay' | 'card'
  >('cinewallet');
  const [voucherCode, setVoucherCode] = useState(booking.voucherCode || '');
  const [appliedDiscount, setAppliedDiscount] = useState<number>(booking.discount || 0);
  const [discountNotice, setDiscountNotice] = useState<string>('');
  const [isProcessing, setIsProcessing] = useState(false);

  // Countdown timer for seat hold
  useEffect(() => {
    const timer = setInterval(() => {
      setTimeLeft((prev) => {
        if (prev <= 1) {
          clearInterval(timer);
          return 0;
        }
        return prev - 1;
      });
    }, 1000);
    return () => clearInterval(timer);
  }, []);

  const minutes = Math.floor(timeLeft / 60);
  const seconds = timeLeft % 60;
  const timeDisplay = `${minutes.toString().padStart(2, '0')}:${seconds.toString().padStart(2, '0')}`;

  const currentSeats = booking.selectedSeats || [];
  const currentConcessions = booking.concessions || booking.selectedConcessions || [];

  const seatsTotal = currentSeats.reduce((acc, s) => acc + s.price, 0);
  const concessionsTotal = currentConcessions.reduce(
    (acc, c) => acc + c.price * c.quantity,
    0
  );
  const subTotal = seatsTotal + concessionsTotal;
  const finalTotal = Math.max(0, subTotal - appliedDiscount);

  const handleApplyVoucher = (codeToApply?: string) => {
    const code = (codeToApply || voucherCode).trim().toUpperCase();
    if (!code) return;

    if (code === 'VIPCINE') {
      const disc = 20000;
      setAppliedDiscount(disc);
      setDiscountNotice('✓ Đã áp dụng mã VIPCINE: Giảm 20.000 ₫');
      setVoucherCode('VIPCINE');
    } else if (code === 'POPBOT') {
      const disc = Math.round(subTotal * 0.1);
      setAppliedDiscount(disc);
      setDiscountNotice(`✓ Đã áp dụng mã POPBOT: Giảm 10% (-${formatCurrency(disc)})`);
      setVoucherCode('POPBOT');
    } else {
      setDiscountNotice('✕ Mã không hợp lệ hoặc đã hết lượt.');
    }
  };

  const handleConfirmPay = () => {
    setIsProcessing(true);
    setTimeout(() => {
      setIsProcessing(false);

      const seatNames = currentSeats.map((s) => s.id);
      const seatType = currentSeats[0]?.type.toUpperCase() || 'VIP';

      const concessionsText =
        currentConcessions.length > 0
          ? currentConcessions.map((c) => `${c.quantity}x ${c.name}`).join(', ')
          : 'Không kèm F&B';

      const newOrder: TicketOrder = {
        id: `ord-${Date.now()}`,
        ticketCode: `CP-${Math.floor(100000 + Math.random() * 900000)}`,
        movieTitle: booking.movieTitle || booking.movie.title,
        moviePoster: booking.movie.posterUrl,
        ageRating: booking.movie.ageRating,
        format: `${booking.format || booking.selectedSlot?.formatBadge || '2D Dolby Atmos'} • Phụ đề`,
        cinemaLocation: `${CINEMA_CONFIG.name} • ${booking.room || booking.selectedSlot?.roomName || 'Phòng C'}`,
        roomName: booking.room || booking.selectedSlot?.roomName || 'Phòng C',
        dateTimeStr: `${booking.time || booking.selectedSlot?.time || '20:30'} • ${booking.date || booking.selectedDate || 'Hôm nay, 14/09/2026'}`,
        seats: seatNames,
        seatsTypeLabel: `${seatNames.length} vé (${seatType})`,
        concessionsSummary: concessionsText,
        totalPrice: finalTotal,
        status: 'upcoming',
        statusLabel: 'Sắp chiếu (Trong 45 phút)',
        countdownMinutes: 45,
      };

      onPaymentSuccess(newOrder);
    }, 1200);
  };

  return (
    <div className="flex flex-col w-full text-[#D4D4D8] pb-36">
      {/* Countdown Timer Warning */}
      <div className="px-4 py-2.5 bg-[#202024] border-b border-[#2B2B30] flex items-center justify-between">
        <div className="flex items-center gap-2">
          <span className="material-symbols-outlined text-[#F5B800] text-[20px] animate-pulse">
            timer
          </span>
          <span className="text-xs text-[#A1A1AA]">Thời gian giữ ghế tạm thời:</span>
        </div>
        <span className="text-sm font-black text-[#F5B800] tracking-widest font-mono">
          {timeDisplay}
        </span>
      </div>

      <div className="flex flex-col gap-4 p-4">
        {/* Booking Summary Card */}
        <div className="rounded-2xl bg-[#171719] p-4 border border-[#2B2B30] shadow-sm flex flex-col gap-3">
          <div className="flex gap-3">
            <img
              src={booking.movie.posterUrl}
              alt={booking.movie.title}
              onError={(e) => handleImageError(e)}
              className="w-16 h-24 rounded-xl object-cover bg-[#202024] shrink-0 border border-[#2B2B30]"
              referrerPolicy="no-referrer"
            />
            <div className="flex flex-col min-w-0 justify-between py-0.5">
              <div>
                <div className="flex items-center gap-1.5 mb-1">
                  <span className="px-1.5 py-0.5 rounded bg-[#242014] border border-[#4D3D0A] text-[#F5B800] text-[9px] font-bold">
                    {booking.movie.ageRating}
                  </span>
                  <span className="text-[11px] font-bold text-[#ddb7ff]">
                    {booking.format || booking.selectedSlot?.formatBadge || 'Dolby Atmos'}
                  </span>
                </div>
                <h3 className="font-extrabold text-base text-white uppercase truncate">
                  {booking.movieTitle || booking.movie.title}
                </h3>
                <p className="text-xs text-[#A1A1AA] truncate">
                  {CINEMA_CONFIG.name}
                </p>
              </div>

              <div className="text-xs text-[#F5B800] font-semibold">
                {booking.time || booking.selectedSlot?.time || '20:30'} •{' '}
                {booking.date || booking.selectedDate || 'Hôm nay, 14/09/2026'}
              </div>
            </div>
          </div>

          <div className="border-t border-[#2B2B30] pt-3 grid grid-cols-2 gap-2 text-xs">
            <div>
              <span className="text-[10px] text-[#71717A] uppercase font-semibold">Phòng chiếu</span>
              <p className="font-bold text-white">
                {booking.room || booking.selectedSlot?.roomName || 'Phòng C'} (Tầng 5)
              </p>
            </div>
            <div>
              <span className="text-[10px] text-[#71717A] uppercase font-semibold">
                Ghế đã chọn ({currentSeats.length})
              </span>
              <p className="font-bold text-[#F5B800] truncate">
                {currentSeats.map((s) => s.id).join(', ')}
              </p>
            </div>
          </div>

          {currentConcessions.length > 0 && (
            <div className="border-t border-[#2B2B30] pt-2 text-xs">
              <span className="text-[10px] text-[#71717A] uppercase font-semibold">
                Bắp nước kèm theo:
              </span>
              <p className="text-[#A1A1AA] mt-0.5">
                {currentConcessions.map((c) => `${c.quantity}x ${c.name}`).join(' • ')}
              </p>
            </div>
          )}
        </div>

        {/* Voucher / Promotion Code */}
        <div className="rounded-2xl bg-[#171719] p-4 border border-[#2B2B30] flex flex-col gap-2.5">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-[#F5B800] text-[20px]">
              local_activity
            </span>
            <span className="font-bold text-sm text-white">Mã ưu đãi / Voucher</span>
          </div>

          <div className="flex gap-2">
            <input
              type="text"
              value={voucherCode}
              onChange={(e) => setVoucherCode(e.target.value)}
              placeholder="Nhập mã ưu đãi (VIPCINE, POPBOT)"
              className="flex-1 bg-[#0E0E0F] border border-[#2B2B30] rounded-xl px-3 text-xs uppercase tracking-wider text-white placeholder:text-[#71717A] focus:outline-none focus:border-[#F5B800]"
            />
            <button
              type="button"
              onClick={() => handleApplyVoucher()}
              className="px-4 py-2.5 rounded-xl bg-[#202024] hover:bg-[#2B2B30] text-[#F5B800] font-bold text-xs border border-[#2B2B30] transition-colors"
            >
              Áp dụng
            </button>
          </div>

          {discountNotice && (
            <span
              className={`text-xs font-semibold ${
                discountNotice.startsWith('✓') ? 'text-emerald-400' : 'text-rose-400'
              }`}
            >
              {discountNotice}
            </span>
          )}

          {/* Quick promo suggestions */}
          <div className="flex gap-2 mt-1">
            <button
              type="button"
              onClick={() => handleApplyVoucher('VIPCINE')}
              className="px-2.5 py-1 rounded-lg bg-[#202024] text-[11px] text-[#A1A1AA] hover:text-[#F5B800] border border-[#2B2B30]"
            >
              VIPCINE (-20k)
            </button>
            <button
              type="button"
              onClick={() => handleApplyVoucher('POPBOT')}
              className="px-2.5 py-1 rounded-lg bg-[#202024] text-[11px] text-[#A1A1AA] hover:text-[#F5B800] border border-[#2B2B30]"
            >
              POPBOT (-10%)
            </button>
          </div>
        </div>

        {/* Payment Methods Selection */}
        <div className="rounded-2xl bg-[#171719] p-4 border border-[#2B2B30] flex flex-col gap-3">
          <div className="flex items-center justify-between">
            <div className="flex items-center gap-2">
              <span className="material-symbols-outlined text-[#F5B800] text-[20px]">
                credit_card
              </span>
              <span className="font-bold text-sm text-white">Phương thức thanh toán</span>
            </div>
            <span className="text-[11px] text-emerald-400 font-semibold">Bảo mật SSL 256-bit</span>
          </div>

          {/* Method 1: CineWallet */}
          <label
            onClick={() => setSelectedMethod('cinewallet')}
            className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-all ${
              selectedMethod === 'cinewallet'
                ? 'bg-[#202024] border-[#F5B800]'
                : 'bg-[#0E0E0F] border-[#2B2B30] hover:border-[#3F3F46]'
            }`}
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-lg bg-[#242014] border border-[#4D3D0A] flex items-center justify-center text-[#F5B800]">
                <span className="material-symbols-outlined text-[20px]">account_balance_wallet</span>
              </div>
              <div className="flex flex-col">
                <div className="flex items-center gap-1.5">
                  <span className="font-bold text-xs text-white">Ví CineWallet</span>
                  <span className="px-1.5 py-0.2 rounded bg-[#F5B800] text-black text-[9px] font-black uppercase">
                    Khuyên dùng
                  </span>
                </div>
                <span className="text-[11px] text-[#71717A]">
                  Số dư khả dụng: <span className="text-[#F5B800] font-bold">450.000 ₫</span>
                </span>
              </div>
            </div>
            <input
              type="radio"
              name="payMethod"
              checked={selectedMethod === 'cinewallet'}
              onChange={() => setSelectedMethod('cinewallet')}
              className="accent-[#F5B800] w-4 h-4"
            />
          </label>

          {/* Method 2: VietQR */}
          <label
            onClick={() => setSelectedMethod('vietqr')}
            className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-all ${
              selectedMethod === 'vietqr'
                ? 'bg-[#202024] border-[#F5B800]'
                : 'bg-[#0E0E0F] border-[#2B2B30] hover:border-[#3F3F46]'
            }`}
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-lg bg-emerald-500/20 border border-emerald-500/30 flex items-center justify-center text-emerald-400">
                <span className="material-symbols-outlined text-[20px]">qr_code_scanner</span>
              </div>
              <div className="flex flex-col">
                <span className="font-bold text-xs text-white">Chuyển khoản VietQR 24/7</span>
                <span className="text-[11px] text-[#71717A]">
                  Quét mã QR từ mọi App ngân hàng (VCB, MB, Techcombank,...)
                </span>
              </div>
            </div>
            <input
              type="radio"
              name="payMethod"
              checked={selectedMethod === 'vietqr'}
              onChange={() => setSelectedMethod('vietqr')}
              className="accent-[#F5B800] w-4 h-4"
            />
          </label>

          {/* Method 3: MoMo */}
          <label
            onClick={() => setSelectedMethod('momo')}
            className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-all ${
              selectedMethod === 'momo'
                ? 'bg-[#202024] border-[#F5B800]'
                : 'bg-[#0E0E0F] border-[#2B2B30] hover:border-[#3F3F46]'
            }`}
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-lg bg-pink-500/20 border border-pink-500/30 flex items-center justify-center text-pink-400 font-bold text-xs">
                MoMo
              </div>
              <div className="flex flex-col">
                <span className="font-bold text-xs text-white">Ví điện tử MoMo</span>
                <span className="text-[11px] text-[#71717A]">Hoàn tiền lên tới 5% cho hội viên</span>
              </div>
            </div>
            <input
              type="radio"
              name="payMethod"
              checked={selectedMethod === 'momo'}
              onChange={() => setSelectedMethod('momo')}
              className="accent-[#F5B800] w-4 h-4"
            />
          </label>

          {/* Method 4: ZaloPay */}
          <label
            onClick={() => setSelectedMethod('zalopay')}
            className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-all ${
              selectedMethod === 'zalopay'
                ? 'bg-[#202024] border-[#F5B800]'
                : 'bg-[#0E0E0F] border-[#2B2B30] hover:border-[#3F3F46]'
            }`}
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-lg bg-blue-500/20 border border-blue-500/30 flex items-center justify-center text-blue-400 font-bold text-xs">
                Zalo
              </div>
              <div className="flex flex-col">
                <span className="font-bold text-xs text-white">Ví ZaloPay</span>
                <span className="text-[11px] text-[#71717A]">Thanh toán bảo mật tức thì</span>
              </div>
            </div>
            <input
              type="radio"
              name="payMethod"
              checked={selectedMethod === 'zalopay'}
              onChange={() => setSelectedMethod('zalopay')}
              className="accent-[#F5B800] w-4 h-4"
            />
          </label>

          {/* Method 5: Credit/Debit Card */}
          <label
            onClick={() => setSelectedMethod('card')}
            className={`p-3 rounded-xl border flex items-center justify-between cursor-pointer transition-all ${
              selectedMethod === 'card'
                ? 'bg-[#202024] border-[#F5B800]'
                : 'bg-[#0E0E0F] border-[#2B2B30] hover:border-[#3F3F46]'
            }`}
          >
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-lg bg-purple-500/20 border border-purple-500/30 flex items-center justify-center text-[#ddb7ff]">
                <span className="material-symbols-outlined text-[20px]">credit_card</span>
              </div>
              <div className="flex flex-col">
                <span className="font-bold text-xs text-white">Thẻ Quốc tế (Visa, Master, JCB)</span>
                <span className="text-[11px] text-[#71717A]">Cổng thanh toán quốc tế 3D-Secure</span>
              </div>
            </div>
            <input
              type="radio"
              name="payMethod"
              checked={selectedMethod === 'card'}
              onChange={() => setSelectedMethod('card')}
              className="accent-[#F5B800] w-4 h-4"
            />
          </label>
        </div>

        {/* Detailed Price Breakdown */}
        <div className="rounded-2xl bg-[#171719] p-4 border border-[#2B2B30] flex flex-col gap-2 text-xs text-[#A1A1AA]">
          <span className="font-bold text-sm text-white mb-1">Chi tiết thanh toán</span>
          <div className="flex justify-between">
            <span>Tiền vé ({currentSeats.length} vé):</span>
            <span className="font-semibold text-white">{formatCurrency(seatsTotal)}</span>
          </div>
          {concessionsTotal > 0 && (
            <div className="flex justify-between">
              <span>Combo bắp & nước:</span>
              <span className="font-semibold text-white">{formatCurrency(concessionsTotal)}</span>
            </div>
          )}
          {appliedDiscount > 0 && (
            <div className="flex justify-between text-[#F5B800]">
              <span>Ưu đãi voucher:</span>
              <span className="font-bold">-{formatCurrency(appliedDiscount)}</span>
            </div>
          )}
          <div className="flex justify-between">
            <span>Phí tiện ích:</span>
            <span className="text-emerald-400 font-medium">Miễn phí hội viên VIP</span>
          </div>
          <div className="border-t border-[#2B2B30] pt-2 mt-1 flex justify-between items-baseline">
            <span className="text-sm font-bold text-white">Tổng tiền cần trả:</span>
            <span className="text-lg font-extrabold text-[#F5B800]">
              {formatCurrency(finalTotal)}
            </span>
          </div>
        </div>
      </div>

      {/* Sticky Bottom Action Bar */}
      <div className="fixed bottom-0 left-0 right-0 z-40 bg-[#0E0E0F]/95 backdrop-blur-xl px-4 py-3 pb-safe shadow-[0_-8px_30px_rgba(0,0,0,0.85)] border-t border-[#2B2B30]">
        <div className="flex items-center justify-between max-w-md mx-auto gap-3">
          <div className="flex flex-col min-w-0 flex-1">
            <span className="text-[10px] text-[#A1A1AA] uppercase font-semibold">
              Tổng thanh toán
            </span>
            <span className="text-base font-extrabold text-[#F5B800]">
              {formatCurrency(finalTotal)}
            </span>
          </div>

          <button
            type="button"
            onClick={handleConfirmPay}
            disabled={isProcessing}
            className="min-w-[180px] h-[50px] rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] text-black text-xs sm:text-sm font-bold flex items-center justify-center gap-2 shadow-md active:scale-[0.98] transition-all cursor-pointer"
          >
            {isProcessing ? (
              <>
                <span className="w-4 h-4 border-2 border-black border-t-transparent rounded-full animate-spin" />
                <span>Đang xử lý...</span>
              </>
            ) : (
              <>
                <span className="material-symbols-outlined text-[18px]">lock</span>
                <span>Xác nhận & Thanh toán</span>
              </>
            )}
          </button>
        </div>
      </div>
    </div>
  );
};
