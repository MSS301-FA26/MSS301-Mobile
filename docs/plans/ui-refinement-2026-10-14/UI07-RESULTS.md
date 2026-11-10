# UI-07 — Đơn của tôi và vé QR

Ngày: **15/10/2026**. Trạng thái: **đã triển khai, code/test/build Android đạt; chờ review và QA thiết bị**.

## Thay đổi

- Viết lại phần trình bày dùng chung của Upcoming/CompletedOrderCard: tên hai dòng, mã đơn dòng riêng, bỏ chiều cao cố định, rạp/giờ/ghế đọc rõ, hiển thị tổng tiền, nút xếp dọc để hỗ trợ chữ lớn.
- Thêm `StatusBadge` và `BookingStatusBadge`: chờ/giữ ghế vàng, đã thanh toán xanh lá, đã dùng xanh dương, hủy đỏ, hết hạn xám, hoàn tiền tím; luôn có nhãn chữ và icon.
- Giữ callback điều hướng; giới hạn hành động tiếp tục theo trạng thái, chỉ USED có đánh giá và PAID có nút hoàn/đổi khi feature preview đã bật. Không bật tính năng hoàn tiền production mới.
- FoodOrderCard: trạng thái và mã ở vị trí riêng, tên món/giá và tổng dùng dòng thích ứng, bỏ phần thập phân giây khỏi ngày tạo hiển thị.
- TicketPage: badge trạng thái, tên/mã rõ, thông tin không cắt ở ba dòng. QR chỉ PAID có payload, kích thước tối đa 240 px và co theo khung, nền trắng, khoảng trắng bốn module tính theo mật độ mã. USED không có QR dùng lại.
- Không sửa BE/DB, repository lịch sử, cache, phân trang hoặc dịch vụ export PDF. Test cuộn tới nút save được cập nhật để bấm đúng nút sau thay đổi chiều cao nội dung.

## Kiểm chứng

- `flutter analyze --no-pub`: **No issues found**.
- **30 test pass**: `ui07_orders_test`, `plan08_ticket_test`, `quick_action_pages_test`, `remote_booking_completion_test`.
- 6 ca UI-07 mới: 320/360/390/430 px với text scale 1.6, tên/mã dài, 8 ghế và tổng lớn; UNKNOWN không tiếp tục, không mở action đánh giá khi chưa USED; QR render từ trang vé khớp ảnh mã sinh từ payload mẫu, nền trắng, quiet zone bốn module và không vượt khung hẹp.
- Ca có sẵn: tài khoản A/B/guest không lộ vé; PAID/USED/HOLDING/PENDING_PAYMENT/CANCELLED/EXPIRED/REFUNDED chỉ có QR/action phù hợp; export revalidate vé đã đổi trạng thái và không báo lưu thành công khi export lỗi; callback/payment vẫn đợi booking PAID.
- Log local: `D:\MSS\.qa-runtime\ui07-test.log`.
- Build debug Android API `http://127.0.0.1:8080`, UI_PREVIEW=false; cài lên emulator giữ dữ liệu đăng nhập.
- API thật: đọc 2 vé đã thanh toán và 10 đơn lịch sử trên tài khoản test; mở vé `BK2610152058518518`, ghế A2, tổng 333.000đ gồm nước 20.000đ, QR xuất hiện theo BE PAID. Không tạo booking/payment mới, không check-in.

## Ảnh local

- `D:\MSS\.qa-runtime\ui07-orders-before.png`: danh sách trước sửa.
- `D:\MSS\.qa-runtime\ui07-orders-after.png`: danh sách sau sửa.
- `D:\MSS\.qa-runtime\ui07-ticket-after.png`: vé thật sau sửa. Ảnh vé có QR của tài khoản test; không đưa vào tài liệu public.

## QA còn mở

- Người dùng review thẩm mỹ và độ gọn của thẻ đơn.
- Test so sánh ảnh QR kiểm tra payload/render; **chưa quét bằng camera/decoder độc lập hoặc check-in BE thật**. Không coi xuất hiện QR là check-in pass.
- Lưu/chia sẻ trên Android/iOS thật, quyền thiết bị và share sheet cần kiểm tra riêng. Test PDF hiện có cảnh báo font Courier không hỗ trợ Unicode; chất lượng chữ tiếng Việt của PDF chưa được nghiệm thu trong batch UI này.
- Giữ nguyên fetch phân trang hiện có; nhiều trang đã có test hồi quy. Trường hợp trang sau lỗi khi refresh giữ data cũ theo AsyncValue hiện tại; không thêm cơ chế streaming từng trang trong batch này.
