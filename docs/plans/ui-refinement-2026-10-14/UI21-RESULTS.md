# UI-21 — Kết quả triển khai

Ngày: **01/11/2026**. Phạm vi: Mobile, diff local chưa commit.

## Đã làm

- Giữ bố cục chi tiết phim từ UI-11: hero/poster, metadata, nội dung mở rộng, credits/reviews khi có dữ liệu, phim liên quan có retry và CTA lịch chiếu lọc đúng movie ID.
- Thêm Lưu/Bỏ lưu trên chi tiết phim và lối vào danh sách muốn xem. Khách chưa đăng nhập được dẫn sang đăng nhập; không tạo dữ liệu khách trộn vào tài khoản.
- CTA đặt vé vẫn dựa trạng thái mở bán; không đổi recommendation lỗi thành phim ngẫu nhiên.

## Kiểm chứng và giới hạn

- Test UI-11 về tên dài/chữ lớn 320–430, recommendation, phim sắp chiếu và route đặt vé đạt trong nhóm **31/31 test** UI-06/UI-11/UI-22/UI-23. Analyzer và build Android đạt.
- Chưa có ảnh Android trước/sau hoặc review thẩm mỹ của người dùng; iOS, ảnh/trailer và recommendation bằng API thật cần QA riêng.
