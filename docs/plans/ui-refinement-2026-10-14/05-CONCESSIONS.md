# UI-05 — Bắp nước kèm vé và đơn độc lập

Trạng thái: **UI đã được người dùng duyệt — “plan 5 đã ổn” (15/10/2026)**. Code/analyzer/test/build Android đạt; QA iOS và E2E đặt/thanh toán thật còn mở. Ưu tiên: **cao**. Liên quan: plan chức năng 06, 09.

Kết quả và giới hạn kiểm chứng: [UI05-RESULTS.md](UI05-RESULTS.md).

## Đã triển khai

- Dùng chung `FoodProductCard` cho bắp nước kèm vé và đơn độc lập: ảnh API giữ tỷ lệ trong khung 80×80, loading/error fallback bằng icon bắp/nước, tên/mô tả/giá dễ đọc.
- Thẻ đã chọn có nền/viền vàng; trạng thái không khả dụng và giới hạn 8 rõ ràng; vẫn giảm được món không khả dụng đang có trong giỏ.
- `FoodCartBar` cố định tổng tiền, số lượng và CTA; tự xếp dọc trên màn hẹp hoặc chữ lớn, có SafeArea.
- Booking ghi rõ không bắt buộc, nút `Bỏ qua · Tiếp tục` khi giỏ trống; giữ countdown ở trên danh sách.
- Đơn độc lập hiển thị tên/địa chỉ rạp nhận và nhắc rạp ở thanh tổng giỏ; đổi rạp giữ lựa chọn món.
- Giữ contract BE hiện tại: chỉ `ACTIVE` được thêm; `LOW_STOCK` ghi sắp hết/tạm ngừng đặt. Không đổi giá, quy tắc khả dụng, API tạo đơn hoặc cơ chế chống gửi lặp.

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

