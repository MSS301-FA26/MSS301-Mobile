# 07 — VNPay return và hoàn tất booking

Cập nhật 13/10/2026 theo BE `9921498`, Mobile `c7e9edd`. Trạng thái: **pending QA và return configuration**, sửa code theo lỗi còn phát hiện. Ưu tiên: cao; phụ thuộc giá/lịch chiếu Plan 03 và checkout Plan 06.

## Baseline và thay đổi BE

- Mobile đã có launcher kiểm URL, resume/polling giới hạn, phục hồi payment/checkpoint và chờ booking PAID/USED trước mở vé. Đây là phần code đã có, không phải bằng chứng sandbox trên baseline mới.
- Outbox thêm deduplication_key và payment migration V8; producer dùng event ID cho key. Không suy ra từ riêng cột/key này rằng toàn hệ thống đã bảo đảm xử lý đúng một lần.
- Award points truyền thêm cinemaId và dùng cấu hình loyalty theo rạp. Voucher/đổi điểm trong checkout vẫn thuộc Plan 10–11, không tự bật trong Plan 07.
- API customer tạo/đọc payment không có thay đổi bắt buộc DTO mới trong diff đã đối chiếu; kiểm chứng lại contract/runtime trước sửa request.

## Việc cần làm

### A. Xác nhận môi trường và return

- Xác nhận payment/booking/catalog/identity image thực sự chứa source mới, payment V8 đã được áp dụng; không chỉ dựa vào git HEAD hoặc container healthy.
- Dùng VNPay sandbox URL/merchant/config của môi trường QA đã chuẩn bị. Không ghi secret, refresh/access token, OTP hay credential vào log/Markdown.
- Chốt return URL/app link với người phụ trách BE: host/path, scheme, Android App Links/deep link và iOS Universal Links/deep link, các định danh được trả về.
- Validate route/ID và tải payment bằng phiên hiện tại khi nhận return; query success không tự đổi booking thành PAID.

### B. Vòng đời thanh toán

- QA success, failed, cancel, hold hết hạn và launcher bị từ chối/mở lỗi.
- Khi SUCCESS nhưng booking còn PENDING_PAYMENT, hiển thị đang xác minh và tiếp tục kiểm tra có giới hạn; chỉ mở vé khi BE PAID/USED, không gọi helper mock để hoàn tất production.
- Khi trạng thái chưa rõ sau hết polling, cho kiểm tra lại thủ công hoặc xem Đơn của tôi, giữ payment ID/checkpoint để phục hồi.
- Kiểm tra app background/resume, kill/restart, mất mạng khi callback đã chạy, timeout lúc create payment và return lặp.
- Trước retry kiểm tra giao dịch đã tạo cho booking; không tạo giao dịch trùng vì response client bị mất. Nếu payment FAILED và BE cho phép, mới tạo retry.
- Polling dừng khi dispose/background/đổi tài khoản; phản hồi cũ không làm thay đổi session mới.
- Đồng hồ giữ ghế dùng cùng deadline BE xuyên các màn; hết giờ không tự kết luận giao dịch đã FAILED nếu server đang xử lý thanh toán.

### C. Sau thanh toán

- Refresh history/ticket và dọn checkpoint đúng tài khoản sau kết quả booking xác nhận; kiểm tra back/reload không hiển thị lại bản chưa trả tiền.
- QR sử dụng nguyên payload từ BE; nếu PAID nhưng QR chưa cập nhật thì tải lại/thông báo đúng, không tự sinh payload.
- Kiểm tra event/callback lặp không làm phát hành/check-in vé hoặc tích điểm lặp. Kết quả points phải lấy từ BE; lỗi loyalty không được khiến Mobile tự đánh dấu giao dịch thanh toán thất bại khi booking đã PAID.

## Scope

Payment repository/launcher, completion controller, payment page, checkpoint/routing và cấu hình return Android/iOS. Không sửa BE/outbox/migration trong plan Mobile; lỗi producer/consumer chuyển người phụ trách BE.

## Kiểm chứng và tiêu chí DONE

- Test transition/HTTP adapter: double submit, create timeout có giao dịch server, callback trước booking cập nhật, callback/return lặp, resume/restart, logout khi request đang chờ, lỗi launcher và polling kết thúc.
- Android/iOS sandbox thật: OPEN tương lai → hold → items → quote → checkout → VNPay → SUCCESS → booking PAID → QR/history.
- Failed/cancel/expiry không giả thành công; retry không trùng payment; dữ liệu tài khoản A không xuất hiện ở B.
- Ghi payment/booking ID QA, trạng thái thực tế và timeline callback/consumer, không ghi secret. Có bằng chứng return và sandbox theo Plan 12.

## Còn cần đầu vào

Suất chiếu OPEN trong tương lai, CUSTOMER test và cấu hình sandbox/return hợp lệ; thiết bị hoặc môi trường iOS. Thiếu một điều kiện phải ghi rõ ca chưa chạy, không đánh dấu DONE từ source/test giả lập.
