# UI-18 — Kết quả hệ thống rạp

Ngày kiểm tra: **23/10/2026**. Trạng thái: **đã triển khai Mobile, chờ review giao diện và QA iOS/thiết bị thật**.

## Đã thực hiện

- Thêm `/cinemas` và `/cinemas/:cinemaId`: danh sách tìm tên/địa chỉ, lọc thành phố, trạng thái tải/lỗi/trống/thử lại; chi tiết rạp hiển thị tên, địa chỉ, thành phố, số điện thoại theo API. Tên rạp trùng nhau được định danh bằng ID.
- Nối “Xem tất cả” và thẻ rạp Home, mục rạp ở Tài khoản, header và thẻ lịch chiếu vào danh sách/chi tiết thật. Bỏ điểm vào trang thông tin rạp mẫu cũ.
- Thêm rạp ưu tiên lưu cục bộ bằng khóa riêng cho guest và từng user. Header, thẻ danh sách và lịch chiếu dùng lựa chọn này; xóa chip ở lịch để xem tất cả. Lựa chọn không thay đổi hold hoặc booking đã tạo.
- `GET /api/v1/cinemas/{id}` cho chi tiết; `GET /api/v1/showtimes` nhận `cinemaId`, phân trang và lọc lại theo ID. Trang chi tiết chỉ cho mở lịch hoặc đặt rạp ưu tiên khi rạp active. “Chỉ đường” chỉ hiện khi API có địa chỉ và thành phố đủ dùng.
- DTO rạp hiện có `name`, `address`, `city`, `phone`, `status`. API chưa có ảnh, tọa độ hay tiện ích, nên trang chi tiết dùng biểu tượng rạp và không hiển thị dữ liệu giả.

## Kiểm chứng

- `flutter analyze`: không có lỗi.
- 38 test liên quan catalog, Home, lịch chiếu và UI-18 qua; UI-18 riêng có 6 ca gồm rạp trùng tên, thành phố khác kiểu, tìm kiếm, chuyển đúng `cinemaId`, phân vùng guest/user và rạp inactive. Test ở 320/390/430 px với chữ lớn. `flutter build apk --debug` đạt.
- Cài APK lên `emulator-5554`, dùng API thật: danh sách có nhiều rạp; mở “CinemaAI Central - Q.1” thấy địa chỉ/điện thoại từ API; lịch chiếu hiển thị chip đúng tên rạp và các suất tại rạp; đặt rạp ưu tiên cập nhật header/danh sách và còn sau khi cài lại APK.
- Ảnh emulator: [khối rạp Home](screenshots/ui18-home-entry.png), [danh sách](screenshots/ui18-directory.png), [chi tiết/rạp ưu tiên](screenshots/ui18-detail-preferred.png), [lịch theo rạp](screenshots/ui18-showtimes.png). Không có màn danh sách/chi tiết trước khi triển khai để đối chiếu trực tiếp.

## Còn mở

- Chưa kiểm tra iOS, thiết bị thật và mở liên kết bản đồ trên thiết bị thật.
- Chưa chạy E2E nhiều rạp xuyên suốt chọn suất → phòng → ghế → thanh toán. UI-19 sẽ mở rộng bộ lọc phim/rạp/ngày thống nhất; UI-18 hiện có chip rạp có thể xóa.
