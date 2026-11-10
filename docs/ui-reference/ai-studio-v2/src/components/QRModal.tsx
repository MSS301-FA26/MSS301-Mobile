import React from 'react';

interface QRModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  subtitle?: string;
  code?: string;
  note?: string;
}

export const QRModal: React.FC<QRModalProps> = ({
  isOpen,
  onClose,
  title = 'Vé vào rạp điện tử',
  subtitle = 'Inception • Ghế C4, C5',
  code = 'CP-8923-4801',
  note = 'Đưa mã QR này trước máy quét tại cổng soát vé CineAI Central',
}) => {
  if (!isOpen) return null;

  const [copied, setCopied] = React.useState(false);

  const handleCopy = () => {
    navigator.clipboard?.writeText(code);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-end sm:items-center justify-center p-0 sm:p-4 animate-in fade-in duration-200">
      <div className="fixed inset-0" onClick={onClose} />

      <div className="relative z-10 w-full max-w-md bg-[#171719] rounded-t-3xl sm:rounded-2xl p-5 border border-[#2B2B30] shadow-2xl flex flex-col items-center gap-4 text-center">
        {/* Drag handle */}
        <div className="w-10 h-1 bg-[#2B2B30] rounded-full mx-auto sm:hidden" />

        <div className="flex items-center justify-between w-full text-left">
          <div className="flex flex-col">
            <h3 className="font-bold text-[18px] text-white">{title}</h3>
            <p className="text-xs text-[#A1A1AA]">{subtitle}</p>
          </div>
          <button
            onClick={onClose}
            className="w-8 h-8 rounded-full bg-[#202024] flex items-center justify-center text-[#D4D4D8] hover:text-white"
          >
            <span className="material-symbols-outlined text-[18px]">close</span>
          </button>
        </div>

        {/* QR Code Container */}
        <div className="p-4 bg-white rounded-2xl flex flex-col items-center justify-center shadow-lg relative">
          <svg className="w-48 h-48 text-black" fill="currentColor" viewBox="0 0 100 100">
            {/* Top Left Locator */}
            <rect x="2" y="2" width="28" height="28" rx="3" fill="none" stroke="currentColor" strokeWidth="3.5" />
            <rect x="8" y="8" width="16" height="16" rx="2" fill="currentColor" />
            {/* Top Right Locator */}
            <rect x="70" y="2" width="28" height="28" rx="3" fill="none" stroke="currentColor" strokeWidth="3.5" />
            <rect x="76" y="8" width="16" height="16" rx="2" fill="currentColor" />
            {/* Bottom Left Locator */}
            <rect x="2" y="70" width="28" height="28" rx="3" fill="none" stroke="currentColor" strokeWidth="3.5" />
            <rect x="8" y="76" width="16" height="16" rx="2" fill="currentColor" />
            {/* Random Matrix Patterns */}
            <rect x="36" y="6" width="6" height="6" />
            <rect x="46" y="6" width="6" height="6" />
            <rect x="56" y="10" width="8" height="6" />
            <rect x="36" y="16" width="8" height="6" />
            <rect x="48" y="18" width="14" height="6" />
            <rect x="14" y="36" width="10" height="6" />
            <rect x="6" y="46" width="8" height="6" />
            <rect x="20" y="56" width="6" height="6" />
            {/* Center Logo Core */}
            <rect x="34" y="34" width="32" height="32" rx="6" fill="#000000" />
            <circle cx="50" cy="50" r="10" fill="#F5B800" />
            <path d="M47 45 L55 50 L47 55 Z" fill="#000000" />
            {/* Extra Blocks */}
            <rect x="74" y="36" width="6" height="12" />
            <rect x="84" y="42" width="10" height="8" />
            <rect x="70" y="56" width="14" height="6" />
            <rect x="88" y="56" width="6" height="14" />
            <rect x="36" y="72" width="12" height="6" />
            <rect x="54" y="70" width="6" height="12" />
            <rect x="44" y="84" width="16" height="8" />
            <rect x="66" y="80" width="8" height="14" />
            <rect x="80" y="76" width="14" height="6" />
          </svg>
          <div className="absolute inset-x-4 h-0.5 bg-gradient-to-r from-transparent via-[#F5B800] to-transparent animate-pulse top-1/2" />
        </div>

        {/* Code & Copy Button */}
        <div className="flex flex-col items-center gap-1 w-full">
          <button
            onClick={handleCopy}
            className="flex items-center gap-2 px-4 py-1.5 rounded-full bg-[#0E0E0F] text-[#F5B800] text-xs font-mono font-bold hover:bg-[#202024] active:scale-95 transition-all border border-[#2B2B30]"
          >
            <span>{code}</span>
            <span className="material-symbols-outlined text-[16px]">content_copy</span>
          </button>
          {copied && <span className="text-[11px] text-emerald-400 font-semibold">Đã sao chép!</span>}
        </div>

        <p className="text-xs text-[#A1A1AA] max-w-xs">{note}</p>

        <button
          onClick={onClose}
          className="w-full h-11 rounded-xl bg-[#202024] hover:bg-[#2B2B30] text-white font-semibold text-sm transition-colors border border-[#2B2B30]"
        >
          Đóng
        </button>
      </div>
    </div>
  );
};
