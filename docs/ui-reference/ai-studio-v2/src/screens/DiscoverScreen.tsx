import React, { useState } from 'react';
import { Movie } from '../types';
import { MOVIES } from '../data/mockData';
import { handleImageError } from '../utils/format';

interface DiscoverScreenProps {
  onSelectMovie: (movie: Movie) => void;
  onStartBooking: (movie: Movie) => void;
}

export const DiscoverScreen: React.FC<DiscoverScreenProps> = ({
  onSelectMovie,
  onStartBooking,
}) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedFormat, setSelectedFormat] = useState('all');
  const [tab, setTab] = useState<'now' | 'soon'>('now');

  const formats = [
    { id: 'all', label: 'Tất cả định dạng' },
    { id: 'imax', label: 'IMAX Laser' },
    { id: 'atmos', label: 'Dolby Atmos' },
    { id: '3d', label: '3D Digital' },
  ];

  const filteredMovies = MOVIES.filter((m) => {
    if (tab === 'now' && !m.isNowShowing) return false;
    if (tab === 'soon' && !m.isComingSoon) return false;

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase();
      const matchTitle = m.title.toLowerCase().includes(q);
      const matchGenre = m.genres.some((g) => g.toLowerCase().includes(q));
      const matchDirector = m.director.name.toLowerCase().includes(q);
      if (!matchTitle && !matchGenre && !matchDirector) return false;
    }

    if (selectedFormat !== 'all') {
      const matchFmt = m.formats.some((f) =>
        f.toLowerCase().includes(selectedFormat.toLowerCase())
      );
      if (!matchFmt) return false;
    }

    return true;
  });

  return (
    <div className="flex flex-col w-full text-[#D4D4D8] pb-6 p-4 gap-4">
      {/* Search Input Bar */}
      <div className="relative w-full">
        <span className="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-[#71717A] text-[20px]">
          search
        </span>
        <input
          type="text"
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
          placeholder="Tìm tên phim, diễn viên, đạo diễn Nolan..."
          className="w-full h-12 rounded-2xl bg-[#171719] border border-[#2B2B30] pl-11 pr-4 text-xs text-white placeholder:text-[#71717A] focus:outline-none focus:border-[#F5B800]"
        />
        {searchQuery && (
          <button
            onClick={() => setSearchQuery('')}
            className="absolute right-3.5 top-1/2 -translate-y-1/2 text-[#71717A] hover:text-white"
          >
            <span className="material-symbols-outlined text-[18px]">cancel</span>
          </button>
        )}
      </div>

      {/* Tab Switcher: Đang chiếu / Sắp chiếu */}
      <div className="p-1 rounded-2xl bg-[#171719] flex border border-[#2B2B30]">
        <button
          onClick={() => setTab('now')}
          className={`flex-1 py-2 rounded-xl text-xs font-bold transition-all ${
            tab === 'now' ? 'bg-[#F5B800] text-black shadow-sm' : 'text-[#A1A1AA] hover:text-white'
          }`}
        >
          Phim đang chiếu ({MOVIES.filter((m) => m.isNowShowing).length})
        </button>

        <button
          onClick={() => setTab('soon')}
          className={`flex-1 py-2 rounded-xl text-xs font-bold transition-all ${
            tab === 'soon' ? 'bg-[#F5B800] text-black shadow-sm' : 'text-[#A1A1AA] hover:text-white'
          }`}
        >
          Phim sắp chiếu ({MOVIES.filter((m) => m.isComingSoon).length})
        </button>
      </div>

      {/* Format Filter Horizontal Chips */}
      <div className="flex gap-2 overflow-x-auto scrollbar-none py-1">
        {formats.map((f) => (
          <button
            key={f.id}
            onClick={() => setSelectedFormat(f.id)}
            className={`shrink-0 px-3.5 py-1.5 rounded-full text-xs font-semibold transition-all ${
              selectedFormat === f.id
                ? 'bg-[#242014] text-[#F5B800] border border-[#4D3D0A]'
                : 'bg-[#171719] text-[#A1A1AA] border border-[#2B2B30] hover:text-white'
            }`}
          >
            {f.label}
          </button>
        ))}
      </div>

      {/* Movie Grid */}
      <div className="grid grid-cols-2 gap-3 mt-1">
        {filteredMovies.map((movie) => (
          <div
            key={movie.id}
            onClick={() => onSelectMovie(movie)}
            className="rounded-2xl bg-[#171719] p-2.5 border border-[#2B2B30] hover:border-[#3F3F46] transition-all flex flex-col justify-between cursor-pointer group"
          >
            <div>
              <div className="relative w-full aspect-[2/3] rounded-xl overflow-hidden mb-2 bg-black border border-[#2B2B30]">
                <img
                  src={movie.posterUrl}
                  alt={movie.title}
                  onError={(e) => handleImageError(e)}
                  className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                  referrerPolicy="no-referrer"
                />
                <span className="absolute top-1.5 left-1.5 px-1.5 py-0.5 rounded bg-black/80 text-[9px] font-bold text-white">
                  {movie.ageRating}
                </span>

                <div className="absolute bottom-1.5 right-1.5 flex items-center gap-0.5 px-1.5 py-0.5 rounded-full bg-black/80 text-[#F5B800] text-[10px] font-bold">
                  <span className="material-symbols-outlined text-[12px] icon-filled">star</span>
                  {movie.rating}
                </div>
              </div>

              <h4 className="font-bold text-xs text-white uppercase line-clamp-2 h-8 flex items-center leading-snug">
                {movie.title}
              </h4>
              <p className="text-[11px] text-[#A1A1AA] truncate mt-0.5">
                {movie.genres[0]} • {movie.duration}
              </p>
            </div>

            <button
              onClick={(e) => {
                e.stopPropagation();
                onStartBooking(movie);
              }}
              className="mt-2.5 w-full h-8 rounded-lg bg-[#202024] group-hover:bg-[#F5B800] group-hover:text-black text-xs font-semibold text-white flex items-center justify-center gap-1 transition-colors border border-[#2B2B30] active:scale-95"
            >
              <span className="material-symbols-outlined text-[14px]">confirmation_number</span>
              Đặt vé
            </button>
          </div>
        ))}
      </div>
    </div>
  );
};
