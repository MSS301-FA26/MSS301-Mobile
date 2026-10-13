# Home redesign — CINEPREMIER

Ngày 14/10/2026. Triển khai trên HomePage hiện tại theo yêu cầu và ảnh tham khảo: chỉ tham khảo bố cục/chuyển động, không sử dụng logo, màu thương hiệu hoặc ảnh chụp CGV làm asset.

## Đã triển khai

- Giữ nguyên theme, header, bottom navigation, router chi tiết phim và booking.
- Banner ngang 2.1:1, bo góc, ảnh contain để giữ nội dung, pagination, vuốt ngang, tự chuyển sau 5 giây. Tạm dừng khi chạm và khi app ra nền; hỗ trợ giảm chuyển động của hệ thống.
- Repository banner sử dụng GET `/api/v1/hero-banners`, ưu tiên ảnh mobile, hỗ trợ aliases trong DTO BE, resolve URL tương đối theo API origin. Loading/error/retry/empty độc lập với danh sách phim. CTA movie ID và URL an toàn dùng router/launcher hiện tại; BOOK_NOW kiểm tra trạng thái phim trước khi vào booking.
- Đúng hai tab Đang chiếu/Sắp chiếu. API `/api/v1/movies?status=NOW_SHOWING` và `status=UPCOMING` qua CatalogRepository hiện tại; cache riêng mỗi trạng thái. Không request khi swipe, không tự fallback sang mock khi API lỗi.
- Poster coverflow thật: Matrix4 perspective 0.0014, rotationY đối xứng khoảng 31.5°, side scale/opacity 0.82, shadow và z-order theo khoảng cách. Chỉ render các poster lân cận. Không lặp phim giả khi ít dữ liệu; đầu/cuối danh sách chỉ hiện hàng xóm thực sự tồn tại.
- Gesture trực tiếp cập nhật transform trong lúc kéo, threshold 27%, xét velocity, settle 380 ms; tap poster bên chuyển về giữa. Vertical scroll không bị chặn.
- Ambient glow cục bộ, nền gốc vẫn đen. Lấy màu từ ảnh decode nhỏ 24×24, cache theo source; không decode mỗi animation frame. Màu chuyển/interpolate trong vùng carousel.
- Một selected movie đã xác nhận sau settle dùng chung cho metadata/CTA. Thông tin fade/slide, thao tác action bị chặn khi poster đang chuyển. Đặt vé giữ đúng movie ID; Sắp chiếu chỉ Xem chi tiết.
- Hiển thị tên phim, tuổi/thời lượng nếu có, thể loại và ngày khởi chiếu. Home mapper không tự đặt tuổi P hoặc thời lượng 0 khi dữ liệu thiếu.
- Giữ QuickActions, PopBot và ResumeBookingBanner. Các dải phim cũ được thay bằng showcase dùng hai tab.
- Preview bằng `UI_PREVIEW=true` trong debug vẫn nằm trong chính HomePage. Chỉ Home dùng fixture/ảnh local; không chuyển repository booking/account/auth sang mock. Chặn điều hướng booking từ movie ID mẫu.

## Kiểm chứng

| Gate | Kết quả |
| --- | --- |
| Dart formatter | PASS |
| `flutter analyze --no-pub` | PASS — No issues found |
| `flutter test --no-pub --reporter expanded` | PASS — toàn bộ 136 test |
| 9 test mới trong `home_redesign_test.dart` | PASS — tab/cache, banner mapping, 0/1/2 phim, transform trước release, booking ID, spring-back, timer pause/resume |
| Test điều hướng Home tại 360/390/412 px | PASS |
| Edge layout 320 px với danh sách ít phim | PASS |
| Build Android debug | PASS |
| Emulator Android | Cài được; swipe coverflow, poster 3D, cuộn metadata/CTA và tab Sắp chiếu/Xem chi tiết đã kiểm tra |

Các test booking/payment chỉ cập nhật helper thao tác Home từ PageView cũ sang coverflow và cuộn tới CTA. Không thay assertions nghiệp vụ ghế/checkout/payment để làm test đạt.

## Giới hạn kiểm chứng

- API thật NOW_SHOWING, UPCOMING và hero-banners vẫn trả 500 do catalog BE đang thiếu schema; chưa thể xác nhận dữ liệu runtime thành công. Contract/query/mapping đã đối chiếu source BE và kiểm tra tự động. Không sửa BE/DB trong redesign này.
- Emulator hiện chạy bản debug preview với fixture đã có; banner preview không đại diện campaign production.
- Chưa QA iOS/thiết bị vật lý và chưa benchmark 60 FPS. Không tuyên bố chỉ tiêu FPS đã đạt từ ảnh chụp hoặc test widget.

## Chạy để chỉnh style

VS Code: Run and Debug → **Mobile - Home UI Preview**. Hoặc:

```powershell
flutter run -d emulator-5554 --dart-define=API_BASE_URL=http://127.0.0.1:8080 --dart-define=UI_PREVIEW=true
```

Bỏ `--dart-define=UI_PREVIEW=true` để dùng API thật; preview luôn tắt trong release/profile. Run config nằm ở `.vscode/launch.json`.

## File chính

- `lib/features/home/presentation/pages/home_page.dart`: bố cục, hai tab, điều hướng hiện tại.
- `lib/features/home/presentation/widgets/movie_coverflow.dart`: gesture, 3D, selected state và metadata/action.
- `lib/features/home/presentation/widgets/promotional_banner_carousel.dart`: carousel/timer/lifecycle/CTA.
- `lib/features/home/data/home_banner_repository.dart`: banner DTO/repository/provider theo BE.
- `lib/features/home/presentation/providers/home_preview_provider.dart`: cache theo tab và debug preview.
- `lib/features/home/presentation/providers/poster_ambient_color.dart`: cache màu ảnh nhỏ.
- `test/home_redesign_test.dart`: test mới; các helper điều hướng hiện có đã cập nhật.

## Ảnh kiểm tra

- [Poster giữa và hai bên sau settle](coverflow.png)
- [Metadata và nút Đặt vé khi cuộn](movie-information.png)
- [Tab Sắp chiếu và Xem chi tiết](upcoming.png)

Logs local tại `D:\MSS\.qa-runtime`: `home-redesign-analyze.log`, `home-regression-tests.log`, `home-redesign-build.log`. Tài liệu của thành viên khác không bị sửa.
