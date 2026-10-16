# UI-03 — Khám phá và Lịch chiếu

Ngày 14/10/2026. Code, kiểm chứng tự động và APK Android đạt. Người dùng đã xác nhận xem được danh sách phim và đánh giá giao diện khá ổn; còn QA lịch có suất thật và iOS.

## Thay đổi

- Khám phá: thay grid tỷ lệ cố định bằng các hàng dựng lazy, chiều cao theo nội dung. Mặc định hai cột; dưới 350 px và text size 14 tăng trên 18 px chuyển một cột. Tên hai dòng, thời lượng/thể loại riêng, CTA tối thiểu 48 px và tự tăng theo chữ. Phim sắp chiếu mở Chi tiết thay vì Đặt vé.
- Count chỉ hiện ở tab có dữ liệu của bộ lọc hiện tại; không dùng count của phim đang chiếu cho phim sắp chiếu.
- `Movie.rating` là nullable; mapper không còn gán 0. API DTO hiện không cung cấp điểm tổng hợp nên ẩn badge ở Khám phá/Lịch chiếu/chi tiết. Các widget Home cũ có fallback Chưa có đánh giá, không hiện null. Danh sách review thật trong chi tiết không thay đổi.
- Lịch chiếu: bớt viền, giờ chiếu 18 px; danh sách suất wrap theo chiều rộng/text scale. Đã chọn có viền/chữ/check, disabled ghi Chưa mở bán/Đã hủy/Đã kết thúc/Đã qua giờ/Không khả dụng theo dữ liệu hiện có.
- OPEN chỉ chọn khi startAt còn ở tương lai; kiểm tra lại khi nhấn Vé & Ghế. Đổi ngày bỏ lựa chọn cũ. Dữ liệu refresh loại bỏ hoặc đóng suất thì CTA không tiếp tục với suất cũ. Refresh lỗi giữ nội dung nhưng khóa chọn/mua và có retry.
- Ngày và cụm tên rạp/trạng thái xuống dòng/co giãn khi phóng chữ. Giữ route ID, giờ Việt Nam và quy tắc booking hiện có.

## Kiểm chứng

- Analyzer không có lỗi; `git diff --check` đạt; APK debug build/cài emulator thành công, API_BASE_URL=127.0.0.1:8080, UI_PREVIEW=false.
- 36 test trong UI-03/UI-01/Home navigation/booking entry/Vietnam time đã pass.
- Thêm ca full-page Lịch chiếu 320 px với chữ 1,8 lần; phát hiện/sửa overflow tên rạp và chờ layout scroll trước tap. Bộ 11 test UI-03 cuối cùng pass, gồm nhiều phòng.
- 320/360/390/430 px, text scale 1,8: tên dài, ảnh hỏng, thẻ phim, nhiều phòng/suất disabled không overflow. Kiểm tra missing rating, callback ID, chọn ngày, hết giờ trước khi tiếp tục.
- Emulator Android 1080×2424: Khám phá có 6 phim thật, không còn 0.0; duration/genre/nút hiển thị rõ. Lịch chiếu trả danh sách trống và hiển thị lời hướng dẫn đúng.
- Runtime lúc bắt đầu QA: Docker đã dừng và Apache lại chiếm 8080. Đã dừng lại đúng Apache EDB PEM theo cấu hình đã chốt, chạy lại các container sẵn có và ADB reverse 8080. Không sửa source BE, reset DB hay áp dụng SQL mới.

## Ảnh local

- [Khám phá trước](D:/MSS/.qa-runtime/ui03-discover-before.png).
- [Khám phá sau](D:/MSS/.qa-runtime/ui03-discover-after.png).
- [Lịch chiếu trước](D:/MSS/.qa-runtime/ui03-showtimes-before.png).
- [Lịch chiếu sau](D:/MSS/.qa-runtime/ui03-showtimes-after.png).

Ảnh Khám phá sau đã scroll tới thẻ để nhìn rõ tên, metadata và CTA; vị trí scroll trước/sau khác nhau.

## Điều chỉnh theo phản hồi bộ lọc thể loại

Đã thay các ChoiceChip xuống nhiều hàng bằng `GenreFilterBar` cuộn ngang một hàng. Bỏ viền trắng và màu tím mặc định; mục được chọn vàng–đen, mục còn lại nền tối/chữ sáng. Tên thể loại dài giữ nguyên, vùng chạm tối thiểu 48 px; giữ callback ID và reset pagination hiện có. Số kết quả tách khỏi hàng lọc bằng khoảng cách 8 px. Bộ lọc được kiểm tra lại ở 320–430 px với chữ 1,8 lần.

Ảnh mới: [Bộ lọc một hàng](D:/MSS/.qa-runtime/ui03-genre-refined.png).

## Còn mở

Cập nhật sau chuyển DB chung Neon: gateway trả 13 suất, emulator hiển thị lịch thật. Đã lọc ngày 15/10, chọn suất PHIM JAVA 09:40, thấy ✓ Đã chọn và CTA Vé & Ghế. Trạng thái Chưa mở bán cũng hiển thị từ dữ liệu thật. Ảnh: [Lịch Neon](D:/MSS/.qa-runtime/shared-db-showtimes.png), [Lọc ngày và chọn suất](D:/MSS/.qa-runtime/shared-db-showtimes-selected.png). Không tạo booking/hold trong kiểm tra này.

- QA lịch có dữ liệu thật đã kiểm tra các bước nêu trên; còn các trạng thái lỗi mạng/quá giờ và iOS trên thiết bị thật.
- Contract điểm tổng hợp chưa có trong MovieDto: chưa tích hợp rating; không tạo điểm thay thế.
- Review danh sách phim/bộ lọc đã có phản hồi tích cực từ người dùng. Còn QA iOS, chữ lớn trên thiết bị thật và trạng thái lịch chiếu có dữ liệu thật.
