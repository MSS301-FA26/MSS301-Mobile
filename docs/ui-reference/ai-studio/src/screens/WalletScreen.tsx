import React, { useState } from 'react';
import { WALLET_TRANSACTIONS } from '../data/mockData';
import { WalletTransaction } from '../types';

interface WalletScreenProps {
  onBack: () => void;
}

export const WalletScreen: React.FC<WalletScreenProps> = () => {
  const [balance, setBalance] = useState(450000);
  const [points, setPoints] = useState(12850);
  const [transactions, setTransactions] = useState<WalletTransaction[]>(WALLET_TRANSACTIONS);
  const [depositAmount, setDepositAmount] = useState<number>(200000);
  const [isDepositModalOpen, setIsDepositModalOpen] = useState(false);

  const handleDeposit = () => {
    setBalance((prev) => prev + depositAmount);
    const newTx: WalletTransaction = {
      id: `tx-${Date.now()}`,
      title: `Nạp tiền ví CineWallet qua VietQR`,
      type: 'deposit',
      dateStr: 'Vừa xong',
      badgeText: 'Thành công',
      amountDisplay: `+${depositAmount.toLocaleString('vi-VN')} ₫`,
      isPositive: true,
    };
    setTransactions([newTx, ...transactions]);
    setIsDepositModalOpen(false);
    alert(`Nạp ${depositAmount.toLocaleString('vi-VN')} ₫ vào ví CineWallet thành công!`);
  };

  const handleRedeemPoints = () => {
    if (points < 2000) {
      alert('Bạn cần tối thiểu 2.000 CinePoints để đổi voucher.');
      return;
    }
    setPoints((prev) => prev - 2000);
    const newTx: WalletTransaction = {
      id: `tx-${Date.now()}`,
      title: 'Đổi 1 Vé Xem Phim Miễn Phí 2D',
      type: 'points',
      dateStr: 'Vừa xong',
      badgeText: 'Đổi quà VIP',
      amountDisplay: '-2.000 pts',
      isPositive: false,
      isPoints: true,
    };
    setTransactions([newTx, ...transactions]);
    alert('Đổi thành công 1 Vé Xem Phim 2D Standard vào kho voucher của bạn!');
  };

  return (
    <div className="flex flex-col w-full text-[#D4D4D8] pb-20 p-4 gap-4">
      {/* Wallet Balance Hero Card */}
      <div className="p-5 rounded-3xl bg-[#171719] border border-[#2B2B30] shadow-sm flex flex-col gap-4">
        <div className="flex items-center justify-between">
          <div className="flex items-center gap-2 text-xs text-[#A1A1AA]">
            <span className="material-symbols-outlined text-[#F5B800] text-[18px]">
              account_balance_wallet
            </span>
            <span>Ví điện tử CineWallet</span>
          </div>
          <span className="px-2 py-0.5 rounded-full bg-emerald-500/20 text-emerald-400 text-[10px] font-bold">
            Hoạt động
          </span>
        </div>

        <div>
          <span className="text-xs text-[#71717A]">Số dư khả dụng</span>
          <div className="flex items-baseline gap-1 mt-0.5">
            <span className="text-3xl font-black text-white">
              {balance.toLocaleString('vi-VN')}
            </span>
            <span className="text-base font-bold text-[#F5B800]">₫</span>
          </div>
        </div>

        <div className="grid grid-cols-2 gap-2 pt-2 border-t border-[#2B2B30]">
          <button
            onClick={() => setIsDepositModalOpen(true)}
            className="h-11 rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] text-black text-xs font-bold flex items-center justify-center gap-1.5 shadow-sm active:scale-95 transition-all"
          >
            <span className="material-symbols-outlined text-[18px]">add_card</span>
            Nạp tiền ví
          </button>

          <button
            onClick={() => alert('Yêu cầu rút tiền về tài khoản ngân hàng sẽ được xử lý trong 5 phút.')}
            className="h-11 rounded-xl bg-[#202024] hover:bg-[#2B2B30] text-white text-xs font-semibold flex items-center justify-center gap-1.5 border border-[#2B2B30] transition-colors"
          >
            <span className="material-symbols-outlined text-[18px]">payments</span>
            Rút tiền
          </button>
        </div>
      </div>

      {/* CinePoints Card */}
      <div className="p-4 rounded-2xl bg-[#171719] border border-[#2B2B30] flex items-center justify-between">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-[#6f00be]/40 flex items-center justify-center text-[#ddb7ff]">
            <span className="material-symbols-outlined text-[22px]">stars</span>
          </div>
          <div>
            <div className="text-xs text-[#A1A1AA]">CinePoints thưởng</div>
            <div className="text-lg font-black text-[#ddb7ff]">{points.toLocaleString()} pts</div>
          </div>
        </div>

        <button
          onClick={handleRedeemPoints}
          className="px-3.5 py-1.5 rounded-xl bg-[#6f00be] hover:bg-[#6900b3] text-white text-xs font-bold transition-colors"
        >
          Đổi quà
        </button>
      </div>

      {/* Transaction History */}
      <div className="flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <h3 className="font-bold text-base text-white flex items-center gap-2">
            <span className="material-symbols-outlined text-[#F5B800] text-[20px]">
              history
            </span>
            Lịch sử giao dịch
          </h3>
          <span className="text-xs text-[#71717A]">Gần đây</span>
        </div>

        <div className="flex flex-col gap-2">
          {transactions.map((tx) => (
            <div
              key={tx.id}
              className="p-3.5 rounded-xl bg-[#171719] border border-[#2B2B30] flex items-center justify-between"
            >
              <div className="flex items-center gap-3">
                <div
                  className={`w-9 h-9 rounded-xl flex items-center justify-center text-sm ${
                    tx.isPositive
                      ? 'bg-emerald-500/20 text-emerald-400'
                      : 'bg-rose-500/20 text-rose-400'
                  }`}
                >
                  <span className="material-symbols-outlined text-[18px]">
                    {tx.isPositive ? 'arrow_downward' : 'arrow_upward'}
                  </span>
                </div>
                <div className="flex flex-col">
                  <span className="font-semibold text-xs text-white truncate max-w-[190px]">
                    {tx.title}
                  </span>
                  <span className="text-[10px] text-[#71717A] mt-0.5">{tx.dateStr}</span>
                </div>
              </div>

              <div className="text-right">
                <span
                  className={`font-black text-sm ${
                    tx.isPoints
                      ? 'text-[#ddb7ff]'
                      : tx.isPositive
                      ? 'text-emerald-400'
                      : 'text-white'
                  }`}
                >
                  {tx.amountDisplay}
                </span>
                <div className="text-[10px] text-[#71717A]">{tx.badgeText}</div>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Deposit Modal */}
      {isDepositModalOpen && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-sm flex items-center justify-center p-4">
          <div className="bg-[#171719] rounded-2xl p-5 w-full max-w-sm border border-[#2B2B30] flex flex-col gap-4">
            <div className="flex items-center justify-between">
              <h3 className="font-bold text-base text-white">Nạp tiền ví CineWallet</h3>
              <button
                onClick={() => setIsDepositModalOpen(false)}
                className="text-[#71717A] hover:text-white"
              >
                <span className="material-symbols-outlined">close</span>
              </button>
            </div>

            <p className="text-xs text-[#A1A1AA]">Chọn mệnh giá nạp nhanh qua VietQR hoặc Ví:</p>

            <div className="grid grid-cols-2 gap-2">
              {[100000, 200000, 500000, 1000000].map((amt) => (
                <button
                  key={amt}
                  onClick={() => setDepositAmount(amt)}
                  className={`p-3 rounded-xl text-xs font-bold border transition-all ${
                    depositAmount === amt
                      ? 'bg-[#242014] border-[#F5B800] text-[#F5B800]'
                      : 'bg-[#202024] border-[#2B2B30] text-[#A1A1AA]'
                  }`}
                >
                  {amt.toLocaleString('vi-VN')} ₫
                  {amt === 1000000 && (
                    <span className="block text-[9px] text-emerald-400">+50k tặng</span>
                  )}
                </button>
              ))}
            </div>

            <button
              onClick={handleDeposit}
              className="h-11 rounded-xl bg-[#F5B800] hover:bg-[#E6AA00] text-black font-bold text-sm shadow-sm"
            >
              Xác nhận nạp {depositAmount.toLocaleString('vi-VN')} ₫
            </button>
          </div>
        </div>
      )}
    </div>
  );
};
