# Báo cáo triển khai luồng booking Mobile

Ngày: 2026-10-11. Người yêu cầu: Tzee314.

Trạng thái: **Đã triển khai phần Mobile của luồng chính; còn QA thanh toán sandbox và thiết bị trước khi chốt done.**

## Phạm vi

- Chọn vé/ghế → giữ ghế → bắp nước → xác nhận đơn → VNPay → kiểm tra booking → vé QR → lịch sử.
- Không chỉnh các file UI đăng nhập/đăng ký, source BE, migration, seed hoặc SQL.
- Các file plan 05–08 hiện có lịch sử chỉnh sửa của thành viên khác; báo cáo này là file mới, không thay đổi Markdown của họ.

## Đã triển khai

| Flow | Thay đổi |
| --- | --- |
| Vé và ghế | Không nhập tuổi người xem; gửi giá trị theo loại vé để tương thích API. Thẻ trẻ em chặn theo phân loại phim và giải thích lý do. Ghế đôi chọn từng cặp thay vì toàn bộ hàng. |
| Giữ ghế | Chống gửi hold hai lần; kiểm tra hết hạn; lỗi xung đột/mất mạng trả lại trạng thái chọn ghế. Back/logo/Search/Account/tab giữ người dùng trong flow nếu hủy hold thất bại. |
| Phục hồi | Lưu booking ID, payment ID và giá trị tuổi API theo ghế trong secure storage, tách khóa theo user. Home có đường tiếp tục đơn. Luôn GET booking từ BE để xác minh trạng thái; không phục hồi hold chỉ bằng dữ liệu trên máy. |
| Bắp nước | Đọc `/api/v1/foods/items` và `/api/v1/foods/combos`, tải đủ trang. Tách khóa `item:id`/`combo:id` để tránh trùng ID. Hiển thị ảnh, giá và trạng thái; LOW_STOCK vẫn chọn được, OUT_OF_STOCK/INACTIVE không được tăng số lượng. |
| Xác nhận đơn | PUT `/api/v1/bookings/{id}/items` → quote. POST `/api/v1/bookings/{id}/checkout` trước tạo payment. Không tạo payment nếu tổng tiền checkout khác báo giá đã xác nhận. Báo giá hết hạn phải được cập nhật và xác nhận lại. |
| VNPay | Dùng launcher kiểm tra URL và kết quả mở. Kiểm tra payment hiện có theo booking trước khi tạo lại. Tải trạng thái khi app resume và polling mỗi 3 giây, tối đa 20 lần; dừng khi rời màn hình/đổi lifecycle hoặc có kết quả cuối. Có kiểm tra thủ công sau khi polling kết thúc. |
| Hoàn tất | Payment SUCCESS chỉ mở vé khi booking PAID/USED. Khi callback booking chậm, tiếp tục kiểm tra; không tự đánh dấu paid. Refresh Orders và xóa checkpoint sau hoàn tất. Rời màn payment giữ đơn để kiểm tra lại, không tự hủy đơn đang thanh toán. |
| Vé QR | Dùng `qr_flutter` render nguyên payload `booking.qrCode` từ BE. USED được xem lại nhưng không hiển thị QR để check-in lần nữa. Không dựng QR giả hoặc tự suy diễn payload từ bookingCode. |
| Lịch sử | Đọc hết các trang thay vì dừng ở 20 đơn, kéo để refresh, tiếp tục đơn HOLDING/PENDING_PAYMENT, mở vé PAID và xem lại vé USED. Provider theo dõi tài khoản; phản hồi booking cũ bị bỏ sau logout. |

## Kiểm chứng

- Analyzer: PASS, không có lỗi/lint; xem [analyze.log](analyze.log).
- Toàn bộ test Mobile: **98/98 PASS**; xem [tests.log](tests.log).
- Android debug APK cuối cùng: PASS; xem [build.log](build.log). Git diff whitespace check: PASS.
- Test mới `test/remote_booking_completion_test.dart` dùng các remote repository thực với HTTP adapter giả lập. Các test này kiểm chứng contract và state transition, không phải giao dịch VNPay thật.
- Các ca mới: item/combo trùng ID; thứ tự items/quote/checkout/payment; gửi payment hai lần; callback SUCCESS trước PAID; hết hold; phục hồi tuổi trẻ em; checkout thay giá; lịch sử 23 đơn/2 trang; logout trong lúc request chờ; LOW_STOCK/OUT_OF_STOCK; sửa giỏ sau Back.
- Bộ widget test hiện có tiếp tục kiểm tra giữ ghế, hủy/expiry, mock payment, màn QR thật và độ rộng 320/430 px.
- Android debug APK build với `--dart-define=API_BASE_URL=http://127.0.0.1:8080`; bản build trung gian đã cài thành công lên `emulator-5554`.
- Đọc Gateway local: foods/items trả 8 sản phẩm; foods/combos trả 4 combo; showtimes trả dữ liệu. Emulator mở được Home/lịch chiếu/Vé & Ghế và đã được kiểm tra ở bản trước khi bỏ trường tuổi. [home-smoke.png](home-smoke.png) chỉ là bằng chứng Home hoạt động, không phải bằng chứng booking thanh toán hoàn tất.

## Còn cần chốt/QA

