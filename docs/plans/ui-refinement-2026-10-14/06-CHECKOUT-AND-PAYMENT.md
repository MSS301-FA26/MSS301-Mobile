# UI-06 — Xác nhận đơn và thanh toán

Trạng thái: **UI đã được người dùng duyệt — “plan 6 ổn ròi” (15/10/2026)**. Analyzer/34 test/build Android đạt; QA iOS và sandbox E2E còn mở. Ưu tiên: **cao**. Liên quan: plan chức năng 06, 07, 09.

Kết quả: [UI06-RESULTS.md](UI06-RESULTS.md).

## Đã điều chỉnh

- Dùng chung khối thông tin đơn, dòng giá thích ứng màn hẹp và thanh tổng tiền/CTA có SafeArea.
- Xác nhận vé: tổng thanh toán cố định, thông báo giá cập nhật/lỗi nằm sát CTA; thể hiện phí, thuế, giảm giá nếu API có trả về.
- Đơn bắp nước: chi tiết món tách khỏi tổng tiền, cảnh báo giá mới sát nút xác nhận giá; countdown cố định và trạng thái hết thời gian không tự biến thành thanh toán thất bại.
- Countdown giữ ghế ổn định trên cả màn kết quả; dưới 60 giây có cảnh báo bằng chữ.
- Kết quả thanh toán phân biệt chờ, đang mở VNPay, xác minh booking, chưa rõ, thất bại và đã xác nhận; giảm thao tác kiểm tra trùng. QR/vé vẫn chỉ mở sau trạng thái BE phù hợp.

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

