# UI-21 — Bố cục chi tiết phim và nối hành trình xem/đặt vé

Ngày lập: **17/10/2026**. Ưu tiên: **P2**. Trạng thái: **planned**. Mở rộng UI-11, liên quan UI-19/UI-22.

## Hướng điều chỉnh

- Hero/trailer ngang crop có chủ đích; poster nhỏ giữ tỷ lệ, nền blur khi ảnh ngang. Tên đầy đủ, badge tuổi + giải thích và metadata dễ quét, không chồng chữ lên vùng ảnh khó đọc.
- Thu gọn khối thông tin và khoảng trống; nội dung phim có Xem thêm/Thu gọn; thông tin đạo diễn/diễn viên/ngôn ngữ chỉ khi API có.
- Một CTA Đặt vé cố định khi mở bán; chạm vào mở lịch chung với chip phim theo UI-19. Phim chưa mở bán có trạng thái rõ, không nút giả hoạt động.
- Thêm Lưu phim/Bỏ lưu và entry danh sách muốn xem sau khi repository UI-22 sẵn sàng; chia sẻ chỉ dùng link hợp lệ.
- Phim liên quan từ API recommendation hiện có, giữ movie ID; lỗi/403 có trạng thái retry phù hợp, không thay bằng phim ngẫu nhiên rồi gắn nhãn AI. Chọn phim liên quan reset scroll/dữ liệu chi tiết đúng ID.
- Reviews giữ summary và người đã mua theo BE; không thêm số lượt thích/rating giả. Phân trang/mutation review chỉ triển khai nếu contract và auth đã xác minh, không gộp tùy tiện vào đổi style.

## Nguồn và giới hạn

`GET /api/v1/movies/{id}` qua repository hiện có; provider reviews/recommendations hiện hành phải được đối chiếu quyền/envelope tại lúc làm. Giữ map ảnh và dữ liệu BE; không sửa banner Home trong batch chi tiết phim.

## File / QA

`movie_detail_page.dart`, `movie_detail_header/content/engagement` và các section đang dùng, route CTA và watchlist widget. Ưu tiên tái dùng theme/component thay vì tạo token toàn app mới.

Test phim now/upcoming/inactive, metadata thiếu, ảnh ngang/dọc/lỗi, tên dài/chữ lớn, recommendation lỗi/success, phim liên quan → back, watchlist qua đổi tài khoản, CTA lọc phim rồi xóa ra lịch chung. Chụp trước/sau trên Android, ghi iOS chưa chạy tại `UI21-RESULTS.md`; cần người dùng review thẩm mỹ.
