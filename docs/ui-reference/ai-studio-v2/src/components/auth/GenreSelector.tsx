import React from 'react';

export interface MovieGenre {
  id: string;
  label: string;
}

export const DEFAULT_GENRES: MovieGenre[] = [
  { id: 'action', label: 'Hành động' },
  { id: 'scifi', label: 'Khoa học viễn tưởng' },
  { id: 'horror', label: 'Kinh dị' },
  { id: 'thriller', label: 'Trinh thám' },
  { id: 'romance', label: 'Tình cảm' },
  { id: 'animation', label: 'Hoạt hình' },
  { id: 'comedy', label: 'Hài kịch' },
];

interface GenreSelectorProps {
  selectedGenreIds: string[];
  onToggleGenre: (genreId: string) => void;
  genres?: MovieGenre[];
}

export const GenreSelector: React.FC<GenreSelectorProps> = ({
  selectedGenreIds,
  onToggleGenre,
  genres = DEFAULT_GENRES,
}) => {
  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-center justify-between">
        <label className="text-xs font-semibold text-[#e5e2e1]">
          Thể loại phim yêu thích
        </label>
        <span className="text-[11px] text-[#9c8f79] font-normal">
          Không bắt buộc
        </span>
      </div>

      {/* Filter chips with responsive wrapping */}
      <div className="flex flex-wrap gap-2 pt-0.5">
        {genres.map((genre) => {
          const isSelected = selectedGenreIds.includes(genre.id);

          return (
            <button
              key={genre.id}
              type="button"
              onClick={() => onToggleGenre(genre.id)}
              aria-pressed={isSelected}
              className={`px-3.5 py-1.5 rounded-full text-xs font-medium transition-all cursor-pointer select-none focus:outline-none ${
                isSelected
                  ? 'bg-[#242014] text-[#F5B800] font-semibold border border-[#F5B800]'
                  : 'bg-[#171719] text-[#D4D4D8] border border-[#2B2B30] hover:border-white/20 hover:text-white'
              }`}
            >
              {genre.label}
            </button>
          );
        })}
      </div>
    </div>
  );
};
