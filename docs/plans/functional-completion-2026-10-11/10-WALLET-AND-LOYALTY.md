# 10 — Wallet withdrawal và loyalty

Trạng thái: **pending**. Ưu tiên: cao cho withdrawal, trung bình cho phần mở rộng.

## Việc cần làm

- Triển khai POST `/api/v1/wallet/withdrawals`; nút hiện không được báo như thao tác chạy được khi mutation chưa có.
- Thay bankName/accountHolder/accountNumber mẫu bằng form thật theo DTO BE; validation amount/balance/bank/account và confirmation.
- Khóa gửi lặp, map lỗi, refresh số dư/history; đối chiếu idempotency trước cho retry mutation.
- Phân trang transactions/withdrawals; thêm loading/error/retry ở Wallet thay spinner vô hạn.
- Loyalty read/config/redeem hiện đã có: kiểm tra lại quy tắc đổi và nội dung xác nhận, không đánh dấu là việc chưa triển khai.
- Lịch sử điểm cần customer endpoint/contract; admin transactions không dùng cho khách hàng.
- Loyalty tại checkout là batch riêng: chốt reserve/deduct/rollback, expiry/refund và giá quote trước mở tính năng.

## Scope dự kiến

Account remote repositories, wallet/points pages, providers và history DTO.

## Tiêu chí hoàn thành và kiểm chứng

- Withdrawal lưu đúng thông tin thật, số dư/history phản ánh server; thiếu tiền/lỗi mạng không giả thành công.
- Lịch sử hơn 20 dòng và thử lại tải lỗi hoạt động; redeem hiện có không bị regression.
- Phần history/checkout thiếu contract giữ pending/blocked riêng, không ngăn hoàn thành batch withdrawal.
