# 03 — Home, Discover, rạp và suất chiếu

Trạng thái: **pending**. Ưu tiên: trung bình.

## Việc cần làm

- Đọc hero banner từ API public và map CTA theo dữ liệu BE; xử lý banner trống/ảnh hỏng/CTA không hợp lệ.
- Lấy rating thật hoặc ẩn rating khi chưa có; không hiển thị điểm 0 do mapper gán mặc định.
- Sửa count riêng cho hai tab Discover; hiển thị lỗi load more, giữ kết quả và cho thử lại.
- Kiểm tra pagination khi đổi search/filter lúc request cũ còn chạy; không trộn kết quả của hai query.
- Tạo chọn rạp và lọc lịch chiếu theo contract; nối rạp ưu tiên khi contract customer cho phép.
- Thay thông tin rạp cố định bằng dữ liệu rạp được chọn; xác định khoảng ngày bán vé thay vì mặc định bảy ngày nếu yêu cầu sản phẩm rộng hơn.

## Scope dự kiến

Catalog DTO/repository/provider, Home/Discover/Showtimes, header và cinema info.

## Tiêu chí hoàn thành và kiểm chứng

- Banner/CTA/rating/count đúng nguồn dữ liệu; search và tải thêm không lặp/trộn phim.
- Chọn rạp/ngày/phim giữ đúng showtimeId khi tới ghế.
- Có test mapping/query và kiểm thử rạp có/không có lịch, pagination lỗi và đổi filter nhanh.
