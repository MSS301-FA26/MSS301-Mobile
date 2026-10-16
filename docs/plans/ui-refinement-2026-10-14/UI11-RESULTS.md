# UI-11 — Chi tiết phim và phim liên quan

Ngày: **16/10/2026**. Trạng thái: **hoàn tất triển khai; chờ người dùng review, iOS và recommendation thành công trên runtime**.

Phạm vi: Mobile. Không sửa BE, DB hoặc UI đăng nhập/đăng ký. Phản hồi “các plan khác đã chỉnh đã oke rồi” được ghi nhận là duyệt UI các batch đã làm trước UI-11; không tự xác nhận các ca tích hợp còn mở đã đạt.

## Thay đổi

- Header Chi tiết phim gọn, Back về đúng màn trước; loading/lỗi/phim không còn công khai đều có đường quay lại.
- Sửa mapping `MovieDto.bannerUrl` → `Movie.bannerAsset`. Banner ngang 16:9 có gradient và nút trailer. Thiếu banner dùng poster; ảnh lỗi có fallback. Poster nhỏ dùng contain, không kéo giãn ảnh ngang thành ảnh dọc.
- Tên đầy đủ nằm trong nội dung; tuổi, giải thích độ tuổi, thời lượng, ngày khởi chiếu và thể loại đặt cạnh poster, wrap khi chữ lớn. Không tự thêm định dạng khi API không có dữ liệu.
- Mô tả tối đa bốn dòng, có Xem thêm/Thu gọn khi thực sự tràn. Tính số dòng theo font và text scale hiện tại. Thông tin đạo diễn/diễn viên/ngôn ngữ/phụ đề dễ đọc, trường thiếu ghi đang cập nhật hoặc ẩn.
- Bỏ dòng mô tả kỹ thuật CatalogRepository khỏi giao diện.
- Đánh giá và danh sách nhận xét có trạng thái tải/lỗi/thử lại riêng. Không hiện 0.0/10 khi chưa có lượt đánh giá; giữ route mở khu vực reviews hiện có.
- Phim liên quan dùng API hiện có, loại phim hiện tại/ID không hợp lệ/ID trùng, giới hạn hiển thị 12 phim. Không gọi bổ sung chi tiết từng phim. Điểm nullable/0 không được dựng thành điểm đánh giá giả; reason chỉ hiển thị khi API cung cấp.
- Thẻ liên quan bấm mở đúng ID bằng push; quay lại giữ scroll của phim trước. Chiều cao hàng thích ứng text scale; cuối nội dung không bị CTA che.
- Các provider engagement dùng retry bằng thao tác người dùng để báo lỗi cục bộ ngay, tránh framework tự retry nhiều lần trong khi màn hình vẫn hiện chờ. Retry không tải lại chi tiết phim.
- CTA cố định có SafeArea. Phim NOW_SHOWING dẫn đến lịch chiếu lọc đúng movieId; phim chưa mở bán bị khóa. Nhãn “Xem lịch chiếu & đặt vé” không khẳng định sẵn suất/ghế khi chưa kiểm tra ở màn lịch chiếu.
- Trailer dùng URL thực từ phim: hộp thoại mở qua ứng dụng video/trình duyệt ngoài. Chặn URL không phải HTTP(S), chống bấm lặp khi đang mở, báo lỗi và cho thử lại nếu launcher thất bại. Loại bỏ nội dung mô phỏng của hộp thoại cũ, áp dụng cho cả entry trailer Home đang dùng chung.

## File

- `lib/features/movie/presentation/pages/movie_detail_page.dart`
- `lib/features/movie/presentation/widgets/movie_detail_sections.dart`
- `lib/features/movie/presentation/widgets/trailer_preview_dialog.dart`
- `lib/features/movie/presentation/providers/movies_provider.dart`
- `lib/features/movie/presentation/providers/movie_engagement_provider.dart`
- `test/ui11_movie_detail_test.dart`
- `test/home_navigation_test.dart`: cập nhật kiểm tra metadata và trailer theo giao diện thật thay cho dòng kỹ thuật/nội dung mô phỏng.

Source phần triển khai đầu đã được ghi nhận trong commit `7429965`; các sửa provider retry, đo mô tả và test sau đó nằm trong diff tiếp theo. Không reset hoặc ghi đè commit của người dùng.

## Kiểm chứng

- `flutter analyze --no-pub`: **No issues found**.
- **40 test đạt**: `ui11_movie_detail_test`, `home_navigation_test`, `home_redesign_test`, `remote_catalog_repository_test`.
- 15 ca UI-11: mapping banner, 320/360/390/430 px với chữ 1.6 lần, poster ngang/ảnh hỏng, tên/diễn viên/mô tả dài, mở rộng/thu gọn, retry gợi ý/nhận xét độc lập, loại ID trùng/hiện tại/không hợp lệ, A → B → Back giữ scroll, phản hồi muộn của A không lẫn vào B, dữ liệu gợi ý rỗng, phim sắp chiếu/trailer thiếu, CTA đúng ID, launcher lỗi/thử lại và URL không hợp lệ, phim lỗi/không tìm thấy có Back.
- Build Android debug thành công; cài lên `emulator-5554`, Android 17. `API_BASE_URL=http://10.0.2.2:8080`, `UI_PREVIEW=false`; giữ dữ liệu đăng nhập, không cần adb reverse.
- Trên app thật: Home → Avengers: Secret Wars (ID 17), thông tin/ảnh/metadata hiển thị; summary không có đánh giá thì không hiện 0.0. Cuộn tới cuối vẫn thấy CTA và thử lại gợi ý cục bộ.
- Trailer thật mở thành công: UI automation thấy trình phát video, tiến trình phát 0:11/2:24. Không khẳng định mọi URL trailer trong DB đều đúng phim; chỉ xác nhận URL API của phim đang kiểm tra mở được trên thiết bị.
- Gateway đọc trực tiếp: `/api/v1/movies/17` HTTP 200; `/api/v1/reviews/movies/17/summary` HTTP 200; `/api/v1/recommendation/content/17` HTTP 403. Trên app cũng hiển thị lỗi gợi ý và nút Thử lại. Không che lỗi bằng danh sách tự tạo.

Log local: `D:/MSS/.qa-runtime/ui11-analyze.log`, `ui11-tests.log`, `ui11-build.log`.

## Ảnh Android

- `D:/MSS/.qa-runtime/ui11-detail-before.png`: giao diện cũ, phim Avengers: Secret Wars.
- `D:/MSS/.qa-runtime/ui11-detail-after.png`: giao diện mới, cùng phim và cấu hình emulator.
- `D:/MSS/.qa-runtime/ui11-detail-related-state.png`: metadata, chưa có đánh giá, lỗi gợi ý và retry.
- `D:/MSS/.qa-runtime/ui11-trailer-dialog.png`: hộp thoại trailer thật.
- `D:/MSS/.qa-runtime/ui11-trailer-external.png`: trình phát video sau khi mở URL.

## Còn mở

- Recommendation qua gateway hiện trả **403**. Cần xác minh quyền/xác thực của runtime rồi QA danh sách thật, bấm A → B → A với API thành công. Chưa thay cấu hình xác thực BE trong batch này.
- iOS, thiết bị thật và review thẩm mỹ của người dùng.
- Khối tin mới/ưu đãi, yêu thích/chia sẻ chưa có flow được xác minh không thêm vào UI-11. UI-12–14 vẫn là các plan kế tiếp riêng.
