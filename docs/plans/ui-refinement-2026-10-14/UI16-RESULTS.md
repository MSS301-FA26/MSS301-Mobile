# UI-16 — Kết quả cập nhật khả dụng ghế

Ngày kiểm tra: **19/10/2026**. Phạm vi: Mobile; không thay đổi source BE, FE hoặc DB.

## Đã triển khai trên Mobile

- Sơ đồ ghế tải lại khi vào màn, khi app tiếp tục hoạt động và mỗi 8 giây lúc màn đang hiển thị. Chỉ một lần tải nền chạy tại một thời điểm; phản hồi của suất chiếu cũ không ghi đè suất mới.
- Theo phản hồi ngày 19/10: lần tải nền định kỳ diễn ra âm thầm. Sơ đồ và vị trí các thành phần giữ nguyên; trạng thái ghế đã xác minh vẫn có thể chọn trong khi request mới đang chạy. Chỉ khi chưa có map mới, map quá 20 giây hoặc tải lỗi mới hiện biểu tượng nhỏ trong thẻ thông tin phim. Lỗi tải có thông báo ngắn một lần và nút thử lại. Preflight ngay trước hold vẫn bắt buộc.
- Khi không kiểm tra được trạng thái mới hoặc dữ liệu quá 20 giây, giữ sơ đồ cũ để xem với cảnh báo, khóa thao tác chọn và nút tiếp tục. Người dùng có thể thử lại. Trước khi gửi yêu cầu giữ ghế, Mobile luôn lấy map mới; lỗi tải map hoặc ghế đã bị chiếm sẽ chặn POST hold.
- Ghế `HOLDING`, `BOOKED`, `CHECKED_IN`, bảo trì và trạng thái không xác định hiển thị biểu tượng không tương tác, giữ nguyên ô trên sơ đồ. Screen reader đọc lý do không khả dụng. Chỉ hiển thị ghế thuộc phiên giữ của mình nếu booking đã được xác nhận từ BE, đúng tài khoản/suất chiếu và còn hạn.
- Nếu ghế đã chọn đổi trạng thái, bỏ lựa chọn đó; với ghế đôi bỏ cả cặp. Giữ nguyên số vé và báo rõ nhãn ghế để người dùng chọn lại. Khi map xác nhận ghế trống trở lại, bỏ chặn cục bộ. Conflict 409 vẫn được xử lý và lấy lại map.
- Hết hạn phiên giữ không tự đánh dấu ghế trống; người dùng phải tải lại sơ đồ trước khi chọn lại. Các phản hồi hết hạn cũ không ghi đè phiên/suất chiếu mới.

## Xác minh

- Test controller: ghế đôi mất một nửa, preflight chặn POST, lỗi mạng, phản hồi cũ sau đổi suất, conflict 409, deadline và hủy hold.
- Test widget: ghế đã giữ/đã bán/unknown không bấm được và không làm thay đổi kích thước ô; tải nền chậm không dịch chuyển sơ đồ hoặc khóa ghế còn hợp lệ; offline vẫn xem được sơ đồ, thử lại khôi phục thao tác; bố cục 320/360/390/430 px với chữ lớn.
- **33 test liên quan đạt**, `flutter analyze` sạch và build APK debug Android đạt. APK đã cài và mở được trên `emulator-5554`; adb reverse `localhost:8080` đang hoạt động. Public API gateway `localhost:8080` đang healthy; `GET /api/v1/showtimes/105/seat-map` trả 200 với 80 ghế AVAILABLE. 20 suất chiếu public đang thấy đều không có ghế occupied, nên chưa thể xác nhận trạng thái HOLDING/BOOKED bằng dữ liệu thật trên hai tài khoản.

## Còn mở để nghiệm thu toàn luồng

- BE `BookingClient.getOccupiedSeats` vẫn bắt lỗi gọi booking nội bộ rồi trả danh sách rỗng. Vì vậy một phản hồi seat-map 200 có thể báo tất cả ghế AVAILABLE khi dữ liệu occupancy không lấy được. Mobile không thể phân biệt trường hợp này; BE cần trả lỗi hoặc trạng thái không xác định, sau đó chạy QA hai khách cùng suất: hold/mua ở khách A, khách B thấy ghế bị khóa; kiểm tra hết hold, PAID/USED, bảo trì, ghế đôi và race 409.
- Chưa QA iOS và chưa tạo booking thật trên DB dùng chung để tránh làm thay đổi dữ liệu đặt vé của người khác. Test/widget Android và public API chỉ xác nhận những phạm vi nêu trên.
