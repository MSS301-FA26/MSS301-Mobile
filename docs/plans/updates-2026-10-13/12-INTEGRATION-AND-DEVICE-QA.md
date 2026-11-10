# 12 — QA tích hợp theo BE sau pull

Cập nhật 13/10/2026 theo BE `9921498`, Mobile `c7e9edd`. Trạng thái: **pending**, chạy theo batch và kết thúc bằng kiểm thử xuyên flow.

## A. Chuẩn bị baseline runtime — chạy trước

- Ghi git HEAD/working tree của Mobile/BE, thời điểm build image/APK, cấu hình môi trường đã che secret, device/OS và timezone runtime.
- Xác minh các image đang chạy thực sự chứa BE sau pull; docker start một image cũ không chứng minh đã cập nhật source.
- Kiểm tra Gateway/routes và health của service/DB/RabbitMQ. Phân biệt lỗi IPv4 port 8080 của Apache với Docker Gateway IPv6; dùng relay/ADB reverse đúng APK khi cần.
- Kiểm tra migration thực tế trong môi trường QA: catalog V14 food_categories/category_id; payment V8 outbox deduplication_key; đồng thời kiểm tra các cột phụ thu Showtime mới đã tồn tại/được quản lý theo cấu hình BE.
- Không tự chạy SQL/seed, thay schema hoặc dựng bảng tay. Thiếu migration/dữ liệu phải ghi rõ để người phụ trách môi trường xử lý.
- Compose đang tham chiếu recommendation-service có Dockerfile/.env.example bị xóa; xác nhận cấu hình service thay thế với BE trước rebuild toàn bộ. Không tự phục hồi kiến trúc cũ.
- Xác minh nghĩa LocalDateTime không offset ở lịch chiếu và timezone deadline hệ thống; display Việt Nam UTC+7, duration hold không lệch 7 giờ.

## B. Dataset và tài khoản cần có

- CUSTOMER A/B, STAFF đúng rạp và ADMIN test khi ca nghiệp vụ yêu cầu; không dùng credential/hash admin làm customer test.
- Rạp/phim/room hợp lệ; suất OPEN ở tương lai, SCHEDULED chưa bán, suất đã qua và rạp không có lịch.
- Ghế thường/VIP/đôi, ghế đã giữ/đã đặt; giá theo loại vé, phụ thu cuối tuần/lễ/đêm và ít nhất một giá 0 nếu nghiệp vụ cho phép.
- Food ACTIVE/LOW_STOCK/OUT_OF_STOCK/INACTIVE, item và combo có thể trùng ID; category đã có data.
- Booking PAID/USED/CANCELLED/EXPIRED/REFUNDED, history >20 đơn; sandbox VNPay và return config hợp lệ.
- Các fixture trong RAM hoặc HTTP adapter dùng kiểm thử tự động phải ghi rõ, không dùng làm bằng chứng PAID/check-in BE thật.

## C. Ma trận QA bắt buộc

| Flow | Ca cần chạy / expected |
| --- | --- |
| Plan 03 catalog | Banner/CTA/rating/count đúng nguồn; đổi query nhanh không trộn; chọn rạp/ngày đúng slot; SCHEDULED/quá giờ không được mua. |
| Giá theo BE mới | Thường/VIP/đôi, hai ghế đôi cùng loại, phụ thu/lễ/cuối tuần/22:00–03:00; tạm tính và quote/checkout không nhân đôi hay cộng phụ thu lặp. |
| Booking Plan 05 | Max 8 ghế, chặn trẻ em theo phim, giữ 3 phút, cancel lỗi giữ flow, ghế conflict, back không tạo thêm hold, restart/đổi user phục hồi đúng. |
| Food Plan 06 | Food tùy chọn, max 8 mỗi item/combo, chỉ ACTIVE mua được, hết hàng giữ giỏ cho sửa; giá đổi phải xác nhận lại; category mới không làm mất món hoặc trộn ID. |
| Payment Plan 07 | Sandbox success/failed/cancel/expiry, return/app link, callback trước PAID, consumer chậm/lặp, timeout create/retry; không tự phát hành vé. |
| Ticket Plan 08 | History >20, detail đúng snapshot/UTC+7, QR PAID scanner + BE lookup/check-in đúng; USED không dùng lại; save/share/cancel/lỗi thiết bị, A/B không lẫn dữ liệu. |
| Profile Plan 02 | /me đúng user, PUT còn sau restart, avatar tải thực, password sai không thành công; Account/profile không bị che bởi lỗi ví. |
| Wallet/loyalty Plan 10 | Wallet customer chưa có ví, withdrawal theo quyền ADMIN mới, config/points theo cinemaId, event lặp không award lặp. |
| Food độc lập/khác | Chỉ chạy mutation khi flow đã triển khai và contract hiện tại được xác nhận; refund không dùng endpoint admin đã xóa để giả định API customer. |

## D. Thiết bị và lỗi mạng

- Android/iOS: Back, resume, return link, restart/kill, bàn phím/loading và các độ rộng 320/360/390/430 px theo scope.
- Mất mạng trước/sau mutation, timeout nhưng server đã hoàn tất, bấm lặp, return lặp, OTP/hold/quote hết hạn, stock/price đổi và payment event chậm.
- Logout/login khác tài khoản trong lúc request chờ: profile/orders/loyalty/booking không nhận phản hồi cũ; exported file chỉ do thao tác người dùng đã yêu cầu.
- iOS/iPad export: picker, share origin, quyền, hủy và phục hồi UI; Android export qua hộp thoại hệ thống.

## E. Lệnh và bằng chứng

- Chạy flutter analyze và test hẹp theo batch; full flutter test trước chốt đợt, build APK/target tương ứng.
- Ghi actual/expected, PASS/FAIL/NOT RUN, commit source, image runtime, thiết bị, ID QA và thời điểm Việt Nam; log không chứa secret/credential.
- Mỗi lỗi có mức ảnh hưởng, bước tái hiện, plan và chủ thể Mobile/BE/môi trường, ảnh/log đã che thông tin cần thiết.
- Báo cáo lịch sử 107/112 test hoặc ảnh QA cũ không tự đánh dấu PASS cho baseline hiện tại. Phải chạy lại ca liên quan thay đổi thực tế; không chạy thêm không có mục đích sau khi đủ gate.

## Lỗi đã biết cần tái kiểm tra

1. GET wallet với user chưa có ví: WalletServiceImpl dùng read-only transaction nhưng getOrCreateWallet có INSERT; đã từng trả 500. Chưa thấy sửa trong diff pull, cần BE xử lý và tái QA.
2. Source/compose recommendation thiếu file build/env như mục A.
3. Giá tạm tính ghế đôi Mobile cần đối chiếu công thức BE mới theo Plan 03.
4. Dataset trước đó chỉ có suất ngày 12/10 đã qua; phải có suất tương lai hợp lệ trước khi gọi QA booking/payment hoàn tất.

## Tiêu chí DONE

Các flow trong scope chạy thật xuyên Gateway/sandbox trên runtime đã xác nhận; đủ bằng chứng callback/PAID/QR check-in và thiết bị yêu cầu. Không có fake success hoặc thiếu bước BE xác nhận. Nếu còn lỗi/điều kiện chặn thì ghi đúng ca chưa chạy và người phụ trách, không kết luận toàn plan DONE chỉ từ unit test.
