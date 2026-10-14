# UI-04 — Header booking và vé/ghế

Trạng thái: **đã triển khai; test/analyzer đạt, chờ QA booking thật, review UI và iOS**. Ưu tiên: **cao**. Liên quan: plan chức năng 05.

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

## Kết quả triển khai

- AppShell có header booking gọn gồm Back, tên màn, bước và lối về Home có leave guard. Áp dụng cho Vé & Ghế (kể cả loading/error), Bắp nước, Xác nhận đơn và Thanh toán. Header các tab chính và màn vé kết quả vẫn dùng chế độ mặc định.
- Gỡ header Back/tiêu đề trùng trong body Bắp nước/Xác nhận đơn. Summary ở Vé & Ghế gọn, vẫn có phim/rạp/phòng/giờ Việt Nam.
- Thẻ loại vé giảm padding, tên 15 px; +/- giữ vùng chạm 48 px và tooltip. Thẻ trẻ em giữ nguyên lý do bị chặn, không xuất hiện nút thêm/giảm khi không đủ điều kiện.
- Ghế thường/VIP có vùng chạm 48×48; ghế đôi 56×48 mỗi ghế. Sơ đồ rộng cuộn ngang/phóng to, không co ghế dưới kích thước ban đầu. Legend xuống dòng, có hướng dẫn ghế đôi cần hai vé cùng loại.
- Countdown Vé & Ghế chuyển lên vùng cố định dưới progress, dùng deadline booking hiện có; Bắp nước/Checkout/Payment giữ countdown BE. Không tạo deadline mới khi chuyển màn.
- Footer Vé & Ghế chuyển bố cục dọc ở màn nhỏ/chữ lớn; giữ tổng tiền và CTA.
- 21 test liên quan pass, analyzer không lỗi. Bộ mới kiểm tra Back/leave guard, deadline xuyên bước và sơ đồ 16 ghế ở 320/430 px với chữ 1,8 lần.
- BE local hiện trả 0 suất chiếu khi kiểm tra: chưa thể QA màn chọn ghế có dữ liệu thật; không tạo suất hay sửa DB để chụp UI.
- Chi tiết: [UI04-RESULTS.md](UI04-RESULTS.md).

