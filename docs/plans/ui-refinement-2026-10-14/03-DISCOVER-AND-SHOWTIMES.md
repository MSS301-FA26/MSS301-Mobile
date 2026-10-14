# UI-03 — Khám phá và lịch chiếu

Trạng thái: **pending**. Ưu tiên: **trung bình**. Liên quan: plan chức năng 03, 04.

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

