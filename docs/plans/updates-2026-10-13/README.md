# Các plan cập nhật theo BE — 13/10/2026

Người yêu cầu: Tzee314. Các file trong folder này là phiên bản cập nhật của Plan 02, 03, 07 và 12 để triển khai tiếp; không thay đổi các tài liệu gốc của thành viên khác.

## Baseline

- BE: `9921498`, pull ngày 13/10 lúc 10:00:23 UTC+7, từ `9f4d53a`.
- Mobile: `c7e9edd`, tại thời điểm đối chiếu tài liệu.
- Đối chiếu bằng source/Git; không chạy lại QA hoặc tự áp dụng migration trong lần cập nhật tài liệu này.
- Không sửa UI đăng nhập–đăng ký, source BE, DB/seed. Công việc bổ sung vào BE nếu cần phải ghi riêng chủ thể xử lý.
- Quy tắc đã chốt: tối đa 8 ghế/đơn; ghế đôi gồm 2 ghế cùng loại vé; không nhập tuổi, vẫn gửi viewerAge tương thích BE; food tùy chọn, tối đa 8 mỗi item/combo; chỉ ACTIVE được mua theo checkout BE; voucher/điểm triển khai ở Plan 10–11.
- Lịch chiếu LocalDateTime không offset được Mobile diễn giải là giờ Việt Nam UTC+7 theo quy ước hiện tại. Deadline hệ thống có parser UTC riêng theo container đã kiểm tra; khi QA phải xác nhận lại timezone runtime, không suy ra múi giờ chỉ từ kiểu LocalDateTime.

## Thứ tự triển khai

| Ưu tiên | Plan | Hướng xử lý |
| --- | --- | --- |
| 1 | [03 — Catalog/rạp/suất chiếu](03-CATALOG-AND-CINEMA.md) | Sửa giá tạm tính ghế đôi, lọc suất hợp lệ, chọn rạp; hoàn thiện banner/rating/Discover. |
| Chờ QA thật | [02 — Hồ sơ/bảo mật](02-PROFILE-AND-SECURITY.md) | Đã triển khai profile remote, avatar URL, đổi mật khẩu và cache theo user; analyzer/121 test/build Android đạt. Còn QA lưu dữ liệu, ảnh và đăng nhập bằng mật khẩu mới. |
| 2 | [07 — VNPay](07-VNPAY-COMPLETION.md) | Chốt return/app link và QA thanh toán/event trên image BE mới. |
| Xuyên suốt | [12 — QA tích hợp](12-INTEGRATION-AND-DEVICE-QA.md) | Xác minh runtime, migration và dữ liệu trước; ghi actual/expected theo từng batch. |

Plan 05/06/08 đã có phần code Mobile triển khai trong phiên trước; vẫn phải kiểm chứng các tiêu chí BE/thiết bị thật liên quan. Báo cáo/test trước đó không tự xác nhận PASS cho baseline mới.

## Thay đổi BE cần theo dõi

- Checkout chỉ chấp nhận OPEN và giờ chiếu ở tương lai; thay đổi giá cặp ghế/phụ thu, suất đêm từ 22:00 hoặc trước 03:00.
- Thêm FoodCategory, categoryId/categoryName và migration catalog V14. Các trường này không làm thay đổi quy tắc ACTIVE-only của checkout.
- Loyalty theo cinemaId, cấu hình/giới hạn đổi điểm theo rạp; Outbox có deduplication_key và migration payment V8.
- Quyền quản trị ví chỉ ADMIN, xóa endpoint refund thủ công trong AdminBookingController. Không suy ra từ đó rằng đã có API customer refund mới.
- WalletServiceImpl.getWallet vẫn gọi getOrCreateWallet trong transaction read-only; lỗi 500 đã ghi nhận cần BE xử lý.
- Compose vẫn tham chiếu recommendation-service/Dockerfile và .env.example đã bị xóa trong pull. Cần chủ thể BE xác nhận cấu hình build đúng trước clean build; không tự tái tạo service cũ.

## Quy tắc chốt trạng thái

Mỗi plan ghi rõ phần code, phần test tự động và QA thật. Chỉ đánh dấu DONE khi đủ tiêu chí của chính plan; trường hợp thiếu dữ liệu, tài khoản, return config hoặc thiết bị ghi đúng điều kiện còn chờ.
