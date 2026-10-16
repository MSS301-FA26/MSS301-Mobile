# UI-06 — Xác nhận đơn và thanh toán

Ngày: **15/10/2026**. Trạng thái: **UI được người dùng duyệt; analyzer/test/build Android đạt; iOS/sandbox E2E còn mở**.

Phản hồi người dùng: **“plan 6 ổn ròi”**. Ghi nhận hoàn tất phần điều chỉnh và review UI-06; không suy ra đã QA iOS hoặc thanh toán sandbox xuyên suốt.

## Thay đổi

- Thêm `shared/widgets/checkout_summary.dart`: khối thông tin, dòng giá tự xếp dọc khi màn hẹp/chữ lớn, thanh tổng tiền và CTA cố định với SafeArea.
- `checkout_page.dart`: phân nhóm phim/rạp/phòng/ghế/vé, bắp nước, giá; tổng và CTA luôn thấy. Thông báo cập nhật giá sát nút thanh toán để người dùng xác nhận lại. Giá vẫn lấy từ quote BE, không cộng lại theo giá local.
- `food_checkout_page.dart`: mã đơn dài có cả chiều ngang để đọc, chi tiết món tách khỏi thanh tổng; cảnh báo giá đổi/lỗi/mở VNPay/kiểm tra kết quả sát CTA. Khi local deadline đã hết, nút kiểm tra kết quả thay nút thanh toán; không gán FAILED từ thời gian phía client.
- `booking_hold_countdown.dart`: thêm cảnh báo bằng chữ khi còn tối đa 60 giây; deadline gốc không đổi.
- `payment_result_page.dart`: countdown ngoài vùng cuộn, hiển thị số tiền giao dịch, thông điệp riêng cho trạng thái chưa rõ/chờ/xác minh/thất bại/thành công; giảm nút kiểm tra trùng, khóa thao tác khi đang xử lý. Nút mở vé vẫn phụ thuộc `ticketReady` từ controller.
- Không sửa source BE/FE, DB, UI đăng nhập/đăng ký hoặc cơ chế xác nhận/đối soát của controller.

## Kiểm chứng

- `flutter analyze --no-pub`: **No issues found**.
- **34 test pass**: `ui06_checkout_test`, `ui04_booking_layout_test`, `quick_action_pages_test`, `remote_booking_completion_test`, `booking_hold_countdown_test`.
- 8 ca mới: đơn dài ở 320/430 px, text scale 1.6, cuộn vẫn thấy giá cập nhật/CTA/countdown; kết quả pending/verifying/error/failed/ready chỉ có nút mở QR sau xác nhận booking; đơn bắp nước quá deadline vẫn giữ trạng thái BE và chỉ cho kiểm tra kết quả.
- Hồi quy: giá đổi chặn tạo payment; callback thành công vẫn đợi booking PAID; payment tạo một lần, resume/đồng hồ qua các màn giữ cùng deadline; lỗi hết hàng giữ giỏ.
- Build Android debug API `http://127.0.0.1:8080`, UI_PREVIEW=false; cài lên emulator giữ dữ liệu đăng nhập.
- API thật: mở lại đơn bắp nước có sẵn `FO-1792070145317-237`, BE EXPIRED, tổng 20.000đ; tổng/CTA cố định và không có nút thanh toán. Chỉ đọc đơn, không tạo đơn/payment mới trong batch này.
- Ảnh local: `D:\MSS\.qa-runtime\ui06-food-expired.png`.

## Còn mở

- Booking checkout đang giữ ghế, giá thay đổi, launcher lỗi và callback chậm đã kiểm qua widget/controller test; chưa chạy lại thanh toán VNPay thật trong batch UI này.
- iOS, bàn phím/SafeArea trên thiết bị iOS và hành trình sandbox E2E vẫn cần QA riêng.
- Không có ảnh baseline có dữ liệu cùng đơn trước khi sửa để so sánh trực tiếp.
