# UI-20 — Kết quả triển khai

Ngày: **01/11/2026**. Phạm vi: Mobile, diff local chưa commit.

## Đã làm

- Dùng `CheckoutOutcomeHeader` chung cho kết quả vé và food: trạng thái do BE xác nhận, số tiền, mã đơn và lời giải thích theo từng loại đơn.
- Checkout vé cho mở/thu gọn chi tiết vé và bắp nước; thông báo báo giá đổi nằm cạnh CTA thanh toán. Giữ quote và deadline từ BE.
- Kết quả vé giữ riêng trạng thái chờ, đang xác minh, thất bại, hết hạn và thành công. Vé QR chỉ mở sau `ticketReady`; thêm đường về Đơn của tôi.
- Food hiển thị đúng đơn food, rạp nhận và mã nhận bắp nước; QR food không gắn nhãn vé vào rạp.

## Kiểm chứng và giới hạn

- `dart analyze lib` và test mới: đạt; `flutter build apk --debug --no-pub`: đạt. Nhóm UI-06/UI-11/UI-22/UI-23 đạt **31/31 test**. Nhóm UI-13 đạt **19/21**, còn 2 test food checkout `standalone location=false/true` timeout trong `pumpAndSettle`; timeout lặp lại khi tạm bỏ status card UI-20, nên chưa quy lỗi cho card mới.
- Chưa chụp trước/sau trên thiết bị, chưa thử màn 320–430 với dữ liệu sandbox thật, iOS và VNPay E2E. Các trạng thái không có fixture thật không được coi là đã xác nhận runtime.
