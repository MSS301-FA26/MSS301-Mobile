# UI-10 — QA tổng hợp và nghiệm thu giao diện

Cập nhật: **16/10/2026**. Test/build và kiểm tra emulator thực hiện **15/10/2026**.

**Đợt QA tự động và kiểm tra Android hiện có đã hoàn tất. Nghiệm thu toàn bộ UI-01–10 chưa đóng**, do còn review người dùng, QA iOS và các ca tích hợp bên dưới.

## 1. Phiên bản và môi trường

| Hạng mục | Giá trị |
| --- | --- |
| Mobile | `2ec57ac` + diff test trong đợt UI-10 |
| BE source đối chiếu | `9921498`; không khẳng định image runtime trùng commit chỉ từ HEAD source |
| Android đã kiểm tra | `emulator-5554`, Android 17, 1080 × 2424, density 420, font scale 1.0 |
| Kiểm tra màn hẹp | Density 540 → 320 logical px; font scale 1.6; đã khôi phục density 420/font 1.0 |
| Build | Android debug, `API_BASE_URL=http://127.0.0.1:8080`, `UI_PREVIEW=false` |
| API trên emulator | Gateway qua `adb reverse tcp:8080 tcp:8080` |
| iOS/thiết bị thật | Chưa kiểm tra |

Ngày 16/10 kiểm tra lại bằng chứng và diff: HEAD không đổi; `adb devices` không có thiết bị kết nối. Không ghi các ca chạy ngày 15/10 thành ca vừa chạy lại ngày 16/10.

## 2. Kết quả cổng kiểm tra

| Kiểm tra | Kết quả | Bằng chứng local |
| --- | --- | --- |
| `flutter analyze --no-pub` | No issues found | `D:/MSS/.qa-runtime/ui10-analyze.log` |
| `flutter test --no-pub` | **218 test đạt**, không có ca bị bỏ qua trong báo cáo cuối | `D:/MSS/.qa-runtime/ui10-tests-final.log` |
| Build APK debug | Thành công | `D:/MSS/.qa-runtime/ui10-build.log` |
| Kiểm tra overflow Android | Không thấy thông báo RenderFlex overflow trong phần logcat đã kiểm tra | Không thay thế kiểm tra toàn bộ thiết bị/trạng thái |

APK: `build/app/outputs/flutter-apk/app-debug.apk`. Bản UI đã được cài trong đợt UI-09; đợt UI-10 chỉ thay test/tài liệu, không thay source giao diện hoặc nghiệp vụ.

### Sửa test sau lượt chạy đầu

Lượt đầu: 209 đạt, 5 lỗi. Bốn ca dùng chung helper booking bấm Tiếp tục trước khi báo giá bất đồng bộ hoàn tất. Sau khi đợi báo giá, hai ca còn vướng việc trang vé hiện trạng thái ở cả badge lẫn dòng thông tin. Ca điều hướng còn dùng nhãn mã đơn và chữ hoa tên phim của UI cũ.

- `test/completion_and_account_test.dart`: đợi quote; kiểm tra trạng thái trong `BookingStatusBadge`. Giữ kiểm tra QR chỉ xuất hiện sau thanh toán và không có QR khi pending.
- `test/home_navigation_test.dart`: kiểm tra `Mã đơn: CP-MOCK-5101` và `Inception` theo UI hiện tại; giữ assertion dữ liệu tài khoản/điểm/ví.
- `test/ui04_booking_layout_test.dart`: thêm 360/390 px cho sơ đồ ghế rộng, chữ lớn và thao tác tới ghế cuối.
- `test/ui06_checkout_test.dart`: thêm 360/390 px cho đơn dài, thông báo cập nhật giá, CTA và countdown.

Không tắt hoặc bỏ qua test thất bại, không nới assertion thành bỏ qua trạng thái. Bốn kích thước bổ sung tạo thêm bốn ca, nên tổng cuối là 218.

## 3. Ma trận QA

**Tự động** dùng fixture/repository kiểm soát trong test. **Android API** là kiểm tra app trên emulator dùng dữ liệu BE thật. Hai loại bằng chứng không thay thế nhau.

