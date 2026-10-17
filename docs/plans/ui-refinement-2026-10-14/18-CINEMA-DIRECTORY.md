# UI-18 — Hệ thống rạp và trang chi tiết rạp

Ngày lập: **17/10/2026**. Ưu tiên: **P1**. Trạng thái: **planned**.

## Mục tiêu

Tạo hành trình **Danh sách rạp → Chi tiết rạp → Xem lịch tại rạp**. Giữ khối rạp Home hiện tại, kết nối “Xem tất cả” và từng thẻ tới flow đầy đủ.

## API đã xác nhận

- `GET /api/v1/cinemas`, `GET /api/v1/cinemas/{cinemaId}`.
- `GET /api/v1/cinemas/{cinemaId}/rooms` khi cần dữ liệu phòng công khai.
- Lịch chiếu: `GET /api/v1/showtimes?cinemaId=...&date=...&page=...&size=...`; dùng bộ lọc thống nhất UI-19.

## Nội dung triển khai

1. Danh sách rạp: tìm tên/địa chỉ, lọc tỉnh/thành theo dữ liệu thực, loading/error/empty và retry. Chuẩn hóa so sánh để lọc nhưng không tự sửa tên địa chỉ server.
2. Trang rạp: tên, địa chỉ và các thông tin liên hệ/ảnh/tiện ích chỉ khi API có. Bản đồ/chỉ đường chỉ khi tọa độ hoặc địa chỉ hợp lệ; không bịa vị trí/khoảng cách, không yêu cầu định vị nếu chưa dùng.
3. CTA Xem lịch chiếu mở route có `cinemaId` và chip rạp đang lọc; không đóng cứng một rạp mẫu. Rạp inactive không có thao tác đặt vé.
4. “Rạp ưu tiên” là preference có phạm vi user/guest rõ ràng; không tự đổi rạp của hold/đơn hiện tại. Đồng bộ header, danh sách và query, không gán rạp ưu tiên thành địa điểm của đơn đã tạo.
5. Tái dùng dữ liệu Home, tách state chọn thành phố/chi tiết; danh sách rạp không bị mất vì request lịch chiếu lỗi.

## File / QA

Thêm pages/provider/repository rạp, mở rộng `catalog_repository.dart`/remote/mock và routes khi thiếu; kết nối `home_cinemas_section.dart`, cinema header/sheet bằng thay đổi có kiểm soát.

QA rạp trùng tên/khác ID, thành phố viết khác nhau, ảnh/địa chỉ thiếu, inactive, rạp chưa có suất, đổi rạp rồi back; kiểm tra giữ đúng cinemaId tới từng phòng/suất/ghế. Kích thước 320–430/chữ lớn, map link và thiết bị thật. Ghi `UI18-RESULTS.md`.
