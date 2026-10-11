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
| Bắp nước | Đọc `/api/v1/foods/items` và `/api/v1/foods/combos`, tải đủ trang. Tách khóa `item:id`/`combo:id` để tránh trùng ID. Hiển thị ảnh, giá và trạng thái; Chỉ ACTIVE được mua theo BE hiện tại; LOW_STOCK/OUT_OF_STOCK/INACTIVE/UNKNOWN không được tăng số lượng. |
| Xác nhận đơn | PUT `/api/v1/bookings/{id}/items` → quote. POST `/api/v1/bookings/{id}/checkout` trước tạo payment. Không tạo payment nếu tổng tiền checkout khác báo giá đã xác nhận. Báo giá hết hạn phải được cập nhật và xác nhận lại. |
| VNPay | Dùng launcher kiểm tra URL và kết quả mở. Kiểm tra payment hiện có theo booking trước khi tạo lại. Tải trạng thái khi app resume và polling mỗi 3 giây, tối đa 20 lần; dừng khi rời màn hình/đổi lifecycle hoặc có kết quả cuối. Có kiểm tra thủ công sau khi polling kết thúc. |
| Hoàn tất | Payment SUCCESS chỉ mở vé khi booking PAID/USED. Khi callback booking chậm, tiếp tục kiểm tra; không tự đánh dấu paid. Refresh Orders và xóa checkpoint sau hoàn tất. Rời màn payment giữ đơn để kiểm tra lại, không tự hủy đơn đang thanh toán. |
| Vé QR | Dùng `qr_flutter` render nguyên payload `booking.qrCode` từ BE. USED được xem lại nhưng không hiển thị QR để check-in lần nữa. Không dựng QR giả hoặc tự suy diễn payload từ bookingCode. |
| Lịch sử | Đọc hết các trang thay vì dừng ở 20 đơn, kéo để refresh, tiếp tục đơn HOLDING/PENDING_PAYMENT, mở vé PAID và xem lại vé USED. Provider theo dõi tài khoản; phản hồi booking cũ bị bỏ sau logout. |

## Kiểm chứng

- Analyzer: PASS, không có lỗi/lint; xem [analyze.log](analyze.log).
- Toàn bộ test Mobile sau cập nhật UTC+7: **104/104 PASS**; xem [vietnam-time-tests.log](vietnam-time-tests.log).
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
6. Người dùng đã chốt tối đa 8 ghế/đơn, ghế đôi gồm 2 ghế cùng loại vé và chặn vé trẻ em theo phân loại phim. Các quy tắc này đã áp dụng trong Mobile; QA phiên thực tế vẫn còn.
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

- Bỏ ô nhập tuổi và yêu cầu nhập tuổi trước khi giữ ghế. Payload API vẫn có `viewerAge` vì BE dùng tuổi để kiểm tra eligibility; nếu không gửi thì hold/checkout mặc định 20 và Catalog quote mặc định 22; các giá trị theo loại vé chỉ dùng để tương thích API.
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

## Chốt quy tắc Plan 05

- Người dùng chốt 1 đơn tối đa 8 **ghế**; mỗi ghế đôi chiếm 2 ghế và 2 vé cùng loại (ví dụ đều sinh viên hoặc đều người lớn).
- Bổ sung mapping cặp ghế trong booking entry: chọn một ghế sẽ kiểm tra/chọn cả cặp, không cho ghép hai loại vé; không cho chọn nếu một ghế trong cặp đã không còn trống. Khi giảm số lượng xuống dưới số ghế đã gán, bỏ nguyên cặp thay vì để lại một nửa. Sau đó phải gán đủ số vé mới được tiếp tục.
- `viewerAge` là trường nullable trong request BE. Hold/checkout mặc định 20, Catalog quote mặc định 22, rồi kiểm tra tuổi với loại vé và phân loại phim. Vì vậy Mobile vẫn gửi giá trị theo loại vé; người dùng không cần nhập tuổi. Các giá trị này không xác minh tuổi thực tế.
- Analyzer PASS; 30/30 test trong booking entry controller/widget và remote booking completion PASS.
- Hiển thị giờ Việt Nam UTC+7 đã được người dùng chốt. Cần xác nhận ý nghĩa giờ suất chiếu không offset trước khi đổi cách diễn giải: schema hiện dùng TIMESTAMP/LocalDateTime không lưu múi giờ. Docker hiện không chạy nên chưa đọc được múi giờ DB trực tiếp. Chưa cộng 7 giờ vào các chuỗi lịch chiếu không offset khi chưa xác định nguồn giờ.

## Quy ước LocalDateTime và hiển thị UTC+7

