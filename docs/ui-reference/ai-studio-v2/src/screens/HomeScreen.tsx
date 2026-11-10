import React, { useState } from 'react';
import { Movie, ScreenName } from '../types';
import { MOVIES } from '../data/mockData';
import { handleImageError } from '../utils/format';

interface HomeScreenProps {
  onNavigate: (screen: ScreenName) => void;
  onSelectMovie: (movie: Movie) => void;
  onOpenTrailer: (movieTitle: string, posterUrl?: string) => void;
  onStartBooking: (movie: Movie) => void;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({
  onNavigate,
  onSelectMovie,
  onOpenTrailer,
  onStartBooking,
}) => {
  const [selectedGenre, setSelectedGenre] = useState<string>('all');
  const [activeHeroIdx, setActiveHeroIdx] = useState<number>(0);
  const [reminders, setReminders] = useState<Record<string, boolean>>({});

  const heroMovies = [
    MOVIES.find((m) => m.id === 'avengers-endgame') || MOVIES[1],
    MOVIES.find((m) => m.id === 'inception') || MOVIES[0],
    MOVIES.find((m) => m.id === 'spider-verse') || MOVIES[3],
  ];

  const currentHero = heroMovies[activeHeroIdx] || heroMovies[0];

  const nowShowingMovies = MOVIES.filter((m) => m.isNowShowing);
  const comingSoonMovies = MOVIES.filter((m) => m.isComingSoon);

  const toggleReminder = (movieId: string) => {
    setReminders((prev) => ({
      ...prev,
      [movieId]: !prev[movieId],
    }));
  };

  const genres = [
    { id: 'all', label: 'Tất cả' },
    { id: 'scifi', label: 'Sci-Fi Cyber' },
    { id: 'noir', label: 'Cinematic Noir' },
    { id: 'animation', label: 'Vision Quest Hoạt hình' },
    { id: 'action', label: 'Pure Action' },
  ];

  const filteredMovies = nowShowingMovies.filter((m) => {
    if (selectedGenre === 'all') return true;
    if (selectedGenre === 'scifi') return m.genres.some((g) => g.includes('Khoa Học') || g.includes('Viễn tưởng'));
    if (selectedGenre === 'noir') return m.genres.some((g) => g.includes('Tội phạm') || g.includes('Tâm lý') || g.includes('Kịch Tính'));
    if (selectedGenre === 'animation') return m.genres.some((g) => g.includes('Hoạt hình') || g.includes('Gia đình'));
    if (selectedGenre === 'action') return m.genres.some((g) => g.includes('Hành Động') || g.includes('Siêu anh hùng'));
    return true;
  });

  return (
    <div className="flex flex-col w-full text-[#D4D4D8] pb-6">
      {/* HERO CAROUSEL: AVENGERS ENDGAME / INCEPTION */}
      <section className="relative w-full overflow-hidden px-4 pb-6 pt-1">
        <div className="relative w-full rounded-2xl overflow-hidden bg-[#171719] shadow-xl border border-[#2B2B30]">
          {/* Backdrop Image with Gradient Scrim */}
          <div
            className="relative w-full h-[370px] bg-cover bg-center flex flex-col justify-end p-4 transition-all duration-500 cursor-pointer"
            style={{ backgroundImage: `url('${currentHero.bannerUrl}')` }}
            onClick={() => onSelectMovie(currentHero)}
          >
            <div className="absolute inset-0 bg-gradient-to-t from-[#0E0E0F] via-[#0E0E0F]/65 to-transparent" />

            {/* Content Overlay */}
            <div className="relative z-10 flex flex-col gap-1">
              {/* Badges / Metadata */}
              <div className="flex items-center gap-2 flex-wrap mb-1">
                <span className="px-2 py-0.5 rounded bg-[#242014] border border-[#4D3D0A] text-[#F5B800] text-[10px] font-bold tracking-wider">
                  {currentHero.ageRating}
                </span>
                <span className="px-2 py-0.5 rounded bg-[#202024]/90 backdrop-blur-md text-[#D4D4D8] text-[10px] font-medium border border-[#2B2B30]">
                  {currentHero.formats[0] || 'IMAX 3D'}
                </span>
                <span className="flex items-center gap-1 text-[#A1A1AA] text-[10px] ml-1">
                  <span className="material-symbols-outlined text-[14px]">schedule</span>
                  {currentHero.duration}
                </span>
                <span className="flex items-center gap-0.5 text-[#F5B800] text-[10px] font-bold ml-auto">
                  <span className="material-symbols-outlined text-[14px] icon-filled">star</span>
                  {currentHero.rating} ({currentHero.ratingCount})
                </span>
              </div>

              {/* Title & Tagline */}
              <h1 className="text-[22px] sm:text-[26px] font-extrabold text-white tracking-tight leading-tight uppercase">
                {currentHero.title}
              </h1>
              <p className="text-xs text-[#A1A1AA] line-clamp-1">
                {currentHero.tagline}
              </p>

              {/* CTAs */}
              <div className="grid grid-cols-2 gap-2 mt-2" onClick={(e) => e.stopPropagation()}>
                <button
                  onClick={() => onStartBooking(currentHero)}
                  className="h-[46px] rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] text-black font-bold text-sm flex items-center justify-center gap-1.5 shadow-md active:scale-[0.98] transition-all"
                >
                  <span className="material-symbols-outlined text-[18px]">confirmation_number</span>
                  Đặt vé ngay
                </button>
                <button
                  onClick={() => onOpenTrailer(currentHero.title, currentHero.bannerUrl)}
                  className="h-[46px] rounded-xl bg-[#202024]/90 hover:bg-[#2B2B30] backdrop-blur-md text-white font-semibold text-sm flex items-center justify-center gap-1.5 transition-colors border border-[#2B2B30]"
                >
                  <span className="material-symbols-outlined text-[18px]">play_circle</span>
                  Xem trailer
                </button>
              </div>
            </div>
          </div>

          {/* Carousel Dots Indicator */}
          <div className="flex items-center justify-center gap-1.5 py-2.5 bg-[#0E0E0F]">
            {heroMovies.map((_, idx) => (
              <button
                key={idx}
                aria-label={`Slide ${idx + 1}`}
                onClick={() => setActiveHeroIdx(idx)}
                className={`transition-all rounded-full ${
                  activeHeroIdx === idx
                    ? 'w-6 h-1.5 bg-[#F5B800]'
                    : 'w-1.5 h-1.5 bg-[#2B2B30] hover:bg-[#71717A]'
                }`}
              />
            ))}
          </div>
        </div>
      </section>

      {/* QUICK ACTION SHORTCUTS */}
      <section className="px-4 pb-6">
        <div className="grid grid-cols-4 gap-2">
          {/* Mua bắp nước */}
          <button
            onClick={() => onNavigate('concessions')}
            className="flex flex-col items-center gap-1.5 p-2 rounded-2xl bg-[#171719] hover:bg-[#202024] transition-all text-center border border-[#2B2B30] group"
          >
            <div className="w-12 h-12 rounded-xl bg-[#6f00be]/30 flex items-center justify-center group-active:scale-95 transition-transform">
              <span className="material-symbols-outlined text-[24px] text-[#ddb7ff]">fastfood</span>
            </div>
            <span className="text-[11px] text-[#D4D4D8] font-semibold text-center leading-tight line-clamp-2 h-7 flex items-center justify-center w-full">
              Bắp & Nước
            </span>
          </button>

          {/* PopBot AI Gợi ý */}
          <button
            onClick={() => onNavigate('popbot')}
            className="flex flex-col items-center gap-1.5 p-2 rounded-2xl bg-[#171719] hover:bg-[#202024] transition-all text-center border border-[#2B2B30] group"
          >
            <div className="w-12 h-12 rounded-xl bg-[#6f00be]/40 flex items-center justify-center group-active:scale-95 transition-transform">
              <span className="material-symbols-outlined text-[24px] text-[#ddb7ff] icon-filled">smart_toy</span>
            </div>
            <span className="text-[11px] text-[#D4D4D8] font-semibold text-center leading-tight line-clamp-2 h-7 flex items-center justify-center w-full">
              PopBot AI
            </span>
          </button>

          {/* Ưu đãi VIP */}
          <button
            onClick={() => onNavigate('account')}
            className="flex flex-col items-center gap-1.5 p-2 rounded-2xl bg-[#171719] hover:bg-[#202024] transition-all text-center border border-[#2B2B30] group"
          >
            <div className="w-12 h-12 rounded-xl bg-[#242014] border border-[#4D3D0A] flex items-center justify-center group-active:scale-95 transition-transform">
              <span className="material-symbols-outlined text-[24px] text-[#F5B800] icon-filled">stars</span>
            </div>
            <span className="text-[11px] text-[#D4D4D8] font-semibold text-center leading-tight line-clamp-2 h-7 flex items-center justify-center w-full">
              Ưu đãi VIP
            </span>
          </button>

          {/* CinePoints / CineWallet */}
          <button
            onClick={() => onNavigate('wallet')}
            className="flex flex-col items-center gap-1.5 p-2 rounded-2xl bg-[#171719] hover:bg-[#202024] transition-all text-center border border-[#2B2B30] group"
          >
            <div className="w-12 h-12 rounded-xl bg-[#202024] border border-[#2B2B30] flex items-center justify-center group-active:scale-95 transition-transform">
              <span className="material-symbols-outlined text-[24px] text-white">loyalty</span>
            </div>
            <span className="text-[11px] text-[#D4D4D8] font-semibold text-center leading-tight line-clamp-2 h-7 flex items-center justify-center w-full">
              CinePoints
            </span>
          </button>
        </div>
      </section>

      {/* NOW SHOWING / PHIM ĐANG CHIẾU */}
      <section className="pb-6">
        {/* Header */}
        <div className="flex items-center justify-between px-4 mb-3">
          <div className="flex items-center gap-2">
            <span className="w-1.5 h-5 rounded-full bg-[#F5B800]" />
            <h2 className="font-bold text-[18px] text-white tracking-tight">
              Phim đang chiếu
            </h2>
          </div>
          <button
            onClick={() => onNavigate('discover')}
            className="text-xs text-[#F5B800] flex items-center gap-0.5 hover:underline font-semibold"
          >
            Xem tất cả
            <span className="material-symbols-outlined text-[16px]">chevron_right</span>
          </button>
        </div>

        {/* Horizontal Poster Scroll */}
        <div className="flex gap-3 overflow-x-auto px-4 scrollbar-none snap-x snap-mandatory">
          {filteredMovies.map((movie) => (
            <div
              key={movie.id}
              onClick={() => onSelectMovie(movie)}
              className="snap-start shrink-0 w-[160px] flex flex-col rounded-2xl overflow-hidden bg-[#171719] p-2 border border-[#2B2B30] cursor-pointer hover:border-[#F5B800]/50 transition-all"
            >
              <div className="relative w-full aspect-[2/3] rounded-xl overflow-hidden mb-2 bg-[#202024]">
                <img
                  src={movie.posterUrl}
                  alt={movie.title}
                  onError={(e) => handleImageError(e)}
                  className="w-full h-full object-cover transition-transform duration-300 hover:scale-105"
                  referrerPolicy="no-referrer"
                />
                <span
                  className={`absolute top-1.5 left-1.5 px-1.5 py-0.5 rounded text-[10px] font-black ${
                    movie.ageRating === '18+'
                      ? 'bg-rose-600/90 text-white'
                      : movie.ageRating === 'P'
                      ? 'bg-emerald-500/90 text-black'
                      : 'bg-[#F5B800] text-black font-bold'
                  }`}
                >
                  {movie.ageRating}
                </span>

                <div className="absolute bottom-1.5 right-1.5 flex items-center gap-0.5 px-1.5 py-0.5 rounded-full bg-[#0E0E0F]/80 backdrop-blur-sm text-[#F5B800] text-[11px] font-bold">
                  <span className="material-symbols-outlined text-[12px] icon-filled">star</span>
                  {movie.rating}
                </div>
              </div>

              <h3 className="text-[13px] font-bold text-white line-clamp-2 h-9 flex items-center leading-snug">
                {movie.title}
              </h3>
              <p className="text-[11px] text-[#A1A1AA] truncate">
                {movie.genres[0]} • {movie.duration}
              </p>

              <button
                onClick={(e) => {
                  e.stopPropagation();
                  onStartBooking(movie);
                }}
                className="mt-2 w-full h-[36px] rounded-lg bg-[#202024] hover:bg-[#F5B800] hover:text-black transition-colors text-white text-xs font-semibold flex items-center justify-center gap-1 active:scale-95 border border-[#2B2B30]"
              >
                <span className="material-symbols-outlined text-[14px]">confirmation_number</span>
                Đặt vé
              </button>
            </div>
          ))}
        </div>
      </section>

      {/* POPBOT AI ASSISTANT BANNER */}
      <section className="px-4 pb-6">
        <div className="relative overflow-hidden rounded-2xl bg-gradient-to-br from-[#171719] via-[#202024] to-[#171719] p-4 border border-[#2B2B30]">
          <div className="relative z-10 flex flex-col gap-3">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-[#ddb7ff] flex items-center justify-center shadow-md">
                <span className="material-symbols-outlined text-[22px] text-[#490080] icon-filled">
                  smart_toy
                </span>
              </div>
              <div>
                <div className="flex items-center gap-1.5">
                  <h3 className="font-bold text-[16px] text-white">PopBot AI</h3>
                  <span className="px-1.5 py-0.2 rounded text-[10px] font-bold bg-[#6f00be] text-[#ddb7ff]">
                    PRO
                  </span>
                </div>
                <p className="text-xs text-[#ddb7ff]">Trợ lý điện ảnh cá nhân hóa</p>
              </div>
            </div>

            <p className="text-xs text-[#D4D4D8] leading-relaxed">
              Chưa biết xem gì tối nay? Nhắn cho PopBot tâm trạng, thể loại ưa thích hoặc bạn đồng hành để nhận ngay rạp & suất chiếu lý tưởng trong 3 giây.
            </p>

            {/* Dynamic Prompt Chips */}
            <div className="flex gap-2 overflow-x-auto scrollbar-none py-1">
              <button
                onClick={() => onNavigate('popbot')}
                className="shrink-0 px-3 py-1.5 rounded-full bg-[#2B2B30] text-[#ddb7ff] text-xs flex items-center gap-1 hover:bg-[#353534] transition-colors"
              >
                <span>✨</span> “Phim hẹn hò cuối tuần”
              </button>
              <button
                onClick={() => onNavigate('popbot')}
                className="shrink-0 px-3 py-1.5 rounded-full bg-[#2B2B30] text-[#ddb7ff] text-xs flex items-center gap-1 hover:bg-[#353534] transition-colors"
              >
                <span>🤯</span> “Hack não như Nolan”
              </button>
            </div>

            <button
              onClick={() => onNavigate('popbot')}
              className="w-full h-[48px] rounded-xl bg-[#6f00be] hover:bg-[#5b009e] text-white font-bold text-sm flex items-center justify-center gap-2 active:scale-[0.99] transition-transform"
            >
              <span className="material-symbols-outlined text-[20px]">chat</span>
              Khám phá cùng PopBot
            </button>
          </div>
        </div>
      </section>

      {/* THỂ LOẠI THỊNH HÀNH */}
      <section className="px-4 pb-6">
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <span className="w-1.5 h-5 rounded-full bg-[#ddb7ff]" />
            <h2 className="font-bold text-[18px] text-white tracking-tight">
              Thể loại thịnh hành
            </h2>
          </div>
        </div>

        <div className="flex gap-2 overflow-x-auto scrollbar-none py-0.5">
          {genres.map((g) => {
            const isSelected = selectedGenre === g.id;
            return (
              <button
                key={g.id}
                onClick={() => setSelectedGenre(g.id)}
                className={`shrink-0 px-4 py-2 rounded-xl text-xs font-bold transition-all ${
                  isSelected
                    ? 'bg-[#202024] text-white border border-[#F5B800]/50 shadow-sm'
                    : 'bg-[#171719] text-[#A1A1AA] hover:text-white border border-[#2B2B30]'
                }`}
              >
                {g.label}
              </button>
            );
          })}
        </div>
      </section>

      {/* PHIM SẮP CHIẾU VIP (COMING SOON) */}
      <section className="pb-6">
        <div className="flex items-center justify-between px-4 mb-3">
          <div>
            <div className="flex items-center gap-2">
              <span className="w-1.5 h-5 rounded-full bg-[#F5B800]" />
              <h2 className="font-bold text-[18px] text-white tracking-tight">
                Phim sắp chiếu VIP
              </h2>
            </div>
            <p className="text-xs text-[#A1A1AA] mt-0.5 ml-3.5">
              Lưu trước thời khắc khởi chiếu và đặt chỗ tiên phong
            </p>
          </div>
          <button
            onClick={() => onNavigate('calendar')}
            className="text-xs text-[#F5B800] flex items-center gap-0.5 hover:underline shrink-0 font-semibold"
          >
            Xem lịch
            <span className="material-symbols-outlined text-[16px]">chevron_right</span>
          </button>
        </div>

        {/* Coming Soon Movie List Cards */}
        <div className="flex flex-col gap-3 px-4">
          {comingSoonMovies.map((movie) => {
            const isReminded = reminders[movie.id];
            return (
              <div
                key={movie.id}
                className="flex gap-3 p-3 rounded-2xl bg-[#171719] border border-[#2B2B30] hover:border-[#F5B800]/30 transition-colors cursor-pointer"
                onClick={() => onSelectMovie(movie)}
              >
                <div className="relative w-24 h-32 rounded-xl overflow-hidden shrink-0 bg-[#202024]">
                  <img
                    src={movie.posterUrl}
                    alt={movie.title}
                    onError={(e) => handleImageError(e)}
                    className="w-full h-full object-cover"
                    referrerPolicy="no-referrer"
                  />
                  <span
                    className={`absolute top-1 left-1 px-1.5 py-0.5 rounded text-[9px] font-bold ${
                      movie.ageRating === '18+'
                        ? 'bg-rose-600/90 text-white'
                        : 'bg-[#0E0E0F]/80 text-[#F5B800]'
                    }`}
                  >
                    {movie.ageRating}
                  </span>
                </div>

                <div className="flex flex-col justify-between flex-1 min-w-0 py-0.5">
                  <div>
                    <div className="flex items-center justify-between gap-1 mb-1">
                      <span className="px-2 py-0.5 rounded-full bg-[#242014] text-[#F5B800] border border-[#4D3D0A] text-[10px] font-semibold">
                        {movie.releaseDate}
                      </span>
                      <span className="text-[#A1A1AA] text-[11px]">{movie.duration}</span>
                    </div>
                    <h3 className="font-bold text-[15px] text-white line-clamp-2 leading-snug min-h-[22px]">
                      {movie.title}
                    </h3>
                    <p className="text-xs text-[#A1A1AA] line-clamp-1 mt-0.5">{movie.genres.join(', ')}</p>
                  </div>

                  <button
                    onClick={(e) => {
                      e.stopPropagation();
                      toggleReminder(movie.id);
                    }}
                    className={`w-full h-[36px] rounded-lg text-xs font-semibold flex items-center justify-center gap-1.5 transition-all ${
                      isReminded
                        ? 'bg-[#242014] text-[#F5B800] border border-[#F5B800]'
                        : 'bg-[#202024] hover:bg-[#2B2B30] text-white border border-[#2B2B30]'
                    }`}
                  >
                    <span
                      className="material-symbols-outlined text-[16px]"
                      style={{ fontVariationSettings: isReminded ? "'FILL' 1" : "'FILL' 0" }}
                    >
                      {isReminded ? 'check_circle' : 'notifications_active'}
                    </span>
                    {isReminded ? 'Đã bật thông báo' : 'Nhắc tôi khi mở bán'}
                  </button>
                </div>
              </div>
            );
          })}
        </div>
      </section>
    </div>
  );
};
