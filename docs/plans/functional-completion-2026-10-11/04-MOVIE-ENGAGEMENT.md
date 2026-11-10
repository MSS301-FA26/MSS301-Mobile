# 04 — Trailer, reviews và gợi ý AI

Trạng thái: **pending**. Ưu tiên: trung bình; response gợi ý cần sửa sớm.

## Việc cần làm

- Thay trailer ảnh bằng playback hoặc mở URL ngoài có xử lý thất bại; hỗ trợ URL trống/hỏng.
- Sửa parser recommendation theo `ApiResponse<ContentRecommendationResponse>`: đọc `data.recommendations` qua route legacy đang rewrite tới AI service.
- Hiển thị loading/error/retry cho reviews/recommendations; không ẩn lỗi như danh sách trống.
- Thêm phân trang review, viết/sửa/xóa/report theo endpoint và quyền đã xác nhận; kiểm tra eligibility đã xem phim.
- Nối nút đánh giá từ Orders tới đúng phim và trạng thái eligibility.
- Gợi ý cá nhân, feedback/click và AI search là batch riêng sau khi chốt Gateway/auth contract. Watchlist theo Plan 11.

## Scope dự kiến

`movie_engagement_repository.dart`, DTO/provider, `movie_detail_page.dart`, trailer widget, Orders review entry.

## Tiêu chí hoàn thành và kiểm chứng

- Parser test sử dụng response hiện tại của AI service, không chỉ fixture list cũ.
- Trailer phát/mở được trên thiết bị; lỗi URL có hành vi rõ.
- Review chỉ mutation khi đủ quyền/điều kiện; pagination và retry hoạt động.
