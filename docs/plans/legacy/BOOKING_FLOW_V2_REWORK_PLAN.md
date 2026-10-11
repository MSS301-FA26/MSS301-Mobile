# Booking V2 — hồ sơ legacy và kiểm chứng hiện tại

Ngày lập ban đầu: 2026-09-27. Cập nhật: 2026-10-11.
Tác giả Git của tài liệu gốc: Tzee314.
Mốc đối chiếu: Mobile dev tại 600298d; Backend dev tại 9f4d53a.

**Trạng thái: pending — còn QA thiết bị và các lỗi tích hợp được liệt kê bên dưới.** Phần rà soát tài liệu đã cập nhật theo source hiện tại; các kết quả mock trước đây không được dùng để xác nhận flow production.

## 1. Phạm vi và lịch sử V2

V2 ban đầu cải tiến flow mock: chọn suất → Vé & Ghế → Bắp nước → Checkout → VNPay mock → vé/lịch sử.

Các vấn đề ban đầu đã được xử lý trong đợt mock: phải nhấn Tiếp tục hai lần, Back từ Bắp nước sai route, giới hạn chọn ghế cũ là 6, chưa có mapping vé theo ghế và tap suất mở ghế ngay. Đây là lịch sử trước V2, không phải mô tả hiện trạng.

| Chặng | Kết quả đợt mock | Kết luận theo code hiện tại |
| --- | --- | --- |
| V2.1 Navigation | Đã chọn suất trước CTA; một nhấn hold và sang Bắp nước; Back về đúng showtime. | Hành vi có trong source/test; cần kiểm tra thiết bị và lỗi cancel trước rời flow. |
| V2.2 Contract/model | Assignment theo seatId và ticketType; ba loại vé; tối đa 8; tuổi đại diện 10/20/30. | Giới hạn 8 có trong Mobile; tuổi đại diện vẫn được gửi cả ở flow remote, cần thay bằng tuổi thật trước xác nhận nghiệp vụ tuổi. |
| V2.3 UI | Counter, xác nhận giảm vé, metadata sơ đồ, nhóm vé/ghế, progress. | Có source/test layout; QA thủ công chưa ghi nhận; nhóm ghế đôi còn lỗi nhiều cặp cùng hàng. |
| V2.4 Downstream | Mapping/cart/quote/payment mock được nối. | Nhánh remote chưa hoàn thiện food, checkout, payment completion và QR; không coi đợt mock là bằng chứng hoàn thành remote. |
| V2.5 Verification | Tài liệu cũ ghi analyze, 30 tests và debug APK đã pass. | Cần kết quả kiểm chứng mới và checklist thiết bị. Kết quả lịch sử giữ tại mục 7. |

## 2. Contract BE đã có — áp dụng khi tích hợp

BE đã có service xử lý tuổi, giá, assignment, hold, update, checkout và cancel. Các quy tắc dưới đây được đọc từ cinema-services; không phải sáu blocker yêu cầu chờ thiết kế service mới.

| Nội dung | Hành vi BE hiện có | Cách Mobile áp dụng |
| --- | --- | --- |
| Loại vé và tuổi | Catalog TicketType: CHILD 0–12, STUDENT 13–25, ADULT 18–59. Quote kiểm tra đồng thời tuổi loại vé và tuổi phim; AgeRating có P/K/T13/T16/T18. | Gửi viewerAge đúng từng người và xử lý lỗi eligibility; không suy ra điều kiện giấy tờ sinh viên chỉ từ tuổi. Catalog chưa có SENIOR. |
| Mapping vé–ghế | Quote kiểm tra ghế trùng, assignment trùng và tổng số vé bằng số ghế. Tickets được lưu từ quote. | Gửi từng ticket có seatId, ticketType, viewerAge và quantity = 1; đọc loại vé từ booking.tickets rồi join bằng seatId. |
| Giá và phụ thu | CheckoutQuoteServiceImpl tính giá theo cấu hình rạp/phòng, audience price, pricing rules và fallback showtime. | Dùng ticket line/subtotal/total BE trả về; giá trên màn ghế là ước tính. Không cộng lại phụ thu vào giá cuối của quote. |
| Ghế đôi | Quote có tính giá theo mỗi seat ID từ giá cặp; preview suất có tổ hợp hai loại vé khác nhau. | Hai vị trí ghế cần ID/mapping rõ; lấy từng line giá từ quote. Có tính giá không đồng nghĩa BE đã bắt buộc mua đủ cặp. |
| Hold | BookingServiceImpl kiểm tra xung đột, tạo HOLDING với holdExpiresAt = now + 3 phút; thay unfinished hold của cùng user/showtime khi hold lại. | Đọc holdExpiresAt từ response; chống gửi lặp, xử lý conflict và expiry. Không đổi deadline chỉ vì Back hoặc mở lại màn. |
| Update/checkout | PUT bookings/{id}/items cập nhật tickets/foods; POST bookings/{id}/checkout quote lại và chuyển PENDING_PAYMENT. | Update khi cần, sau đó checkout trước tạo payment; kiểm tra booking response authoritative. |
| Đổi ghế | API hiện có cancel booking và hold mới; update items không đổi seat IDs. | Xác nhận giải phóng hold → cancel thành công → sửa chọn ghế → hold mới. API đổi ghế nguyên tử là cải tiến tùy chọn. |
| Giới hạn vé | HoldSeatsRequest chưa có giới hạn 8; quote request giới hạn tối đa 100 seat IDs. | Giữ 8 là giới hạn UI Mobile hiện tại. Chỉ bổ sung BE khi product yêu cầu cùng giới hạn trên mọi client. |