- Người dùng xác nhận BE lưu kiểu LocalDateTime. Kiểu này không chứa offset; thông tin này không tự xác định thời gian được lưu là UTC hay giờ Việt Nam. Mobile áp dụng quy ước lịch chiếu không offset là giờ Việt Nam theo yêu cầu hiển thị UTC+7; chưa xác minh trực tiếp ý nghĩa dữ liệu lịch chiếu trong DB đang chạy.
- `cinemaTimeFromJson` diễn giải chuỗi lịch chiếu không offset theo +07:00 và lưu instant UTC trong DTO. Ví dụ `2026-10-12T10:00:00` hiển thị 10:00 Việt Nam; `2026-10-12T03:00:00Z` cũng hiển thị 10:00 Việt Nam. Không phụ thuộc múi giờ thiết bị.
- Lịch chiếu, Vé & Ghế, quote/Xác nhận đơn, Vé QR và lịch sử đều dùng formatter Việt Nam chung. Ngày Hôm nay và lọc ngày lịch chiếu dùng ngày Việt Nam, kể cả khi UTC còn ở ngày trước.
- Hold expiry và quote expiry giữ parser server UTC riêng, dựa trên giờ UTC container đã kiểm tra ở lần chạy trước. Không đổi hạn giữ ghế thành giờ local hoặc cộng thêm 7 tiếng vào thời lượng. Nếu BE thay đổi múi giờ chạy thì contract này cần được cập nhật rõ ràng.
- Analyzer PASS, full suite **104/104 PASS**. Test mới kiểm tra local schedule, explicit UTC/+07/-05, đổi ngày Việt Nam, mapping showtime/booking và thời hạn 3 phút vẫn đúng.
- Không sửa BE/DB, không sửa Markdown của thành viên khác.

## Chốt Plan 06: bắp nước và checkout

Người dùng chốt: bắp nước không bắt buộc; tối đa 8 mỗi sản phẩm/combo (không thêm giới hạn tổng giỏ); LOW_STOCK vẫn bán, OUT_OF_STOCK bị chặn; giá thay đổi phải cập nhật báo giá và xác nhận lại; hết hàng trong lúc đặt phải báo lỗi để người dùng sửa giỏ, không tự bỏ món; voucher/điểm thuộc Plan 10–11.

- Bổ sung phục hồi sau lỗi mutation/quote: giữ nguyên số lượng giỏ, tải lại danh sách sản phẩm và cho sửa ngay. Sản phẩm đã chọn nhưng biến mất khỏi catalog vẫn hiện trong giỏ với trạng thái không bán để người dùng giảm/bỏ thủ công. Không tạo payment nếu giỏ còn món không bán.
- Bổ sung thông báo lỗi trên màn bắp nước; lỗi từ checkout chuyển về giỏ sửa được.
- Giá thay đổi trong POST checkout: tải items/quote mới, hiển thị giá mới và chờ người dùng bấm xác nhận lại; không tạo payment trong lần phát hiện đổi giá.
- 28/28 test remote booking completion + booking entry + completion/account PASS. Test mới: hết hàng giữ giỏ và cho bỏ món đã bị ẩn khỏi catalog, bỏ qua food, giới hạn 8 độc lập cho item/combo, giá mới phải xác nhận trước tạo payment.

### Điều kiện BE phát hiện trước khi đồng bộ Mobile

Source `catalog-service/.../service/impl/CheckoutQuoteServiceImpl.java` hiện chỉ chấp nhận `FoodItemStatus.ACTIVE` ở bước tính giá food. Trong khi `FoodServiceImpl` công khai cả ACTIVE và LOW_STOCK. Vì vậy Mobile cho chọn LOW_STOCK theo yêu cầu, nhưng BE quote có thể từ chối. Cần người phụ trách BE đồng bộ điều kiện bán để chốt Plan 06; không sửa BE/DB trong đợt này. Các test dùng HTTP adapter kiểm chứng Mobile, chưa chứng minh LOW_STOCK thanh toán được qua BE thật.

Plan 06 chưa DONE: còn QA Gateway thật cho giỏ/stock/giá/timeout cùng luồng checkout. Vấn đề LOW_STOCK được xử lý bằng việc cho Mobile tuân theo BE trong cập nhật dưới đây.

## Điều chỉnh Plan 06 theo BE hiện tại

Yêu cầu mới của người dùng thay thế quyết định cho mua LOW_STOCK trước đó: Mobile tuân theo điều kiện bán của CheckoutQuoteService, không sửa BE/DB.

- Chỉ ACTIVE được tăng số lượng, áp dụng cho cả item và combo. LOW_STOCK/OUT_OF_STOCK/INACTIVE/UNKNOWN bị chặn ngay trên thẻ và tại controller.
- LOW_STOCK hiển thị “Sắp hết • Tạm ngừng đặt”; OUT_OF_STOCK hiển thị “Tạm hết hàng”; INACTIVE hiển thị “Tạm ngừng bán”. Danh sách vẫn có thể hiển thị LOW_STOCK do endpoint catalog trả về, nhưng không cho chọn mua.
- Món không đủ điều kiện đã có trong giỏ được giữ để người dùng giảm/bỏ; không tự xóa và không gửi checkout khi giỏ còn món này.
- Các quy tắc còn lại giữ theo yêu cầu: food tùy chọn; 8 mỗi item/combo; giá thay đổi phải xác nhận lại; lỗi hàng phải sửa giỏ; voucher/điểm ở Plan 10–11.
- Phụ thuộc thay đổi BE LOW_STOCK nêu ở mục trước đã được xử lý bằng việc điều chỉnh Mobile. Plan 06 vẫn cần QA Gateway thật; không đánh dấu DONE chỉ dựa trên test adapter.

- Kiểm chứng lần đồng bộ BE: analyzer PASS; 29/29 test booking/checkout/account PASS, gồm cả item/combo mọi trạng thái và giỏ phục hồi chứa LOW_STOCK.
