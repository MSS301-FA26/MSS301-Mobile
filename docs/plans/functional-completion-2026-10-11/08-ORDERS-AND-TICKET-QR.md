# 08 — Lịch sử đơn và vé QR

Trạng thái: **pending**. Ưu tiên: cao cho QR; trung bình cho lịch sử nâng cao.

## Việc cần làm

- Thêm pagination lịch sử booking, refresh và cache theo user/session.
- Thêm chi tiết đơn và tiếp tục payment cho trạng thái BE cho phép; hiển thị HOLDING/PENDING_PAYMENT/PAID/USED/CANCELLED/EXPIRED/REFUNDED phù hợp.
- Render QR quét được từ payload BE thay vì chuỗi text; xác nhận `qrCode` là payload hay URL trước chọn renderer.
- Cho xem lịch sử vé USED với trạng thái đã sử dụng; không trình bày như vé còn được check-in.
- Thêm lưu/chia sẻ vé nếu thuộc scope sản phẩm; xử lý quyền và lỗi thiết bị.
- Nối review entry tới Plan 04. Customer refund/đổi vé theo contract ở Plan 11.

## Scope dự kiến

Booking history repository/provider, Orders widgets, ticket page và QR renderer.

## Tiêu chí hoàn thành và kiểm chứng

- Xem được quá 20 booking; trạng thái/CTA không gây thao tác sai lifecycle.
- QR đọc bằng scanner và lookup/check-in BE nhận đúng booking; USED không được check-in lại.
- Account A/B không lẫn history; payment completion cập nhật danh sách.
