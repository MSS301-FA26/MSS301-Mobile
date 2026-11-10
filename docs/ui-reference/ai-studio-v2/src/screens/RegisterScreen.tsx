import React, { useState } from 'react';
import { ScreenName } from '../types';
import { useAuth } from '../context/AuthContext';
import { AuthLayout } from '../components/auth/AuthLayout';
import { FormField } from '../components/auth/FormField';
import { PasswordField } from '../components/auth/PasswordField';
import { PrimaryButton } from '../components/auth/PrimaryButton';
import { AvatarSelector, DEFAULT_AVATARS } from '../components/auth/AvatarSelector';
import { GenreSelector, DEFAULT_GENRES } from '../components/auth/GenreSelector';

interface RegisterScreenProps {
  onNavigate: (screen: ScreenName) => void;
  onBack?: () => void;
  onSuccess?: () => void;
  onSuccessRedirect?: () => void;
}

export const RegisterScreen: React.FC<RegisterScreenProps> = ({
  onNavigate,
  onBack,
  onSuccess,
  onSuccessRedirect,
}) => {
  const { register, isLoading } = useAuth();

  // Nhóm 1: Thông tin tài khoản
  const [fullName, setFullName] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [birthYear, setBirthYear] = useState('');
  const [password, setPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');

  // Nhóm 2: Cá nhân hóa
  const [selectedAvatarId, setSelectedAvatarId] = useState(DEFAULT_AVATARS[0].id);
  const [selectedGenreIds, setSelectedGenreIds] = useState<string[]>([DEFAULT_GENRES[0].id]);

  // Điều khoản & Đồng ý
  const [agreeTerms, setAgreeTerms] = useState(false);
  const [isTermsModalOpen, setIsTermsModalOpen] = useState(false);

  const [errors, setErrors] = useState<{
    fullName?: string;
    phone?: string;
    email?: string;
    birthYear?: string;
    password?: string;
    confirmPassword?: string;
    agreeTerms?: string;
    form?: string;
  }>({});

  const handleBackAction = () => {
    if (onBack) {
      onBack();
    } else {
      onNavigate('home');
    }
  };

  const handleToggleGenre = (genreId: string) => {
    setSelectedGenreIds((prev) =>
      prev.includes(genreId) ? prev.filter((id) => id !== genreId) : [...prev, genreId]
    );
  };

  const validate = (): boolean => {
    const newErrors: {
      fullName?: string;
      phone?: string;
      email?: string;
      birthYear?: string;
      password?: string;
      confirmPassword?: string;
      agreeTerms?: string;
    } = {};

    // 1. Full name
    if (!fullName.trim()) {
      newErrors.fullName = 'Vui lòng nhập họ và tên của bạn.';
    } else if (fullName.trim().length < 2) {
      newErrors.fullName = 'Họ và tên tối thiểu 2 ký tự.';
    }

    // 2. Phone
    const cleanPhone = phone.trim().replace(/\s+/g, '');
    const phoneRegex = /^(0|\+84)[3|5|7|8|9][0-9]{8}$/;
    if (!cleanPhone) {
      newErrors.phone = 'Vui lòng nhập số điện thoại.';
    } else if (!phoneRegex.test(cleanPhone)) {
      newErrors.phone = 'Số điện thoại không hợp lệ (ví dụ: 0901234567).';
    }

    // 3. Email
    const cleanEmail = email.trim();
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!cleanEmail) {
      newErrors.email = 'Vui lòng nhập địa chỉ email.';
    } else if (!emailRegex.test(cleanEmail)) {
      newErrors.email = 'Địa chỉ email không hợp lệ (ví dụ: name@example.com).';
    }

    // 4. Birth year (Optional check if provided)
    if (birthYear.trim()) {
      const yearNum = parseInt(birthYear.trim(), 10);
      const currentYear = new Date().getFullYear();
      if (isNaN(yearNum) || yearNum < 1920 || yearNum > currentYear) {
        newErrors.birthYear = `Năm sinh không hợp lệ (1920–${currentYear}).`;
      }
    }

    // 5. Password
    if (!password) {
      newErrors.password = 'Vui lòng nhập mật khẩu.';
    } else if (password.length < 6) {
      newErrors.password = 'Mật khẩu phải có tối thiểu 6 ký tự.';
    }

    // 6. Confirm password
    if (!confirmPassword) {
      newErrors.confirmPassword = 'Vui lòng xác nhận lại mật khẩu.';
    } else if (confirmPassword !== password) {
      newErrors.confirmPassword = 'Mật khẩu xác nhận không khớp.';
    }

    // 7. Terms agreement
    if (!agreeTerms) {
      newErrors.agreeTerms = 'Bạn cần đồng ý với Điều khoản sử dụng và Chính sách bảo mật.';
    }

    setErrors(newErrors);
    return Object.keys(newErrors).length === 0;
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!validate()) return;

    setErrors({});
    const res = await register({
      name: fullName,
      email,
      phone,
      password,
    });

    if (res.success) {
      if (onSuccess) {
        onSuccess();
      } else if (onSuccessRedirect) {
        onSuccessRedirect();
      } else {
        onNavigate('account');
      }
    } else {
      setErrors({ form: res.error || 'Đăng ký không thành công. Vui lòng thử lại.' });
    }
  };

  return (
    <AuthLayout
      activeTab="register"
      onTabChange={(tab) => onNavigate(tab === 'login' ? 'login' : 'register')}
      onBack={handleBackAction}
      title="Tạo tài khoản"
      description="Đăng ký để đặt vé nhanh hơn, tích CinePoints và nhận ưu đãi từ CinePremier."
      maxWidthClass="max-w-[620px]"
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

      <form onSubmit={handleSubmit} className="flex flex-col gap-6" noValidate>
        {/* Nhóm 1: Thông tin tài khoản */}
        <div className="flex flex-col gap-4">
          <h2 className="text-xs font-bold text-[#d3c5ac] uppercase tracking-wider border-b border-white/5 pb-2">
            1. Thông tin tài khoản
          </h2>

          {/* Desktop 2 columns, Mobile 1 column */}
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <FormField
              id="register-fullname"
              label="Họ và tên"
              value={fullName}
              onChange={(e) => {
                setFullName(e.target.value);
                if (errors.fullName) setErrors((prev) => ({ ...prev, fullName: undefined }));
              }}
              placeholder="Ví dụ: Nguyễn Văn A"
              icon="badge"
              error={errors.fullName}
              autoComplete="name"
            />

            <FormField
              id="register-phone"
              label="Số điện thoại"
              type="tel"
              value={phone}
              onChange={(e) => {
                setPhone(e.target.value);
                if (errors.phone) setErrors((prev) => ({ ...prev, phone: undefined }));
              }}
              placeholder="Ví dụ: 0901234567"
              icon="call"
              error={errors.phone}
              autoComplete="tel"
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <FormField
              id="register-email"
              label="Địa chỉ email"
              type="email"
              value={email}
              onChange={(e) => {
                setEmail(e.target.value);
                if (errors.email) setErrors((prev) => ({ ...prev, email: undefined }));
              }}
              placeholder="name@example.com"
              icon="mail"
              error={errors.email}
              autoComplete="email"
            />

            <FormField
              id="register-birthyear"
              label="Năm sinh"
              type="text"
              value={birthYear}
              onChange={(e) => {
                setBirthYear(e.target.value);
                if (errors.birthYear) setErrors((prev) => ({ ...prev, birthYear: undefined }));
              }}
              placeholder="Ví dụ: 2000"
              icon="cake"
              optional={true}
              helperText="Dùng để xác định độ tuổi xem phim."
              error={errors.birthYear}
            />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <PasswordField
              id="register-password"
              label="Mật khẩu"
              value={password}
              onChange={(e) => {
                setPassword(e.target.value);
                if (errors.password) setErrors((prev) => ({ ...prev, password: undefined }));
              }}
              placeholder="Tối thiểu 6 ký tự"
              helperText="Tối thiểu 6 ký tự."
              error={errors.password}
              autoComplete="new-password"
            />

            <PasswordField
              id="register-confirm-password"
              label="Xác nhận mật khẩu"
              value={confirmPassword}
              onChange={(e) => {
                setConfirmPassword(e.target.value);
                if (errors.confirmPassword)
                  setErrors((prev) => ({ ...prev, confirmPassword: undefined }));
              }}
              placeholder="Nhập lại mật khẩu vừa tạo"
              error={errors.confirmPassword}
              autoComplete="new-password"
              icon="lock_reset"
            />
          </div>
        </div>

        {/* Nhóm 2: Cá nhân hóa */}
        <div className="flex flex-col gap-4">
          <h2 className="text-xs font-bold text-[#A1A1AA] uppercase tracking-wider border-b border-[#2B2B30] pb-2">
            2. Cá nhân hóa trải nghiệm
          </h2>

          <AvatarSelector
            selectedAvatarId={selectedAvatarId}
            onSelectAvatar={setSelectedAvatarId}
          />

          <GenreSelector
            selectedGenreIds={selectedGenreIds}
            onToggleGenre={handleToggleGenre}
          />
        </div>

        {/* Điều khoản sử dụng & Chính sách bảo mật */}
        <div className="flex flex-col gap-1.5 pt-1">
          <div className="flex items-start gap-2.5">
            <input
              type="checkbox"
              id="agreeTerms"
              checked={agreeTerms}
              onChange={(e) => {
                setAgreeTerms(e.target.checked);
                if (errors.agreeTerms) setErrors((prev) => ({ ...prev, agreeTerms: undefined }));
              }}
              className="mt-0.5 w-4 h-4 rounded border-[#2B2B30] bg-[#0E0E0F] text-[#F5B800] focus:ring-[#F5B800] accent-[#F5B800] cursor-pointer shrink-0"
            />
            <label
              htmlFor="agreeTerms"
              className="text-xs text-[#71717A] cursor-pointer select-none leading-relaxed"
            >
              Tôi đồng ý với{' '}
              <button
                type="button"
                onClick={() => setIsTermsModalOpen(true)}
                className="text-[#F5B800] hover:underline font-semibold"
              >
                Điều khoản sử dụng
              </button>{' '}
              và{' '}
              <button
                type="button"
                onClick={() => setIsTermsModalOpen(true)}
                className="text-[#F5B800] hover:underline font-semibold"
              >
                Chính sách bảo mật
              </button>{' '}
              của CinePremier.
            </label>
          </div>
          {errors.agreeTerms && (
            <span className="text-[11px] text-rose-400 font-medium pl-0.5">
              {errors.agreeTerms}
            </span>
          )}
        </div>

        {/* Primary Register Button */}
        <div className="pt-2">
          <PrimaryButton
            type="submit"
            isLoading={isLoading}
            loadingText="Đang tạo tài khoản..."
            disabled={!agreeTerms}
          >
            Tạo tài khoản
          </PrimaryButton>
        </div>

        {/* Switch to Login */}
        <div className="text-center text-xs text-[#71717A]">
          <span>Đã có tài khoản? </span>
          <button
            type="button"
            onClick={() => onNavigate('login')}
            className="text-[#F5B800] hover:underline font-bold focus:outline-none"
          >
            Đăng nhập
          </button>
        </div>
      </form>

      {/* Terms & Conditions Modal */}
      {isTermsModalOpen && (
        <div
          role="dialog"
          aria-modal="true"
          className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4"
          onClick={() => setIsTermsModalOpen(false)}
        >
          <div
            className="w-full max-w-md bg-[#171719] border border-[#2B2B30] rounded-2xl p-5 shadow-2xl flex flex-col gap-3 text-[#D4D4D8] max-h-[80vh]"
            onClick={(e) => e.stopPropagation()}
          >
            <div className="flex items-center justify-between pb-2 border-b border-[#2B2B30]">
              <h3 className="font-bold text-sm text-white">Điều khoản & Chính sách bảo mật</h3>
              <button
                onClick={() => setIsTermsModalOpen(false)}
                className="w-8 h-8 rounded-full flex items-center justify-center text-[#71717A] hover:text-white hover:bg-white/5"
              >
                <span className="material-symbols-outlined text-[20px]">close</span>
              </button>
            </div>

            <div className="overflow-y-auto text-xs text-[#A1A1AA] space-y-3 pr-1 py-1 leading-relaxed">
              <p className="font-semibold text-white">1. Quyền lợi thành viên CinePremier</p>
              <p>
                Tài khoản đăng ký tại hệ thống rạp CinePremier cho phép tích lũy điểm thưởng CinePoints, lưu vé xem phim điện tử và sử dụng các voucher khuyến mãi độc quyền.
              </p>
              <p className="font-semibold text-white">2. Bảo mật thông tin cá nhân</p>
              <p>
                CinePremier cam kết bảo mật tuyệt đối số điện thoại, email và dữ liệu đặt vé của bạn. Thông tin chỉ được sử dụng để gửi mã vé điện tử và hỗ trợ xử lý dịch vụ khách hàng.
              </p>
              <p className="font-semibold text-white">3. Quy định sử dụng vé và đổi/hoàn</p>
              <p>
                Vé đã đặt được lưu dưới dạng mã QR điện tử. Thành viên có quyền hoàn hủy theo chính sách từng hạng thẻ tại mục "Trung tâm trợ giúp".
              </p>
            </div>

            <button
              type="button"
              onClick={() => {
                setAgreeTerms(true);
                setIsTermsModalOpen(false);
                if (errors.agreeTerms) setErrors((prev) => ({ ...prev, agreeTerms: undefined }));
              }}
              className="mt-2 w-full py-2.5 rounded-xl bg-[#F5B800] text-black font-bold text-xs hover:bg-[#E6AA00] transition-colors"
            >
              Tôi đồng ý với điều khoản này
            </button>
          </div>
        </div>
      )}
    </AuthLayout>
  );
};
