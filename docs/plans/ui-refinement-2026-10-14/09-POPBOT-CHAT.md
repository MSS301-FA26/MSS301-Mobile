# UI-09 — PopBot chat

Trạng thái: **pending**. Ưu tiên: **trung bình**. Liên quan: plan chức năng 11.

## Việc cần làm

- Đồng bộ nhận diện tím, avatar/icon bot và bubble giữa chat với Home.
- Thêm câu hỏi gợi ý ở trạng thái hội thoại trống, có thể điền/gửi qua flow thật hiện có.
- Hiển thị đang trả lời rõ ràng; bảo đảm chống gửi lặp, input limit và retry không nhân đôi prompt.
- Lỗi dịch vụ nằm sát lượt gửi liên quan; cho thử lại hoặc sửa câu hỏi, không giả câu trả lời.
- Input luôn thấy khi mở bàn phím; cuộn theo tin mới hợp lý, không kéo người dùng khỏi nội dung đang đọc.
- Reset/đổi tài khoản bỏ phản hồi cũ và hội thoại cũ như cơ chế hiện tại.

## Dependency và file dự kiến

AI runtime hiện thiếu OPENAI_API_KEY; style empty/loading/error có thể thực hiện độc lập. Không coi chat trả lời thật đã QA khi dịch vụ còn lỗi.
`lib/features/popbot/presentation/chat_page.dart`, `lib/features/home/presentation/widgets/popbot_banner.dart`.

## Tiêu chí hoàn thành và QA

Kiểm tra bàn phím, prompt/response dài, pending, lỗi, retry và reset giữa request. Gợi ý không tạo phản hồi cục bộ giả; giữ đúng conversationId. QA LLM thật ghi riêng khi cấu hình sẵn sàng.

