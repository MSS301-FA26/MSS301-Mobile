# UI-16 — Ghế đã bán/đang giữ và dữ liệu khả dụng

Ngày lập: **17/10/2026**. Ưu tiên: **P0**. Trạng thái: **Mobile đã triển khai và kiểm thử ngày 19/10/2026; QA hai khách thật và độ tin cậy dữ liệu BE còn mở**. Xem [UI16-RESULTS.md](UI16-RESULTS.md).

## Hiện trạng và nguồn dữ liệu

- `ShowtimeSeatDto.selectable` và `_SeatButton` đã chặn ghế không AVAILABLE; `BookingEntryController` kiểm tra unavailable IDs và xử lý conflict. Cần sửa độ mới/độ tin cậy và cách trình bày thay vì chỉ thêm một điều kiện tap nữa.
- API: `GET /api/v1/showtimes/{id}/seat-map`; catalog lấy runtime status và holdExpiresAt từ booking. `BookingServiceImpl.holdSeats` kiểm tra ghế đã có người giữ/bán, trả 409 khi conflict.
- Phụ thuộc BE: `BookingClient.getOccupiedSeats` trả rỗng khi gọi nội bộ lỗi; seat-map 200 không đủ chứng minh dữ liệu occupancy đầy đủ. Yêu cầu backend biểu diễn unavailable/unknown rõ ràng, không coi lỗi thành ghế trống.

## Trải nghiệm và triển khai

1. Lấy map mới khi vào màn, resume và trước xác nhận hold; bổ sung refresh/poll có vòng đời trong lúc chọn ghế, dừng khi rời màn. Chống request chồng/response cũ ghi đè khi đổi suất.
2. Ghế BOOKED/HELD bởi người khác không có thao tác chọn. Ẩn phần tương tác/nhãn lựa chọn hoặc dùng placeholder mờ/khóa; giữ nguyên ô vật lý trong sơ đồ, không xóa khỏi mảng rồi dồn ghế/lối đi. Có chú giải Đã bán/Đang giữ/Không khả dụng.
3. Nhận diện ghế của hold hiện tại bằng booking đã được BE xác nhận thuộc user hiện tại; không tự suy ra quyền sở hữu chỉ từ ID ghế local. Giữ đúng trạng thái xem/sửa hold và cặp ghế đôi.
4. Nếu ghế vừa chọn bị người khác giữ: bỏ assignment không hợp lệ theo cặp khi cần, báo rõ ghế nào đổi trạng thái, cập nhật quote; không tự chọn ghế khác.
5. Dữ liệu stale/offline: giữ sơ đồ để tham khảo kèm cảnh báo, khóa xác nhận đến khi map mới hợp lệ. Nếu BE chưa cho biết occupancy lỗi, ghi blocker và tiếp tục dựa hold 409 để bảo vệ; không tuyên bố giải quyết hoàn toàn từ Mobile.
6. Expiry không tự biến ghế thành AVAILABLE chỉ từ đồng hồ client; refresh server. Không giải phóng hold của người khác hoặc reset thời gian.

## File dự kiến / QA

`seat_selection_page.dart`, `seat_map_provider.dart`, `showtime_dto.dart`, `booking_entry_session.dart`, repository seat-map; phía BE được chủ thể backend xử lý riêng.

- Hai khách cùng suất: một người hold/mua, người kia không chọn được sau refresh; race vẫn trả conflict đúng.
- Hết hold, đã PAID/USED, MAINTENANCE/unknown, ghế đôi một bên bận, hold của chính mình, refresh lỗi và response ngược thứ tự.
- Kiểm tra tọa độ/lối đi không đổi khi ghế bị ẩn tương tác, screen reader không báo là có thể chọn.
- Kết quả `UI16-RESULTS.md`, test hành vi và QA nhiều client thật; chỉ chốt khi độ tin cậy occupancy đã được xác minh.
- hệ thống rạp
- chỉnh lại chi tiết phim
- luồng hiện tại: chọn phim -> đặt vé -> hiện lịch chiếu theo phim, vậy có cách nào để từ cái lịch chiếu theo phim đó mình ra lịch chiếu toàn bộ để người dùng có nhiều lựa chọn hơn, ví dụ như thêm vào lịch chiếu màn lọc, khi chọn đặt vé theo phim thì sẽ lọc phim đó, xóa bộ lọc thì ra toàn bộ, thêm vào đó là hệ thống rạp để chọn lịch chiếu theo rạp nữa
- watch list
- thanh toán thành công hiện tại call localhost cổng 3000 của FE, hãy điều chỉnh thành quay lại app hoặc hiện nút quay lại app
chỉnh lại style trang thanh toán và thanh toán thành công, bố cục và style hiện khá xấu, của mua vé và mua đồ ăn
- không cho chọn các vị trí đã mua, ẩn các ghế đã được mua, hoặc đang được hold 
- không cho chọn ghế mà lẻ ghế ở giữa, ví dụ chọn 1,2,4,5 là không được vì sẽ lẻ ghế 3, cho tôi biết có rule này ở BE không, vì theo tôi biêt hiện tại rule này đang có ở FE
