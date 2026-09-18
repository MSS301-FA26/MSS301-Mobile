import React from 'react';

export interface LogoProps {
  /**
   * 'responsive': Compact 'CP' below 768px, Full 'CINEPREMIER' at 768px and above.
   * 'compact': Always show 'CP'.
   * 'full': Always show 'CINEPREMIER'.
   */
  variant?: 'responsive' | 'compact' | 'full';
  onClick?: () => void;
  className?: string;
}

export const Logo: React.FC<LogoProps> = ({
  variant = 'responsive',
  onClick,
  className = '',
}) => {
  const isClickable = !!onClick;
  const Tag = isClickable ? 'button' : 'div';

  // Compact 'CP' emblem for mobile (38-42px)
  const renderCompact = () => (
    <div
      className="w-10 h-10 rounded-xl bg-[#171719] border border-[#2B2B30] hover:border-[#F5B800]/40 flex items-center justify-center shrink-0 shadow-sm transition-colors cursor-pointer select-none"
      title="CinePremier"
    >
      <span className="font-black text-[18px] tracking-tight leading-none flex items-center justify-center">
        <span className="text-white">C</span>
        <span className="text-[#F5B800]">P</span>
      </span>
    </div>
  );

  // Full 'CINEPREMIER' brand wordmark
  const renderFull = () => (
    <div
      className="flex items-baseline font-black text-[21px] sm:text-[22px] tracking-wider leading-none select-none shrink-0 py-1 cursor-pointer"
      title="CinePremier"
    >
      <span className="text-white">CINE</span>
      <span className="text-[#F5B800] ml-0.5">PREMIER</span>
    </div>
  );

  return (
    <Tag
      type={isClickable ? 'button' : undefined}
      onClick={onClick}
      aria-label="CinePremier"
      className={`focus:outline-none transition-transform active:scale-95 flex items-center shrink-0 ${className}`}
    >
      {variant === 'compact' && renderCompact()}
      {variant === 'full' && renderFull()}
      {variant === 'responsive' && (
        <>
          {/* Mobile (< 768px): Compact CP logo */}
          <div className="block md:hidden">
            {renderCompact()}
          </div>
          {/* Desktop & Tablet (>= 768px): Full CINEPREMIER logo */}
          <div className="hidden md:block">
            {renderFull()}
          </div>
        </>
      )}
    </Tag>
  );
};
