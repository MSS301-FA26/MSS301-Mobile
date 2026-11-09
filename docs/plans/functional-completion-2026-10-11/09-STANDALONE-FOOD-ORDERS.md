# 09 — Mua bắp nước độc lập

Trạng thái: **pending**. Ưu tiên: trung bình. Lịch sử đọc thật đã có.

## Việc cần làm

- Mở rộng `FoodOrderRepository` ngoài `getMyOrders`: tạo, chi tiết, cancel và sync theo customer endpoints BE.
- Tạo catalog/cart, chọn rạp nếu contract yêu cầu, validation số lượng/stock và tổng tiền authoritative.
- Tạo đơn độc lập và payment bằng `foodOrderId`; tái dùng xử lý VNPay đã hoàn thiện ở Plan 07.
- Thêm detail, trạng thái pickup và mã nhận hàng/QR theo response BE; đồng bộ lịch sử sau mutation.
- Thay route preview bằng flow production khi đủ acceptance; giữ phân biệt food kèm booking và food độc lập.

## Scope dự kiến

`lib/features/food/`, catalog food, payment DTO/repository, routing.

## Tiêu chí hoàn thành và kiểm chứng

- Cart → create → pay → pickup/detail/history hoạt động với Gateway và staff lookup.
- Cancel/stock conflict/payment failed không hiển thị đơn như đã thanh toán hoặc đã nhận.
- Có contract/state tests và một lần chạy food order sandbox xuyên service.
