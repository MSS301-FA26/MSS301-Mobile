import React from 'react';
import { ScreenName } from '../types';

interface BottomNavProps {
  currentScreen: ScreenName;
  onNavigate: (screen: ScreenName) => void;
  orderCount?: number;
}

export const BottomNav: React.FC<BottomNavProps> = ({
  currentScreen,
  onNavigate,
  orderCount = 1,
}) => {
  // Global Bottom Navigation is strictly restricted to the 5 primary tabs:
  // Trang chủ, Khám phá, Lịch chiếu, Đơn của tôi, Tài khoản.
  // It is automatically hidden during all booking transactional steps.
  const allowedScreens: ScreenName[] = [
    'home',
    'discover',
    'calendar',
    'orders',
    'account',
  ];

  if (!allowedScreens.includes(currentScreen)) {
    return null;
  }

  const navItems = [
    {
      id: 'home' as ScreenName,
      label: 'Trang chủ',
      icon: 'home',
    },
    {
      id: 'discover' as ScreenName,
      label: 'Khám phá',
      icon: 'explore',
    },
    {
      id: 'calendar' as ScreenName,
      label: 'Lịch chiếu',
      icon: 'calendar_month',
    },
    {
      id: 'orders' as ScreenName,
      label: 'Đơn của tôi',
      icon: 'confirmation_number',
      badge: orderCount > 0 ? orderCount : undefined,
    },
    {
      id: 'account' as ScreenName,
      label: 'Tài khoản',
      icon: 'account_circle',
    },
  ];

  return (
    <nav className="fixed bottom-0 left-0 right-0 z-40 pb-safe bg-[#0E0E0F]/95 backdrop-blur-xl border-t border-[#2B2B30] shadow-lg">
      <div className="flex justify-around items-center h-16 px-2 max-w-lg mx-auto">
        {navItems.map((item) => {
          const isActive = currentScreen === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onNavigate(item.id)}
              className={`flex flex-col items-center justify-center min-w-[56px] h-12 py-1 px-2 rounded-xl transition-all active:scale-95 ${
                isActive
                  ? 'text-[#F5B800] font-semibold'
                  : 'text-[#A1A1AA] hover:text-white'
              }`}
            >
              <div className="relative flex items-center justify-center">
                <span
                  className="material-symbols-outlined text-[22px]"
                  style={{ fontVariationSettings: isActive ? "'FILL' 1" : "'FILL' 0" }}
                >
                  {item.icon}
                </span>
                {item.badge && (
                  <span className="absolute -top-1 -right-2 bg-[#F5B800] text-black text-[9px] font-black w-4 h-4 rounded-full flex items-center justify-center shadow-sm">
                    {item.badge}
                  </span>
                )}
              </div>
              <span className="text-[10px] mt-0.5 tracking-tight">{item.label}</span>
            </button>
          );
        })}
      </div>
    </nav>
  );
};
