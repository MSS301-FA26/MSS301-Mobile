# UI-06 — Xác nhận đơn và thanh toán

Trạng thái: **pending**. Ưu tiên: **cao**. Liên quan: plan chức năng 06, 07, 09.

## Việc cần làm

- Tách rõ thông tin phim/rạp/ghế/bắp nước, giá từng phần và tổng cuối cùng.
- Làm tổng tiền và CTA thanh toán nổi bật; cân nhắc thanh cố định cuối màn với SafeArea, không che nội dung.
- Countdown đặt ở vị trí ổn định; cảnh báo gần hết hạn có chữ/icon, không chỉ màu.
- Xác nhận giá mới hiển thị sát tổng tiền/CTA; giữ yêu cầu người dùng kiểm tra giá authoritative.
- Trạng thái mở VNPay, đang xác minh, thành công, thất bại và chưa rõ có thông điệp/hành động riêng.
- Không hiển thị vé hoặc QR thành công trước xác nhận BE, không suy ra FAILED chỉ từ đồng hồ hết giờ.

## File dự kiến

`lib/features/booking/presentation/pages/checkout_page.dart`, `payment_result_page.dart`, `lib/features/food/presentation/pages/food_checkout_page.dart`.

## Tiêu chí hoàn thành và QA

Tổng tiền và CTA dễ thấy; cuộn vẫn đọc đủ chi tiết. QA bàn phím/SafeArea, đơn dài, giá đổi, expiry, launcher lỗi, callback chậm và resume. QA sandbox thật vẫn thuộc plan chức năng 07/12.

