import React from 'react';

interface TrailerModalProps {
  isOpen: boolean;
  onClose: () => void;
  movieTitle?: string;
  posterUrl?: string;
}

export const TrailerModal: React.FC<TrailerModalProps> = ({
  isOpen,
  onClose,
  movieTitle = 'Inception',
  posterUrl = 'https://lh3.googleusercontent.com/aida-public/AB6AXuBDPKu9Mg29oMCm3XdWaVGVUiojMff_qhhOxA0e679hCN3UPaYajB8jm6V0YeKfiiLt7k5Sg2vZ4-jhFt3zhjjTR35MYUCCPKKWHAt-O84T7Z5j_ICqVwRA8nAq-CBxx710ocELRzy72KtMvPZASy36RtRgJvB9TxLR6sY1diBp3KDUTbd_TpuvzzQoQyhUYfSdYuOfSW4m5OEGh8KAfx96GIAvudYpXvWTek_ke0qf9rNxgYpJHo2g',
}) => {
  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 bg-black/90 backdrop-blur-md flex items-center justify-center p-4 animate-in fade-in duration-200">
      <div
        className="fixed inset-0"
        onClick={onClose}
        aria-label="Đóng trailer"
      />
      <div className="relative z-10 w-full max-w-lg bg-[#171719] rounded-2xl overflow-hidden shadow-2xl flex flex-col border border-[#2B2B30]">
        {/* Header */}
        <div className="flex items-center justify-between px-4 py-3 bg-[#202024] border-b border-[#2B2B30]">
          <div className="flex items-center gap-2">
            <span className="material-symbols-outlined text-[#F5B800] text-[20px]">
              smart_display
            </span>
            <span className="font-bold text-[16px] text-white truncate">
              Trailer Chính Thức: {movieTitle}
            </span>
          </div>
          <button
            className="w-8 h-8 rounded-full bg-[#2B2B30] flex items-center justify-center text-[#A1A1AA] hover:text-white transition-colors"
            onClick={onClose}
          >
            <span className="material-symbols-outlined text-[20px]">close</span>
          </button>
        </div>

        {/* Video Screen Preview */}
        <div className="relative aspect-video w-full bg-black flex items-center justify-center overflow-hidden">
          <img
            src={posterUrl}
            alt={`${movieTitle} trailer opening scene`}
            className="w-full h-full object-cover opacity-80"
          />
          <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/40 gap-2">
            <div className="w-16 h-16 rounded-full bg-[#F5B800] flex items-center justify-center text-black shadow-lg cursor-pointer hover:scale-105 transition-transform">
              <span className="material-symbols-outlined text-[36px] ml-1">play_arrow</span>
            </div>
            <span className="text-[13px] font-medium text-white px-3 py-1 rounded-full bg-black/60 backdrop-blur-sm">
              Đang phát trailer 4K IMAX (Dolby 7.1)
            </span>
          </div>
        </div>

        {/* Footer controls */}
        <div className="p-3 bg-[#171719] border-t border-[#2B2B30] flex items-center justify-between text-xs text-[#A1A1AA]">
          <span className="flex items-center gap-1">
            <span className="w-2 h-2 rounded-full bg-emerald-400" /> Bản quyền Warner Bros / CinePremier
          </span>
          <button
            onClick={onClose}
            className="px-3 py-1.5 rounded-lg bg-[#202024] hover:bg-[#2B2B30] text-white font-medium border border-[#2B2B30] transition-colors"
          >
            Đóng
          </button>
        </div>
      </div>
    </div>
  );
};
