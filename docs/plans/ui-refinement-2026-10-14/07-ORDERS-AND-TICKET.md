# UI-07 — Đơn của tôi và vé QR

Trạng thái: **pending**. Ưu tiên: **trung bình**. Liên quan: plan chức năng 08, 09.

## Việc cần làm

- Tên phim dài hiển thị hai dòng hoặc xem đủ trong chi tiết; mã đơn có vị trí riêng, không cạnh tranh với trạng thái.
- Badge theo lifecycle: chờ, đã thanh toán, đã dùng, hủy, hết hạn; kèm nhãn chữ.
- Giữ poster, ngày/giờ/rạp/ghế theo thứ bậc rõ; CTA chỉ bật khi lifecycle cho phép.
- Vé QR có nền trắng, khoảng trống quanh mã và kích thước dễ quét; không đặt blur/gradient trên QR.
- Giữ lưu/chia sẻ vé, refresh/phân trang và cache theo tài khoản; lỗi thêm trang giữ đơn đã tải.
- Loại nội dung kỹ thuật/mock khỏi giao diện production nếu còn hiện; thay bằng diễn đạt đúng trạng thái.

## File dự kiến

`lib/features/orders/presentation/`, `lib/features/booking/presentation/pages/ticket_page.dart`, `lib/features/food/presentation/widgets/food_order_card.dart`.

## Tiêu chí hoàn thành và QA

Tên/mã dài, vé USED, đơn trống và nhiều trang đều đọc rõ. Mã vẫn quét/giải mã đúng payload sau thay đổi trình bày; check-in BE thật không được coi đã PASS chỉ từ ảnh QR. QA chia sẻ/lưu bị từ chối hoặc lỗi.

