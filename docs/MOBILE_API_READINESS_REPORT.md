# CINEPREMIER Mobile API Readiness Report

> Version: 1.0  
> Date: 2026-09-27  
> Scope: handoff after Backend-aligned Mock UI R0–R8

## 1. Kết luận

Mobile đã sẵn sàng thay repository mock bằng remote repository theo từng vertical slice. UI, typed DTO, mapper, state machine và route không phụ thuộc backend đang chạy. Chưa được bật tích hợp thật cho đến khi các blocker dưới đây được thống nhất giữa Mobile, Gateway và từng service.

## 2. Mức sẵn sàng theo slice

| Slice | Mobile mock | Có thể bắt đầu remote | Điều kiện |
| --- | --- | --- | --- |
| Catalog/movie/showtime/seat map | Sẵn sàng | Có | Chốt response envelope, timezone và seat runtime status |
| Identity/profile/auth | Sẵn sàng UI | Có điều kiện | Chốt token lifecycle, refresh, social auth và OTP/reset contract |
| Booking hold/update/checkout | Sẵn sàng | Có điều kiện | Chốt idempotency, conflict payload và hold-expiry rule |
| Payment/VNPay | Sẵn sàng UI/state | Chưa | Cần deep link, server-side verify và quy tắc payment sau hold expiry |
| Orders/ticket QR | Sẵn sàng | Có điều kiện | Chốt khi nào booking thành `PAID` và booking QR là mã chính |
| Wallet/withdrawal | Sẵn sàng | Có điều kiện | Chốt masking, validation, status và retry/idempotency |
| Loyalty | Sẵn sàng read-only | Chưa cho checkout redemption | Cần reserve/deduct/rollback điểm xuyên service |
| Food độc lập/refund/voucher/VIP/social/PopBot | Preview sau flag | Chưa | Cần public contract riêng trước khi bỏ `Provisional*` |

## 3. Blocker bắt buộc

1. Booking hold 3 phút và VNPay URL 15 phút chưa có quy tắc nhất quán khi callback đến sau expiry.
2. Payment success không được tự suy ra booking `PAID`; backend phải verify và công bố trạng thái booking cuối cùng.
3. Mobile callback cần app link/deep link chính thức; không dùng callback localhost hoặc tin query phía client.
4. Gateway phải chịu trách nhiệm identity/role; mobile không tự gửi `X-User-Id` như header đáng tin cậy.
5. Cần idempotency key cho hold, checkout, create payment, callback và withdrawal.
6. Booking và loyalty chưa thống nhất kiểm tra số dư, reserve, deduct và rollback điểm.
7. `CINEWALLET` có trong enum payment nhưng product rule hiện không cho dùng ví thanh toán vé.
8. Food order status cần enum và public customer lifecycle API.
9. Refund cần eligibility/quote/request/status contract; mobile không tự tính deadline hoặc mức hoàn.
10. Voucher, membership, favorite, review, notification và PopBot chat chưa có public contract đầy đủ.

## 4. Contract cần xác nhận

- Response envelope và error code thống nhất, đặc biệt `409` conflict, expired và validation.
- ID nghiệp vụ là integer; VND là integer, không dùng floating point.
- Timestamp có timezone/UTC và quy tắc hiển thị theo Asia/Ho_Chi_Minh.
- Enum phải có fallback `unknown`; backend không đổi giá trị mà không version contract.
- Quote có `quoteId`, `validUntil`, snapshot, fee/discount/total và lý do quote changed.
- Booking response có `holdExpiresAt`, status, immutable snapshot và booking QR khi `PAID`.
- Payment response có payment ID, booking ID, provider, status và server verification result.

## 5. Thứ tự tích hợp đề xuất

1. Catalog read-only: movies → detail → showtimes → seat map.
2. Identity/profile và auth gate.
3. Booking hold/update/checkout.
4. Payment create, deep link và polling/verify.
5. Orders và ticket QR.
6. Wallet/loyalty read-only rồi mới đến mutation.
7. Thay từng preview repository khi public contract tương ứng được duyệt.

Mỗi slice phải giữ mock repository cho widget test/demo offline, thêm remote contract test và chỉ đổi provider binding theo environment. Không xóa fallback `unknown`, fake clock hoặc scenario conflict/expiry hiện có.
