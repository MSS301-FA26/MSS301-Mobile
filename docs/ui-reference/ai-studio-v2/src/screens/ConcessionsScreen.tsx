import React, { useState } from 'react';
import { BookingState, ConcessionItem } from '../types';
import { CONCESSIONS_DATA } from '../data/mockData';
import { formatCurrency, handleImageError, FALLBACK_CONCESSION_IMAGE } from '../utils/format';
import { BookingProgressBar } from '../components/BookingProgressBar';
import { CINEMA_CONFIG } from '../data/cinemaConfig';

interface ConcessionsScreenProps {
  booking: BookingState;
  onContinue: (updatedBooking: BookingState) => void;
  onBack: () => void;
}

export const ConcessionsScreen: React.FC<ConcessionsScreenProps> = ({
  booking,
  onContinue,
}) => {
  const existingConcessions = booking.concessions || booking.selectedConcessions || [];

  const [concessions, setConcessions] = useState<ConcessionItem[]>(() => {
    if (existingConcessions.length > 0) {
      return CONCESSIONS_DATA.map((item) => {
        const found = existingConcessions.find((c) => c.id === item.id);
        return found ? { ...item, quantity: found.quantity } : item;
      });
    }
    return CONCESSIONS_DATA;
  });

  const [selectedCategory, setSelectedCategory] = useState<string>('all');

  const categories = [
    { id: 'all', label: 'Tất cả' },
    { id: 'combos', label: 'Hot Combo' },
    { id: 'popcorn', label: 'Bắp rang' },
    { id: 'drinks', label: 'Đồ uống' },
  ];

  const updateQuantity = (id: string, delta: number) => {
    setConcessions((prev) =>
      prev.map((item) => {
        if (item.id === id) {
          const newQ = Math.max(0, item.quantity + delta);
          return { ...item, quantity: newQ };
        }
        return item;
      })
    );
  };

  const filteredConcessions = concessions.filter((item) => {
    if (selectedCategory === 'all') return true;
    return item.category === selectedCategory;
  });

  const ticketBaseSubtotal =
    booking.ticketSubtotal !== undefined && booking.ticketSubtotal > 0
      ? booking.ticketSubtotal
      : (booking.selectedSeats || []).reduce((acc, s) => acc + s.price, 0);

  const seatSurcharge = booking.seatSurcharge || 0;
  const ticketsAndSeatsTotal = ticketBaseSubtotal + seatSurcharge;

  const concessionsTotal = concessions.reduce(
    (acc, item) => acc + item.price * item.quantity,
    0
  );
  const subtotal = ticketsAndSeatsTotal + concessionsTotal;
  const discount = booking.discount || 0;
  const finalTotal = Math.max(0, subtotal - discount);

  const handleNext = () => {
    const chosenConcessions = concessions.filter((item) => item.quantity > 0);
    const updated: BookingState = {
      ...booking,
      concessions: chosenConcessions,
      selectedConcessions: chosenConcessions,
      ticketSubtotal: ticketBaseSubtotal,
      seatSurcharge,
      subtotal,
      discount,
      total: finalTotal,
      totalPrice: finalTotal,
      grandTotal: finalTotal,
      bookingStatus: 'review_order',
    };
    onContinue(updated);
  };

  const handleSkip = () => {
    const updated: BookingState = {
      ...booking,
      concessions: [],
      selectedConcessions: [],
      ticketSubtotal: ticketBaseSubtotal,
      seatSurcharge,
      subtotal: ticketsAndSeatsTotal,
      discount,
      total: Math.max(0, ticketsAndSeatsTotal - discount),
      totalPrice: Math.max(0, ticketsAndSeatsTotal - discount),
      grandTotal: Math.max(0, ticketsAndSeatsTotal - discount),
      bookingStatus: 'review_order',
    };
    onContinue(updated);
  };

  const ticketSummaryText =
    booking.ticketSelections && booking.ticketSelections.length > 0
      ? booking.ticketSelections.map((t) => `${t.quantity} ${t.name}`).join(', ')
      : `${booking.ticketQuantity || (booking.selectedSeats || []).length} vé`;

  const seatsListText = (booking.selectedSeats || []).map((s) => s.id).join(', ');

  const seatAssignmentsGrouped = (() => {
    if (!booking.seatAssignments || booking.seatAssignments.length === 0) return null;
    const groups: Record<string, string[]> = {};
    booking.seatAssignments.forEach((a) => {
      if (!groups[a.ticketTypeName]) groups[a.ticketTypeName] = [];
      groups[a.ticketTypeName].push(a.seatLabel);
    });
    return Object.entries(groups)
      .map(([name, seats]) => `${name}: ${seats.join(', ')}`)
      .join(' • ');
  })();

  return (
    <div className="flex flex-col flex-1 w-full text-[#D4D4D8] min-h-[calc(100dvh-4rem)] pb-44 sm:pb-36 bg-[#0E0E0F]">
      {/* 4-Step Booking Progress Indicator */}
      <div className="shrink-0">
        <BookingProgressBar currentStep="concessions" />
      </div>

      {/* Booking Context Strip */}
      <div className="px-4 py-2 bg-[#171719] border-b border-[#2B2B30] flex items-center justify-between text-xs">
        <div className="flex items-center gap-2 min-w-0">
          <span className="font-extrabold text-white truncate">
            {booking.movieTitle || booking.movie.title}
          </span>
          <span className="text-[#71717A]">•</span>
          <span className="text-[#F5B800] font-semibold truncate" title={seatAssignmentsGrouped || seatsListText}>
            {seatAssignmentsGrouped || `${ticketSummaryText} (${seatsListText})`}
          </span>
        </div>
        <span className="text-[11px] text-[#A1A1AA] shrink-0">
          {CINEMA_CONFIG.name}
        </span>
      </div>

      {/* Top Banner FastTrack Notice */}
      <div className="px-4 py-2.5 bg-[#1C1C20] border-b border-[#2B2B30] flex items-center justify-between">
        <div className="flex items-center gap-2 min-w-0 pr-2">
          <span className="material-symbols-outlined text-[#F5B800] text-[20px] shrink-0">
            fastfood
          </span>
          <span className="text-xs text-[#A1A1AA] truncate">
            Nhận bắp nước nhanh tại quầy FastTrack bằng mã QR vé
          </span>
        </div>
        <button
          type="button"
          onClick={handleSkip}
          className="text-xs text-[#F5B800] font-bold hover:underline shrink-0 px-2 py-1"
        >
          Bỏ qua
        </button>
      </div>

      {/* Category Tabs */}
      <div className="px-4 py-3 flex gap-2 overflow-x-auto scrollbar-none">
        {categories.map((cat) => {
          const isSelected = selectedCategory === cat.id;
          return (
            <button
              type="button"
              key={cat.id}
              onClick={() => setSelectedCategory(cat.id)}
              className={`shrink-0 px-4 py-1.5 min-h-[36px] rounded-full text-xs font-bold transition-all ${
                isSelected
                  ? 'bg-[#202024] text-[#F5B800] border border-[#F5B800] shadow-sm'
                  : 'bg-[#171719] text-[#A1A1AA] border border-[#2B2B30] hover:text-white'
              }`}
            >
              {cat.label}
            </button>
          );
        })}
      </div>

      {/* Concession Cards List */}
      <div className="flex flex-col gap-3 px-4 mt-1">
        {filteredConcessions.map((item) => (
          <div
            key={item.id}
            className={`p-3.5 rounded-2xl bg-[#171719] border transition-all flex gap-3 ${
              item.quantity > 0
                ? 'border-[#F5B800]/60 shadow-sm'
                : 'border-[#2B2B30] hover:border-[#3F3F46]'
            }`}
          >
            {/* Thumbnail */}
            <div className="relative w-24 h-24 rounded-xl overflow-hidden bg-[#202024] shrink-0 border border-[#2B2B30]">
              <img
                src={item.imageUrl}
                alt={item.name}
                onError={(e) => handleImageError(e, FALLBACK_CONCESSION_IMAGE)}
                className="w-full h-full object-cover"
                referrerPolicy="no-referrer"
              />
              {item.badge && (
                <span className="absolute top-1 left-1 px-1.5 py-0.5 rounded bg-[#F5B800] text-black text-[9px] font-black uppercase">
                  {item.badge}
                </span>
              )}
            </div>

            {/* Info and Counter */}
            <div className="flex flex-col justify-between flex-1 min-w-0 py-0.5">
              <div>
                <h3 className="font-bold text-sm text-white truncate">{item.name}</h3>
                <p className="text-xs text-[#A1A1AA] line-clamp-2 mt-0.5 leading-relaxed">
                  {item.description}
                </p>
              </div>

              <div className="flex items-center justify-between mt-2 pt-1 border-t border-[#2B2B30]">
                <span className="font-extrabold text-sm text-[#F5B800]">
                  {formatCurrency(item.price)}
                </span>

                {/* Counter controls */}
                <div className="flex items-center gap-2">
                  {item.quantity > 0 && (
                    <button
                      type="button"
                      onClick={() => updateQuantity(item.id, -1)}
                      className="w-8 h-8 rounded-lg bg-[#202024] hover:bg-[#2B2B30] text-white flex items-center justify-center transition-colors active:scale-95 border border-[#2B2B30]"
                    >
                      <span className="material-symbols-outlined text-[18px]">remove</span>
                    </button>
                  )}

                  {item.quantity > 0 && (
                    <span className="w-6 text-center text-sm font-extrabold text-white">
                      {item.quantity}
                    </span>
                  )}

                  <button
                    type="button"
                    onClick={() => updateQuantity(item.id, 1)}
                    className="w-8 h-8 rounded-lg bg-[#F5B800] hover:bg-[#E6AA00] text-black font-black flex items-center justify-center transition-colors active:scale-95 shadow-sm"
                  >
                    <span className="material-symbols-outlined text-[18px]">add</span>
                  </button>
                </div>
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Sticky Bottom Summary & Checkout Bar */}
      <footer
        className="fixed bottom-0 left-0 right-0 z-40 bg-[#121214] border-t border-[#2B2B30] px-4 pt-3.5 shadow-[0_-4px_24px_rgba(0,0,0,0.9)] pointer-events-auto"
        style={{ paddingBottom: 'max(14px, calc(14px + env(safe-area-inset-bottom, 0px)))' }}
      >
        <div className="w-full max-w-md mx-auto flex flex-col min-[390px]:flex-row min-[390px]:items-center justify-between gap-3">
          <div className="flex flex-col min-w-0 flex-1">
            <span className="text-[10px] text-[#A1A1AA] uppercase font-semibold">
              Tổng tiền
            </span>
            <span className="text-base sm:text-lg font-extrabold text-[#F5B800]">
              {formatCurrency(finalTotal)}
            </span>
            <span className="text-[10px] text-[#A1A1AA] truncate mt-0.5">
              {booking.selectedSeats?.length || booking.totalTicketQuantity || 1} vé ({formatCurrency(ticketsAndSeatsTotal)})
              {concessionsTotal > 0 && ` + F&B (${formatCurrency(concessionsTotal)})`}
            </span>
          </div>

          <button
            type="button"
            onClick={handleNext}
            className="w-full min-[390px]:w-auto min-[390px]:min-w-[170px] h-[48px] rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] text-black text-xs sm:text-sm font-bold flex items-center justify-center gap-1.5 shadow-md active:scale-[0.98] transition-all shrink-0 cursor-pointer select-none"
          >
            <span>Tiếp tục: Thanh toán</span>
            <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
          </button>
        </div>
      </footer>
    </div>
  );
};
