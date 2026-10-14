# UI-03 — Khám phá và lịch chiếu

Trạng thái: **đã triển khai, test/build Android đạt; chờ review UI, QA suất thật và iOS**. Ưu tiên: **trung bình**. Liên quan: plan chức năng 03, 04.

## Việc cần làm

- Thẻ Khám phá: tăng độ dễ đọc tên phim/metadata, đủ vùng chạm Đặt vé, tên hai dòng không ép các dòng khác.
- Không coi rating 0 mặc định là đánh giá thật. Cần trạng thái thiếu rating rõ trong model/mapper trước khi chọn ẩn hoặc ghi Chưa có đánh giá; không tự gán điểm.
- Lịch chiếu: giảm khung viền lồng nhau, làm giờ chiếu và trạng thái được chọn nổi bật.
- Suất chưa mở bán/quá giờ/không khả dụng có cách thể hiện khác trạng thái đã chọn; không chỉ phân biệt bằng màu.
- Skeleton, empty theo bộ lọc và lỗi tải theo UI-01. Lỗi không xóa lựa chọn/kết quả đã có khi còn hợp lệ.

## File dự kiến

`lib/features/discover/presentation/`, `lib/features/showtime/presentation/`, movie mapper khi cần xử lý rating.

## Tiêu chí hoàn thành và QA

Grid không tràn với tên dài/chữ lớn; giờ chiếu dễ quét mắt; rạp/ngày/phim/CTA vẫn giữ đúng ID. Kiểm tra không có lịch, nhiều phòng, suất disabled, ảnh lỗi và đổi filter. API rating chưa có phải ghi phụ thuộc, không dựng số.

## Kết quả ngày 14/10/2026

- Khám phá: tên 14 px/hai dòng co giãn theo text scale; thời lượng và thể loại tách dòng; nút từ 48 px. Các hàng thẻ có chiều cao theo nội dung. Màn dưới 350 px với chữ lớn chuyển một cột.
- Model `Movie.rating` nullable; mapper API/Home dùng null khi contract không có rating. Không hiện badge 0.0 hoặc null/10. Không tính/gán điểm từ dữ liệu mẫu. Count tab chỉ hiện cho tab đã có kết quả đúng bộ lọc.
- Lịch chiếu: bỏ viền card/phòng lồng nhau, giờ 18 px; ô suất tự tăng chiều cao và giảm số cột khi phóng chữ. Suất chọn có viền vàng và chữ ✓ Đã chọn; suất bị chặn có lý do theo status/thời gian.
- Chặn OPEN đã qua giờ; kiểm tra lại lúc nhấn tiếp tục. Đổi ngày bỏ lựa chọn cũ; kết quả refresh không còn suất hợp lệ thì không hiện CTA tiếp tục. Lỗi tải lại giữ dữ liệu và khóa thao tác mua.
- Ngày và thông tin rạp co giãn theo chữ; thông báo không có lịch không nhắc bộ lọc định dạng chưa triển khai.
- Analyzer, diff check và build Android đạt; 36 test liên quan pass, thêm test full-page 320 px/chữ 1,8 lần, bộ 11 test UI-03 pass sau sửa cuối.
- Emulator: Khám phá tải 6 phim thật, không còn 0.0; Lịch chiếu hiển thị đúng trạng thái trống. BE hiện không trả suất chiếu trong lượt QA này; chưa xác nhận UI suất chọn bằng dữ liệu BE thật.
- Ảnh và chi tiết: [UI03-RESULTS.md](UI03-RESULTS.md).

