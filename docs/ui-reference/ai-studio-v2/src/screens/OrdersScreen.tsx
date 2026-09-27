import React, { useState } from 'react';
import { TicketOrder } from '../types';
import { formatCurrency, handleImageError } from '../utils/format';

interface OrdersScreenProps {
  orders: TicketOrder[];
  onSelectOrder: (order: TicketOrder) => void;
  onBookAgain: (movieTitle: string) => void;
  onCancelOrder: (orderId: string) => void;
}

export const OrdersScreen: React.FC<OrdersScreenProps> = ({
  orders,
  onSelectOrder,
  onBookAgain,
  onCancelOrder,
}) => {
  const [activeTab, setActiveTab] = useState<'upcoming' | 'completed'>('upcoming');

  const upcomingOrders = orders.filter((o) => o.status === 'upcoming');
  const completedOrders = orders.filter((o) => o.status === 'completed');

  return (
    <div className="flex flex-col w-full text-[#D4D4D8] pb-6 p-4">
      {/* Tab Switcher */}
      <div className="p-1 rounded-2xl bg-[#171719] flex border border-[#2B2B30] mb-4">
        <button
          type="button"
          onClick={() => setActiveTab('upcoming')}
          className={`flex-1 py-2.5 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 ${
            activeTab === 'upcoming'
              ? 'bg-[#F5B800] text-black shadow-sm'
              : 'text-[#A1A1AA] hover:text-white'
          }`}
        >
          <span>Sắp chiếu</span>
          <span
            className={`px-1.5 py-0.2 rounded-full text-[10px] font-black ${
              activeTab === 'upcoming' ? 'bg-black/20 text-black' : 'bg-[#202024] text-[#A1A1AA]'
            }`}
          >
            {upcomingOrders.length}
          </span>
        </button>

        <button
          type="button"
          onClick={() => setActiveTab('completed')}
          className={`flex-1 py-2.5 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 ${
            activeTab === 'completed'
              ? 'bg-[#F5B800] text-black shadow-sm'
              : 'text-[#A1A1AA] hover:text-white'
          }`}
        >
          <span>Lịch sử đã xem</span>
          <span
            className={`px-1.5 py-0.2 rounded-full text-[10px] font-black ${
              activeTab === 'completed' ? 'bg-black/20 text-black' : 'bg-[#202024] text-[#A1A1AA]'
            }`}
          >
            {completedOrders.length}
          </span>
        </button>
      </div>

      {/* UPCOMING ORDERS */}
      {activeTab === 'upcoming' && (
        <div className="flex flex-col gap-4">
          {upcomingOrders.length === 0 ? (
            <div className="py-16 flex flex-col items-center justify-center text-center gap-2">
              <span className="material-symbols-outlined text-[48px] text-[#71717A]">
                confirmation_number
              </span>
              <h3 className="font-bold text-base text-white">Chưa có vé sắp chiếu nào</h3>
              <p className="text-xs text-[#A1A1AA]">
                Hãy chọn một bộ phim yêu thích và đặt chỗ ngay hôm nay!
              </p>
            </div>
          ) : (
            upcomingOrders.map((order) => (
              <div
                key={order.id}
                className="rounded-3xl bg-[#171719] p-4 border border-[#2B2B30] shadow-sm flex flex-col gap-3"
              >
                {/* Urgent notification badge */}
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-1.5">
                    <span className="w-2 h-2 rounded-full bg-[#F5B800] animate-pulse" />
                    <span className="text-xs font-black text-[#F5B800]">
                      {order.statusLabel || 'Sắp chiếu (Trong 45 phút)'}
                    </span>
                  </div>
                  <span className="font-mono text-[11px] text-[#71717A] font-semibold">
                    {order.ticketCode}
                  </span>
                </div>

                <div className="flex gap-3">
                  <img
                    src={order.moviePoster}
                    alt={order.movieTitle}
                    onError={(e) => handleImageError(e)}
                    className="w-20 h-28 rounded-xl object-cover bg-black border border-[#2B2B30] shadow-sm shrink-0"
                    referrerPolicy="no-referrer"
                  />
                  <div className="flex flex-col justify-between py-0.5 min-w-0 flex-1">
                    <div>
                      <div className="flex items-center gap-1.5 mb-1">
                        <span className="px-1.5 py-0.2 rounded bg-[#242014] border border-[#4D3D0A] text-[#F5B800] text-[9px] font-bold">
                          {order.ageRating}
                        </span>
                        <span className="text-[11px] text-[#ddb7ff] font-medium truncate">
                          {order.format}
                        </span>
                      </div>
                      <h3 className="font-black text-lg text-white uppercase truncate">
                        {order.movieTitle}
                      </h3>
                      <p className="text-xs text-[#A1A1AA] truncate mt-0.5">
                        {order.cinemaLocation}
                      </p>
                    </div>

                    <div className="text-xs text-white">
                      <span className="font-bold text-[#F5B800]">{order.dateTimeStr}</span>
                      <div className="text-[11px] text-[#A1A1AA] mt-0.5">
                        Ghế:{' '}
                        <span className="text-white font-bold">
                          {order.seatAssignments && order.seatAssignments.length > 0
                            ? order.seatAssignments.map((a) => `${a.seatLabel} (${a.ticketTypeName})`).join(', ')
                            : order.seats.join(', ')}
                        </span>
                      </div>
                    </div>
                  </div>
                </div>

                {/* Additional concessions info if any */}
                {order.concessionsSummary && order.concessionsSummary !== 'Không kèm F&B' && (
                  <div className="px-3 py-2 rounded-xl bg-[#202024] border border-[#2B2B30] text-xs text-[#A1A1AA] flex items-center gap-2">
                    <span className="material-symbols-outlined text-[16px] text-[#F5B800]">
                      fastfood
                    </span>
                    <span>Bắp nước: {order.concessionsSummary}</span>
                  </div>
                )}

                {/* Action CTA Buttons */}
                <div className="grid grid-cols-2 gap-2 pt-1 border-t border-[#2B2B30]">
                  <button
                    type="button"
                    onClick={() => {
                      if (confirm('Bạn có chắc chắn muốn hoàn vé theo chính sách hủy trước 60 phút của CinePremier?')) {
                        onCancelOrder(order.id);
                      }
                    }}
                    className="h-11 rounded-xl bg-[#202024] hover:bg-[#2B2B30] text-[#A1A1AA] hover:text-white text-xs font-semibold flex items-center justify-center gap-1 transition-colors border border-[#2B2B30]"
                  >
                    <span className="material-symbols-outlined text-[16px]">cancel</span>
                    Hoàn / Đổi vé
                  </button>

                  <button
                    type="button"
                    onClick={() => onSelectOrder(order)}
                    className="h-11 rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] text-black text-xs font-bold flex items-center justify-center gap-1.5 shadow-sm active:scale-95 transition-all"
                  >
                    <span className="material-symbols-outlined text-[18px]">qr_code</span>
                    Mở mã vé
                  </button>
                </div>
              </div>
            ))
          )}
        </div>
      )}

      {/* COMPLETED ORDERS */}
      {activeTab === 'completed' && (
        <div className="flex flex-col gap-3">
          {completedOrders.map((order) => (
            <div
              key={order.id}
              className="rounded-2xl bg-[#171719] p-4 border border-[#2B2B30] flex flex-col gap-3"
            >
              <div className="flex items-center justify-between text-xs">
                <span className="px-2 py-0.5 rounded bg-[#202024] text-[#A1A1AA] font-medium border border-[#2B2B30]">
                  {order.statusLabel}
                </span>
                <span className="text-[#71717A] font-mono text-[11px]">{order.ticketCode}</span>
              </div>

              <div className="flex gap-3 items-center">
                <img
                  src={order.moviePoster}
                  alt={order.movieTitle}
                  onError={(e) => handleImageError(e)}
                  className="w-14 h-20 rounded-xl object-cover bg-black border border-[#2B2B30] shrink-0"
                  referrerPolicy="no-referrer"
                />
                <div className="flex flex-col min-w-0 flex-1">
                  <h3 className="font-bold text-base text-white truncate uppercase">
                    {order.movieTitle}
                  </h3>
                  <span className="text-xs text-[#A1A1AA] truncate">{order.cinemaLocation}</span>
                  <span className="text-xs text-[#71717A] mt-0.5">{order.dateTimeStr}</span>
                  <span className="text-xs text-[#F5B800] font-semibold mt-1">
                    Ghế {order.seats.join(', ')} • {formatCurrency(order.totalPrice)}
                  </span>
                </div>
              </div>

              <div className="flex gap-2 pt-2 border-t border-[#2B2B30]">
                <button
                  type="button"
                  onClick={() => onBookAgain(order.movieTitle)}
                  className="flex-1 h-9 rounded-xl bg-[#202024] hover:bg-[#2B2B30] text-xs font-semibold text-white flex items-center justify-center gap-1 border border-[#2B2B30] transition-colors"
                >
                  <span className="material-symbols-outlined text-[16px]">replay</span>
                  Đặt lại vé
                </button>
                <button
                  type="button"
                  onClick={() => alert('Cảm ơn bạn đã đánh giá 5 sao cho suất chiếu này!')}
                  className="px-3 h-9 rounded-xl bg-[#202024] hover:bg-[#2B2B30] text-xs font-semibold text-[#F5B800] flex items-center justify-center gap-1 border border-[#2B2B30] transition-colors"
                >
                  <span className="material-symbols-outlined text-[16px] icon-filled">star</span>
                  Đánh giá
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
};
