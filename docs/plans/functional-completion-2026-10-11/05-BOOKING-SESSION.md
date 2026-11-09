# 05 — Vé, ghế, giữ chỗ và phục hồi phiên

Trạng thái: **pending**. Ưu tiên: cao.

## Việc cần làm

- Áp dụng cùng leave guard cho logo, Search, Account, tab và Back tại các bước liên quan.
- Nếu cancel hold thất bại, giữ người dùng trong flow với lỗi/thử lại; không điều hướng như đã hủy.
- Phục hồi booking/session sau restart từ ID tối thiểu và trạng thái BE; không phục hồi hold chỉ bằng state local.
- Đối chiếu ticketType/viewerAge, giới hạn vé, ghế đôi và tuổi xem phim với BE/product; bỏ tuổi đại diện khỏi production nếu cần nhập tuổi thật.
- Đồng bộ thời gian hold, expiry, xung đột và thay ghế; không tạo thêm hold khi chỉ quay lại xem lựa chọn.
- Dọn state đặt vé khi hoàn tất hoặc đổi tài khoản; kiểm tra cache theo phiên.

## Scope dự kiến

`booking_entry_session.dart`, seat UI/repository, `app_shell.dart`, routing và persistence tối thiểu.

## Tiêu chí hoàn thành và kiểm chứng

- Mọi lối rời flow xử lý hold nhất quán; cancel lỗi không bị che mất.
- Restart, mất mạng, ghế vừa bị chiếm và hold hết hạn phục hồi/thoát đúng.
- Ticket mapping và tuổi xuyên hold → quote → checkout → ticket đúng contract.
