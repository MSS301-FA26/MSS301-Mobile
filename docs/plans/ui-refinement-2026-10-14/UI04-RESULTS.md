# UI-04 — Header booking và vé/ghế

Ngày triển khai: 14/10/2026. Code/test/analyzer đạt; còn QA booking thật, review UI và iOS.

## File thay đổi

- `lib/shared/widgets/app_shell.dart`: chế độ header booking tùy chọn, Back do page cung cấp; nút Home gọi leave guard hiện có. Toolbar tự tăng theo text scale. Các page không truyền bookingTitle vẫn dùng CinemaHeader.
- `seat_selection_page.dart`: header/back ở success/loading/error, summary gọn, countdown cố định; giảm padding thẻ vé, tăng vùng chạm +/- và ghế; sơ đồ rộng cuộn ngang và phóng to; legend/hướng dẫn; footer phù hợp chữ lớn.
- `concessions_page.dart`, `checkout_page.dart`: dùng header chung, bỏ tiêu đề/Back bị lặp trong body; giữ progress/countdown và đường quay về bước trước.
- `payment_result_page.dart`: header Thanh toán; Back đi qua PopScope và dialog rời thanh toán hiện có, không bypass việc lưu đơn.
- `test/ui04_booking_layout_test.dart`: kiểm chứng hành vi header/leave guard, deadline xuyên bước và truy cập ghế cuối trong sơ đồ rộng.

## Kiểm chứng

- 21 test trong UI-04, booking_entry, booking_hold_countdown, completion_and_account: pass.
- Analyzer không có lỗi, diff không lỗi whitespace.
- APK debug build và cài emulator thành công với API_BASE_URL=127.0.0.1:8080, UI_PREVIEW=false; không xóa dữ liệu app.
- Header Back ở Vé & Ghế mở đúng cảnh báo; chọn Ở lại giữ ghế đã chọn. Header Payment cũng mở cảnh báo và chọn Ở lại giữ cùng hold deadline.
- Countdown dùng cùng holdExpiresAt qua Bắp nước/Xác nhận đơn/Thanh toán; các test cũ xác nhận lifecycle resume và ẩn khi booking đã paid.
- Sơ đồ 16 cột ở 320/430 logical px, text scale 1,8: cuộn tới A16, chạm chọn đúng ID 9016, không overflow.
- Test hiện có: hạn chế vé trẻ em, ghế đôi, tối đa 8 ghế, lỗi ghế xung đột, hết hold và QR sau xác nhận thanh toán vẫn pass.

## Phạm vi QA thật

Gateway 8080 truy cập được, ADB reverse 8080 còn kết nối; API có 7 phim nhưng danh sách showtimes trả 0 trong lần kiểm tra. Chưa có dữ liệu để QA trực tiếp sơ đồ ghế/hold thật trên emulator. Không tạo showtime, sửa dữ liệu hoặc thay đổi source BE để phục vụ QA UI.

## Còn mở

Sau khi chuyển bốn service Java sang Neon, gateway đã có 13 suất và Mobile chọn được suất ngày 15/10. Giới hạn 0 suất phía trên là kết quả trước khi đổi DB. Chưa tạo booking/hold trên DB chung trong lần chuyển kết nối này.

- Người dùng xem header/thẻ vé/sơ đồ ghế khi có suất thật; so sánh trước/sau và phản hồi.
- QA iOS, pinch/scroll trên thiết bị thật, booking thật qua các bước với countdown và lỗi mạng.
- Bộ test dùng fixtures có kiểm soát; không đồng nghĩa luồng thanh toán BE thật đã được QA lại trong batch UI này.
