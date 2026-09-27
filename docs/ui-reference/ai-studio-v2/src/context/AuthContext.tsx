import React, { createContext, useContext, useState, useEffect } from 'react';
import { UserProfile, ScreenName } from '../types';

export const DEMO_USER: UserProfile = {
  id: 'usr-alex',
  name: 'Alex Nguyen',
  initials: 'AN',
  email: 'alex.nguyen@cinepremier.vn',
  phone: '0901234567',
  membershipTier: 'Diamond VIP',
  memberCode: 'CP-992-8114',
  joinDate: '2024',
  points: 12850,
  walletBalance: 450000,
};

interface AuthContextType {
  user: UserProfile | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  login: (emailOrPhone: string, password: string, remember?: boolean) => Promise<{ success: boolean; error?: string }>;
  register: (data: { name: string; email: string; phone: string; password: string }) => Promise<{ success: boolean; error?: string }>;
  logout: () => void;
  redirectTarget: ScreenName | null;
  setRedirectTarget: (screen: ScreenName | null) => void;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

const STORAGE_KEY = 'cinepremier_session_user';

export const AuthProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [user, setUser] = useState<UserProfile | null>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEY);
      if (saved) {
        return JSON.parse(saved);
      }
    } catch {
      // Fallback
    }
    // Default to null (Guest) to cleanly showcase guest state and login flow
    return null;
  });

  const [isLoading, setIsLoading] = useState<boolean>(false);
  const [redirectTarget, setRedirectTarget] = useState<ScreenName | null>(null);

  // Sync to localStorage
  useEffect(() => {
    try {
      if (user) {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(user));
      } else {
        localStorage.removeItem(STORAGE_KEY);
      }
    } catch {
      // Ignore localStorage errors
    }
  }, [user]);

  const login = async (
    emailOrPhone: string,
    password: string,
    remember: boolean = true
  ): Promise<{ success: boolean; error?: string }> => {
    setIsLoading(true);

    // Simulate network authentication latency
    await new Promise((resolve) => setTimeout(resolve, 600));

    const trimmedInput = emailOrPhone.trim().toLowerCase();

    // Check if matching demo user
    const isDemoMatch =
      trimmedInput === DEMO_USER.email.toLowerCase() ||
      trimmedInput === DEMO_USER.phone ||
      trimmedInput === 'alex.nguyen@cinepremier.vn' ||
      trimmedInput === '0901234567' ||
      trimmedInput === 'demo';

    if (password.length < 6) {
      setIsLoading(false);
      return { success: false, error: 'Mật khẩu phải có ít nhất 6 ký tự.' };
    }

    if (isDemoMatch) {
      setUser(DEMO_USER);
      setIsLoading(false);
      return { success: true };
    }

    // Accept custom login for testing any account
    const initials = trimmedInput
      .split(/[@.\s_-]/)
      .filter(Boolean)
      .slice(0, 2)
      .map((s) => s[0].toUpperCase())
      .join('') || 'CP';

    const customUser: UserProfile = {
      id: `usr-${Date.now()}`,
      name: emailOrPhone.includes('@') ? emailOrPhone.split('@')[0] : `Người dùng ${emailOrPhone.slice(-4)}`,
      initials: initials.length > 0 ? initials : 'CP',
      email: emailOrPhone.includes('@') ? emailOrPhone : `${emailOrPhone}@cinepremier.vn`,
      phone: emailOrPhone.includes('@') ? '0988888888' : emailOrPhone,
      membershipTier: 'Standard',
      memberCode: `CP-${Math.floor(100 + Math.random() * 900)}-${Math.floor(1000 + Math.random() * 9000)}`,
      joinDate: '2026',
      points: 100,
      walletBalance: 50000,
    };

    setUser(customUser);
    setIsLoading(false);
    return { success: true };
  };

  const register = async (data: {
    name: string;
    email: string;
    phone: string;
    password: string;
  }): Promise<{ success: boolean; error?: string }> => {
    setIsLoading(true);

    // Simulate network registration latency
    await new Promise((resolve) => setTimeout(resolve, 700));

    const nameParts = data.name.trim().split(' ').filter(Boolean);
    let initials = 'CP';
    if (nameParts.length >= 2) {
      initials = `${nameParts[0][0]}${nameParts[nameParts.length - 1][0]}`.toUpperCase();
    } else if (nameParts.length === 1 && nameParts[0].length >= 2) {
      initials = nameParts[0].slice(0, 2).toUpperCase();
    }

    const newUser: UserProfile = {
      id: `usr-${Date.now()}`,
      name: data.name.trim(),
      initials,
      email: data.email.trim(),
      phone: data.phone.trim(),
      membershipTier: 'Standard',
      memberCode: `CP-${Math.floor(100 + Math.random() * 900)}-${Math.floor(1000 + Math.random() * 9000)}`,
      joinDate: '2026',
      points: 200, // Welcome gift points
      walletBalance: 50000, // Welcome gift balance
    };

    setUser(newUser);
    setIsLoading(false);
    return { success: true };
  };

  const logout = () => {
    setUser(null);
    try {
      localStorage.removeItem(STORAGE_KEY);
    } catch {
      // Ignore
    }
  };

  return (
    <AuthContext.Provider
      value={{
        user,
        isAuthenticated: !!user,
        isLoading,
        login,
        register,
        logout,
        redirectTarget,
        setRedirectTarget,
      }}
    >
      {children}
    </AuthContext.Provider>
  );
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (!context) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