Bằng chứng BE (đường dẫn từ root MSS301-Backend):

- cinema-services/catalog-service/src/main/java/com/cinemaai/catalog/service/impl/CheckoutQuoteServiceImpl.java: quote, kiểm tra tuổi/assignment và resolveTicketPrice.
- cinema-services/catalog-service/src/main/java/com/cinemaai/catalog/enums/TicketType.java và AgeRating.java: quy tắc tuổi.
- cinema-services/catalog-service/src/main/java/com/cinemaai/catalog/service/impl/ShowtimeServiceImpl.java: preview giá ghế đôi theo tổ hợp loại vé.
- cinema-services/booking-service/src/main/java/com/cinemaai/booking/service/impl/BookingServiceImpl.java: holdSeats, checkout, updateHoldingItems, populateTicketsAndFoods và cancelBooking.
- cinema-services/booking-service/src/main/java/com/cinemaai/booking/controller/BookingController.java: public mappings.
- cinema-services/catalog-service/src/main/java/com/cinemaai/catalog/dto/request/quote/CheckoutQuoteRequest.java: giới hạn 100.

## 3. Điểm còn cần sửa hoặc quyết định cụ thể

| Mã | Hiện trạng | Hành động và nơi tiếp nhận |
| --- | --- | --- |
| BE-01 | BookingSeat.ticketType được tạo ADULT trong khi BookingTicket nhận loại từ quote. | Mobile ưu tiên tickets ngay; BE đồng bộ field hoặc công bố rõ semantics để client khác không đọc sai. [Plan 05](../05-BOOKING-SESSION.md). |
| BE-02 | populateTicketsAndFoods lưu BookingTicket.viewerAge = 20, không giữ tuổi thực đã gửi. | BE cần bảo toàn tuổi; Mobile thu thập/gửi tuổi thật, không dùng tuổi response bị thay đổi để kết luận eligibility. [Plan 05](../05-BOOKING-SESSION.md). |
| PRODUCT-01 | Catalog ADULT dừng ở 59; chưa có SENIOR trong Catalog dù Booking có enum này. | Chốt loại vé cho người trên 59 và điều kiện xác minh Student/Child. Quy tắc tuổi đã có cho các trường hợp hiện được hỗ trợ vẫn áp dụng bình thường. |
| PRODUCT-02 | Mobile chặn 8; BE không áp dụng cùng giới hạn. | Quyết định có áp dụng server-wide hay giữ giới hạn riêng Mobile. Không coi đây là blocker của mọi tích hợp. |
| BE/UI-03 | Có tính giá ghế đôi; chưa thấy kiểm tra bắt buộc giữ đủ cặp trong hold/quote đã đọc. Mobile _seatGroup đang lấy mọi ghế COUPLE cùng hàng. | Chốt quy tắc bán cặp và metadata xác định từng cặp; sửa grouping để hàng có nhiều cặp không chọn cả hàng. [Plan 05](../05-BOOKING-SESSION.md). |
| UI-04 | AppShell và seat Back vẫn điều hướng sau abandon dù cancel có thể thất bại; các lối Search/Account chưa có cùng guard. | Cancel lỗi giữ flow và cho retry; áp dụng guard cho mọi đường thoát liên quan. [Plan 05](../05-BOOKING-SESSION.md). |
| UI-05 | Remote food methods chưa triển khai; controller chỉ tải food khi mock và bỏ update/checkout trong remote. | Nối food → items → quote → checkout thật. [Plan 06](../06-CONCESSIONS-AND-CHECKOUT.md). |
| UI-06 | Refresh payment SUCCESS chỉ tới verifyingBooking; transition ticketReady nằm trong simulateSuccess. | Xác minh booking PAID trong flow thật, refresh history và mở vé. [Plan 07](../07-VNPAY-COMPLETION.md). |
| UI-07 | TicketPage hiển thị qrCode dưới dạng text. | Render QR theo payload BE, kiểm tra scanner/staff lookup. [Plan 08](../08-ORDERS-AND-TICKET-QR.md). |

