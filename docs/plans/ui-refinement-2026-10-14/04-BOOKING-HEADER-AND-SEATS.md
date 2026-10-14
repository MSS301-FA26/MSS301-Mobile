# UI-04 — Header booking và vé/ghế

Trạng thái: **pending**. Ưu tiên: **cao**. Liên quan: plan chức năng 05.

## Việc cần làm

- Tạo header booking gọn: Back, tiêu đề/bước hiện tại; rạp/phim trong phần tóm tắt và thời gian giữ ghế khi đã có hold.
- Đối chiếu mọi page dùng AppShell trước khi thêm chế độ header; các tab chính vẫn dùng header hiện tại.
- Thu gọn thẻ số lượng vé nhưng giữ tên loại vé, số lượng, trạng thái gán ghế và vùng chạm +/-.
- Vé trẻ em không đủ điều kiện: giữ thẻ giải thích lý do, ẩn/khóa thao tác thêm theo quy tắc đã triển khai.
- Sơ đồ ghế đủ lớn để chạm, legend dễ đọc; ghế đôi vẫn gắn hai ghế cùng loại vé, tổng tối đa 8.
- Giữ leave guard, hold/cancel/retry và deadline BE; không reset countdown khi đổi màn.

## File dự kiến

`lib/shared/widgets/app_shell.dart`, `cinema_header.dart`, `lib/features/seat/presentation/pages/seat_selection_page.dart`, `lib/features/booking/presentation/widgets/`.

## Tiêu chí hoàn thành và QA

Sơ đồ ghế xuất hiện sớm hơn mà vẫn đọc đủ cảnh báo. Back/header mới không bỏ qua leave guard. Kiểm tra ghế đôi, loại vé bị chặn, hết hold, mạng lỗi và chữ lớn trên màn nhỏ.

