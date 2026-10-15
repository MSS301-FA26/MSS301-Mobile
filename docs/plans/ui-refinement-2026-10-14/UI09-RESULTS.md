# UI-09 — Kết quả PopBot chat

Ngày triển khai: **15/10/2026**. Trạng thái: **hoàn tất triển khai UI; chờ người dùng review, QA iOS và chat AI thành công**.

## Đã điều chỉnh

- Header chat gọn, avatar bot dùng chung với banner Home; màu tím/lavender thống nhất, phân biệt bubble người dùng và PopBot.
- Hội thoại trống có ba câu hỏi gợi ý. Chạm để soạn vào input; chỉ gửi khi người dùng xác nhận bằng nút gửi hoặc bàn phím.
- Trạng thái “PopBot đang trả lời…” nằm ngay sau câu hỏi, có thông báo accessibility. Khóa gửi trong lúc chờ; không gửi chuỗi trống hoặc quá giới hạn 1000 theo guard hiện có.
- Lỗi nằm trong hội thoại, cạnh lượt gửi tương ứng. Thử lại giữ nguyên bubble câu hỏi; sửa câu hỏi đưa nội dung về input để chỉnh và gửi lại. Giải quyết lượt lỗi bằng thử lại/sửa trước khi tiếp tục hội thoại.
- Giữ conversationId từ API; reset hoặc đổi tài khoản hủy request, xóa hội thoại và bỏ phản hồi đến muộn. Không tạo câu trả lời giả.
- Composer nằm trên bàn phím và safe area. Tự cuộn khi đang ở cuối; phản hồi đến khi đọc tin cũ có nút “Tin nhắn mới”. Sửa tình huống ước lượng chiều cao danh sách với phản hồi rất dài khiến cuộn quá cuối.

## File

- `lib/features/popbot/presentation/chat_page.dart`
- `lib/shared/widgets/popbot_avatar.dart`
- `lib/features/home/presentation/widgets/popbot_banner.dart`
- `test/ui09_popbot_test.dart`
- `test/quick_action_pages_test.dart`: thêm frame sau nhập để nút gửi cập nhật trạng thái enabled.

## Kiểm chứng

- `flutter analyze --no-pub`: **No issues found**.
- `flutter test --no-pub test/ui09_popbot_test.dart test/quick_action_pages_test.dart test/quick_action_api_test.dart`: **19 test đạt** (8 test UI-09 và 11 test hiện có).
- Bao phủ 320/360/390/430 logical px, chữ 1.6 lần, bàn phím chiếm 280 px, câu hỏi/câu trả lời dài; không overflow và input không bị che.
- Bao phủ draft từ gợi ý, chống gửi trống/quá dài/khi busy, conversationId, lỗi/thử lại không lặp prompt, sửa prompt, reset, đổi tài khoản và phản hồi muộn, đọc tin cũ và xem phản hồi mới.
- Build debug Android thành công, đã cài lên `emulator-5554`, API `http://127.0.0.1:8080` qua adb reverse; `UI_PREVIEW=false`.
- Kiểm tra trực tiếp Home → PopBot, empty state, gợi ý điền câu hỏi, bàn phím, gửi câu hỏi và thử lại khi lỗi.

## QA API thật còn mở

Gửi “Làm sao để đặt vé xem phim?” và thử lại trên emulator: dịch vụ trả lỗi, app hiển thị trạng thái lỗi cùng Thử lại/Sửa câu hỏi. Log Docker của **recommendation-service** ghi `POST /api/v1/chat/message` trả **403** tại 14:42:17 và 14:43:10 theo timestamp log service.

Chưa xác minh được câu trả lời LLM thành công trên runtime hiện tại. Chưa xác định nguyên nhân cụ thể của 403; không suy ra thiếu OPENAI_API_KEY. Cần kiểm tra xác thực giữa gateway và service, sau đó test hai lượt chat thật trong cùng conversation. Không sửa BE, DB hoặc runtime trong batch UI này.

## Ảnh Android local

- Trước: `D:/MSS/.qa-runtime/ui09-chat-before.png`
- Sau, hội thoại trống: `D:/MSS/.qa-runtime/ui09-chat-after.png`
- Bàn phím và draft gợi ý: `D:/MSS/.qa-runtime/ui09-chat-keyboard.png`
- Lỗi runtime thật: `D:/MSS/.qa-runtime/ui09-chat-runtime.png`

QA iOS, thiết bị thật và đánh giá thẩm mỹ của người dùng chưa thực hiện. UI-09 chưa được đánh dấu nghiệm thu toàn bộ.

## Bổ sung nền chat theo yêu cầu

- Nền rạp phim tối với ánh tím, đường cong màn chiếu, tia sáng dịu và các hàng ghế mờ ở phía dưới. Vẽ trực tiếp bằng Flutter, không phụ thuộc ảnh mạng hoặc API.
- Lớp nền tĩnh dùng RepaintBoundary, IgnorePointer và ExcludeSemantics để không cản thao tác hoặc tạo nội dung thừa cho trình đọc màn hình.
- File: `lib/features/popbot/presentation/widgets/chat_cinema_background.dart`.
- Analyzer sạch, 8 test UI-09 đạt sau thay đổi nền; build Android thành công.
- Ảnh xem thử: `D:/MSS/.qa-runtime/ui09-chat-cinema-background.png`.
