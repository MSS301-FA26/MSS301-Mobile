# UI-09 — PopBot chat

Trạng thái: **đã triển khai UI ngày 15/10/2026; analyzer/19 test/build Android đạt; chờ review, QA iOS và chat AI thành công**. Ưu tiên: **trung bình**. Liên quan: plan chức năng 11.

Kết quả: [UI09-RESULTS.md](UI09-RESULTS.md).

## Việc cần làm

- Đồng bộ nhận diện tím, avatar/icon bot và bubble giữa chat với Home.
- Thêm câu hỏi gợi ý ở trạng thái hội thoại trống, có thể điền/gửi qua flow thật hiện có.
- Hiển thị đang trả lời rõ ràng; bảo đảm chống gửi lặp, input limit và retry không nhân đôi prompt.
- Lỗi dịch vụ nằm sát lượt gửi liên quan; cho thử lại hoặc sửa câu hỏi, không giả câu trả lời.
- Input luôn thấy khi mở bàn phím; cuộn theo tin mới hợp lý, không kéo người dùng khỏi nội dung đang đọc.
- Reset/đổi tài khoản bỏ phản hồi cũ và hội thoại cũ như cơ chế hiện tại.

## Dependency và file dự kiến

Runtime kiểm tra ngày 15/10: `recommendation-service` đang chạy nhưng trả HTTP 403 cho `POST /api/v1/chat/message` khi gửi từ emulator và thử lại. Chưa xác nhận chat LLM thành công; chưa kết luận nguyên nhân là thiếu API key. Phần UI đã kiểm thử với repository kiểm soát trong test và trạng thái lỗi thật trên Android.
`lib/features/popbot/presentation/chat_page.dart`, `lib/features/home/presentation/widgets/popbot_banner.dart`, `lib/shared/widgets/popbot_avatar.dart`.

## Tiêu chí hoàn thành và QA

Kiểm tra bàn phím, prompt/response dài, pending, lỗi, retry và reset giữa request. Gợi ý không tạo phản hồi cục bộ giả; giữ đúng conversationId. QA LLM thật ghi riêng khi cấu hình sẵn sàng.

