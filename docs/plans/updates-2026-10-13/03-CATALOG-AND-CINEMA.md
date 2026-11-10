# 03 — Home, Discover, rạp và suất chiếu

Cập nhật 13/10/2026 theo BE `9921498`, Mobile `c7e9edd`. Trạng thái: **pending**. Ưu tiên: cao cho giá/lịch chiếu trước QA Plan 07; trung bình cho các mục trình bày còn lại.

## Thay đổi BE ảnh hưởng

- Quote chỉ cho suất OPEN có startTime ở tương lai; SCHEDULED chưa bán được.
- Giá ghế đôi và phân bổ phụ thu đã đổi; không coi couplePrice luôn là giá mỗi ghế.
- Showtime có weekendSurchargeAmount/holidaySurchargeAmount và cấu hình phụ thu theo rạp. Khung giờ đêm là từ 22:00 hoặc trước 03:00.
- Giá admin cho phép khoảng 0–10.000.000 theo DTO mới; Mobile không áp dụng giới hạn giá cũ hoặc coi 0 đồng là thiếu giá.
- Food category là phần mở rộng catalog cho Plan 06/09, không đưa quản trị danh mục vào UI customer Plan 03.

## Việc cần làm

### A. Giá và suất chiếu — thực hiện trước

- Đối chiếu các field giá theo loại vé/loại ghế với công thức BE sau pull, nhất là COUPLE. Mobile hiện cộng giá couple theo từng seat trong _ticketPrice; cần kiểm tra việc chia giá cặp và phụ thu để không nhân đôi tạm tính.
- Tách giá 0 hợp lệ khỏi null/thiếu giá. Không tự dựng giá thay cho cấu hình chưa có.
- Dùng quote/booking BE làm giá authoritative khi giữ ghế và checkout; phần giá trước đó phải thể hiện là tạm tính và khớp test contract.
- Kiểm tra các mốc đêm 21:59, 22:00, 02:59, 03:00; cuối tuần, ngày lễ và ngày có cả hai phụ thu. Đối chiếu với response/quote thay vì tự áp dụng thêm phụ thu lần nữa.
- Chỉ bật CTA mua cho OPEN còn ở tương lai; SCHEDULED hiển thị chưa mở bán, các trạng thái khác không được đi tiếp như suất hợp lệ.
- Phân biệt trạng thái không còn suất bán với lỗi tải API; vẫn có retry cho lỗi mạng.

### B. Chọn rạp/ngày/phim

- Bổ sung cinemaId vào query/provider nếu contract public hỗ trợ; thay đổi rạp phải làm mới danh sách và xóa slot chọn cũ.
- Header, thông tin rạp và lịch chiếu dùng cùng rạp được chọn, giữ đúng movieId/showtimeId/room khi đến màn ghế.
- Rạp ưu tiên dùng customer endpoint hiện có nếu thuộc scope; không dùng API admin để thay thế.
- Hiển thị lịch chiếu và lọc ngày theo Việt Nam UTC+7. Chuỗi LocalDateTime không offset giữ quy ước hiện tại; timestamp có offset phải chuyển đúng ngày/giờ Việt Nam.
- Xác nhận khoảng ngày bán vé với sản phẩm/contract trước khi thay mặc định 7 ngày; không coi giới hạn 7 ngày là quy tắc BE đã chốt.

### C. Home và Discover

- Đọc hero banner từ API public, map CTA và URL ảnh; xử lý banner trống, ảnh hỏng, CTA không hợp lệ hoặc target không còn bán được.
- Lấy rating/review summary thật; khi chưa có đánh giá thì ẩn số hoặc hiện trạng thái chưa có đánh giá, không dùng rating = 0 từ mapper làm điểm thật.
- Count riêng NOW_SHOWING/UPCOMING. Hiện hai tab Discover đều dùng page.totalItems của query đang mở; cần tách tổng theo từng trạng thái và phạm vi search/filter.
- Pagination giữ kết quả cũ khi load more lỗi và có retry; đổi query trong lúc request chờ không trộn/lặp phim.
- Nối dữ liệu rạp thật và giữ lịch sử lựa chọn trong scope được phép, không giữ state rạp/slot sai sau đổi tài khoản nếu có preference riêng.

## Scope

Catalog DTO/repository/provider, Home/Discover/Showtimes, header/cinema info; sửa tạm tính tại seat page nếu cần để đồng bộ công thức BE. Không triển khai màn quản trị giá/rạp trong Mobile customer.

## Kiểm chứng và tiêu chí DONE

- Test mapping/query/count/phân trang: hai trạng thái, đổi filter nhanh, load more lỗi, duplicate ID, ảnh/banner/CTA trống.
- Test giá: ghế thường/VIP/đôi, hai ghế đôi cùng loại vé, giá 0, phụ thu và quote BE khớp tạm tính/đơn.
- QA Gateway với rạp có/không có lịch, OPEN/SCHEDULED/quá giờ, chọn rạp/ngày/phim và back về không giữ slot sai.
- Đối chiếu nguồn timezone và các mốc chuyển ngày Việt Nam; không cộng 7 giờ vào duration hold.
- Có bằng chứng Android và các kích thước màn thuộc scope; các mục UI/query chưa kiểm tra phải ghi pending theo Plan 12.

## Phụ thuộc môi trường

Recommendation-service cũ bị xóa file nhưng compose còn tham chiếu. Nếu ảnh hưởng phần gợi ý hoặc khởi động Gateway, ghi lỗi BE/runtime; catalog không được treo toàn trang chỉ vì recommendation không hoạt động.
