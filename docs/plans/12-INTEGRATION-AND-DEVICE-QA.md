# 12 — Kiểm thử tích hợp và QA thiết bị

Trạng thái: **pending**. Thực hiện theo từng batch, kết thúc bằng kiểm thử xuyên flow.

## Việc cần làm

- Chạy `flutter analyze` và test phù hợp từng thay đổi; chạy full `flutter test` trước chốt đợt hoàn thiện.
- Chạy Gateway + services + dữ liệu test; kiểm tra auth → movie → showtime → hold → food → quote → checkout → VNPay sandbox → PAID → QR → history.
- Kiểm tra profile/password, withdrawal/loyalty và food độc lập theo scope đã triển khai.
- Kiểm tra logout/login tài khoản khác: cache account/orders/loyalty/booking phải đúng user và không giữ state cũ.
- Thiết bị Android/iOS: Back, resume, return link, restart/kill, loading, bàn phím và màn 320/360/390/430 px.
- Tình huống mất mạng, timeout, gửi lặp, OTP/hold expiry, ghế conflict, giá/stock thay đổi và payment event chậm.
- Cập nhật route/flow/mapping đang dùng; loại bỏ nội dung mock gây hiểu nhầm trong production.

## Bằng chứng cần ghi

Commit Mobile/BE, môi trường, lệnh kiểm chứng và kết quả; checklist thiết bị với actual/expected; lỗi còn mở và plan liên quan. Không ghi PASS nếu chỉ đọc source hoặc dùng báo cáo lịch sử.

## Tiêu chí hoàn thành

Các flow trong scope chạy xuyên Gateway với dữ liệu thật/sandbox, không còn giả thành công ở mutation hoặc thiếu bước xác nhận; lỗi còn mở có mức ảnh hưởng và chủ thể xử lý. QA thủ công còn chờ ở [Booking V2 legacy](legacy/BOOKING_FLOW_V2_REWORK_PLAN.md) được kiểm tra lại theo source mới.
