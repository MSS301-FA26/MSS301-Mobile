# UI-15 — Khôi phục phim Home theo coverflow 3D

Ngày: **17/10/2026**. Baseline triển khai: Mobile `f41261f` + diff batch này.
Trạng thái: **hoàn tất code và kiểm tra Android; chờ người dùng review giao diện, QA iOS/TalkBack**.

## Thay đổi

- Thay hai dải thẻ phim ngang bằng một cụm tab **Đang chiếu / Sắp chiếu**, gạch vàng và coverflow 3D đã chốt.
- Poster giữa lớn, hai bên nghiêng theo chiều sâu, vuốt/snap; ảnh chính giữ tỷ lệ, nền ảnh blur và ambient theo poster. Không thay map ảnh hoặc dữ liệu phim bằng fixture.
- Tên phim wrap, phân loại tuổi chỉ xuất hiện khi API có, thời lượng/ngày/thể loại dưới carousel. CTA/trailer theo phim đã settle; phim sắp chiếu mở chi tiết. Trailer chỉ hiển thị khi URL HTTP(S) có host hợp lệ.
- Mỗi tab nhớ movie ID được chọn; quay lại tab/Home giữ đúng phim. Refresh đổi thứ tự giữ ID, nếu ID mất thì về phim hợp lệ. Dừng animation khi danh sách đổi.
- Khu phim dùng provider riêng với status chính xác và đọc các trang API; loại ID trùng, bỏ giới hạn hiển thị 20 phim của Home cũ. Đổi tab/retry khu phim không invalidate hero, mua vé nhanh hoặc rạp.
- Loading/error/empty và retry riêng; refresh lỗi giữ danh sách đã tải. Response đến sau từ tab khác không thay nội dung tab hiện tại.
- Bổ sung semantics tăng/giảm để chuyển phim và nhãn giá trị kế tiếp/trước, giữ giảm chuyển động. Prefix key `home-3d` tránh trùng key poster với hero hiện tại.

## Các khối giữ nguyên

Thứ tự: **hero → mua vé nhanh → tab phim 3D → rạp phim**.

Không có diff ở `home_hero_carousel.dart`, `home_quick_booking.dart`, `home_cinemas_section.dart`, `home_providers.dart`, header và bottom navigation. `HomePage` chỉ đổi khu phim, giữ callbacks và auth boundary của mua vé nhanh/rạp. Không sửa BE/DB hoặc login/register.

## File chính

- `home_page.dart`: tích hợp khu phim mới.
- `home_movie_section.dart`: hai tab, trạng thái API và lưu lựa chọn.
- `movie_coverflow.dart`: tái dùng hiệu ứng cũ, giữ ID qua refresh, hỗ trợ key riêng/semantics và trailer hợp lệ.
- `home_preview_provider.dart`: tuổi có dữ liệu và phân trang danh sách theo status; mặc định vẫn API thật, preview chỉ khi bật rõ.
- `test/ui15_home_coverflow_test.dart`: 13 ca mới; cập nhật các test Home/booking/completion để thao tác qua carousel mới.

## Kiểm chứng

- **42 test đạt**: UI-15 + Home redesign/navigation/wallet + booking entry + completion/account. Log: `D:/MSS/.qa-runtime/ui15-tests.log`.
- Các ca mới: bốn chiều rộng 320/360/390/430 và text scale 1.6; nhớ riêng từng tab; CTA đúng phim; thứ tự refresh/ID mất; empty/error/retry; giữ dữ liệu khi refresh lỗi; response tab chậm; trailer hợp lệ/không hợp lệ và ảnh thiếu; reduced motion; bộ chọn mua vé nhanh không mất lựa chọn/không tạo lại state rạp; phân trang status và khử trùng ID.
- Bộ test cũ tiếp tục kiểm tra 0/1/nhiều phim, transform theo ngón tay, snap, booking theo phim settle, đăng nhập/ghế và thanh toán/QR theo trạng thái.
- `flutter analyze --no-pub`: **No issues found** (`ui15-analyze.log`).
- `flutter build apk --debug --no-pub`: **đạt** (`ui15-build.log`); APK cài thành công lên emulator `emulator-5554` và khởi động lại.

### Emulator với API thật

- Gateway `localhost:8080` hoạt động; GET phim UPCOMING trả 200. UI hiện **11 phim đang chiếu / 6 phim sắp chiếu** tại thời điểm kiểm tra, không suy diễn status theo ngày phát hành.
- Vuốt từ Avengers sang Avatar: poster/metadata/CTA cập nhật đúng. Đổi sang Sắp chiếu, mở chi tiết phim, Android Back, rồi về Đang chiếu: vẫn chọn Avatar. Không tạo booking/hold/payment trong thao tác QA này.
- Cuộn dọc từ phim xuống danh sách rạp hoạt động, vẫn hiển thị bộ lọc thành phố và thẻ rạp thật.
- Trước: `D:/MSS/.qa-runtime/ui15-before-home.png`, `ui15-before-movies.png`.
- Sau: `ui15-after-home.png`, `ui15-after-movies.png`, `ui15-after-selected.png`, `ui15-after-upcoming.png`, `ui15-after-cinemas.png` trong cùng thư mục.
- Ảnh baseline có poster chưa tải xong, còn ảnh sau chụp khi đã tải; không dùng khác biệt tải ảnh để kết luận có thay nguồn ảnh. Hai bộ ảnh minh họa thay đổi bố cục, không phải so sánh pixel cùng frame.

## Còn review / QA

- Người dùng xác nhận lại thẩm mỹ 3D, kích thước và khoảng cách sau khi tích hợp cùng Home mới.
- iOS, TalkBack/VoiceOver và hiệu năng trên thiết bị thật. Test semantics/reduced motion đạt chưa thay thế trải nghiệm trình đọc màn hình thật.
- Chuỗi mua vé nhanh đủ phim/rạp/ngày/giờ với dữ liệu BE thật; test hiện đã xác nhận lựa chọn phim giữ qua đổi tab, widget rạp giữ state và regression booking/auth đạt. Không tạo đơn thật chỉ để chứng minh giao diện.
- UI-15 không thay đổi điều kiện mở bán, giá, hold, checkout hay xử lý thanh toán.
