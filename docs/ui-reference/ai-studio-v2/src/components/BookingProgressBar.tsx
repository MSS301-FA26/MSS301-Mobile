import React from 'react';

export type BookingStep = 'showtimes' | 'seats' | 'concessions' | 'payment' | 'ticket-types';

interface BookingProgressBarProps {
  currentStep: BookingStep;
  onStepClick?: (step: BookingStep) => void;
}

const STEPS: Array<{ key: 'showtimes' | 'seats' | 'concessions' | 'payment'; label: string; icon: string; index: number }> = [
  { key: 'showtimes', label: 'Suất chiếu', icon: 'schedule', index: 1 },
  { key: 'seats', label: 'Vé & Ghế', icon: 'event_seat', index: 2 },
  { key: 'concessions', label: 'Bắp nước', icon: 'fastfood', index: 3 },
  { key: 'payment', label: 'Thanh toán', icon: 'payment', index: 4 },
];

export const BookingProgressBar: React.FC<BookingProgressBarProps> = ({ currentStep, onStepClick }) => {
  // Normalize legacy step key
  const normalizedKey = currentStep === 'ticket-types' ? 'seats' : currentStep;
  const currentIdx = STEPS.findIndex((s) => s.key === normalizedKey);

  return (
    <div className="w-full bg-[#131315] border-b border-[#2B2B30] px-3 py-2.5">
      <div className="max-w-md mx-auto flex items-center justify-between relative">
        {/* Continuous Connecting Line Background */}
        <div className="absolute top-3.5 left-4 right-4 h-[2px] bg-[#242429] -z-0" />
        {/* Active Connecting Line */}
        <div
          className="absolute top-3.5 left-4 h-[2px] bg-[#F5B800] -z-0 transition-all duration-300"
          style={{
            width: `${Math.max(0, (currentIdx / (STEPS.length - 1)) * 100)}%`,
            maxWidth: 'calc(100% - 32px)',
          }}
        />

        {STEPS.map((step, idx) => {
          const isDone = idx < currentIdx;
          const isCurrent = idx === currentIdx;
          const isPending = idx > currentIdx;
          const isClickable = Boolean(onStepClick && isDone);

          return (
            <div
              key={step.key}
              onClick={() => isClickable && onStepClick?.(step.key)}
              className={`flex flex-col items-center relative z-10 select-none ${
                isClickable ? 'cursor-pointer hover:opacity-90' : ''
              }`}
            >
              {/* Step Circle Indicator */}
              <div
                className={`w-7 h-7 rounded-full flex items-center justify-center text-[11px] font-bold transition-all ${
                  isDone
                    ? 'bg-[#F5B800] text-black shadow-sm ring-2 ring-[#0E0E0F]'
                    : isCurrent
                    ? 'bg-[#0E0E0F] text-[#F5B800] border-2 border-[#F5B800] ring-2 ring-[#0E0E0F]'
                    : 'bg-[#1C1C20] text-[#71717A] border border-[#2B2B30]'
                }`}
              >
                {isDone ? (
                  <span className="material-symbols-outlined text-[16px] font-bold">check</span>
                ) : (
                  <span>{step.index}</span>
                )}
              </div>

              {/* Step Label */}
              <span
                className={`text-[10px] mt-1 font-medium transition-colors ${
                  isCurrent
                    ? 'text-[#F5B800] font-bold'
                    : isDone
                    ? 'text-[#E4E4E7]'
                    : 'text-[#71717A]'
                }`}
              >
                {step.label}
              </span>
            </div>
          );
        })}
      </div>
    </div>
  );
};
