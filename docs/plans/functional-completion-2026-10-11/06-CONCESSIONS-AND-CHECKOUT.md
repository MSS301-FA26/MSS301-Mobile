# 06 — Bắp nước và checkout thật

Trạng thái: **pending**. Ưu tiên: cao.

## Việc cần làm

- Triển khai `RemoteCatalogRepository.getFoodItems/getFoodCombos` theo food endpoints và envelope hiện tại.
- Tải sản phẩm trong nhánh remote của `BookingCompletionController.load`; xử lý trạng thái hàng, ảnh, giá và lỗi tải.
- Gửi tickets/foods tới PUT `/api/v1/bookings/{id}/items`; lấy booking mới và quote authoritative.
- Gọi POST `/api/v1/bookings/{id}/checkout` với đúng `CheckoutBookingRequest` trước tạo payment; không chỉ chuyển state local.
- Phục hồi quote khi vào lại checkout; chặn expiry và quote/booking không khớp.
- Bỏ label VNPay Mock khỏi flow thật; xử lý thay đổi giá/tồn kho trước xác nhận.
- Voucher và loyalty checkout chỉ thêm sau contract reserve/deduct/rollback; theo Plan 10–11.

## Scope dự kiến

Remote catalog/booking mutation DTO và repository, booking completion controller, concessions/checkout pages.

## Tiêu chí hoàn thành và kiểm chứng

- Có/không chọn food đều đi items → quote → checkout → payment đúng lifecycle BE.
- Giỏ, giá và snapshot đúng sau Back, reload, stock/price change và timeout.
- Có test request/response/state transition; smoke test Gateway với booking và food thật.
