import React from 'react';
import { CINEMA_CONFIG } from '../data/cinemaConfig';

export interface CinemaInfoModalProps {
  isOpen: boolean;
  onClose: () => void;
  onViewShowtimes?: () => void;
  selectedCinemaId?: string;
  onSelectCinema?: (cinemaId: string) => void;
}

export const CinemaInfoModal: React.FC<CinemaInfoModalProps> = ({
  isOpen,
  onClose,
  onViewShowtimes,
}) => {
  if (!isOpen) return null;

  return (
    <div
      id="cinema-info-backdrop"
      className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-end sm:items-center justify-center p-0 sm:p-4 animate-in fade-in duration-200"
    >
      <div className="fixed inset-0" onClick={onClose} aria-hidden="true" />

      <div
        id="cinema-info-sheet"
        style={{
          maxHeight: 'calc(100dvh - max(20px, env(safe-area-inset-top, 20px)))',
        }}
        className="relative z-10 w-full max-w-lg bg-[#171719] rounded-t-3xl sm:rounded-2xl border border-[#2B2B30] shadow-2xl flex flex-col overflow-hidden animate-in slide-in-from-bottom-4 duration-200"
      >
        {/* Pinned Header with Drag Notch */}
        <div className="shrink-0 pt-2.5 px-5 sm:pt-5 sm:px-6 bg-[#171719]">
          {/* Top drag notch on mobile (10px pt + 4px h + 8px mb = 22px to Header) */}
          <div className="w-10 h-1 bg-[#2B2B30] rounded-full mx-auto sm:hidden mb-2" />

          {/* Header row */}
          <div className="flex items-center justify-between border-b border-[#2B2B30] pb-3.5">
            <div className="flex items-center gap-2.5 min-w-0">
              <div className="w-9 h-9 rounded-xl bg-[#202024] border border-[#2B2B30] flex items-center justify-center text-[#F5B800] shrink-0">
                <span className="material-symbols-outlined text-[20px]">apartment</span>
              </div>
              <div className="min-w-0">
                <h3 className="font-bold text-[17px] sm:text-[18px] text-white tracking-tight leading-tight truncate">
                  Thông tin rạp
                </h3>
                <p className="text-xs text-[#A1A1AA] mt-0.5 truncate">Chi nhánh trung tâm CineAI</p>
              </div>
            </div>
            <button
              type="button"
              id="btn-close-cinema-info"
              onClick={onClose}
              aria-label="Đóng bảng thông tin rạp"
              className="w-8 h-8 rounded-full bg-[#202024] hover:bg-[#2B2B30] flex items-center justify-center text-[#D4D4D8] hover:text-white transition-colors focus:outline-none shrink-0 ml-2"
            >
              <span className="material-symbols-outlined text-[18px]">close</span>
            </button>
          </div>
        </div>

        {/* Scrollable Content Body */}
        <div className="flex-1 overflow-y-auto min-h-0 px-5 sm:px-6 py-4 space-y-4">
          {/* Cinema Main Card */}
          <div className="p-4 rounded-2xl bg-[#1C1C1F] border border-[#2B2B30] flex flex-col gap-3">
            <div className="flex items-start justify-between gap-2">
              <div>
                <h4 className="font-extrabold text-lg text-white tracking-tight">
                  {CINEMA_CONFIG.name}
                </h4>
                <div className="flex items-center gap-1.5 mt-1">
                  <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse" />
                  <span className="text-xs font-semibold text-emerald-400">
                    {CINEMA_CONFIG.statusText}
                  </span>
                </div>
              </div>
              <span className="px-2.5 py-1 rounded-full bg-[#242014] border border-[#4D3D0A] text-[#F5B800] text-[10px] font-bold uppercase tracking-wider shrink-0">
                Flagship Cinema
              </span>
            </div>

            {/* Full Address */}
            <div className="flex items-start gap-2.5 pt-2 border-t border-[#2B2B30]/60 text-xs">
              <span className="material-symbols-outlined text-[#F5B800] text-[18px] shrink-0 mt-0.5">
                location_on
              </span>
              <div className="flex flex-col">
                <span className="text-[#71717A] text-[11px] font-semibold">Địa chỉ rạp</span>
                <span className="text-white font-medium leading-relaxed">
                  {CINEMA_CONFIG.address}
                </span>
              </div>
            </div>

            {/* Contact & Hours */}
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 pt-2 border-t border-[#2B2B30]/60 text-xs">
              <div className="flex items-center gap-2 text-[#D4D4D8]">
                <span className="material-symbols-outlined text-[#A1A1AA] text-[16px]">schedule</span>
                <span>{CINEMA_CONFIG.operatingHours}</span>
              </div>
              <div className="flex items-center gap-2 text-[#D4D4D8]">
                <span className="material-symbols-outlined text-[#A1A1AA] text-[16px]">call</span>
                <span>Hotline: {CINEMA_CONFIG.hotline}</span>
              </div>
            </div>
          </div>

          {/* Cinema Amenities & Technologies */}
          <div className="flex flex-col gap-2">
            <span className="text-xs font-bold uppercase tracking-wider text-[#A1A1AA]">
              Tiện ích & Công nghệ rạp
            </span>
            <div className="grid grid-cols-3 gap-2">
              {CINEMA_CONFIG.amenities.map((amenity) => (
                <div
                  key={amenity}
                  className="p-3 rounded-xl bg-[#202024] border border-[#2B2B30] flex flex-col items-center text-center gap-1.5"
                >
                  <span className="material-symbols-outlined text-[#F5B800] text-[20px]">
                    {amenity.includes('IMAX')
                      ? 'smart_display'
                      : amenity.includes('Dolby')
                      ? 'surround_sound'
                      : 'airline_seat_recline_extra'}
                  </span>
                  <span className="text-xs font-bold text-white leading-tight">
                    {amenity}
                  </span>
                </div>
              ))}
            </div>
          </div>

          {/* Screening Rooms */}
          <div className="flex flex-col gap-2">
            <span className="text-xs font-bold uppercase tracking-wider text-[#A1A1AA]">
              Hệ thống phòng chiếu
            </span>
            <div className="flex flex-col gap-2">
              {CINEMA_CONFIG.rooms.map((room) => (
                <div
                  key={room.id}
                  className="p-3 rounded-xl bg-[#202024]/60 border border-[#2B2B30] flex items-center justify-between gap-3 text-xs"
                >
                  <div className="flex flex-col min-w-0">
                    <div className="flex items-center gap-2">
                      <span className="font-extrabold text-white text-[13px]">{room.name}</span>
                      <span className="px-1.5 py-0.5 rounded bg-[#2B2B30] text-[#ddb7ff] text-[10px] font-bold">
                        {room.format}
                      </span>
                    </div>
                    <span className="text-[#71717A] text-[11px] truncate mt-0.5">
                      {room.description}
                    </span>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex items-center gap-3 pt-2 pb-1">
            {onViewShowtimes && (
              <button
                type="button"
                id="btn-view-showtimes-from-info"
                onClick={() => {
                  onClose();
                  onViewShowtimes();
                }}
                className="flex-1 py-3 px-4 rounded-xl bg-[#F5B800] hover:bg-[#d49e00] text-black font-extrabold text-sm flex items-center justify-center gap-2 transition-all active:scale-95 shadow-md"
              >
                <span className="material-symbols-outlined text-[18px]">calendar_month</span>
                <span>Xem lịch chiếu</span>
              </button>
            )}
            <button
              type="button"
              id="btn-dismiss-cinema-info"
              onClick={onClose}
              className={`py-3 px-5 rounded-xl bg-[#202024] hover:bg-[#2B2B30] text-white font-semibold text-sm border border-[#2B2B30] transition-all active:scale-95 ${
                !onViewShowtimes ? 'w-full' : ''
              }`}
            >
              Đóng
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};

// Backwards-compatible alias for CinemaPickerModal
export const CinemaPickerModal = CinemaInfoModal;
