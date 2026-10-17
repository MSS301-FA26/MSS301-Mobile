# UI-20 — Style thanh toán và kết quả cho vé / bắp nước

Ngày lập: **17/10/2026**. Ưu tiên: **P1**. Trạng thái: **planned**. Tích hợp sau UI-17, giữ logic UI-13/14.

## Nhận xét và mục tiêu

Hai flow đang có màn và state riêng, cách nhấn tổng tiền/trạng thái/CTA chưa đồng đều. Giữ đen–vàng, làm một hệ bố cục dùng chung nhưng nội dung đúng loại đơn; không thay đổi giao diện VNPay/ngân hàng do bên ngoài quản lý.

## Thiết kế dự kiến

1. **Xác nhận/thanh toán:** header gọn, countdown đúng ngữ cảnh, tóm tắt phim hoặc rạp nhận food, chi tiết đơn có thể mở rộng. Tổng cuối/CTA cố định, dòng phụ ít cạnh tranh. Giữ combo ngang/sheet UI-14 và cảnh báo quote mới ngay gần CTA.
2. **Chờ thanh toán:** thẻ trạng thái, số tiền, mã đơn và một CTA chính Tiếp tục thanh toán; nút Kiểm tra kết quả/Quay lại đơn dễ tìm. Không dùng cùng một spinner vô hạn cho chờ cổng và chờ BE xác nhận.
3. **Đang xác nhận:** giải thích ngắn “Đang kiểm tra với hệ thống”, retry có trạng thái; không chuyển xanh hoặc hiện QR sớm vì URL báo success.
4. **Thành công vé:** biểu tượng thành công, tên phim/rạp/suất/ghế, số tiền đã trả, mã đơn; CTA Xem vé QR và về đơn/Home. Tách receipt thanh toán với QR vé đủ điều kiện.
5. **Thành công food:** mã đơn, rạp nhận, món/số lượng/tổng, trạng thái nhận hàng và mã nhận nếu BE có; không dựng ghế/phim trống, không nhầm QR nhận hàng với vé vào rạp.
6. **Fail/cancel/expired/unknown:** thông điệp và CTA khác nhau, không tô cùng màu hoặc ghi thanh toán thất bại khi chỉ chưa đồng bộ được. Không hủy đơn đã trả tiền khi hết thời gian hold ở client.

## Bảo toàn nghiệp vụ

Tiền từ quote/order BE, không cộng phụ thu lần nữa; snapshot là nguồn của receipt. Thời gian hold vé và expiry đơn food dùng đúng deadline riêng, dừng countdown không còn ý nghĩa sau PAID. Khóa gửi lặp, giữ retry/idempotency và guard user/order của controller hiện có. Không thêm voucher/phương thức thanh toán chưa tích hợp.

## File / QA

`checkout_page.dart`, `payment_result_page.dart`, `food_checkout_page.dart`, các widget summary/status/CTA dùng chung; không viết lại controller chỉ để đổi padding/màu.

Review trước/sau theo từng trạng thái vé/food, tên dài/8 ghế/nhiều món/ảnh lỗi, 320–430/chữ lớn/SafeArea/keyboard. Test chuyển state, quote đổi, callback chậm và nút quay app; E2E sandbox sau UI-17. Ghi `UI20-RESULTS.md` với trạng thái nào chưa có dữ liệu thật.