Giá/phụ thu và cancel → hold mới đã có cách tích hợp hiện tại. Nếu muốn breakdown phụ thu riêng hoặc đổi ghế nguyên tử, tách thành cải tiến contract có phạm vi rõ, không gọi là service còn thiếu.

## 4. Flow và tiêu chí cần đạt

Chọn phim → chọn suất → auth nếu cần → chọn số vé theo loại → gán đủ ghế → một lần nhấn tạo hold → chọn/bỏ qua food → quote + checkout → VNPay → xác minh payment SUCCESS và booking PAID → vé QR/lịch sử.

- State lựa chọn dùng mapping seatId → loại vé/tuổi; không duy trì hai danh sách chọn ghế độc lập.
- Số vé 1–8 theo giới hạn Mobile; đủ ghế từng loại, không trùng và không chọn runtime unavailable.
- Back từ food về đúng showtime, giữ lựa chọn và cart trong phiên; xem lại không tự hold thêm.
- Đổi ghế có xác nhận cancel; đổi loại/tuổi trên cùng seat IDs có thể update items theo API BE.
- Quote là nguồn giá cuối; Student/Child không lấy giá Adult làm giá cuối.
- Expired không được checkout; mất mạng/cancel lỗi không được hiển thị như đã hoàn thành.
- Production phải xác minh payment/booking từ BE; không dùng thao tác mô phỏng làm bằng chứng đã trả tiền.
- QR phải quét được; vé USED có giao diện lịch sử phù hợp, không trình bày như còn được check-in.

## 5. Checklist QA thủ công

Điều kiện: ghi commit Mobile/BE, cấu hình mock hoặc Gateway thật, thiết bị/emulator, kích thước màn và text scale. Kết quả từng ca: PASS/FAIL, actual/expected, ảnh hoặc video nếu có. Hiện tất cả ca dưới đây là **chưa chạy thủ công**.

| Ca | Thao tác | Kết quả mong đợi |
| --- | --- | --- |
| QA-01 | Guest chọn suất, nhấn Tiếp tục, login. | Trở về đúng showtime; chưa tự tạo hold trước lựa chọn hợp lệ. |
| QA-02 | Một loại vé rồi nhiều loại vé; tăng/giảm số lượng đã gán. | Mapping đúng từng loại; giảm có xác nhận; hủy dialog giữ lựa chọn. |
| QA-03 | Thử 0 vé, thiếu ghế, 8 vé và vượt 8. | CTA chỉ bật khi đủ mapping; không vượt giới hạn Mobile. |
| QA-04 | Hàng STANDARD/VIP và hàng có ít nhất hai cặp COUPLE. | Nhãn/lối đi/trạng thái đúng; chọn một cặp không chọn tất cả COUPLE cùng hàng. |
| QA-05 | Nhấn Tiếp tục một lần và nhấn nhanh nhiều lần. | Một hold request hợp lệ, một booking và một lần sang food. |
| QA-06 | Back bằng UI và Android Back từ food; chỉ xem rồi đi tiếp. | Đúng showtime, mapping/cart không mất, không tạo hold mới hoặc reset deadline. |
| QA-07 | Sửa ghế/đổi suất; thử cancel thành công và lỗi mạng. | Cancel thành công mới rời/sửa; cancel lỗi giữ flow với retry. |
| QA-08 | Hai tài khoản giữ cùng ghế; hold hết hạn trước/sau Back. | Conflict reconcile đúng ghế; expired không checkout và có đường chọn lại. |
| QA-09 | Tuổi đúng/sai loại vé; Child với phim T13/T16/T18. | Request mang tuổi thật; lỗi BE hiển thị rõ; không dùng tuổi đại diện để qua validation. |
| QA-10 | Thêm/bỏ food, sửa cart rồi checkout. | Items và snapshot BE khớp quote; tổng đúng khi giá/tồn kho thay đổi. |
| QA-11 | VNPay sandbox success/failed/cancel; resume và callback chậm. | Chỉ mở vé sau PAID; pending có retry/refresh; không kẹt verifyingBooking. |
| QA-12 | Mở QR và quét bằng scanner/staff lookup. | Mã đọc được, đúng booking; trạng thái đã sử dụng không check-in lại. |
| QA-13 | Màn rộng 320/360/390/430 px, chữ lớn, bàn phím. | Không overflow; footer không che nội dung; ghế chạm được và vùng zoom/cuộn hợp lý. |
| QA-14 | Kill/restart trong hold/payment; logout/login tài khoản khác. | Phục hồi dựa trên BE hoặc hướng dẫn rõ; không hiện booking/cache của user cũ. |

