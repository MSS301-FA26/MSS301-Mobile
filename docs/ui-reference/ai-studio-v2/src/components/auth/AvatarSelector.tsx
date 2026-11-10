import React from 'react';

export interface AvatarOption {
  id: string;
  name: string;
  icon: string;
  bgColor?: string;
}

export const DEFAULT_AVATARS: AvatarOption[] = [
  { id: 'critic', name: 'Nhà phê bình', icon: '🎬' },
  { id: 'popcorn', name: 'Tín đồ bắp rang', icon: '🍿' },
  { id: 'astronaut', name: 'Du hành vũ trụ', icon: '🧑‍🚀' },
  { id: 'director', name: 'Đạo diễn', icon: '🎥' },
  { id: 'cinephile', name: 'Cinephile', icon: '🕶️' },
];

interface AvatarSelectorProps {
  selectedAvatarId: string;
  onSelectAvatar: (avatarId: string) => void;
  avatars?: AvatarOption[];
}

export const AvatarSelector: React.FC<AvatarSelectorProps> = ({
  selectedAvatarId,
  onSelectAvatar,
  avatars = DEFAULT_AVATARS,
}) => {
  return (
    <div className="flex flex-col gap-2">
      <div className="flex items-center justify-between">
        <label className="text-xs font-semibold text-[#e5e2e1]">
          Ảnh đại diện điện ảnh
        </label>
        <span className="text-[11px] text-[#9c8f79] font-normal">
          Không bắt buộc
        </span>
      </div>

      {/* Avatar Container: scrollable on mobile, grid on desktop */}
      <div className="flex overflow-x-auto gap-3 py-1 px-0.5 sm:grid sm:grid-cols-5 sm:gap-2.5 sm:overflow-visible no-scrollbar">
        {avatars.map((av) => {
          const isSelected = selectedAvatarId === av.id;

          return (
            <button
              key={av.id}
              type="button"
              onClick={() => onSelectAvatar(av.id)}
              aria-pressed={isSelected}
              className="flex flex-col items-center gap-1.5 focus:outline-none shrink-0 w-20 sm:w-auto group cursor-pointer"
            >
              <div
                className={`w-14 h-14 rounded-full flex items-center justify-center text-2xl transition-all relative select-none ${
                  isSelected
                    ? 'border-2 border-[#F5B800] bg-[#242014] scale-105'
                    : 'border border-[#2B2B30] bg-[#171719] group-hover:border-[#3F3F46] group-hover:bg-[#202024]'
                }`}
              >
                <span>{av.icon}</span>

                {/* Small check badge for selected avatar */}
                {isSelected && (
                  <span className="absolute -top-1 -right-1 w-5 h-5 rounded-full bg-[#F5B800] text-black flex items-center justify-center shadow-md">
                    <span className="material-symbols-outlined text-[13px] font-bold">
                      check
                    </span>
                  </span>
                )}
              </div>

              <span
                className={`text-[11px] text-center font-medium leading-tight line-clamp-1 transition-colors ${
                  isSelected ? 'text-[#F5B800] font-semibold' : 'text-[#71717A] group-hover:text-white'
                }`}
              >
                {av.name}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
};
