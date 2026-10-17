# UI-19 — Một màn lịch chiếu, lọc phim/rạp/ngày có thể xóa

Ngày lập: **17/10/2026**. Ưu tiên: **P1**. Trạng thái: **planned**. Liên quan UI-18.

## Flow cần đạt

- Home/chi tiết phim → Đặt vé → Lịch chiếu với chip **Phim: tên phim ×**.
- Xóa chip phim → tất cả phim trong ngày/rạp đang chọn, không phải thoát màn hoặc quay Home.
- Danh sách/chi tiết rạp → Xem lịch → chip **Rạp: tên rạp ×**; có thể kết hợp phim/ngày hoặc xóa rạp để xem nhiều rạp.
- Tab Lịch chiếu → tất cả phim/rạp, ngày mặc định hôm nay theo lịch Việt Nam. “Xóa tất cả” trả về trạng thái này; từng chip xóa riêng giữ các bộ lọc còn lại.

## Thiết kế và state

1. Khu lọc gọn Phim/Rạp/Ngày, chip lựa chọn rõ, nút xóa từng chip và xóa tất cả. Có search trong sheet phim/rạp; không ép người dùng đi tuần tự như mua vé nhanh.
2. Route/query là nguồn filter có thể chia sẻ/restore: movieId, cinemaId, date. ID truyền từ trang trước chỉ seed bộ lọc; thao tác xóa phải cập nhật route và provider thật, không bị `widget.movieId` gán trở lại.
3. Tách filter movieId khỏi movieId của suất đang chọn; khi bất kỳ filter thay đổi, xóa selectedSlot cũ và kiểm tra bookable theo thời gian hiện tại.
4. Mở rộng `ShowtimeQuery` equality/hash và catalog repository với cinemaId; request đổi tab/bộ lọc có guard response cũ. Không làm thay đổi query của mua vé nhanh/rạp ngoài phạm vi cần thiết.
5. BE public `/api/v1/showtimes` đã hỗ trợ movieId/roomId/cinemaId/date và phân trang. `/customer-schedule` hiện chỉ nhận movieId/date; không gửi cinemaId vào endpoint chưa hỗ trợ rồi cho rằng đã lọc.
6. Đọc đủ trang, nhóm **rạp → phim → phòng/định dạng → giờ** theo dữ liệu thực. Giữ cinemaId/cinemaName và metadata phòng khi lọc/copy; `_visibleRooms` hiện đang dựng lại room mà bỏ các trường rạp cần được sửa.
7. Chuẩn hóa ngày theo Việt Nam/LocalDateTime hiện hành. Calendar và giới hạn ngày theo dữ liệu/quy tắc API; trạng thái chưa có suất khác với lỗi tải. Không tự suy ra hết phim vì một trang 100 suất không có dữ liệu tương ứng.
8. CTA tới seatSelection lấy đúng showtimeId; giữ auth redirect; không tạo hold khi đổi bộ lọc.

## Nghiệm thu

Kiểm tra đầy đủ bốn entry: phim, rạp, lịch chung, mua vé nhanh. Xóa phim còn rạp/ngày, xóa rạp còn phim/ngày, clear all, route/back/resume, ID không tồn tại, request chậm/ngược thứ tự, phân trang, suất đóng/vừa bắt đầu, nhiều rạp cùng tên phòng. Không còn màn lọc cố định không thoát được.

File chính: `showtimes_page.dart`, `showtimes_provider.dart`, model query/room, repository, router, các CTA phim/rạp. Ghi `UI19-RESULTS.md`, test query/route và QA API thật.
