# UI-05 — Bắp nước kèm vé và đơn độc lập

Trạng thái: **pending**. Ưu tiên: **cao**. Liên quan: plan chức năng 06, 09.

## Việc cần làm

- Thêm ảnh từ imageUrl vào thẻ sản phẩm/combo, với tỷ lệ ổn định và fallback khi thiếu/hỏng; không gán ảnh khác sản phẩm.
- Bố trí tên, mô tả ngắn, giá và bộ chọn số lượng thành nhóm dễ đọc.
- Làm rõ đang chọn, không khả dụng và giới hạn 8 mỗi item/combo; item/combo có cùng ID vẫn độc lập.
- Đơn độc lập: rạp nhận hàng rõ ràng, tóm tắt giỏ và CTA dễ thấy.
- Bắp nước kèm vé: Bỏ qua dễ tìm, tổng bắp nước và countdown không bị ảnh/thẻ che khuất.
- Áp dụng skeleton/error/empty từ UI-01; không đổi contract khả dụng hay giá authoritative của BE.

## File dự kiến

`lib/features/booking/presentation/pages/concessions_page.dart`, `lib/features/food/presentation/pages/standalone_food_page.dart`, widget sản phẩm dùng chung nếu phù hợp.

## Tiêu chí hoàn thành và QA

Ảnh tải chậm/hỏng không nhảy layout. Kiểm tra tên dài, giá lớn, giỏ trống, hết hàng, giới hạn số lượng, đổi rạp và price change. UI không làm mất giỏ hoặc gửi lặp đơn.