1. Chạy CUSTOMER thật trên môi trường QA: hold → items → checkout → VNPay sandbox → callback → booking PAID → quét QR/check-in. Đợt này không tạo booking hoặc thanh toán thật để giữ phạm vi không can thiệp dữ liệu BE/DB.
2. Chốt return URL/app link với cấu hình payment hiện có. Resume/polling đã có; chưa bổ sung Android App Links/iOS Universal Links khi chưa có domain và contract return đã xác nhận.
3. Kiểm tra iOS, restart giữa payment, timeout khi server đã tạo payment, callback trễ và hai tài khoản trên thiết bị thật.
4. BE đang ghi `viewerAge(20)` khi dựng ticket snapshot. Theo yêu cầu mới, Mobile không hỏi tuổi người xem. Mobile gửi giá trị theo loại vé (trẻ em 10, sinh viên 20, người lớn 30) để tương thích contract hiện có, đồng thời chặn trẻ em với phim T13/T16/T18. Checkpoint lưu giá trị này; nếu không còn checkpoint thì suy ra lại theo loại vé thay vì dùng snapshot 20 của BE. Đây không phải xác minh tuổi thực tế của người xem. Cần người phụ trách BE xác minh, không sửa BE trong đợt này.
5. Dữ liệu local có khác biệt tên phim: `/movies` movie ID 1 hiển thị Avatar, trong khi `/showtimes/1` và seat-map cùng ID phim hiển thị Dune. Cần đối chiếu dữ liệu QA trước khi kết luận tên phim xuyên flow đã đúng.
6. Chính sách tối đa 8 vé và cách ghép ghế đôi trong Mobile còn cần xác nhận theo sản phẩm/contract BE. Không đánh dấu phần chính sách của plan 05 done khi chưa xác nhận.
7. Lưu/chia sẻ vé, review entry và refund là các mục còn lại của plan 08/04/11; chưa triển khai trong luồng thanh toán chính này. Chi tiết đơn đã hiển thị cho mọi trạng thái, gồm tổng tiền/bắp nước và tải lại đơn; đơn chưa trả tiền không có QR sử dụng được.

## Lệnh kiểm tra

```powershell
flutter analyze --no-pub
flutter test --no-pub
$env:GRADLE_OPTS = '-Dorg.gradle.project.kotlin.incremental=false'
flutter build apk --debug --no-pub --dart-define=API_BASE_URL=http://127.0.0.1:8080
```

Với cấu hình local hiện tại, emulator dùng ADB reverse `tcp:8080 → tcp:18080`; relay chuyển tới Docker Gateway `[::1]:8080`. Cần giữ relay hoạt động.

## Cập nhật yêu cầu ngày 11/10: loại vé và thời hạn

- Bỏ ô nhập tuổi và yêu cầu nhập tuổi trước khi giữ ghế. Payload API vẫn có `viewerAge` vì Catalog Service bắt buộc trường này; các giá trị theo loại vé chỉ dùng để tương thích API.
- Thẻ Trẻ em với phim T13/T16/T18 hoặc 13+/16+/18+ hiển thị lý do không được mua và ẩn cả nút cộng/trừ. Controller cũng từ chối chọn vé trẻ em để không thể bỏ qua kiểm tra UI. P/K vẫn cho phép; K có nhắc trẻ dưới 13 tuổi cần người lớn đi cùng.
- Nguyên nhân báo hết hạn ngay: booking-service và catalog-service chạy UTC (đã đọc `docker exec ... date`), nhưng `LocalDateTime` JSON không có offset bị Mobile hiểu theo múi giờ thiết bị. Parser dành riêng cho `holdExpiresAt` và quote `validUntil` đọc timestamp thiếu offset là UTC, giữ đúng instant nếu đã có offset. Không reset hay kéo dài phiên 3 phút khi chuyển màn; giờ lịch chiếu vẫn giữ cách đọc cũ.
- Phiên thực sự hết hạn có nút **Chọn lại ghế**, thay vì tải lại cùng booking hết hạn.
- Thêm kiểm thử phim giới hạn tuổi, ẩn nút vé trẻ em/kèm lý do, không còn age input, UTC không offset trên thiết bị +07:00, giữ được 3 phút qua bước bắp nước/quote và ngừng payment khi hết hạn, offset/fractional seconds. Tổng **98/98 test PASS**, analyzer PASS.
- Các bài kiểm thử thời hạn/booking dùng HTTP adapter giả lập; chưa tạo giao dịch VNPay thật trong lần sửa này. Không thay đổi source BE hoặc database.

- APK sau cập nhật đã build thành công, cài bằng `adb install -r` và mở lại trên `emulator-5554`; ADB reverse được giữ cho Gateway local.

## Đồng hồ giữ ghế ở bắp nước và thanh toán

- Thêm `BookingHoldCountdown` dùng chung ở Bắp nước, Xác nhận đơn và màn VNPay. Đọc cùng `booking.holdExpiresAt` từ BE; không tạo phiên hay reset thời gian khi chuyển màn.
- Cập nhật mỗi giây theo AppClock; còn 30 giây đổi màu cảnh báo, hết hạn hiển thị 00:00. Khi ứng dụng trở lại từ nền/VNPay, tính lại từ thời hạn gốc. Sau booking PAID/USED không còn hiện đồng hồ giữ ghế.
- Analyzer PASS. 17/17 test trong `booking_hold_countdown_test.dart`, `booking_entry_test.dart`, `completion_and_account_test.dart` PASS; kiểm tra chuyển màn, background/resume, không âm sau hết hạn, ẩn sau thanh toán và màn 320 px.
