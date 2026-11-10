# UI-02 — Kết quả tinh chỉnh Trang chủ

Ngày: 14/10/2026. Trạng thái: code/Android đạt; chờ người dùng review và QA iOS.

## Thay đổi

- `home_page.dart`: khoảng cách từ tiện ích đến PopBot còn 16 px.
- `movie_coverflow.dart`: giảm khoảng trống quanh poster/metadata/CTA; trailer có vùng chạm 48 px. Giữ ảnh foreground contain trên nền blur, transform 3D và callback theo phim đã settle.
- `quick_actions.dart`: giữ bốn thẻ một hàng; bỏ chiều cao cố định và ellipsis ở label/caption, cho phép xuống dòng và tăng chiều cao khi phóng chữ. Giữ route bắp nước/chat/điểm và VIP chưa khả dụng.
- `popbot_banner.dart`: thu gọn nội dung còn header, một câu gợi ý và CTA chat; nền tím nhẹ.
- `promotional_banner_carousel.dart`: vùng chạm chỉ mục 48 px và semantic tên/trạng thái chọn; các chỉ mục xuống hàng nếu nhiều banner. Cập nhật autoplay khi thiết lập reduced motion thay đổi, dùng jumpToPage cho chọn thủ công khi giảm chuyển động.

## Kiểm chứng

- `flutter analyze --no-pub`: không có lỗi.
- 28 test trong `ui02_home_test.dart`, `home_redesign_test.dart`, `home_navigation_test.dart`, `home_banner_selection_test.dart`: pass.
- Test viewport của ca swipe/đổi tab được sửa, sau đó chạy lại riêng và pass, không còn cảnh báo drag ngoài màn hình.
- 320/360/390/430 logical px với text scale 1,8: không overflow, bốn thẻ cùng hàng, tên phim dài/ảnh poster hỏng không làm mất CTA, CTA PopBot hoạt động.
- Test reduced motion: bật trong khi banner đang có timer sẽ dừng autoplay, vẫn chọn banner thủ công được. Lỗi animateToPage với duration zero tìm thấy trong test đã được sửa bằng jumpToPage.
- APK debug build/cài thành công; BE thật `http://127.0.0.1:8080`, UI_PREVIEW=false, emulator Android 1080×2424 px.
- QA emulator: Home tải dữ liệu thật; swipe đổi poster/tên/metadata từ Lật Mặt 7 sang Deadpool & Wolverine (18+, 128 phút, 01/10/2026); CTA PopBot mở đúng màn chat. Không gửi tin nhắn AI hay tạo đơn trong QA style này.

## Ảnh trên máy local

- [Home trước chỉnh](D:/MSS/.qa-runtime/ui02-before.png).
- [Home sau chỉnh](D:/MSS/.qa-runtime/ui02-after.png).
- [Thông tin phim, tiện ích và PopBot sau chỉnh](D:/MSS/.qa-runtime/ui02-after-actions.png).
- [Sau swipe sang Deadpool](D:/MSS/.qa-runtime/ui02-after-swipe.png).

Banner tự chuyển và ảnh network tải theo thời điểm, vì vậy ảnh trước/sau có thể ở phim khác nhau. So sánh bố cục/khoảng cách, không dùng các ảnh này để đánh giá thay đổi nội dung phim.

## Còn mở

- Người dùng review trực tiếp bản đã cài trên emulator.
- QA iOS, chữ lớn trên thiết bị thật và kiểm tra cảm giác thao tác trên máy cấu hình thấp.
- Map ảnh FE giữ theo quyết định trước; không sửa dữ liệu phim hoặc ID trong batch UI này.
