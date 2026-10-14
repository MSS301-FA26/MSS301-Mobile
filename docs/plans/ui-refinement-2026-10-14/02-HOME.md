# UI-02 — Trang chủ

Trạng thái: **pending**; banner/poster đã có thay đổi local trước đợt này.
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