| Nhóm | Tự động đã đạt | Android API/bằng chứng | Còn mở |
| --- | --- | --- | --- |
| Kích thước | 320/360/390/430 px trong các test UI; chữ lớn 1.6–1.8 theo từng màn; keyboard chat/form; CTA, số tiền và tên dài | Home/Khám phá/Tài khoản ở 320 px, font 1.6; các màn chính ở cấu hình mặc định | iOS, thiết bị thật; không khẳng định mọi màn đã kiểm tra trực tiếp ở cả bốn kích thước |
| Home/ảnh | Chuyển phim, CTA đúng phim đang chọn, tab/cache, banner API ưu tiên desktop, autoplay/reduced motion, ảnh thiếu và fallback | Banner/poster tải được; Home → các tab và bắp nước hoạt động | Chưa có bộ ảnh đối chiếu trực tiếp đủ LEFT/CENTER/RIGHT và poster ngang/dọc cùng dữ liệu; cách chọn focalPoint/contain/cover đã đọc source, chưa tính là visual pass đầy đủ |
| Trạng thái dữ liệu | Loading/error/empty, refresh, load more lỗi giữ dữ liệu và retry, tên/mã dài, giá lớn | Khám phá có 11 phim; Lịch chiếu có dữ liệu; ví lỗi hiện retry thay vì số dư 0 giả | Lỗi mạng vật lý và nhiều trang BE thật chưa chạy lại trong batch này |
| Booking | Vé trẻ em bị chặn theo phim; ghế đôi cùng loại; giới hạn 8; quote có phụ thu; chống submit lặp; xung đột, expiry và leave guard; giữ deadline qua các bước | Lịch chiếu thật hiển thị tên phim/phòng/giờ/giá | Không tạo booking/hold mới trong đợt QA này; E2E giữ ghế → checkout thật chưa chạy lại |
| Bắp nước | Ảnh lỗi; item/combo trùng ID; tối đa 8 mỗi loại; tùy chọn bỏ qua; không khả dụng; hết hàng/giá đổi giữ giỏ và chặn payment khi cần xác nhận | Danh sách món, ảnh, mô tả, giá và giỏ trống tải được; chưa chọn rạp thì CTA yêu cầu chọn rạp | Mua thật và tồn kho/giá thay đổi đồng thời trên BE chưa kiểm tra |
| Payment | Pending/verifying/error/failed/ready, resume/expiry, tạo payment một lần, thành công vẫn đợi booking PAID, quote đổi chặn tạo payment | Chỉ đọc đơn đã có; không tạo giao dịch | VNPay sandbox E2E, callback chậm/thất bại trên runtime thật |
| QR/export | PAID mới có QR; USED và các trạng thái khác không có QR dùng lại; payload, quiet zone, sở hữu tài khoản; lỗi export không báo thành công | Mở vé PAID hiện có: ghế A2, tổng 333.000đ, gồm nước 20.000đ; QR xuất hiện | Quét độc lập/check-in, save/share sheet/quyền thiết bị; chất lượng PDF tiếng Việt |
| Account | Tên/email dài, điểm/ví lớn; phân biệt số dư thật 0 với lỗi; retry cục bộ; form có bàn phím | Hồ sơ và điểm tải được; ví báo chưa tải được số dư; tên/email xuống dòng ở chữ lớn | Số dư ví thành công trên runtime hiện tại |
| Chat | Gợi ý chỉ điền draft, gửi/retry/sửa, pending, giới hạn input, conversationId, reset/đổi user và phản hồi muộn; cuộn phản hồi dài; nền rạp phim | Bằng chứng UI-09 ngày 15/10: mở bàn phím/gợi ý, gửi/thử lại gặp HTTP 403 | Hai lượt chat LLM thành công cùng conversation; nguyên nhân 403 chưa kết luận |
| Điều hướng | Tab, Back/leave guard, route đặt vé theo phim, ticket/payment route, auth guard và reset theo user | Home → Khám phá/Lịch chiếu/Đơn/Tài khoản; Home → bắp nước; Đơn → Mở mã vé | Deep link từ hệ điều hành và app khởi động lạnh chưa QA trên thiết bị thật |

Nguồn tự động chính: `ui01_states_test` đến `ui09_popbot_test`, `home_navigation_test`, `home_redesign_test`, `booking_entry_test`, `booking_entry_controller_test`, `booking_hold_countdown_test`, `remote_booking_completion_test`, `plan08_ticket_test`, các test repository/contract/thời gian. Báo cáo cuối lưu tên từng ca.

## 4. Ảnh và so sánh trước/sau

Ảnh local của đợt tổng hợp nằm trong `D:/MSS/.qa-runtime/`:

