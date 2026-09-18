import React, { useState } from 'react';
import { BookingState, Seat } from '../types';
import { formatCurrency } from '../utils/format';

interface SeatsScreenProps {
  booking: BookingState;
  onContinue: (updatedBooking: BookingState) => void;
  onBack: () => void;
}

export const SeatsScreen: React.FC<SeatsScreenProps> = ({
  booking,
  onContinue,
}) => {
  // Restore previously selected seats if available, or start empty for user choice
  const [selectedSeatIds, setSelectedSeatIds] = useState<string[]>(() => {
    if (booking.selectedSeats && booking.selectedSeats.length > 0) {
      return booking.selectedSeats.map((s) => s.id);
    }
    return [];
  });

  const [warningMessage, setWarningMessage] = useState<string | null>(null);

  const rows = ['A', 'B', 'C', 'D', 'E'];

  // Construct seat matrix
  const generateSeats = (): Seat[] => {
    const seats: Seat[] = [];
    rows.forEach((row) => {
      const count = row === 'E' ? 6 : 8; // Row E is couple seats
      for (let i = 1; i <= count; i++) {
        const id = `${row}${i}`;
        const isOccupied = ['A2', 'A7', 'B3', 'B4', 'D6', 'D7'].includes(id);

        let type: 'standard' | 'vip' | 'couple' = 'standard';
        let price = 90000;

        if (['C', 'D'].includes(row)) {
          type = 'vip';
          price = 110000;
        } else if (row === 'E') {
          type = 'couple';
          price = 240000;
        }

        seats.push({
          id,
          row,
          col: i,
          type,
          price,
          status: isOccupied ? 'occupied' : 'available',
        });
      }
    });
    return seats;
  };

  const [allSeats] = useState<Seat[]>(generateSeats());

  const toggleSeat = (seat: Seat) => {
    if (seat.status === 'occupied') return;
    setWarningMessage(null);

    if (selectedSeatIds.includes(seat.id)) {
      setSelectedSeatIds(selectedSeatIds.filter((id) => id !== seat.id));
    } else {
      // Limit to 6 seats max
      if (selectedSeatIds.length >= 6) {
        setWarningMessage('Bạn chỉ có thể chọn tối đa 6 ghế cho mỗi lượt đặt vé.');
        return;
      }
      setSelectedSeatIds([...selectedSeatIds, seat.id]);
    }
  };

  const selectedSeatObjects = allSeats.filter((s) => selectedSeatIds.includes(s.id));
  const totalSeatsPrice = selectedSeatObjects.reduce((acc, s) => acc + s.price, 0);

  const handleNext = () => {
    if (selectedSeatObjects.length === 0) {
      setWarningMessage('Vui lòng chọn ít nhất một ghế để tiếp tục.');
      return;
    }

    const currentConcessions = booking.concessions || booking.selectedConcessions || [];
    const concessionsTotal = currentConcessions.reduce(
      (acc, c) => acc + c.price * c.quantity,
      0
    );
    const subtotal = totalSeatsPrice + concessionsTotal;
    const discount = booking.discount || 0;
    const finalTotal = Math.max(0, subtotal - discount);

    const updated: BookingState = {
      ...booking,
      ticketQuantity: selectedSeatObjects.length,
      selectedSeats: selectedSeatObjects,
      concessions: currentConcessions,
      selectedConcessions: currentConcessions,
      subtotal,
      discount,
      total: finalTotal,
      totalPrice: finalTotal,
      bookingStatus: 'selecting_concessions',
    };
    onContinue(updated);
  };

  return (
    <div className="flex flex-col w-full text-[#D4D4D8] pb-36">
      {/* Screening Room Banner */}
      <div className="px-4 py-3 bg-[#171719] border-b border-[#2B2B30] flex items-center justify-between">
        <div className="flex flex-col min-w-0 pr-2">
          <span className="text-xs text-[#F5B800] font-bold uppercase tracking-wider truncate">
            {booking.room || booking.selectedSlot?.roomName || 'Phòng C'} • {booking.format || booking.selectedSlot?.formatBadge || 'Dolby Atmos'}
          </span>
          <span className="text-sm font-extrabold text-white truncate">
            {booking.movieTitle || booking.movie.title}
          </span>
          <span className="text-xs text-[#A1A1AA] truncate">
            {booking.time || booking.selectedSlot?.time || '20:30'} • {booking.date || booking.selectedDate || 'Hôm nay, 14/09/2026'}
          </span>
        </div>
        <span className="px-2.5 py-1 rounded-full bg-[#202024] text-[#A1A1AA] text-xs font-semibold shrink-0 border border-[#2B2B30]">
          Tầng 5
        </span>
      </div>

      {/* 3D Curved Cinema Screen */}
      <div className="px-4 pt-5 pb-3 flex flex-col items-center overflow-hidden">
        <div className="relative w-full max-w-sm flex flex-col items-center">
          {/* Light projection gradient - Silver/neutral light */}
          <div className="w-full h-10 bg-gradient-to-b from-white/15 via-white/5 to-transparent blur-md rounded-t-full pointer-events-none" />

          {/* Curved Screen Stroke */}
          <svg className="w-full h-7 -mt-5" viewBox="0 0 320 30" fill="none">
            <path
              d="M 10 25 Q 160 5 310 25"
              stroke="url(#screenGrad)"
              strokeWidth="4"
              strokeLinecap="round"
            />
            <defs>
              <linearGradient id="screenGrad" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stopColor="#2B2B30" />
                <stop offset="50%" stopColor="#71717A" />
                <stop offset="100%" stopColor="#2B2B30" />
              </linearGradient>
            </defs>
          </svg>

          <span className="text-[11px] font-bold text-[#A1A1AA] tracking-[0.2em] -mt-1 uppercase">
            Màn hình chiếu
          </span>
        </div>
      </div>

      {/* In-UI Warning Feedback */}
      {warningMessage && (
        <div className="mx-4 mb-2 p-2.5 rounded-xl bg-[#242014] border border-[#4D3D0A] text-xs text-[#F5B800] font-medium flex items-center gap-2">
          <span className="material-symbols-outlined text-[18px]">info</span>
          <span>{warningMessage}</span>
        </div>
      )}

      {/* Seat Layout Matrix with horizontal responsiveness */}
      <div className="w-full overflow-x-auto scrollbar-none px-2 py-2 flex flex-col items-center select-none">
        <div className="flex flex-col items-center gap-2.5 min-w-[320px]">
          {rows.map((row) => {
            const rowSeats = allSeats.filter((s) => s.row === row);
            const isCoupleRow = row === 'E';

            return (
              <div key={row} className="flex items-center gap-2">
                <span className="w-5 text-center text-xs font-bold text-[#A1A1AA]">{row}</span>

                <div className="flex items-center gap-1.5 sm:gap-2">
                  {rowSeats.map((seat) => {
                    const isSelected = selectedSeatIds.includes(seat.id);
                    const isOccupied = seat.status === 'occupied';

                    if (isCoupleRow) {
                      // Couple double seat pill
                      return (
                        <button
                          type="button"
                          key={seat.id}
                          disabled={isOccupied}
                          onClick={() => toggleSeat(seat)}
                          className={`w-14 sm:w-16 h-8 rounded-xl flex items-center justify-center text-[10px] font-extrabold transition-all active:scale-95 ${
                            isOccupied
                              ? 'bg-[#131315] text-[#52525B] opacity-40 cursor-not-allowed border border-[#202024]'
                              : isSelected
                              ? 'bg-[#F5B800] text-black shadow-sm scale-105'
                              : 'bg-[#6f00be]/30 text-[#ddb7ff] border border-[#6f00be]/50 hover:bg-[#6f00be]/50'
                          }`}
                        >
                          {seat.id}
                        </button>
                      );
                    }

                    // Standard or VIP Seat
                    const isVip = seat.type === 'vip';

                    return (
                      <button
                        type="button"
                        key={seat.id}
                        disabled={isOccupied}
                        onClick={() => toggleSeat(seat)}
                        className={`w-8 h-8 sm:w-9 sm:h-9 rounded-lg flex items-center justify-center text-[11px] font-bold transition-all active:scale-95 ${
                          isOccupied
                            ? 'bg-[#131315] text-[#52525B] cursor-not-allowed border border-[#202024]'
                            : isSelected
                            ? 'bg-[#F5B800] text-black shadow-sm scale-105 font-extrabold'
                            : isVip
                            ? 'bg-[#202024] text-[#F5B800] border border-[#F5B800]/40 hover:border-[#F5B800]'
                            : 'bg-[#171719] text-[#D4D4D8] hover:bg-[#202024] border border-[#2B2B30]'
                        }`}
                      >
                        {isOccupied ? '✕' : seat.id}
                      </button>
                    );
                  })}
                </div>

                <span className="w-5 text-center text-xs font-bold text-[#A1A1AA]">{row}</span>
              </div>
            );
          })}
        </div>
      </div>

      {/* Seat Types Legend */}
      <div className="px-4 py-3 mt-1">
        <div className="flex items-center justify-center flex-wrap gap-3.5 p-3 rounded-2xl bg-[#171719] border border-[#2B2B30] text-xs text-[#A1A1AA]">
          <div className="flex items-center gap-1.5">
            <span className="w-4 h-4 rounded-md bg-[#171719] border border-[#2B2B30]" />
            <span className="text-[#D4D4D8]">Thường (90k)</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-4 h-4 rounded-md bg-[#202024] border border-[#F5B800]/60" />
            <span className="text-[#F5B800]">VIP (110k)</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-7 h-4 rounded-md bg-[#6f00be]/30 border border-[#6f00be]" />
            <span className="text-[#ddb7ff]">Đôi (240k)</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-4 h-4 rounded-md bg-[#F5B800]" />
            <span className="text-white font-bold">Đang chọn</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-4 h-4 rounded-md bg-[#131315] border border-[#202024] flex items-center justify-center text-[10px] text-[#52525B]">
              ✕
            </span>
            <span>Đã bán</span>
          </div>
        </div>
      </div>

      {/* Sticky Bottom Action Bar */}
      <div className="fixed bottom-0 left-0 right-0 z-40 bg-[#0E0E0F]/95 backdrop-blur-xl px-4 py-3 pb-safe shadow-[0_-8px_30px_rgba(0,0,0,0.85)] border-t border-[#2B2B30]">
        <div className="flex items-center justify-between max-w-md mx-auto gap-3">
          <div className="flex flex-col min-w-0 flex-1">
            <span className="text-[10px] text-[#A1A1AA] uppercase font-semibold">
              Ghế đã chọn ({selectedSeatObjects.length}/6)
            </span>
            <span className="text-sm font-extrabold text-[#F5B800] truncate">
              {selectedSeatObjects.length > 0
                ? selectedSeatObjects.map((s) => s.id).join(', ')
                : 'Chưa chọn ghế'}
            </span>
            <span className="text-base font-extrabold text-white">
              {formatCurrency(totalSeatsPrice)}
            </span>
          </div>

          <button
            type="button"
            onClick={handleNext}
            disabled={selectedSeatObjects.length === 0}
            className={`min-w-[180px] h-[50px] rounded-xl text-xs sm:text-sm font-bold flex items-center justify-center gap-1.5 shadow-md transition-all shrink-0 ${
              selectedSeatObjects.length > 0
                ? 'bg-[#F5B800] hover:bg-[#E6AA00] text-black active:scale-[0.98] cursor-pointer'
                : 'bg-[#202024] text-[#71717A] cursor-not-allowed shadow-none border border-[#2B2B30]'
            }`}
          >
            <span>Tiếp tục: Bắp & Nước</span>
            <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
          </button>
        </div>
      </div>
    </div>
  );
};
