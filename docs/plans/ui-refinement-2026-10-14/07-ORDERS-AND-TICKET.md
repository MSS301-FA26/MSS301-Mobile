# UI-07 — Đơn của tôi và vé QR

Trạng thái: **đã triển khai; analyzer/30 test/build Android đạt; chờ người dùng review, QA quét/check-in và iOS** (15/10/2026). Ưu tiên: **trung bình**. Liên quan: plan chức năng 08, 09.

Kết quả và giới hạn kiểm chứng: [UI07-RESULTS.md](UI07-RESULTS.md).

## Đã triển khai

- Thẻ đơn vé: mã đơn ở dòng riêng, tên phim tối đa hai dòng, thông tin rạp/giờ/ghế tách rõ và không cố định chiều cao nội dung.
- Badge có chữ/icon/màu theo lifecycle cho vé và đơn bắp nước. Nút tiếp tục, mở vé, hoàn/đổi preview và đánh giá được giới hạn theo trạng thái.
- Chi tiết vé dùng dòng thông tin thích ứng màn hẹp/chữ lớn, không cắt còn ba dòng như trước; bỏ diễn đạt mock khỏi thẻ đơn.
- QR PAID giữ nguyên dữ liệu BE, nền trắng, kích thước co theo màn hình và quiet zone bốn module; USED vẫn chỉ là vé lịch sử, không hiện lại QR sử dụng.
- Giữ luồng tải lại, phân trang, cache theo tài khoản và revalidate trước lưu/chia sẻ; không thay repository/provider nghiệp vụ.

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

