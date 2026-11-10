import React, { useState, useMemo } from 'react';
import { ScreenName } from '../types';
import { HELP_CATEGORIES, FAQ_ITEMS, SUPPORT_CONFIG } from '../data/helpData';

interface HelpScreenProps {
  onNavigate: (screen: ScreenName) => void;
  onBack: () => void;
}

export const HelpScreen: React.FC<HelpScreenProps> = ({ onNavigate, onBack }) => {
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');
  const [expandedId, setExpandedId] = useState<string | null>('faq-1'); // Default first expanded
  const [copiedEmail, setCopiedEmail] = useState(false);
  const [isChatModalOpen, setIsChatModalOpen] = useState(false);

  // Filter FAQs based on query and category
  const filteredFaqs = useMemo(() => {
    let list = FAQ_ITEMS;

    if (selectedCategory !== 'all') {
      list = list.filter((item) => item.categoryId === selectedCategory);
    }

    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      list = list.filter(
        (item) =>
          item.question.toLowerCase().includes(q) ||
          item.answer.toLowerCase().includes(q)
      );
    }

    return list;
  }, [selectedCategory, searchQuery]);

  const toggleAccordion = (id: string) => {
    setExpandedId((prev) => (prev === id ? null : id));
  };

  const handleCopyEmail = () => {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(SUPPORT_CONFIG.email);
    }
    setCopiedEmail(true);
    setTimeout(() => setCopiedEmail(false), 2500);
  };

  return (
    <div className="w-full max-w-2xl mx-auto px-4 py-6 flex flex-col text-[#D4D4D8] pb-12">
      {/* Header Banner */}
      <div className="relative overflow-hidden rounded-3xl bg-[#171719] border border-[#2B2B30] p-5 sm:p-6 mb-6 shadow-sm">
        <div className="flex items-center gap-4">
          <div className="w-14 h-14 rounded-2xl bg-[#242014] border border-[#4D3D0A] flex items-center justify-center text-[#F5B800] shrink-0">
            <span className="material-symbols-outlined text-[32px]">support_agent</span>
          </div>
          <div>
            <h1 className="text-xl sm:text-2xl font-black text-white">
              Trung tâm trợ giúp & CSKH
            </h1>
            <p className="text-xs text-[#A1A1AA] mt-1">
              Giải đáp mọi thắc mắc về đặt vé, chính sách hoàn/đổi, ưu đãi và dịch vụ tại CinePremier.
            </p>
          </div>
        </div>

        {/* Live Search Input */}
        <div className="mt-5 relative">
          <span className="material-symbols-outlined absolute left-3.5 top-1/2 -translate-y-1/2 text-[#71717A] text-[20px]">
            search
          </span>
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Tìm kiếm câu hỏi (ví dụ: hoàn vé, thanh toán, tích điểm, đổi ghế...)"
            className="w-full bg-[#0E0E0F] border border-[#2B2B30] rounded-2xl py-3 pl-11 pr-10 text-xs sm:text-sm text-white placeholder-[#71717A] focus:outline-none focus:border-[#F5B800] transition-all"
          />
          {searchQuery && (
            <button
              type="button"
              onClick={() => setSearchQuery('')}
              className="absolute right-3 top-1/2 -translate-y-1/2 w-6 h-6 rounded-full bg-[#202024] flex items-center justify-center text-[#71717A] hover:text-white"
            >
              <span className="material-symbols-outlined text-[14px]">close</span>
            </button>
          )}
        </div>
      </div>

      {/* Support Category Pills */}
      <div className="flex items-center gap-2 overflow-x-auto pb-2 scrollbar-none mb-6">
        {HELP_CATEGORIES.map((cat) => {
          const isSelected = selectedCategory === cat.id;
          return (
            <button
              key={cat.id}
              type="button"
              onClick={() => setSelectedCategory(cat.id)}
              className={`h-9 px-3.5 rounded-full text-xs font-bold whitespace-nowrap transition-all flex items-center gap-1.5 shrink-0 focus:outline-none ${
                isSelected
                  ? 'bg-[#202024] text-[#F5B800] border border-[#F5B800] shadow-sm'
                  : 'bg-[#171719] border border-[#2B2B30] text-[#A1A1AA] hover:text-white hover:bg-[#202024]'
              }`}
            >
              <span className="material-symbols-outlined text-[16px]">{cat.icon}</span>
              <span>{cat.name}</span>
            </button>
          );
        })}
      </div>

      {/* FAQ List Section */}
      <div className="flex flex-col gap-3">
        <div className="flex items-center justify-between px-1 mb-1">
          <h2 className="text-xs font-bold text-white uppercase tracking-wider">
            Câu hỏi thường gặp ({filteredFaqs.length})
          </h2>
          {searchQuery && (
            <span className="text-[11px] text-[#F5B800]">
              Kết quả cho &ldquo;{searchQuery}&rdquo;
            </span>
          )}
        </div>

        {filteredFaqs.length === 0 ? (
          <div className="py-14 flex flex-col items-center justify-center text-center bg-[#171719] border border-[#2B2B30] rounded-3xl p-6">
            <span className="material-symbols-outlined text-[40px] text-[#71717A] mb-2">
              help_center
            </span>
            <h3 className="text-sm font-bold text-white">Không tìm thấy câu trả lời phù hợp</h3>
            <p className="text-xs text-[#71717A] mt-1 max-w-sm">
              Bạn có thể thử tìm với từ khóa khác hoặc liên hệ trực tiếp với bộ phận chăm sóc khách hàng bên dưới.
            </p>
            <button
              type="button"
              onClick={() => {
                setSearchQuery('');
                setSelectedCategory('all');
              }}
              className="mt-4 px-4 py-2 rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] text-black text-xs font-bold transition-colors"
            >
              Xem tất cả câu hỏi
            </button>
          </div>
        ) : (
          filteredFaqs.map((faq) => {
            const isExpanded = expandedId === faq.id;

            return (
              <div
                key={faq.id}
                className="bg-[#171719] border border-[#2B2B30] rounded-2xl overflow-hidden transition-colors hover:border-[#3F3F46]"
              >
                <button
                  type="button"
                  onClick={() => toggleAccordion(faq.id)}
                  aria-expanded={isExpanded}
                  className="w-full text-left p-4 sm:p-5 flex items-start justify-between gap-3 focus:outline-none"
                >
                  <span className="text-xs sm:text-sm font-bold text-white leading-snug">
                    {faq.question}
                  </span>
                  <div
                    className={`w-7 h-7 rounded-full flex items-center justify-center shrink-0 transition-transform duration-200 ${
                      isExpanded
                        ? 'bg-[#242014] text-[#F5B800] border border-[#4D3D0A] rotate-180'
                        : 'bg-[#202024] text-[#71717A]'
                    }`}
                  >
                    <span className="material-symbols-outlined text-[18px]">expand_more</span>
                  </div>
                </button>

                {isExpanded && (
                  <div className="px-4 sm:px-5 pb-5 pt-0 text-xs sm:text-sm text-[#A1A1AA] leading-relaxed border-t border-[#2B2B30] pt-3 animate-fade-in">
                    <p>{faq.answer}</p>
                  </div>
                )}
              </div>
            );
          })
        )}
      </div>

      {/* Contact Channels Section */}
      <div className="mt-10 pt-8 border-t border-[#2B2B30] flex flex-col gap-4">
        <div>
          <div className="flex items-center gap-2">
            <h2 className="text-sm font-bold text-white uppercase tracking-wider">
              Liên hệ hỗ trợ khách hàng
            </h2>
            <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#202024] text-[#A1A1AA] border border-[#2B2B30]">
              Demo
            </span>
          </div>
          <p className="text-xs text-[#71717A] mt-1">
            Đội ngũ hỗ trợ CinePremier luôn sẵn sàng giải đáp thắc mắc của bạn từ {SUPPORT_CONFIG.workingHours}.
          </p>
        </div>

        <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
          {/* Chat with Support */}
          <button
            type="button"
            onClick={() => setIsChatModalOpen(true)}
            className="p-4 rounded-2xl bg-[#171719] border border-[#2B2B30] hover:border-[#F5B800]/50 flex flex-col items-center text-center gap-2.5 transition-all group active:scale-95"
          >
            <div className="w-11 h-11 rounded-xl bg-[#242014] border border-[#4D3D0A] flex items-center justify-center text-[#F5B800] group-hover:scale-110 transition-transform">
              <span className="material-symbols-outlined text-[24px]">forum</span>
            </div>
            <div className="flex flex-col">
              <span className="text-xs font-bold text-white group-hover:text-[#F5B800] transition-colors">
                Chat với CSKH
              </span>
              <span className="text-[11px] text-[#71717A] mt-0.5">Phản hồi tức thì 24/7</span>
            </div>
          </button>

          {/* Call Hotline */}
          <a
            href={`tel:${SUPPORT_CONFIG.hotline}`}
            className="p-4 rounded-2xl bg-[#171719] border border-[#2B2B30] hover:border-[#F5B800]/50 flex flex-col items-center text-center gap-2.5 transition-all group active:scale-95"
          >
            <div className="w-11 h-11 rounded-xl bg-emerald-500/15 border border-emerald-500/30 flex items-center justify-center text-emerald-400 group-hover:scale-110 transition-transform">
              <span className="material-symbols-outlined text-[24px]">call</span>
            </div>
            <div className="flex flex-col">
              <span className="text-xs font-bold text-white group-hover:text-emerald-400 transition-colors">
                Hotline CSKH
              </span>
              <span className="text-[11px] text-[#F5B800] font-bold mt-0.5">
                {SUPPORT_CONFIG.hotlineDisplay}
              </span>
            </div>
          </a>

          {/* Send Email */}
          <button
            type="button"
            onClick={handleCopyEmail}
            className="p-4 rounded-2xl bg-[#171719] border border-[#2B2B30] hover:border-[#F5B800]/50 flex flex-col items-center text-center gap-2.5 transition-all group active:scale-95 relative"
          >
            <div className="w-11 h-11 rounded-xl bg-blue-500/15 border border-blue-500/30 flex items-center justify-center text-blue-400 group-hover:scale-110 transition-transform">
              <span className="material-symbols-outlined text-[24px]">mail</span>
            </div>
            <div className="flex flex-col">
              <span className="text-xs font-bold text-white group-hover:text-blue-400 transition-colors">
                {copiedEmail ? 'Đã sao chép!' : 'Gửi Email'}
              </span>
              <span className="text-[11px] text-[#71717A] mt-0.5 truncate max-w-[150px]">
                {SUPPORT_CONFIG.email}
              </span>
            </div>
          </button>
        </div>

        {/* Demo Disclaimer Note */}
        <p className="text-[11px] text-[#71717A]/80 italic text-center mt-1">
          * {SUPPORT_CONFIG.note}
        </p>
      </div>

      {/* Interactive CSKH Chat Modal */}
      {isChatModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4"
          onClick={() => setIsChatModalOpen(false)}
        >
          <div
            className="w-full max-w-sm bg-[#171719] border border-[#2B2B30] rounded-3xl p-5 shadow-2xl flex flex-col gap-4 text-[#D4D4D8]"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-3 border-b border-[#2B2B30]">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-full bg-[#242014] border border-[#4D3D0A] text-[#F5B800] flex items-center justify-center">
                  <span className="material-symbols-outlined text-[18px]">support_agent</span>
                </div>
                <div>
                  <h3 className="font-bold text-xs text-white">Chăm sóc khách hàng CinePremier</h3>
                  <span className="text-[10px] text-emerald-400 flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" /> Đang trực tuyến
                  </span>
                </div>
              </div>
              <button
                onClick={() => setIsChatModalOpen(false)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#71717A] hover:text-white hover:bg-[#202024]"
              >
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            </div>

            <div className="py-2 text-xs text-[#A1A1AA] space-y-3 leading-relaxed">
              <p>
                Xin chào! Tôi có thể hỗ trợ bạn kiểm tra vé, chính sách hoàn hủy hoặc tư vấn chương trình ưu đãi đặc biệt hôm nay.
              </p>
              <div className="p-3 rounded-2xl bg-[#0E0E0F] border border-[#2B2B30] text-[11px] text-[#D4D4D8] space-y-1.5">
                <p className="font-bold text-[#F5B800]">Bạn có thể:</p>
                <p>• Bấm vào biểu tượng gọi hotline <strong>1900 8888</strong> để gặp trực tiếp tổng đài viên.</p>
                <p>• Hoặc trò chuyện cùng <strong>Trợ lý điện ảnh PopBot AI</strong> để được giải đáp tức thì về lịch chiếu và gợi ý phim.</p>
              </div>
            </div>

            <div className="flex gap-2 pt-1">
              <button
                type="button"
                onClick={() => {
                  setIsChatModalOpen(false);
                  onNavigate('popbot');
                }}
                className="flex-1 py-2.5 rounded-xl bg-[#F5B800] text-black font-bold text-xs hover:bg-[#E6AA00] flex items-center justify-center gap-1.5 shadow-sm transition-colors"
              >
                <span className="material-symbols-outlined text-[16px]">smart_toy</span>
                <span>Mở PopBot AI</span>
              </button>
              <button
                type="button"
                onClick={() => setIsChatModalOpen(false)}
                className="py-2.5 px-4 rounded-xl bg-[#202024] hover:bg-[#2B2B30] text-white border border-[#2B2B30] font-bold text-xs transition-colors"
              >
                Đóng
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
