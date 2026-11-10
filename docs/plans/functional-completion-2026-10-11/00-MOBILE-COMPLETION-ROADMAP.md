# Mobile completion roadmap

Trạng thái: **pending**. Ngày rà soát: 2026-10-11.

Mốc source: Mobile `600298d`, Backend `9f4d53a`. Đây là backlog từ static review; mức độ ảnh hưởng cần xác nhận khi chạy hệ thống. Phạm vi BE tích hợp là `cinema-services` qua API Gateway.

| Flow | Phần còn thiếu hoặc lỗi trong source | Plan |
| --- | --- | --- |
| Đăng nhập/đăng ký/OTP | Form email chưa nhận username; chưa Google; thiếu trường đăng ký; validation mật khẩu lệch BE; chưa resend OTP; chưa khóa gửi lặp; verify email chưa tạo phiên. | [01](01-AUTH-AND-RECOVERY.md) |
| Quên mật khẩu | Chưa resend/sửa email ở bước OTP; chưa xác nhận mật khẩu; cần đối chiếu validation và Google password setup. | [01](01-AUTH-AND-RECOVERY.md) |
| Hồ sơ | Provider vẫn dùng mock và DemoIds; thiếu remote profile, avatar và các trường mới; thiếu error/retry. | [02](02-PROFILE-AND-SECURITY.md) |
| Đổi mật khẩu | Chỉ hiện thông báo mock thành công, chưa gọi API. | [02](02-PROFILE-AND-SECURITY.md) |
| Home/Discover | Chưa hero banner thật; rating gán 0; số lượng hai tab dùng chung giá trị; lỗi load more bị bỏ qua. | [03](03-CATALOG-AND-CINEMA.md) |
| Rạp/suất chiếu | Thiếu chọn/lọc rạp và rạp ưu tiên; thông tin rạp cố định; selector chỉ bảy ngày. | [03](03-CATALOG-AND-CINEMA.md) |
| Movie detail | Trailer là ảnh; reviews chỉ đọc, chưa phân trang/mutation; gợi ý AI lệch envelope; lỗi sections bị ẩn. | [04](04-MOVIE-ENGAGEMENT.md) |
| Vé/ghế/hold | Thiếu phục hồi sau restart; leave guard chưa áp dụng mọi lối thoát; cancel thất bại vẫn về Home; tuổi đại diện cần đối chiếu nghiệp vụ. | [05](05-BOOKING-SESSION.md) |
| Bắp nước kèm vé | Remote không tải sản phẩm; food methods chưa triển khai; chưa gọi items update trong remote. | [06](06-CONCESSIONS-AND-CHECKOUT.md) |
| Checkout | Remote bỏ qua checkout booking; thiếu phục hồi quote; label mock; voucher/điểm cần contract. | [06](06-CONCESSIONS-AND-CHECKOUT.md) |
| VNPay | Thiếu nhận return trên thiết bị/resume; chưa đưa flow thật từ verifyingBooking sang ticketReady; thiếu xử lý lỗi nhất quán. | [07](07-VNPAY-COMPLETION.md) |
| Orders/ticket | Chỉ trang đầu 20 booking; thiếu resume payment; QR chỉ text; USED bị chặn; thiếu lưu/chia sẻ/review entry. | [08](08-ORDERS-AND-TICKET-QR.md) |
| Food độc lập | Mới có lịch sử đọc thật; thiếu tạo giỏ/đơn, payment, chi tiết, nhận hàng và cancel/sync. | [09](09-STANDALONE-FOOD-ORDERS.md) |
| Wallet | Withdrawal mutation chưa triển khai nhưng nút bật; form dữ liệu mẫu; history chỉ 20 dòng; lỗi tải vẫn spinner. | [10](10-WALLET-AND-LOYALTY.md) |
| Loyalty | Đọc/config/redeem đã có; thiếu lịch sử và checkout redemption, cần phân biệt contract từng loại đổi điểm. | [10](10-WALLET-AND-LOYALTY.md) |
| Chat/social/voucher/VIP/refund/support | Phần lớn preview; chat đã có Gateway route; các tính năng khác phải xác nhận API, role và lifecycle. Thông tin CSKH/rạp còn mẫu. | [11](11-CHAT-AND-DEFERRED-FEATURES.md) |
| Toàn bộ flow | Chưa có bằng chứng tích hợp/thiết bị mới cho các sửa chữa này; cần kiểm tra đổi tài khoản, mất mạng và expiry. | [12](12-INTEGRATION-AND-DEVICE-QA.md) |

## Thứ tự thực hiện

1. Plan 02: thay profile/đổi mật khẩu mock; Plan 05–08: hoàn tất hành trình hold → food → checkout → payment → QR.
2. Plan 01 và 10: auth/recovery và withdrawal thật.
3. Plan 03–04 và 09: catalog/engagement và food độc lập.
4. Plan 11: tách batch chat đã có route; các phần thiếu contract ghi dependency cụ thể.
5. Plan 12 chạy theo từng batch và kết thúc bằng QA xuyên flow.

## Tiêu chí hoàn thành chung

- Hành vi ghi dữ liệu production sử dụng API thật; thông báo thành công chỉ sau response hợp lệ.
- Có loading/error/retry, chống gửi lặp và xử lý hết phiên.
- Có bằng chứng các trường hợp nghiệp vụ quan trọng; không dùng kết quả test cũ trong `done` thay kết quả mới.
- Mỗi batch ghi commit, file sửa, lệnh và kết quả kiểm chứng; contract/dependency còn mở phải hiện rõ.
