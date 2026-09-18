import React, { useState } from 'react';
import { BookingState, ConcessionItem } from '../types';
import { CONCESSIONS_DATA } from '../data/mockData';
import { formatCurrency, handleImageError, FALLBACK_CONCESSION_IMAGE } from '../utils/format';

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

  const seatsTotal = (booking.selectedSeats || []).reduce((acc, s) => acc + s.price, 0);
  const concessionsTotal = concessions.reduce(
    (acc, item) => acc + item.price * item.quantity,
    0
  );
  const subtotal = seatsTotal + concessionsTotal;
  const discount = booking.discount || 0;
  const finalTotal = Math.max(0, subtotal - discount);

  const handleNext = () => {
    const chosenConcessions = concessions.filter((item) => item.quantity > 0);
    const updated: BookingState = {
      ...booking,
      concessions: chosenConcessions,
      selectedConcessions: chosenConcessions,
      subtotal,
      discount,
      total: finalTotal,
      totalPrice: finalTotal,
      bookingStatus: 'review_order',
    };
    onContinue(updated);
  };

  const handleSkip = () => {
    const updated: BookingState = {
      ...booking,
      concessions: [],
      selectedConcessions: [],
      subtotal: seatsTotal,
      discount,
      total: Math.max(0, seatsTotal - discount),
      totalPrice: Math.max(0, seatsTotal - discount),
      bookingStatus: 'review_order',
    };
    onContinue(updated);
  };

  return (
    <div className="flex flex-col w-full text-[#D4D4D8] pb-36">
      {/* Top Banner Notice */}
      <div className="px-4 py-3 bg-[#171719] border-b border-[#2B2B30] flex items-center justify-between">
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
      <div className="fixed bottom-0 left-0 right-0 z-40 bg-[#0E0E0F]/95 backdrop-blur-xl px-4 py-3 pb-safe shadow-[0_-8px_30px_rgba(0,0,0,0.85)] border-t border-[#2B2B30]">
        <div className="flex items-center justify-between max-w-md mx-auto gap-3">
          <div className="flex flex-col min-w-0 flex-1">
            <span className="text-[10px] text-[#A1A1AA] uppercase font-semibold">
              Tổng tiền
            </span>
            <span className="text-base font-extrabold text-[#F5B800]">
              {formatCurrency(finalTotal)}
            </span>
            <span className="text-[10px] text-[#A1A1AA] truncate">
              {booking.selectedSeats.length} vé ({formatCurrency(seatsTotal)})
              {concessionsTotal > 0 && ` + F&B (${formatCurrency(concessionsTotal)})`}
            </span>
          </div>

          <button
            type="button"
            onClick={handleNext}
            className="min-w-[180px] h-[50px] rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] text-black text-xs sm:text-sm font-bold flex items-center justify-center gap-1.5 shadow-md active:scale-[0.98] transition-all shrink-0 cursor-pointer"
          >
            <span>Tiếp tục thanh toán</span>
            <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
          </button>
        </div>
      </div>
    </div>
  );
};
