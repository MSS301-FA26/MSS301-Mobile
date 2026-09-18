import React from 'react';

interface PrimaryButtonProps {
  type?: 'button' | 'submit' | 'reset';
  onClick?: () => void;
  disabled?: boolean;
  isLoading?: boolean;
  loadingText?: string;
  children: React.ReactNode;
  className?: string;
}

export const PrimaryButton: React.FC<PrimaryButtonProps> = ({
  type = 'submit',
  onClick,
  disabled = false,
  isLoading = false,
  loadingText = 'Đang xử lý...',
  children,
  className = '',
}) => {
  return (
    <button
      type={type}
      onClick={onClick}
      disabled={disabled || isLoading}
      className={`w-full h-12 rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] active:scale-[0.99] text-black font-bold text-sm transition-all flex items-center justify-center gap-2 cursor-pointer disabled:bg-[#202024] disabled:text-[#71717A] disabled:cursor-not-allowed disabled:hover:bg-[#202024] disabled:active:scale-100 ${className}`}
    >
      {isLoading ? (
        <>
          <span className="w-4 h-4 border-2 border-black border-t-transparent rounded-full animate-spin" />
          <span>{loadingText}</span>
        </>
      ) : (
        children
      )}
    </button>
  );
};