QA mock chỉ xác nhận UI/mock state; QA Gateway/sandbox xác nhận lifecycle thật. Ca đang gặp lỗi source ở mục 3 phải được sửa rồi chạy lại.

Bàn giao QA tiếp theo tại [Plan 12](../12-INTEGRATION-AND-DEVICE-QA.md). Khi đã đủ bằng chứng, cập nhật từng ca và mới chuyển trạng thái tổng thể sang done.

## 6. Kiểm chứng trong lần cập nhật 2026-10-11

| Kiểm tra | Kết quả |
| --- | --- |
| Đọc code Mobile/BE và đối chiếu 6 câu hỏi contract | Hoàn thành; kết quả ở mục 2–3. |
| flutter analyze --no-pub | PASS — No issues found. |
| flutter test --no-pub test/booking_entry_controller_test.dart test/booking_entry_test.dart test/completion_and_account_test.dart test/backend_aligned_contract_test.dart | PASS — 30/30 tests. Các widget completion tests dùng mock; không xác nhận VNPay/Gateway thật. |
| adb devices -l | Đã kết nối emulator-5554, Android x86_64, 1080×2424, density 420. |
| QA thiết bị | Đã kiểm tra catalog thật, chọn suất, khách chuyển tới login, Back login và layout Home/Login ở khoảng 360 dp với font 1.3. Chi tiết và ảnh tại báo cáo bên dưới. |
| Build APK mới | PASS — debug APK đã build/cài/mở trên emulator. Chạy flutter pub get trước build để tạo lại plugin registrant; tắt Kotlin incremental cache riêng trong tiến trình build do Pub cache ở ổ C và dự án ở ổ D. |
| Regression Back/login | PASS — test/auth_back_navigation_test.dart: 1/1; trên emulator Back đã về Home, không lặp lại login. |

Các sửa Mobile trong lần QA: cho phép HTTP ở debug manifest để dùng gateway local, logger thêm loại exception (không log body/token), sửa fallback Back/login từ Account sang Home. Không dùng kết quả static review/analyzer để đánh dấu QA thủ công hay tích hợp production đã pass.

Sau yêu cầu không thay đổi BE/DB, đã hoàn tác toàn bộ file BE do lần QA này sửa và xác nhận Git BE sạch. Không tiếp tục các API ghi dữ liệu. Database Docker local mới đã được tạo và chạy migration/tạo user QA trước yêu cầu này; chưa xóa hoặc sửa lại dữ liệu trong các volume đó. Stack QA được dừng khi kết thúc.

**QA-01 chỉ pass phần khách chuyển đến login và Back; chưa kiểm tra login rồi tiếp tục cùng suất. QA-02–12, QA-14 chưa pass trên thiết bị. QA-13 mới kiểm tra một phần màn Home/Login. Legacy vẫn pending.**

Báo cáo chi tiết: [QA emulator 2026-10-11](qa-2026-10-11/QA-REPORT.md).

## 7. Bằng chứng lịch sử — 2026-09-27

Tài liệu gốc ghi:

- dart analyze lib test: No issues found.
- flutter test --no-pub: 30/30 test pass, có widget test không overflow ở 320 px và 430 px.
- flutter build apk --debug --no-pub: thành công, APK tại build/app/outputs/flutter-apk/app-debug.apk.
- QA thủ công chưa ghi nhận.

Các kết quả trên là của đợt mock trước đây. Chúng không thay thế kết quả mới khi sửa remote flow.

## 8. Tài liệu và source tham chiếu

- [UI Flows của Tzee314](../../CINEPREMIER_MOBILE_UI_FLOWS.md).
- [Mock UI Plan đã lưu](../../done/BACKEND_ALIGNED_MOCK_UI_PLAN.md).
- [CTA Registry đã lưu](../../done/MOBILE_CTA_ROUTE_REGISTRY.md).
- [API Readiness Report đã lưu](../../done/MOBILE_API_READINESS_REPORT.md).
- [Booking entry controller](../../../lib/features/seat/application/booking_entry_session.dart).
- [Seat selection UI](../../../lib/features/seat/presentation/pages/seat_selection_page.dart).
- [Booking completion controller](../../../lib/features/booking/application/booking_completion_controller.dart).
- [Booking controller tests](../../../test/booking_entry_controller_test.dart).
- [Booking widget tests](../../../test/booking_entry_test.dart).
