# UI-19 — Kết quả lịch chiếu thống nhất

Ngày kiểm tra: **23/10/2026**. Trạng thái: **đã triển khai Mobile, chờ review giao diện và QA iOS/thiết bị thật**.

## Đã thực hiện

- Trang Lịch chiếu mặc định tải tất cả phim/rạp của **hôm nay theo lịch Việt Nam**. Lối vào từ chi tiết phim và chi tiết rạp gắn `movieId` hoặc `cinemaId` vào route; mua vé nhanh vẫn giữ luồng chọn suất riêng.
- Ba bộ lọc Phim/Rạp/Ngày ở cùng màn. Sheet phim và rạp có tìm kiếm; ngày có dải ngày và calendar trong 30 ngày tới. Mỗi chip xóa độc lập; “Xóa tất cả” trở về lịch chung hôm nay. Route chứa bộ lọc nên mở lại và quay lại vẫn có trạng thái đúng. Đổi bộ lọc xóa suất đã chọn.
- API showtimes nhận `movieId`, `cinemaId`, `date`; đọc đủ trang và đối chiếu ID/ngày trong dữ liệu trả về. Danh mục phim đọc đủ trang để sheet không mất phim ngoài 100 kết quả đầu. Suất nhóm theo **rạp → phim → phòng → giờ**, giữ đúng ID rạp, phòng và suất.
- Suất đóng hoặc đã qua giờ không thể chọn. CTA Vé & Ghế dùng `showtimeId` và tiếp tục giữ auth redirect.

## Kiểm chứng

- `flutter analyze`: không có lỗi.
- 54 test thuộc catalog, lịch chiếu, UI-18, UI-19, Home và booking qua. UI-19 có ca route, xóa từng lọc, clear all, tìm rạp, tách phòng trùng ID ở hai rạp, phản hồi API cũ đến muộn và đổi lọc xóa suất đã chọn. Helper booking mẫu đã chọn ngày mai vì suất mẫu nằm ngày mai, còn lịch chung mặc định hôm nay.
- `flutter build apk --debug` thành công, cài APK lên `emulator-5554`. Gateway local trả 4 suất ngày 23/10/2026; màn lịch chung hiển thị suất và nhóm theo rạp. Chọn rạp không có suất hiển thị trạng thái trống, vẫn xóa lọc được.
- Ảnh: [lịch chung](screenshots/ui19-all.png), [lọc rạp không có suất](screenshots/ui19-cinema-filter.png).

## Còn mở

- Chưa kiểm tra iOS/thiết bị thật và toàn bộ đường đi chọn suất → ghế → thanh toán trên API thật.
- Calendar hiện giới hạn 30 ngày tới ở Mobile; cần xác nhận nếu chính sách ngày bán vé của BE thay đổi.