- `ui10-home.png`, `ui10-discover.png`, `ui10-showtimes.png`
- `ui10-orders.png`, `ui10-ticket.png`, `ui10-account.png`, `ui10-food.png`
- `ui10-home-320-large.png`, `ui10-discover-320-large.png`, `ui10-account-320-large.png`

Gallery nội bộ để xem ảnh: `D:/MSS/.qa-runtime/ui10-review.html`. Ảnh tài khoản/vé chứa dữ liệu tài khoản test, giữ local.

Ảnh trước/sau theo batch đã ghi trong UI02–UI09-RESULTS. Các ảnh lịch sử có thể khác dữ liệu API, thời điểm và vị trí cuộn; không coi là so sánh pixel cùng dữ liệu. Không có đủ baseline đúng điều kiện cho tất cả màn; đây là một hạng mục còn mở khi nghiệm thu thị giác toàn bộ.

## 5. Phản hồi đã có

| Batch | Phản hồi được ghi nhận |
| --- | --- |
| UI-03 | Người dùng xác nhận danh sách phim xem được và khá ổn |
| UI-05 | Người dùng xác nhận “plan 5 đã ổn” |
| UI-06 | Người dùng xác nhận “plan 6 ổn ròi” |
| UI-09 | Đã thêm nền rạp phim theo yêu cầu; chưa có phản hồi duyệt nền mới |
| Các batch khác | Không tự suy ra đã duyệt chỉ vì người dùng chuyển sang plan kế tiếp |

## 6. Việc cần chốt trước nghiệm thu toàn bộ

1. **Chat 403:** xác minh quyền/xác thực gateway → recommendation-service; test chat thành công hai lượt, giữ conversationId. Chưa thay BE/runtime trong đợt UI-10.
2. **Ví:** xác minh API số dư; retry trả số dư thật và phân biệt 0 với lỗi. UI hiện xử lý lỗi đúng nhưng dữ liệu thành công chưa QA được.
3. **PDF:** test xuất file đạt nhưng còn cảnh báo Courier không hỗ trợ Unicode; chưa xác nhận hiển thị tiếng Việt đúng. Cần xử lý font và kiểm tra file xuất trước khi duyệt chất lượng PDF.
4. **VNPay/check-in:** QA sandbox xuyên booking/food/payment/resume, sau đó quét QR bằng camera/decoder độc lập và kiểm tra trạng thái từ BE. Không lấy fixture hoặc ảnh QR làm bằng chứng giao dịch/check-in.
5. **Thiết bị:** iOS, safe area/keyboard thật, lưu/chia sẻ vé, deep link khởi động lạnh.
6. **Review thị giác:** duyệt các batch còn lại, banner focalPoint ba vị trí/poster hai tỷ lệ và baseline trước/sau đúng điều kiện.

Có thể tiếp tục phát triển UI-11 sau đợt QA này, nhưng các việc trên vẫn còn mở và cần kiểm tra lại các màn bị ảnh hưởng sau mỗi thay đổi. Không đánh dấu toàn bộ ứng dụng đã nghiệm thu hoặc sẵn sàng production từ kết quả UI-10.

## 7. Khôi phục kết nối Android Emulator — 16/10/2026

Sau báo lỗi chưa tải được dữ liệu, emulator đã kết nối trở lại. Kiểm tra gateway và `GET /api/v1/movies?page=0&size=1` từ host đều HTTP 200; Docker gateway đang publish port 8080. App cũ dùng `127.0.0.1:8080`, nhưng danh sách `adb reverse` trống. Nối lại reverse và restart app khôi phục được banner/phim.

Đã chuyển hai profile VS Code trong `.vscode/launch.json` sang **Android Emulator**, dùng `API_BASE_URL=http://10.0.2.2:8080`. Build và cài APK cùng địa chỉ mới, chủ động gỡ mapping reverse `tcp:8080`, restart app: Home vẫn tải được banner/phim. Đây là đường host dành cho Android Emulator, không phải cấu hình chung cho iOS hoặc điện thoại thật.

- Build thành công: `D:/MSS/.qa-runtime/mobile-emulator-host-build.log`.
- Ảnh Home sau sửa: `D:/MSS/.qa-runtime/mobile-emulator-host-home.png`.
- Không đổi port gateway, source BE hay dữ liệu DB. Kết quả 218 test bên trên thuộc đợt QA trước; thay đổi kết nối này kiểm chứng bằng build và app/API thật, không ghi là đã chạy lại toàn bộ test.
