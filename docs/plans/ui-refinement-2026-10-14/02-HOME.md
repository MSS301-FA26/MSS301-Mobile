# UI-02 — Trang chủ

Trạng thái: **đã triển khai và kiểm tra Android; chờ phản hồi giao diện và QA iOS**.
Ưu tiên: **trung bình**. Liên quan: plan chức năng 03, 11.

## Việc cần làm

- Giảm khoảng trống quanh tên phim, metadata, nút đặt vé và Xem trailer; giữ khoảng cách đủ thoáng và vùng chạm.
- Giữ banner crop, poster blur thử nghiệm, carousel có chiều sâu và đồng bộ metadata với phim đang chọn.
- Giữ bốn thẻ tiện ích trên một hàng. Kiểm tra tên/caption ở màn 320 px và chữ lớn.
- Thu gọn banner PopBot: ít dòng hơn, cân đối với thẻ PopBot đã có. Giữ CTA chat hoạt động.
- Giữ map ảnh FE đã chọn; không tự sửa dữ liệu/ID trong đợt chỉnh style.
- Áp dụng skeleton/banner lỗi/ảnh lỗi từ UI-01.

## File dự kiến

`lib/features/home/presentation/pages/home_page.dart`, `widgets/movie_coverflow.dart`, `promotional_banner_carousel.dart`, `quick_actions.dart`, `popbot_banner.dart`.

## Tiêu chí hoàn thành và QA

Ảnh ngang/dọc/hỏng hiển thị hợp lý; tên dài không lấn CTA; poster/metadata/đặt vé cùng một phim sau swipe hoặc đổi tab. So sánh ảnh trước/sau với người dùng. Kiểm tra carousel reduced motion và thao tác chạm/kéo.

## Kết quả ngày 14/10/2026

- Thu gọn khoảng cách poster → tên phim → metadata → CTA; nút trailer giữ vùng chạm 48 px.
- Bốn tiện ích giữ một hàng và màu/icon cũ. Label/caption 12/11 px, xuống dòng khi cần; chiều cao tự tăng theo chữ thay vì cắt caption.
- Banner PopBot còn nhận diện bot, một câu gợi ý và một CTA chat; đã mở trang chat thật trên emulator.
- Giữ banner crop/focalPoint, poster blur và map ảnh FE. Khi bật giảm chuyển động, banner dừng autoplay; chọn banner thủ công không chạy animation. Coverflow giảm animation theo thiết lập hệ thống.
- Analyzer đạt, 28 test Home đạt, build Android và cài emulator thành công với BE 8080. Test swipe/đổi tab đã được sửa kích thước viewport để thao tác thực sự chạm carousel.
- QA Android dữ liệu thật: Home tải phim/banner; swipe đổi đồng bộ từ Lật Mặt 7 sang Deadpool & Wolverine, metadata hiện 18+, 128 phút; khối tiện ích/PopBot không tràn.
- Kết quả/ảnh: [UI02-RESULTS.md](UI02-RESULTS.md).
- Còn mở: phản hồi thẩm mỹ của người dùng, thiết bị iOS và kiểm tra chữ lớn trên thiết bị thật. Chữ lớn 1,8 lần ở 320/360/390/430 px đã kiểm tra bằng widget test.

