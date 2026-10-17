# 07 — VNPay return và hoàn tất booking

Trạng thái: **pending**. Ưu tiên: cao. Phụ thuộc checkout ở Plan 06.

## Việc cần làm

- Chốt return URL/app link và cấu hình Android/iOS với BE; không tin query return là bằng chứng thanh toán thành công.
- Kiểm tra trạng thái khi app resume hoặc nhận return; polling có giới hạn trong thời gian chờ và dừng đúng lifecycle.
- Khi payment SUCCESS, tải booking tới PAID rồi chuyển `ticketReady`; xử lý payment thành công nhưng booking chưa cập nhật do xử lý bất đồng bộ.
- Refresh Orders, dọn hold/session sau completion thật; không gọi hàm mô phỏng để hoàn tất production.
- Catch lỗi attach/refresh/retry; dùng payment launcher có kiểm tra URL và kết quả mở.
- Phục hồi payment bằng ID/booking khi restart; retry không tạo thao tác trùng.
- Tách nội dung/nút mock khỏi UI production.

## Scope dự kiến

Payment repository/launcher, booking completion, payment page, routing và Android/iOS return config.

## Tiêu chí hoàn thành và kiểm chứng

- Sandbox success → booking PAID → mở vé chạy trên thiết bị; failed/cancel/expiry có đường tiếp tục rõ.
- Return lặp, resume, network timeout và callback chậm không xác nhận vé hai lần.
- Có test transition và bằng chứng sandbox; response client không tự đánh dấu paid.
