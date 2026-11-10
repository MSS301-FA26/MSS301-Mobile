import React, { useState } from 'react';
import { Movie } from '../types';
import { handleImageError } from '../utils/format';

interface MovieDetailScreenProps {
  movie: Movie;
  onBack: () => void;
  onStartBooking: (movie: Movie) => void;
  onOpenTrailer: (title: string, posterUrl?: string) => void;
}

export const MovieDetailScreen: React.FC<MovieDetailScreenProps> = ({
  movie,
  onStartBooking,
  onOpenTrailer,
}) => {
  const [isFavorite, setIsFavorite] = useState<boolean>(true);
  const [isSynopsisExpanded, setIsSynopsisExpanded] = useState<boolean>(false);
  const [reviewsList, setReviewsList] = useState(movie.reviews || []);
  const [isReviewModalOpen, setIsReviewModalOpen] = useState<boolean>(false);
  const [newReviewText, setNewReviewText] = useState<string>('');
  const [newReviewRating, setNewReviewRating] = useState<number>(10);

  const handleAddReview = () => {
    if (!newReviewText.trim()) return;
    const newRev = {
      id: `rev-${Date.now()}`,
      userName: 'Vy Nguyễn',
      userAvatarBg: 'bg-secondary-container text-secondary',
      date: 'Vừa xong',
      location: 'Chiếu tại CineAI Central',
      rating: newReviewRating,
      verifiedTicket: true,
      comment: newReviewText.trim(),
    };
    setReviewsList([newRev, ...reviewsList]);
    setNewReviewText('');
    setIsReviewModalOpen(false);
  };

  return (
    <div className="flex flex-col w-full text-[#D4D4D8] pb-36">
      {/* Cinematic Hero Banner with Backdrop and Trailer Play */}
      <div className="relative w-full h-72 sm:h-80 overflow-hidden">
        <div
          className="absolute inset-0 bg-cover bg-center scale-105"
          style={{ backgroundImage: `url('${movie.bannerUrl}')` }}
        />
        {/* Layered atmospheric gradient scrims */}
        <div className="absolute inset-0 bg-gradient-to-t from-[#0E0E0F] via-[#0E0E0F]/65 to-transparent" />
        <div className="absolute inset-0 bg-gradient-to-r from-[#0E0E0F]/80 via-transparent to-[#0E0E0F]/40" />

        {/* Floating Favorite Heart Pill */}
        <div className="absolute top-3 right-4 flex items-center gap-2 z-10">
          <button
            id="favBtn"
            onClick={() => setIsFavorite(!isFavorite)}
            className="w-10 h-10 rounded-full bg-[#202024]/80 backdrop-blur-md flex items-center justify-center transition-transform active:scale-90 shadow-md border border-[#2B2B30]"
            aria-label="Thêm vào yêu thích"
          >
            <span
              className={`material-symbols-outlined text-[20px] ${
                isFavorite ? 'text-rose-400 icon-filled' : 'text-[#A1A1AA]'
              }`}
            >
              favorite
            </span>
          </button>
        </div>

        {/* Play Trailer Floating Center Button */}
        <div className="absolute inset-0 flex items-center justify-center">
          <button
            onClick={() => onOpenTrailer(movie.title, movie.bannerUrl)}
            className="group flex items-center gap-2 px-4 py-2.5 rounded-full bg-[#202024]/85 hover:bg-[#202024] backdrop-blur-md shadow-lg transition-all active:scale-95 border border-[#2B2B30]"
          >
            <div className="w-8 h-8 rounded-full bg-[#F5B800] flex items-center justify-center text-black shadow-md group-hover:scale-105 transition-transform">
              <span className="material-symbols-outlined text-[20px] ml-0.5">play_arrow</span>
            </div>
            <span className="text-xs font-bold text-white tracking-wide uppercase">
              Xem Trailer
            </span>
          </button>
        </div>
      </div>

      {/* Movie Header Identity & Poster Mosaic */}
      <div className="px-4 -mt-20 relative z-10 flex flex-col gap-4">
        <div className="flex gap-4 items-end">
          {/* 2:3 Movie Poster */}
          <div className="relative flex-shrink-0 w-28 sm:w-32 aspect-[2/3] rounded-xl overflow-hidden shadow-xl bg-[#171719] border border-[#2B2B30]">
            <img
              src={movie.posterUrl}
              alt={movie.title}
              onError={(e) => handleImageError(e)}
              className="w-full h-full object-cover"
              referrerPolicy="no-referrer"
            />
            <div className="absolute top-2 left-2 px-1.5 py-0.5 rounded bg-[#0E0E0F]/90 backdrop-blur-sm text-[#F5B800] text-[10px] font-extrabold border border-[#2B2B30]">
              {movie.formats[0]?.includes('IMAX') ? 'IMAX' : 'VIP'}
            </div>
          </div>

          {/* Core Movie Details */}
          <div className="flex flex-col gap-1 min-w-0 pb-1">
            <div className="flex items-center gap-1.5 flex-wrap">
              <span className="px-2 py-0.5 rounded bg-[#242014] border border-[#4D3D0A] text-[#F5B800] text-[10px] font-bold">
                {movie.ageRating}
              </span>
              <span className="text-[#A1A1AA] text-xs flex items-center gap-1">
                <span className="material-symbols-outlined text-[13px]">schedule</span>
                {movie.duration}
              </span>
            </div>

            <h1 className="text-2xl font-extrabold text-white leading-tight tracking-tight uppercase truncate">
              {movie.title}
            </h1>

            {/* Rating Highlight */}
            <div className="flex items-center gap-2 mt-0.5">
              <div className="flex items-center gap-1 bg-[#202024] px-2 py-1 rounded-lg border border-[#2B2B30]">
                <span className="material-symbols-outlined text-[#F5B800] text-[16px] icon-filled">
                  star
                </span>
                <span className="text-xs font-bold text-white">{movie.rating}</span>
                <span className="text-[11px] text-[#A1A1AA]">/10</span>
              </div>
              <span className="text-xs text-[#A1A1AA] truncate">
                ({movie.ratingCount || '12.4k đánh giá'})
              </span>
            </div>
          </div>
        </div>

        {/* Genre Tags & Specs Matrix */}
        <div className="flex flex-wrap gap-2 pt-1">
          {movie.genres.map((g) => (
            <span
              key={g}
              className="px-3 py-1 rounded-full bg-[#171719] text-xs text-[#D4D4D8] border border-[#2B2B30]"
            >
              {g}
            </span>
          ))}
          <span className="px-3 py-1 rounded-full bg-[#6f00be]/20 text-[#ddb7ff] text-xs flex items-center gap-1 border border-[#6f00be]/30">
            <span className="material-symbols-outlined text-[14px]">translate</span>
            {movie.audioInfo}
          </span>
        </div>
      </div>

      {/* Key Highlights & Stats Row */}
      <div className="px-4 mt-6">
        <div className="grid grid-cols-3 gap-2 p-3 rounded-xl bg-[#171719] shadow-sm border border-[#2B2B30]">
          <div className="flex flex-col items-center justify-center p-2 text-center">
            <span className="text-[#ddb7ff] text-lg font-extrabold flex items-center gap-0.5">
              {movie.stats?.cineScore || 95}<span className="text-[12px] font-normal">%</span>
            </span>
            <span className="text-[11px] text-[#A1A1AA] mt-0.5">CineScore</span>
          </div>

          <div className="flex flex-col items-center justify-center p-2 text-center bg-[#202024] rounded-lg border border-[#2B2B30]">
            <span className="text-[#F5B800] text-lg font-extrabold">
              {movie.stats?.boxOfficeRank || 'TOP 1'}
            </span>
            <span className="text-[11px] text-[#A1A1AA] mt-0.5">Phòng vé tuần</span>
          </div>

          <div className="flex flex-col items-center justify-center p-2 text-center">
            <span className="text-white text-lg font-extrabold flex items-center gap-0.5">
              2D <span className="text-[10px] text-[#D4D4D8] bg-[#202024] px-1 rounded border border-[#2B2B30]">IMAX</span>
            </span>
            <span className="text-[11px] text-[#A1A1AA] mt-0.5">Định dạng</span>
          </div>
        </div>
      </div>

      {/* Synopsis Section */}
      <div className="px-4 mt-6 flex flex-col gap-2">
        <div className="flex items-center justify-between">
          <h2 className="text-base font-bold text-white flex items-center gap-2">
            <span className="material-symbols-outlined text-[#F5B800] text-[20px]">
              auto_stories
            </span>
            Nội dung phim
          </h2>
        </div>
        <div className="relative bg-[#171719] p-4 rounded-xl border border-[#2B2B30]">
          <p
            className={`text-sm text-[#D4D4D8] leading-relaxed transition-all duration-300 ${
              isSynopsisExpanded ? '' : 'line-clamp-3'
            }`}
          >
            {movie.synopsis}
          </p>
          <button
            onClick={() => setIsSynopsisExpanded(!isSynopsisExpanded)}
            className="mt-2 text-[#F5B800] text-xs font-semibold flex items-center gap-1 hover:underline"
          >
            <span>{isSynopsisExpanded ? 'Thu gọn' : 'Xem thêm'}</span>
            <span
              className={`material-symbols-outlined text-[16px] transition-transform ${
                isSynopsisExpanded ? 'rotate-180' : ''
              }`}
            >
              expand_more
            </span>
          </button>
        </div>
      </div>

      {/* Director & Cast Horizontal Carousel */}
      <div className="mt-6 flex flex-col gap-2">
        <div className="px-4 flex items-center justify-between">
          <h2 className="text-base font-bold text-white flex items-center gap-2">
            <span className="material-symbols-outlined text-[#ddb7ff] text-[20px]">groups</span>
            Đạo diễn & Diễn viên
          </h2>
          <span className="text-xs text-[#A1A1AA]">12 thành viên</span>
        </div>

        <div className="flex gap-4 overflow-x-auto px-4 py-2 scrollbar-none snap-x">
          {/* Director Card */}
          <div className="flex flex-col items-center flex-shrink-0 w-24 snap-start text-center">
            <div className="relative w-[72px] h-[72px] rounded-full overflow-hidden p-0.5 bg-[#F5B800] mb-2 shadow-md">
              <img
                src={movie.director.avatarUrl}
                alt={movie.director.name}
                className="w-full h-full rounded-full object-cover"
              />
              <div className="absolute bottom-0 right-0 w-5 h-5 bg-[#202024] rounded-full flex items-center justify-center text-[#F5B800] shadow border border-[#2B2B30]">
                <span className="material-symbols-outlined text-[12px]">movie_edit</span>
              </div>
            </div>
            <span className="text-xs font-semibold text-white truncate w-full">
              {movie.director.name}
            </span>
            <span className="text-[10px] text-[#F5B800] font-medium">{movie.director.role}</span>
          </div>

          {/* Cast Cards */}
          {movie.cast.map((actor, idx) => (
            <div
              key={idx}
              className="flex flex-col items-center flex-shrink-0 w-24 snap-start text-center"
            >
              <div className="w-[72px] h-[72px] rounded-full overflow-hidden mb-2 bg-[#202024] shadow-md border border-[#2B2B30]">
                <img
                  src={actor.avatarUrl}
                  alt={actor.name}
                  className="w-full h-full object-cover"
                />
              </div>
              <span className="text-xs font-semibold text-white truncate w-full">
                {actor.name}
              </span>
              <span className="text-[10px] text-[#A1A1AA] truncate w-full">{actor.character}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Verified CineScore & Community Reviews */}
      <div className="px-4 mt-6 flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <h2 className="text-base font-bold text-white flex items-center gap-2">
            <span className="material-symbols-outlined text-[#F5B800] text-[20px] icon-filled">
              verified
            </span>
            Khán giả đánh giá
          </h2>
          <button
            onClick={() => setIsReviewModalOpen(true)}
            className="text-xs text-[#F5B800] flex items-center gap-0.5 font-semibold hover:underline"
          >
            Viết nhận xét
            <span className="material-symbols-outlined text-[16px]">rate_review</span>
          </button>
        </div>

        {reviewsList.map((rev) => (
          <div
            key={rev.id}
            className="p-3.5 rounded-xl bg-[#171719] flex flex-col gap-2 border border-[#2B2B30]"
          >
            <div className="flex items-center justify-between">
              <div className="flex items-center gap-2">
                <div
                  className={`w-8 h-8 rounded-full flex items-center justify-center font-bold text-xs ${
                    rev.userAvatarBg || 'bg-[#202024] text-[#D4D4D8]'
                  }`}
                >
                  {rev.userName.slice(0, 2).toUpperCase()}
                </div>
                <div>
                  <div className="text-xs font-semibold text-white flex items-center gap-1.5">
                    {rev.userName}
                    {rev.verifiedTicket && (
                      <span className="px-1.5 py-0.2 rounded bg-[#242014] text-[#F5B800] border border-[#4D3D0A] text-[9px] font-bold">
                        Đã xem vé
                      </span>
                    )}
                  </div>
                  <div className="text-[11px] text-[#A1A1AA]">
                    {rev.date} • {rev.location}
                  </div>
                </div>
              </div>

              <div className="flex items-center text-[#F5B800]">
                <span className="material-symbols-outlined text-[15px] icon-filled">star</span>
                <span className="text-xs font-bold ml-0.5">{rev.rating}/10</span>
              </div>
            </div>

            <p className="text-xs text-[#D4D4D8] leading-relaxed">{rev.comment}</p>
          </div>
        ))}
      </div>

      {/* Sticky Bottom Checkout Bar */}
      <div className="fixed bottom-0 left-0 right-0 z-40 bg-[#0E0E0F]/95 backdrop-blur-xl px-4 py-3 pb-safe shadow-[0_-8px_30px_rgba(0,0,0,0.8)] border-t border-[#2B2B30]">
        <div className="flex items-center justify-between max-w-lg mx-auto gap-4">
          <div className="flex flex-col min-w-0">
            <span className="text-[10px] text-[#A1A1AA] uppercase tracking-wider font-semibold">
              Giá vé chuẩn
            </span>
            <div className="flex items-baseline gap-1">
              <span className="text-lg font-extrabold text-white">Từ 90.000</span>
              <span className="text-xs font-bold text-[#F5B800]">₫</span>
            </div>
            <span className="text-[11px] text-emerald-400 flex items-center gap-1 font-medium">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
              14 suất chiếu hôm nay
            </span>
          </div>

          <button
            onClick={() => onStartBooking(movie)}
            className="flex-1 max-w-[210px] h-[52px] rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] text-black text-base font-bold flex items-center justify-center gap-2 shadow-md active:scale-[0.98] transition-all"
          >
            <span className="material-symbols-outlined text-[22px]">confirmation_number</span>
            <span>Đặt vé ngay</span>
          </button>
        </div>
      </div>

      {/* Review Modal */}
      {isReviewModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#171719] rounded-2xl p-5 w-full max-w-md border border-[#2B2B30] flex flex-col gap-4">
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-lg text-white">Đánh giá phim {movie.title}</h3>
              <button
                onClick={() => setIsReviewModalOpen(false)}
                className="text-[#A1A1AA] hover:text-white"
              >
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>

            <div className="flex items-center gap-2">
              <span className="text-sm text-[#A1A1AA]">Chấm điểm:</span>
              <div className="flex gap-1">
                {[7, 8, 9, 10].map((star) => (
                  <button
                    key={star}
                    onClick={() => setNewReviewRating(star)}
                    className={`px-2.5 py-1 rounded-lg text-xs font-bold transition-all ${
                      newReviewRating === star
                        ? 'bg-[#242014] text-[#F5B800] border border-[#F5B800]'
                        : 'bg-[#202024] text-[#D4D4D8] border border-[#2B2B30]'
                    }`}
                  >
                    {star} ★
                  </button>
                ))}
              </div>
            </div>

            <textarea
              rows={3}
              value={newReviewText}
              onChange={(e) => setNewReviewText(e.target.value)}
              placeholder="Chia sẻ cảm nhận của bạn về phim, kỹ xảo, diễn xuất hoặc âm thanh rạp..."
              className="w-full bg-[#0E0E0F] border border-[#2B2B30] rounded-xl p-3 text-sm text-white placeholder:text-[#71717A] focus:outline-none focus:border-[#F5B800]"
            />

            <button
              onClick={handleAddReview}
              className="h-11 rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] text-black font-bold text-sm shadow-md transition-all"
            >
              Gửi nhận xét
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
