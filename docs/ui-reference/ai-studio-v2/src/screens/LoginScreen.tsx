import React, { useState } from 'react';
import { ScreenName } from '../types';
import { useAuth, DEMO_USER } from '../context/AuthContext';
import { AuthLayout } from '../components/auth/AuthLayout';
import { FormField } from '../components/auth/FormField';
import { PasswordField } from '../components/auth/PasswordField';
import { PrimaryButton } from '../components/auth/PrimaryButton';
import { SocialLoginButton } from '../components/auth/SocialLoginButton';

interface LoginScreenProps {
  onNavigate: (screen: ScreenName) => void;
  onBack?: () => void;
  onSuccess?: () => void;
  onSuccessRedirect?: () => void;
}

export const LoginScreen: React.FC<LoginScreenProps> = ({
  onNavigate,
  onBack,
  onSuccess,
  onSuccessRedirect,
}) => {
  const { login, isLoading } = useAuth();

  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [rememberMe, setRememberMe] = useState(true);
  const [isGoogleLoading, setIsGoogleLoading] = useState(false);

  const [errors, setErrors] = useState<{
    identifier?: string;
    password?: string;
    form?: string;
  }>({});

  const [isForgotPasswordModalOpen, setIsForgotPasswordModalOpen] = useState(false);
  const [forgotEmail, setForgotEmail] = useState('');
  const [forgotSentMessage, setForgotSentMessage] = useState('');

  const handleBackAction = () => {
    if (onBack) {
      onBack();
    } else {
      onNavigate('home');
    }
  };

  const validate = (): boolean => {
    const newErrors: { identifier?: string; password?: string } = {};

    const cleanId = identifier.trim();
    if (!cleanId) {
      newErrors.identifier = 'Vui lòng nhập email hoặc số điện thoại.';
    } else if (cleanId.includes('@')) {
      const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
      if (!emailRegex.test(cleanId)) {
        newErrors.identifier = 'Địa chỉ email không đúng định dạng.';
      }
    } else {
      const phoneRegex = /^[0-9+]{9,12}$/;
      if (!phoneRegex.test(cleanId.replace(/\s+/g, ''))) {
        newErrors.identifier = 'Số điện thoại không hợp lệ (cần 9–11 chữ số).';
      }
    }

    if (!password) {
      newErrors.password = 'Vui lòng nhập mật khẩu.';
    } else if (password.length < 6) {
      newErrors.password = 'Mật khẩu phải có tối thiểu 6 ký tự.';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleLoginSuccess = () => {
    if (onSuccess) {
      onSuccess();
    } else if (onSuccessRedirect) {
      onSuccessRedirect();
    } else {
      onNavigate('account');
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    setErrors({});
    const res = await login(identifier, password, rememberMe);

    if (res.success) {
      handleLoginSuccess();
    } else {
      setErrors({ form: res.error || 'Đăng nhập không thành công. Vui lòng thử lại.' });
    }
  };

  const handleGoogleLogin = async () => {
    setIsGoogleLoading(true);
    setErrors({});

    try {
      // Authenticate via Google profile (Alex Nguyen demo identity)
      const res = await login('alex.nguyen@cinepremier.vn', '123456', true);
      setIsGoogleLoading(false);

      if (res.success) {
        handleLoginSuccess();
      } else {
        setErrors({ form: res.error || 'Đăng nhập bằng Google không thành công.' });
      }
    } catch {
      setIsGoogleLoading(false);
      setErrors({ form: 'Đã có lỗi xảy ra khi kết nối Google. Vui lòng thử lại.' });
    }
  };

  const handleQuickDemoFill = () => {
    setIdentifier(DEMO_USER.email);
    setPassword('123456');
    setErrors({});
  };

  const handleForgotPasswordSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!forgotEmail || !forgotEmail.includes('@')) {
      alert('Vui lòng nhập địa chỉ email hợp lệ để nhận liên kết khôi phục.');
      return;
    }
    setForgotSentMessage(`CinePremier đã gửi hướng dẫn đặt lại mật khẩu đến ${forgotEmail}. Vui lòng kiểm tra hộp thư!`);
  };

  return (
    <AuthLayout
      activeTab="login"
      onTabChange={(tab) => onNavigate(tab === 'login' ? 'login' : 'register')}
      onBack={handleBackAction}
      title="Chào mừng trở lại"
      description="Đăng nhập để đặt vé, quản lý đơn hàng và sử dụng ưu đãi cá nhân."
      maxWidthClass="max-w-[460px]"
    >
      {/* Form Error Banner */}
      {errors.form && (
        <div className="mb-5 p-3 rounded-xl bg-rose-500/15 border border-rose-500/30 flex items-center gap-2.5 text-rose-300 text-xs">
          <span className="material-symbols-outlined text-[18px] text-rose-400 shrink-0">
            error
          </span>
          <span>{errors.form}</span>
        </div>
      )}

      <form onSubmit={handleSubmit} className="flex flex-col gap-4" noValidate>
        {/* Email or Phone field */}
        <FormField
          id="login-identifier"
          label="Email hoặc số điện thoại"
          value={identifier}
          onChange={(e) => {
            setIdentifier(e.target.value);
            if (errors.identifier) setErrors((prev) => ({ ...prev, identifier: undefined }));
          }}
          placeholder="Ví dụ: alex.nguyen@cinepremier.vn"
          icon="person"
          error={errors.identifier}
          autoComplete="username"
        />

        {/* Password field */}
        <PasswordField
          id="login-password"
          label="Mật khẩu"
          value={password}
          onChange={(e) => {
            setPassword(e.target.value);
            if (errors.password) setErrors((prev) => ({ ...prev, password: undefined }));
          }}
          placeholder="Nhập mật khẩu của bạn"
          error={errors.password}
          showForgotPassword={true}
          onForgotPassword={() => {
            setForgotSentMessage('');
            setForgotEmail(identifier.includes('@') ? identifier : '');
            setIsForgotPasswordModalOpen(true);
          }}
          autoComplete="current-password"
        />

        {/* Remember me option */}
        <div className="flex items-center gap-2 pt-0.5">
          <input
            type="checkbox"
            id="rememberMe"
            checked={rememberMe}
            onChange={(e) => setRememberMe(e.target.checked)}
            className="w-4 h-4 rounded border-[#2B2B30] bg-[#0E0E0F] text-[#F5B800] focus:ring-[#F5B800] accent-[#F5B800] cursor-pointer"
          />
          <label
            htmlFor="rememberMe"
            className="text-xs text-[#71717A] hover:text-[#A1A1AA] cursor-pointer select-none"
          >
            Ghi nhớ đăng nhập
          </label>
        </div>

        {/* Primary Submit Button */}
        <div className="pt-2">
          <PrimaryButton
            type="submit"
            isLoading={isLoading && !isGoogleLoading}
            loadingText="Đang đăng nhập..."
          >
            Đăng nhập
          </PrimaryButton>
        </div>

        {/* Divider "Hoặc" */}
        <div className="relative flex items-center justify-center my-2">
          <div className="border-t border-[#2B2B30] w-full" />
          <span className="bg-[#171719] px-3 text-xs text-[#71717A] select-none uppercase tracking-wider font-medium">
            Hoặc
          </span>
          <div className="border-t border-[#2B2B30] w-full" />
        </div>

        {/* Google Login Button */}
        <SocialLoginButton
          onClick={handleGoogleLogin}
          isLoading={isGoogleLoading}
          disabled={isLoading}
        />

        {/* Quick Demo Fill Helper */}
        <div className="mt-2 text-center">
          <button
            type="button"
            onClick={handleQuickDemoFill}
            className="text-xs text-[#71717A] hover:text-[#F5B800] inline-flex items-center gap-1.5 py-1.5 px-3 rounded-full bg-[#202024] hover:bg-[#2B2B30] transition-colors border border-[#2B2B30]"
          >
            <span className="material-symbols-outlined text-[15px] text-[#F5B800]">
              stars
            </span>
            <span>Điền nhanh tài khoản VIP mẫu (Alex Nguyen)</span>
          </button>
        </div>

        {/* Today's Special Offer Mini Card */}
        <div className="mt-3 p-3 rounded-xl bg-[#242014] border border-[#4D3D0A] flex items-center gap-2.5 text-xs text-[#A1A1AA]">
          <span className="material-symbols-outlined text-[18px] text-[#F5B800] shrink-0">
            redeem
          </span>
          <p className="leading-snug">
            <strong className="text-[#F5B800] font-semibold">Ưu đãi hôm nay:</strong> Hoàn tiền 10% cho thành viên khi mua vé trong khung giờ vàng.
          </p>
        </div>

        {/* Switch to Register */}
        <div className="mt-4 text-center text-xs text-[#71717A]">
          <span>Chưa có tài khoản? </span>
          <button
            type="button"
            onClick={() => onNavigate('register')}
            className="text-[#F5B800] hover:underline font-bold focus:outline-none"
          >
            Đăng ký ngay
          </button>
        </div>
      </form>

      {/* Forgot Password Modal */}
      {isForgotPasswordModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4"
          onClick={() => setIsForgotPasswordModalOpen(false)}
        >
          <div
            className="w-full max-w-sm bg-[#171719] border border-[#2B2B30] rounded-2xl p-5 shadow-2xl flex flex-col gap-3 text-[#D4D4D8]"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-2 border-b border-[#2B2B30]">
              <h3 className="font-bold text-sm text-white">Khôi phục mật khẩu</h3>
              <button
                onClick={() => setIsForgotPasswordModalOpen(false)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#71717A] hover:text-white hover:bg-white/5"
              >
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            </div>

            {forgotSentMessage ? (
              <div className="py-3 flex flex-col items-center text-center gap-2">
                <span className="material-symbols-outlined text-[36px] text-emerald-400">check_circle</span>
                <p className="text-xs text-[#D4D4D8]">{forgotSentMessage}</p>
                <button
                  type="button"
                  onClick={() => setIsForgotPasswordModalOpen(false)}
                  className="mt-2 w-full py-2.5 rounded-xl bg-[#F5B800] text-black font-bold text-xs"
                >
                  Đã hiểu
                </button>
              </div>
            ) : (
              <form onSubmit={handleForgotPasswordSubmit} className="flex flex-col gap-3 py-1">
                <p className="text-xs text-[#71717A]">
                  Nhập địa chỉ email đăng ký để nhận mã OTP hoặc liên kết đặt lại mật khẩu của bạn.
                </p>
                <input
                  type="email"
                  value={forgotEmail}
                  onChange={(e) => setForgotEmail(e.target.value)}
                  placeholder="Nhập email của bạn..."
                  className="w-full h-11 bg-[#0E0E0F] border border-[#2B2B30] rounded-xl px-3 text-xs text-white placeholder-[#71717A] focus:outline-none focus:border-[#F5B800]"
                />
                <div className="flex gap-2 mt-2">
                  <button
                    type="button"
                    onClick={() => setIsForgotPasswordModalOpen(false)}
                    className="flex-1 py-2.5 rounded-xl bg-[#202024] text-[#A1A1AA] font-semibold text-xs hover:bg-[#2B2B30] border border-[#2B2B30]"
                  >
                    Hủy
                  </button>
                  <button
                    type="submit"
                    className="flex-1 py-2.5 rounded-xl bg-[#F5B800] text-black font-bold text-xs hover:bg-[#E6AA00]"
                  >
                    Gửi yêu cầu
                  </button>
                </div>
              </form>
            )}
          </div>
        </div>
      )}
    </AuthLayout>
  );
};
