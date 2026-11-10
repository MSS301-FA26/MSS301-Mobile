import React, { useState } from 'react';
import { PopBotMessage, Movie } from '../types';
import { MOVIES } from '../data/mockData';
import { handleImageError } from '../utils/format';

interface PopBotScreenProps {
  onSelectMovie: (movie: Movie) => void;
  onStartBooking: (movie: Movie) => void;
}

export const PopBotScreen: React.FC<PopBotScreenProps> = ({
  onSelectMovie,
  onStartBooking,
}) => {
  const inceptionMovie = MOVIES.find((m) => m.id === 'inception') || MOVIES[0];

  const [messages, setMessages] = useState<PopBotMessage[]>([
    {
      id: 'm-1',
      sender: 'popbot',
      text: 'Xin chào Alex! Tôi là PopBot - Trợ lý điện ảnh thông minh của CinePremier. Bạn đang tìm phim theo tâm trạng nào hôm nay, hay muốn tôi gợi ý suất chiếu VIP gần bạn nhất?',
      timestamp: '19:40',
      suggestions: [
        '🎬 Phim giật gân hack não',
        '🍿 Suất chiếu tối nay sau 20:00',
        '💑 Ghế đôi Sweetbox hẹn hò',
        '⭐ Phim có điểm CineScore cao nhất',
      ],
    },
  ]);

  const [inputVal, setInputVal] = useState('');
  const [isTyping, setIsTyping] = useState(false);

  const handleSendMessage = (textToSend?: string) => {
    const text = textToSend || inputVal;
    if (!text.trim()) return;

    const userMsg: PopBotMessage = {
      id: `usr-${Date.now()}`,
      sender: 'user',
      text: text.trim(),
      timestamp: '19:42',
    };

    setMessages((prev) => [...prev, userMsg]);
    if (!textToSend) setInputVal('');
    setIsTyping(true);

    // AI Response simulation
    setTimeout(() => {
      setIsTyping(false);
      const lower = text.toLowerCase();

      let reply: PopBotMessage;

      if (lower.includes('hack não') || lower.includes('nolan') || lower.includes('inception') || lower.includes('kinh điển')) {
        reply = {
          id: `bot-${Date.now()}`,
          sender: 'popbot',
          text: `Dựa trên sở thích của bạn, tôi đề xuất ngay siêu phẩm tái chiếu **INCEPTION (2D Dolby Atmos / IMAX Laser)** của đạo diễn Christopher Nolan. Phim đạt 95% CineScore và suất chiếu 20:30 tối nay tại CineAI Central đang có ghế VIP C4, C5 cực đẹp nhìn thẳng tâm màn hình!`,
          timestamp: '19:42',
          movieCard: {
            movie: inceptionMovie,
            recommendedShowtime: '20:30 • Hôm nay • Phòng C (Dolby Atmos)',
            matchReason: '95% Độ tương thích thể loại Sci-Fi & Tâm lý kịch tính',
          },
        };
      } else if (lower.includes('hẹn hò') || lower.includes('sweetbox') || lower.includes('người yêu')) {
        const lala = MOVIES.find((m) => m.id === 'la-la-land') || MOVIES[6];
        reply = {
          id: `bot-${Date.now()}`,
          sender: 'popbot',
          text: `Dành cho buổi hẹn hò lãng mạn, bạn có thể cân nhắc đặt trước hàng ghế Sweetbox cho tuyệt phẩm **La La Land (4K Remastered)** sắp khởi chiếu, hoặc trải nghiệm Ghế VIP Bed tại CineAI Central với không gian sang trọng và dịch vụ thượng hạng.`,
          timestamp: '19:42',
          movieCard: {
            movie: lala,
            recommendedShowtime: 'Khởi chiếu 12.11 • Phòng Suite VIP Bed',
            matchReason: 'Lý tưởng cho cặp đôi & kỷ niệm ngọt ngào',
          },
        };
      } else {
        const avg = MOVIES.find((m) => m.id === 'avengers-endgame') || MOVIES[1];
        reply = {
          id: `bot-${Date.now()}`,
          sender: 'popbot',
          text: `Tôi tìm thấy các suất chiếu hot nhất tối nay tại CineAI Central! Nếu thích đại tiệc kỹ xảo âm thanh hoành tráng, bạn không nên bỏ lỡ **Avengers: Endgame (IMAX 3D)** hoặc **Spider-Man: Into the Spider-Verse**.`,
          timestamp: '19:43',
          movieCard: {
            movie: avg,
            recommendedShowtime: '20:45 • Phòng B • Standard 2D',
            matchReason: 'Bom tấn giải trí hàng đầu phòng vé tuần',
          },
        };
      }

      setMessages((prev) => [...prev, reply]);
    }, 900);
  };

  return (
    <div className="flex flex-col h-[calc(100vh-64px)] w-full text-[#D4D4D8] max-w-lg mx-auto">
      {/* Bot Identity Sub-header */}
      <div className="px-4 py-2.5 bg-[#171719] border-b border-[#2B2B30] flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="relative">
            <div className="w-8 h-8 rounded-full bg-[#ddb7ff] flex items-center justify-center text-[#490080] shadow">
              <span className="material-symbols-outlined text-[18px] icon-filled">smart_toy</span>
            </div>
            <span className="absolute bottom-0 right-0 w-2.5 h-2.5 rounded-full bg-emerald-400 border-2 border-[#171719]" />
          </div>
          <div>
            <div className="flex items-center gap-1.5">
              <span className="text-xs font-bold text-white">PopBot AI Cinema Assistant</span>
              <span className="px-1.5 py-0.2 rounded bg-[#6f00be] text-[#ddb7ff] text-[9px] font-black">
                PRO
              </span>
            </div>
            <span className="text-[10px] text-emerald-400">Sẵn sàng tư vấn theo thời gian thực</span>
          </div>
        </div>
      </div>

      {/* Messages Scroll Area */}
      <div className="flex-1 overflow-y-auto p-4 flex flex-col gap-4">
        {messages.map((msg) => {
          const isBot = msg.sender === 'popbot';
          return (
            <div
              key={msg.id}
              className={`flex flex-col ${isBot ? 'items-start' : 'items-end'}`}
            >
              <div className="flex items-end gap-2 max-w-[85%]">
                {isBot && (
                  <div className="w-7 h-7 rounded-full bg-[#ddb7ff] flex items-center justify-center text-[#490080] shrink-0 mb-1">
                    <span className="material-symbols-outlined text-[15px] icon-filled">
                      smart_toy
                    </span>
                  </div>
                )}

                <div
                  className={`p-3.5 rounded-2xl text-xs leading-relaxed ${
                    isBot
                      ? 'bg-[#171719] text-[#D4D4D8] rounded-bl-sm border border-[#2B2B30] shadow-sm'
                      : 'bg-[#F5B800] text-black font-medium rounded-br-sm shadow-sm'
                  }`}
                >
                  <p>{msg.text}</p>
                </div>
              </div>

              {/* Recommended Movie Action Card */}
              {msg.movieCard && (
                <div className="mt-2.5 ml-9 max-w-[85%] rounded-2xl bg-[#171719] p-3 border border-[#6f00be]/40 shadow-md flex flex-col gap-2.5">
                  <div className="flex items-center gap-1.5 text-[10px] text-[#ddb7ff] font-bold">
                    <span className="material-symbols-outlined text-[14px]">auto_awesome</span>
                    <span>{msg.movieCard.matchReason}</span>
                  </div>

                  <div className="flex gap-3">
                    <img
                      src={msg.movieCard.movie.posterUrl}
                      alt={msg.movieCard.movie.title}
                      onError={(e) => handleImageError(e)}
                      className="w-14 h-20 rounded-lg object-cover bg-black shrink-0 border border-[#2B2B30]"
                      referrerPolicy="no-referrer"
                    />
                    <div className="flex flex-col justify-between py-0.5 min-w-0">
                      <div>
                        <h4 className="font-extrabold text-sm text-white uppercase line-clamp-2 leading-tight">
                          {msg.movieCard.movie.title}
                        </h4>
                        <span className="text-[11px] text-[#F5B800] font-semibold">
                          ★ {msg.movieCard.movie.rating}/10 • {msg.movieCard.movie.duration}
                        </span>
                      </div>
                      <span className="text-[11px] text-[#A1A1AA] truncate">
                        {msg.movieCard.recommendedShowtime}
                      </span>
                    </div>
                  </div>

                  <div className="grid grid-cols-2 gap-2 pt-1 border-t border-[#2B2B30]">
                    <button
                      onClick={() => onSelectMovie(msg.movieCard!.movie)}
                      className="h-8 rounded-lg bg-[#202024] hover:bg-[#2B2B30] text-white text-[11px] font-semibold flex items-center justify-center transition-colors border border-[#2B2B30]"
                    >
                      Chi tiết
                    </button>
                    <button
                      onClick={() => onStartBooking(msg.movieCard!.movie)}
                      className="h-8 rounded-lg bg-[#F5B800] hover:bg-[#E6AA00] text-black text-[11px] font-black flex items-center justify-center shadow-sm transition-colors"
                    >
                      Đặt vé ngay
                    </button>
                  </div>
                </div>
              )}

              {/* Suggestions chips */}
              {msg.suggestions && (
                <div className="flex flex-wrap gap-1.5 mt-3 ml-9">
                  {msg.suggestions.map((sug, idx) => (
                    <button
                      key={idx}
                      onClick={() => handleSendMessage(sug)}
                      className="px-3 py-1.5 rounded-full bg-[#202024] hover:bg-[#2B2B30] text-[11px] text-[#ddb7ff] font-medium transition-colors border border-[#2B2B30]"
                    >
                      {sug}
                    </button>
                  ))}
                </div>
              )}
            </div>
          );
        })}

        {isTyping && (
          <div className="flex items-center gap-2 text-xs text-[#71717A] ml-9">
            <span className="w-2 h-2 rounded-full bg-[#ddb7ff] animate-bounce" />
            <span className="w-2 h-2 rounded-full bg-[#ddb7ff] animate-bounce [animation-delay:0.2s]" />
            <span className="w-2 h-2 rounded-full bg-[#ddb7ff] animate-bounce [animation-delay:0.4s]" />
            <span>PopBot đang tìm kiếm suất chiếu lý tưởng...</span>
          </div>
        )}
      </div>

      {/* Message Input Bar */}
      <div className="p-3 bg-[#0E0E0F] border-t border-[#2B2B30] pb-safe">
        <form
          onSubmit={(e) => {
            e.preventDefault();
            handleSendMessage();
          }}
          className="flex items-center gap-2"
        >
          <input
            type="text"
            value={inputVal}
            onChange={(e) => setInputVal(e.target.value)}
            placeholder="Hỏi PopBot về phim, suất chiếu, ghế VIP..."
            className="flex-1 h-12 rounded-2xl bg-[#171719] border border-[#2B2B30] px-4 text-xs text-white placeholder:text-[#71717A] focus:outline-none focus:border-[#F5B800]"
          />

          <button
            type="button"
            onClick={() => alert('Đang lắng nghe... Hãy nói yêu cầu của bạn (ví dụ: "Tìm suất chiếu Inception tối nay")')}
            className="w-12 h-12 rounded-2xl bg-[#202024] hover:bg-[#2B2B30] text-[#A1A1AA] flex items-center justify-center transition-colors border border-[#2B2B30]"
          >
            <span className="material-symbols-outlined text-[20px]">mic</span>
          </button>

          <button
            type="submit"
            className="w-12 h-12 rounded-2xl bg-[#F5B800] hover:bg-[#E6AA00] text-black flex items-center justify-center shadow-md active:scale-95 transition-all"
          >
            <span className="material-symbols-outlined text-[20px] font-bold">send</span>
          </button>
        </form>
      </div>
    </div>
  );
};
