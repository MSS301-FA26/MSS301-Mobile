import React, { useState } from 'react';
import { Movie, ShowtimeSlot, ScreenName } from '../types';
import { SHOWTIMES_DATA, MOVIES } from '../data/mockData';
import { CINEMA_CONFIG } from '../data/cinemaConfig';
import { handleImageError } from '../utils/format';
import { BookingProgressBar } from '../components/BookingProgressBar';

interface ShowtimesScreenProps {
  currentMovie?: Movie;
  onNavigate: (screen: ScreenName) => void;
  onSelectSlot: (movie: Movie, slot: ShowtimeSlot, dateStr: string) => void;
  selectedCinemaId?: string;
  onOpenCinemaPicker?: () => void;
  isCalendarTab?: boolean;
}

export const ShowtimesScreen: React.FC<ShowtimesScreenProps> = ({
  currentMovie,
  onSelectSlot,
  onOpenCinemaPicker,
  isCalendarTab = false,
}) => {
  const cinema = CINEMA_CONFIG;

  const dates = [
    { label: 'Hôm nay', sub: '14/09', key: '2026-09-14' },
    { label: 'T.Ba', sub: '15/09', key: '2026-09-15' },
    { label: 'T.Tư', sub: '16/09', key: '2026-09-16' },
    { label: 'T.Năm', sub: '17/09', key: '2026-09-17' },
    { label: 'T.Sáu', sub: '18/09', key: '2026-09-18' },
    { label: 'T.Bảy', sub: '19/09', key: '2026-09-19' },
    { label: 'Chủ Nhật', sub: '20/09', key: '2026-09-20' },
  ];

  const [selectedDate, setSelectedDate] = useState<string>(dates[0].key);
  const [selectedFormat, setSelectedFormat] = useState<string>('all');
  const [activeSlot, setActiveSlot] = useState<{
    movie: Movie;
    slot: ShowtimeSlot;
  } | null>(() => {
    // If currentMovie is set, find its first available slot
    const targetMovie = currentMovie || MOVIES.find((m) => m.id === 'inception') || MOVIES[0];
    const movieSt = SHOWTIMES_DATA.find((s) => s.movieId === targetMovie.id) || SHOWTIMES_DATA[0];
    for (const room of movieSt.rooms) {
      const avail = room.slots.find((s) => !s.isSoldOut);
      if (avail) {
        return { movie: targetMovie, slot: avail };
      }
    }
    return null;
  });

  const formats = [
    { id: 'all', label: 'Tất cả' },
    { id: 'imax', label: 'IMAX Laser' },
    { id: 'atmos', label: 'Dolby Atmos' },
    { id: 'vip', label: 'VIP Suite' },
    { id: '2d', label: '2D Phụ đề' },
  ];

  // If a specific movie was chosen from Detail screen, prioritize it first
  const showtimesList = currentMovie
    ? [
        SHOWTIMES_DATA.find((s) => s.movieId === currentMovie.id) || SHOWTIMES_DATA[0],
        ...SHOWTIMES_DATA.filter((s) => s.movieId !== currentMovie.id),
      ]
    : SHOWTIMES_DATA;

  const handleSlotClick = (movieId: string, slot: ShowtimeSlot) => {
    if (slot.isSoldOut) return;
    const movieObj = MOVIES.find((m) => m.id === movieId) || MOVIES[0];
    const dateObj = dates.find((d) => d.key === selectedDate);
    const dateString = `${dateObj?.label || 'Hôm nay'}, ${dateObj?.sub || '14/09'}/2026`;

    if (isCalendarTab) {
      // In the Calendar tab with BottomNav visible:
      // Directly select slot and transition to seat selection
      onSelectSlot(movieObj, slot, dateString);
    } else {
      setActiveSlot({ movie: movieObj, slot });
    }
  };

  const handleContinueToSeats = () => {
    if (!activeSlot) return;
    const dateObj = dates.find((d) => d.key === selectedDate);
    const dateString = `${dateObj?.label || 'Hôm nay'}, ${dateObj?.sub || '14/09'}/2026`;
    onSelectSlot(activeSlot.movie, activeSlot.slot, dateString);
  };

  return (
    <div className={`flex flex-col w-full text-[#D4D4D8] ${isCalendarTab ? 'pb-0' : 'pb-24'}`}>
      {/* 5-Step Booking Progress Indicator (when in dedicated booking flow) */}
      {!isCalendarTab && <BookingProgressBar currentStep="showtimes" />}

      {/* Cinema Information Bar (Static Single Cinema) */}
      <section className="px-4 py-3 bg-[#171719] border-b border-[#2B2B30]">
        <div className="flex items-center justify-between gap-2">
          <div className="flex items-start gap-2.5 min-w-0">
            <div className="w-8 h-8 rounded-full bg-[#202024] flex items-center justify-center text-[#F5B800] shrink-0 mt-0.5 border border-[#2B2B30]">
              <span className="material-symbols-outlined text-[18px]">location_on</span>
            </div>
            <div className="flex flex-col min-w-0">
              <div className="flex items-center gap-2">
                <span className="text-sm font-bold text-white truncate">{cinema.name}</span>
                <span className="px-1.5 py-0.2 rounded bg-emerald-500/15 text-emerald-400 border border-emerald-500/25 text-[10px] font-bold shrink-0">
                  Đang chiếu
                </span>
              </div>
              <span className="text-xs text-[#A1A1AA] truncate">
                {cinema.address}
              </span>
            </div>
          </div>
          {onOpenCinemaPicker && (
            <button
              type="button"
              id="btn-showtimes-cinema-info"
              onClick={onOpenCinemaPicker}
              className="px-2.5 sm:px-3 py-1.5 min-h-[32px] rounded-full bg-[#202024] hover:bg-[#2B2B30] text-[#D4D4D8] hover:text-white text-xs font-semibold shrink-0 transition-colors border border-[#2B2B30] flex items-center gap-1 active:scale-95"
            >
              <span className="material-symbols-outlined text-[15px] text-[#F5B800]">info</span>
              <span className="text-[11px] hidden xs:inline">Thông tin rạp</span>
            </button>
          )}
        </div>
      </section>

      {/* Date Horizontal Picker */}
      <section className="px-4 py-3 bg-[#0E0E0F] border-b border-[#2B2B30]">
        <div className="flex gap-2 overflow-x-auto scrollbar-none py-1">
          {dates.map((d) => {
            const isSelected = selectedDate === d.key;
            return (
              <button
                type="button"
                key={d.key}
                onClick={() => setSelectedDate(d.key)}
                className={`shrink-0 w-16 py-2.5 rounded-2xl flex flex-col items-center justify-center min-h-[52px] transition-all active:scale-95 ${
                  isSelected
                    ? 'bg-[#202024] text-white font-bold border border-[#F5B800] shadow-sm'
                    : 'bg-[#171719] text-[#A1A1AA] hover:bg-[#202024] border border-[#2B2B30]'
                }`}
              >
                <span className={`text-[11px] uppercase tracking-tight ${isSelected ? 'text-[#F5B800] font-bold' : 'text-[#71717A]'}`}>
                  {d.label}
                </span>
                <span className={`text-sm font-extrabold mt-0.5 ${isSelected ? 'text-white' : 'text-[#D4D4D8]'}`}>
                  {d.sub}
                </span>
              </button>
            );
          })}
        </div>
      </section>

      {/* Format Filter Chips */}
      <section className="px-4 py-3">
        <div className="flex gap-2 overflow-x-auto scrollbar-none py-0.5">
          {formats.map((f) => {
            const isSelected = selectedFormat === f.id;
            return (
              <button
                type="button"
                key={f.id}
                onClick={() => setSelectedFormat(f.id)}
                className={`shrink-0 px-3.5 py-1.5 min-h-[36px] rounded-full text-xs font-semibold transition-colors flex items-center justify-center ${
                  isSelected
                    ? 'bg-[#202024] text-[#F5B800] border border-[#F5B800]'
                    : 'bg-[#171719] text-[#A1A1AA] border border-[#2B2B30] hover:text-white'
                }`}
              >
                {f.label}
              </button>
            );
          })}
        </div>
      </section>

      {/* Showtimes List */}
      <section className="flex flex-col gap-4 px-4 mt-1">
        {showtimesList.map((movieShowtime) => {
          return (
            <div
              key={movieShowtime.movieId}
              className="rounded-2xl bg-[#171719] p-4 border border-[#2B2B30] shadow-sm flex flex-col gap-4"
            >
              {/* Movie Header in Card */}
              <div className="flex gap-3 items-center">
                <img
                  src={movieShowtime.posterUrl}
                  alt={movieShowtime.movieTitle}
                  onError={(e) => handleImageError(e)}
                  className="w-14 h-20 rounded-lg object-cover bg-[#202024] shrink-0"
                  referrerPolicy="no-referrer"
                />
                <div className="flex flex-col min-w-0">
                  <div className="flex items-center gap-2 mb-1">
                    <span className="px-1.5 py-0.5 rounded bg-[#242014] border border-[#4D3D0A] text-[#F5B800] text-[10px] font-bold">
                      {movieShowtime.ageRating}
                    </span>
                    <span className="flex items-center gap-1 text-[#F5B800] text-xs font-bold">
                      <span className="material-symbols-outlined text-[14px] icon-filled">star</span>
                      {movieShowtime.rating}
                    </span>
                  </div>
                  <h3 className="font-extrabold text-[17px] text-white uppercase truncate">
                    {movieShowtime.movieTitle}
                  </h3>
                  <p className="text-xs text-[#A1A1AA] truncate">
                    {movieShowtime.genres} • {movieShowtime.duration}
                  </p>
                </div>
              </div>

              {/* Rooms and Slot Grids */}
              {movieShowtime.rooms.map((room) => {
                if (
                  selectedFormat !== 'all' &&
                  !room.formatBadge.toLowerCase().includes(selectedFormat.replace('atmos', 'dolby'))
                ) {
                  return null;
                }

                return (
                  <div key={room.id} className="flex flex-col gap-2.5 pt-2 border-t border-[#2B2B30]">
                    {/* Room Header */}
                    <div className="flex items-center justify-between">
                      <div className="flex items-center gap-2">
                        <span className="font-bold text-sm text-white">{room.roomName}</span>
                        <span
                          className={`px-2 py-0.5 rounded text-[10px] font-bold ${
                            room.formatBadge.includes('IMAX')
                              ? 'bg-[#6f00be]/30 text-[#ddb7ff] border border-[#6f00be]/30'
                              : 'bg-[#242014] text-[#F5B800] border border-[#4D3D0A]'
                          }`}
                        >
                          {room.formatBadge}
                        </span>
                      </div>
                      <span className="text-[11px] text-[#A1A1AA]">{room.screenDetail}</span>
                    </div>

                    {/* Slot Pills Grid */}
                    <div className="grid grid-cols-3 gap-2">
                      {room.slots.map((slot) => {
                        const isChosen =
                          activeSlot?.slot.id === slot.id &&
                          activeSlot?.movie.id === movieShowtime.movieId;

                        if (slot.isSoldOut) {
                          return (
                            <div
                              key={slot.id}
                              className="p-2.5 rounded-xl bg-[#0E0E0F]/60 border border-[#2B2B30] opacity-40 flex flex-col items-center justify-center cursor-not-allowed text-center min-h-[64px]"
                            >
                              <span className="text-sm font-bold text-[#71717A] line-through">
                                {slot.time}
                              </span>
                              <span className="text-[10px] text-rose-400 font-medium">Hết chỗ</span>
                            </div>
                          );
                        }

                        return (
                          <button
                            type="button"
                            key={slot.id}
                            onClick={() => handleSlotClick(movieShowtime.movieId, slot)}
                            className={`p-2.5 rounded-xl flex flex-col items-center justify-center min-h-[64px] transition-all relative active:scale-95 ${
                              isChosen
                                ? 'bg-[#202024] text-white border-2 border-[#F5B800] shadow-sm'
                                : 'bg-[#171719] text-white hover:bg-[#202024] border border-[#2B2B30]'
                            }`}
                          >
                            {isChosen && (
                              <div className="absolute -top-1.5 -right-1.5 w-4 h-4 rounded-full bg-[#F5B800] text-black flex items-center justify-center shadow">
                                <span className="material-symbols-outlined text-[12px] font-black">
                                  check
                                </span>
                              </div>
                            )}
                            <span className="text-sm font-extrabold text-white">{slot.time}</span>
                            <span className="text-[10px] mt-0.5 text-[#A1A1AA]">
                              {slot.endTime}
                            </span>
                            <span className="text-[11px] font-bold mt-0.5 text-[#F5B800]">
                              {slot.priceDisplay}
                            </span>
                          </button>
                        );
                      })}
                    </div>
                  </div>
                );
              })}
            </div>
          );
        })}
      </section>

      {/* Sticky Bottom Action Bar - Only shown in booking flow when BottomNav is not present */}
      {!isCalendarTab && (
        <footer
          className="fixed bottom-0 left-0 right-0 z-40 bg-[#121214] border-t border-[#2B2B30] px-4 pt-3.5 shadow-[0_-4px_24px_rgba(0,0,0,0.9)] pointer-events-auto"
          style={{ paddingBottom: 'max(14px, calc(14px + env(safe-area-inset-bottom, 0px)))' }}
        >
          <div className="w-full max-w-md mx-auto flex flex-col min-[390px]:flex-row min-[390px]:items-center justify-between gap-3">
            <div className="flex flex-col min-w-0 flex-1">
              {activeSlot ? (
                <>
                  <div className="flex items-center gap-1.5">
                    <span className="w-1.5 h-1.5 rounded-full bg-[#F5B800] animate-pulse" />
                    <span className="text-[10px] text-[#F5B800] font-bold uppercase tracking-wider">
                      Suất đã chọn
                    </span>
                  </div>
                  <span className="text-sm font-extrabold text-white truncate">
                    {activeSlot.slot.time} • {activeSlot.slot.roomName} ({activeSlot.slot.formatBadge})
                  </span>
                  <span className="text-xs text-[#A1A1AA] truncate">
                    {activeSlot.movie.title} • {activeSlot.slot.priceDisplay}
                  </span>
                </>
              ) : (
                <>
                  <span className="text-xs font-bold text-[#F5B800]">Chưa chọn suất chiếu</span>
                  <span className="text-[11px] text-[#A1A1AA] truncate">
                    Vui lòng bấm chọn một khung giờ chiếu để tiếp tục
                  </span>
                </>
              )}
            </div>

            <button
              type="button"
              disabled={!activeSlot}
              onClick={handleContinueToSeats}
              className={`w-full min-[390px]:w-auto min-[390px]:min-w-[170px] h-[48px] rounded-xl text-xs sm:text-sm font-bold flex items-center justify-center gap-1.5 transition-all shrink-0 select-none ${
                activeSlot
                  ? 'bg-[#F5B800] hover:bg-[#E6AA00] text-black shadow-md active:scale-[0.98] cursor-pointer'
                  : 'bg-[#202024] text-[#71717A] cursor-not-allowed border border-[#2B2B30]'
              }`}
            >
              <span>Tiếp tục: Vé & Ghế</span>
              <span className="material-symbols-outlined text-[18px]">arrow_forward</span>
            </button>
          </div>
        </footer>
      )}
    </div>
  );
};

