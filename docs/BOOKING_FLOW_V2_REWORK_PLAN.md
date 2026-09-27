# Kế hoạch chỉnh luồng đặt vé V2 — Vé & Ghế

> Ngày rà soát: 2026-09-27  
> Trạng thái: **V2.1–V2.5 đã triển khai trong phạm vi backend-aligned mock UI; chờ kiểm thử thủ công trên thiết bị/emulator**  
> Phạm vi: Flutter backend-aligned mock UI; `docs/ui-reference/ai-studio-v2` là tham chiếu visual/tương tác. Public DTO và quy tắc giá/tuổi trong `BE/MSS301-Backend/cinema-services` được ưu tiên khi khác prototype.

## 1. Kết luận rà soát hiện trạng

| Vấn đề người dùng nêu | Kết quả kiểm tra | Điểm sửa chính |
| --- | --- | --- |
| Phải nhấn **Tiếp tục** hai lần từ Chọn ghế | **Đúng.** `SeatSelectionPage` gọi `holdSelectedSeats()` ở lần đầu rồi dừng; chỉ khi state đã `holding`, lần nhấn tiếp mới `go` sang bắp nước. | Một lần nhấn hợp lệ phải `await hold`, kiểm tra booking `HOLDING`, rồi điều hướng ngay; khóa CTA trong lúc gửi. |
| Bắp nước không quay lại chọn ghế | **Đúng.** Màn bắp nước gọi `context.pop()`, trong khi từ ghế sang bắp nước dùng `context.go()`. Route ghế không còn trong navigation stack. | Điều hướng bằng route ghế theo `showtimeId` từ booking/session; hỗ trợ cả nút Back hệ thống. |
| Sơ đồ ghế chưa đẹp/dễ dùng | **Có cơ sở.** UI hiện vẽ các hàng `Row` tuyến tính, mã ghế 38 px, ghế đôi rộng 52 px, thiếu lối đi/căn theo `displayColumn`/`startColumn`, legend gộp held/booked/maintenance. | Dựng layout theo metadata phòng, tách trạng thái, tăng khả năng đọc và thao tác trên màn 320–430 px. |
| Vé Người lớn/Sinh viên/Trẻ em gán theo ghế | **Chưa có.** `TicketType` trong DTO đã tồn tại nhưng booking entry chỉ lưu `selectedSeatIds`; hold/quote mock và `BookingSeatDto.ticketType` mặc định `ADULT`. | Một nguồn state `seatId → ticketType + viewerAge`; truyền cùng mapping qua hold, update, quote, checkout, ticket/order. |
| Giới hạn tối đa 8 vé | UI hiện chặn **6 ghế**. Backend quote cho phép tối đa 100 seat IDs theo validation; chưa thấy quy tắc public giới hạn 8. | Dùng cấu hình mock tập trung `maxTicketsPerBooking = 8`; ghi là giới hạn UI sản phẩm cần backend chốt trước tích hợp thật. |
| Chọn suất rồi nhấn **Tiếp tục: Vé & Ghế** | Hiện tap suất hợp lệ mở ghế ngay. | Lưu một suất đang chọn ở trang Lịch chiếu, hiển thị tóm tắt và CTA sticky; auth gate chạy khi nhấn CTA. |

Các thay đổi R5–R8 trước đó đang có trong worktree, gồm `features/booking`, account và preview. Khi triển khai V2 phải giữ và sửa trên các file này; không thay thế hay làm mất thay đổi chưa commit.

## 2. Những ràng buộc phải theo backend

1. Catalog đã có `ADULT`, `STUDENT`, `CHILD`; booking enum còn có `SENIOR`, nhưng catalog quote chưa có giá/điều kiện `SENIOR`. V2 chỉ bật ba loại catalog hỗ trợ.
2. `ShowtimeResponse` đã có giá theo **loại vé × loại ghế** (`adult/child/student` × `standard/vip/couple`) và các surcharge theo suất. Dùng giá/quote theo suất; **không** lấy 110.000/120.000/130.000đ hoặc phụ thu +20.000/+60.000đ trong ảnh làm quy tắc toàn hệ thống. `ShowtimeSeatDto.unitPrice` hiện có thể là giá ghế người lớn; không được dùng nó làm giá cuối của Sinh viên/Trẻ em.
3. Catalog quote nhận `tickets[]` có `seatId`, `ticketType`, `viewerAge`, `quantity`. Mỗi ghế được gán rõ một loại vé thì gửi một ticket line với `quantity: 1`. Quote từ backend kiểm tra số vé bằng số ghế, seat ID không trùng, tuổi đúng loại vé và phân loại tuổi phim.
4. Tuổi không thể để mặc định 22 cho mọi vé. Backend catalog hiện quy định `CHILD: 0–12`, `STUDENT: 13–25`, `ADULT: 18–59`; các mốc này khác câu chữ prototype. Bản mock V2 dùng tuổi đại diện hợp lệ theo từng loại (10/20/30) để kiểm tra mapping. Trước khi nối API thật, UI phải thu thập `viewerAge` theo quyết định product/backend và không đưa ra cam kết tuổi/chiều cao riêng của prototype. Vấn đề người xem trên 59 tuổi cần backend/product quyết định vì catalog không có `SENIOR` dù booking enum có.
5. Hold của booking service tồn tại 3 phút. Public API hiện có hold, update **tickets/foods** của booking đang giữ, checkout và cancel; **không có endpoint đổi danh sách seat IDs trong một hold**.
6. `BookingTicketResponse` chứa `seatId + ticketType`, đủ để dựng mapping vé–ghế ở client. Tuy nhiên `BookingServiceImpl` hiện tạo `BookingSeat.ticketType = ADULT` cho mọi ghế và không đồng bộ lại field này khi `populateTicketsAndFoods()`. Trước tích hợp thật, backend cần sửa/công bố nguồn chuẩn cho mapping. Flutter mock phải giữ mapping đúng ở `BookingTicketDto`, và các màn ticket/order ưu tiên join qua `seatId` với tickets, không tin field seat đang mặc định `ADULT`.
7. Checkout hiện chỉ có VNPay mock trong core flow. Voucher/VIP, CineWallet, VietQR, MoMo, ZaloPay và thẻ trong ảnh V2 không được bật như phương thức thanh toán thật; voucher hiện là preview sau flag. QR ở Flutter hiện là ô vuông mock, không phải mã QR quét được; nếu muốn demo quét mã, cần một work item riêng và dữ liệu `booking.qrCode` hợp lệ.

## 3. Luồng V2 đã chọn

```text
Trang chủ / Khám phá / Chi tiết phim
  → Lịch chiếu: chọn đúng một suất → Tiếp tục: Vé & Ghế
  → Auth gate nếu cần → Vé & Ghế: chọn số lượng + gán ghế theo loại vé
  → Tiếp tục: Bắp nước [một lần nhấn = tạo hold + chuyển màn]
  → Bắp nước hoặc bỏ qua → Thanh toán/Checkout
  → VNPay mock → verify booking PAID → Vé điện tử / Đơn của tôi
```

Progress hiển thị bốn bước: **Suất chiếu → Vé & Ghế → Bắp nước → Thanh toán**. Sau khi trả về từ bắp nước, màn Vé & Ghế vẫn hiển thị đúng suất, số lượng và mapping; đồng hồ hold không được khởi động lại do điều hướng. Không có bước gán loại vé riêng sau khi chọn ghế.

### Quy tắc Back và sửa lựa chọn khi đã hold

- Từ bắp nước về Vé & Ghế: dùng `booking.showtimeId`/route ghế, tải lại booking theo `bookingId`, giữ mapping và giỏ bắp nước; không gọi hold lần nữa nếu người dùng chỉ xem rồi đi tiếp.
- Khi người dùng muốn **đổi số lượng hoặc đổi ghế** của hold hiện có: báo rõ ghế đang giữ sẽ được giải phóng; sau khi xác nhận, cancel hold cũ, giữ draft mapping local, cho sửa rồi tạo hold mới. Nếu ghế cũ bị người khác lấy, chỉ bỏ assignment xung đột và báo loại vé còn thiếu.
- Nếu chỉ đổi loại vé/tuổi cho **cùng seat IDs** trong hold còn hiệu lực, có thể dùng `updateItems(tickets)` và quote lại; không hủy hold. Cần bảo đảm mock repository phản ánh cùng quy tắc.
- Khi hold hết hạn: giữ phần thông tin suất/vé để người dùng chọn ghế lại; không cho checkout hoặc dùng lại booking đã `EXPIRED`.
- Đổi suất chiếu: hỏi xác nhận nếu có draft/hold, cancel hold cũ, xóa assignment và giá/quote cũ, tải seat map/giá mới.
- Direct link/refresh: xác minh `showtimeId` và booking status; nếu state trong bộ nhớ mất nhưng booking còn hợp lệ, khôi phục từ repository; nếu không còn hợp lệ, về Lịch chiếu có thông báo. Với mock in-memory, **không cam kết khôi phục sau khi ứng dụng bị kill/restart** nếu chưa thêm persistence.

## 4. State và giá của bước Vé & Ghế

**Nguồn state duy nhất:** mở rộng `bookingEntryProvider` để lưu `showtimeId`, số lượng theo `TicketType`, loại vé active, và `Map<int, SeatTicketAssignment>` theo `seatId`. `selectedSeatIds` chỉ là giá trị derive từ assignment; không có hai danh sách độc lập. Assignment mock lưu `seatId`, `ticketType`; `viewerAge` được suy ra từ policy mock 10/20/30 khi tạo request. Nhãn ghế/loại ghế/giá lấy từ seat map và quote. Bắp nước tiếp tục do `bookingCompletionProvider` giữ, nhưng hai controller tham chiếu cùng `bookingId` khi quay lại hoặc re-hold.

- Mặc định chưa chọn số lượng vé và chưa có loại vé active. Tổng số vé từ 1 đến 8. Loại vé có số lượng 0 không active được.
- Fixture phòng mặc định hiện không có đủ 8 ghế khả dụng đồng thời; test giới hạn 8 phải dùng fixture riêng với ít nhất 8 ghế hợp lệ, không tự thêm ghế vào sơ đồ demo đang hiển thị hoặc đổi trạng thái ghế đã bán.
- Tăng số lượng giữ assignment cũ và active loại vừa tăng. Giảm số lượng nếu cần bỏ ghế đã gán phải xác nhận; bỏ assignment mới nhất **của chính loại vé đó**.
- Chọn ghế trống gán cho loại active đang thiếu ghế; ghế đã chọn có thể bỏ hoặc chuyển loại bằng bottom sheet, với điều kiện loại đích còn suất. Tự chuyển active theo Người lớn → Sinh viên → Trẻ em khi loại hiện tại đủ ghế.
- Ghế đôi: giữ nguyên cách thể hiện theo physical seat IDs từ backend. Nếu rule giữ cặp hiện tại còn áp dụng, thao tác chọn/bỏ hai ghế phải nguyên tử và cần đủ **hai vé còn thiếu** ở một hoặc các loại vé; không ép cả cặp là cùng loại vé. Giá cho mỗi seat ID đến từ quote. Xác nhận với backend nếu loại ghế đôi thực tế là một đơn vị bán duy nhất.
- CTA chỉ bật khi có vé, từng loại đã gán đủ ghế, seat IDs duy nhất, tuổi hợp lệ, seat runtime còn khả dụng và không đang submit. Lỗi thiếu ghế nêu rõ từng loại (`Còn 1 ghế Sinh viên`).
- Hiển thị **ước tính** từ bảng giá suất theo loại vé × ghế; lấy `CheckoutQuoteDto` làm tổng authoritative trong mock/backend. Quote cần có tickets đầy đủ ở cả hold, `updateItems` và checkout. Không cộng surcharge hai lần: nếu `unitPrice` theo loại vé/ghế đã gồm phụ thu thì dòng “phụ thu” chỉ là breakdown giải thích. Khi backend không trả breakdown đáng tin cậy, chỉ hiển thị giá theo từng vé/ghế và tổng quote.

## 5. UI theo `ai-studio-v2`, có điều chỉnh cho Flutter/backend

| Màn | Áp dụng từ reference | Điều chỉnh bắt buộc |
| --- | --- | --- |
| Lịch chiếu | Header nhỏ, progress 4 bước, suất selected rõ, footer tóm tắt + CTA vàng | Giữ dữ liệu phim/suất/rạp hiện có; chỉ một suất active, không tự chọn ngày/suất. |
| Vé & Ghế | Thông tin suất compact; ba card vé dạng dọc; card active có nhãn; thanh “Đang chọn ghế cho…”; danh sách nhóm vé/ghế; footer `đã chọn x/y` | Card phải cuộn được; giá/tuổi theo backend; loại ghế và trạng thái không phụ thuộc màu duy nhất. |
| Sơ đồ ghế | Màn chiếu cong nhẹ, row label hai bên, lối đi rõ, màu chọn theo loại vé, legend tách biệt | Dựng từ `rowLabel`, `displayOrder`, `displayColumn`, `startColumn`, `columnCount` của `ShowtimeSeatMapDto`; không copy ma trận A–E hoặc mã ghế giả trong TSX. `InteractiveViewer`/cuộn ngang chỉ nằm trong vùng sơ đồ. |
| Bắp nước | Chip phân loại, card ảnh/tên/giá/quantity, footer tổng và Bỏ qua | Dùng catalog mock hiện tại; route Back quay về Vé & Ghế và giữ hold/cart. |
| Thanh toán | Snapshot theo từng loại vé và ghế, F&B, tổng, footer cố định | Chỉ VNPay mock; Voucher vẫn preview/off; lấy quote và booking snapshot, không tự tính tổng khác backend. |
| Vé điện tử | Summary đẹp, nhóm ghế theo loại vé, booking code/QR | Chỉ mở khi booking `PAID`; QR hiện là minh họa chưa quét được, cần ghi rõ trong UI nếu tiếp tục dùng. |

Tạo shared booking progress/header/action-bar **nếu** các màn dùng chung được; dùng `SafeArea`, `Scaffold` và vùng cuộn Flutter thay cho CSS `100dvh`/`env(safe-area-inset-bottom)` trong prompt React. Bottom navigation chỉ ở năm tab chính; CTA booking không bị che ở 320/360/375/390/430 px hoặc text scale lớn.

## 6. Thứ tự triển khai và gate

| Chặng | Công việc | Gate trước khi sang chặng tiếp |
| --- | --- | --- |
| V2.1 — Navigation | Sửa double tap; chọn suất + CTA rõ; route bắp nước Back về ghế; PopScope/hold guard; progress 4 bước | Một nhấn hợp lệ đi tới bắp nước; Back trên UI và hệ thống đều về đúng suất/ghế; không tạo hold trùng. |
| V2.2 — Contract/mock | Thêm assignment model; chuẩn hóa giới hạn 8; map request `seatId + ticketType + viewerAge`; sửa mock quote/booking để không mặc định Adult; đồng bộ tickets ở update/checkout | Quote, booking tickets và seat map cùng một mapping; kiểm tra giá/tuổi, ghế đôi, conflict, expiry bằng unit test. |
| V2.3 — Vé & Ghế UI | Ticket counter/active/assignment, xác nhận khi giảm, grouped summary, seat map theo metadata, sticky footer và semantic labels | 1/3 vé chạy trong demo; test 8 vé bằng fixture đủ chỗ; 0 vé/thiếu ghế/ghế trùng/ghế unavailable bị chặn; 320–430 px không tràn. |
| V2.4 — Downstream | Back/re-hold an toàn; giữ cart; quote và checkout theo assignment; ticket/order join ghế với booking tickets | Trở lại không mất mapping; đổi ghế có cancel/re-hold; checkout/ticket/order cùng phân loại và cùng tổng quote. |
| V2.5 — Regression/docs | Widget/E2E mock cho một loại, nhiều loại, chuyển loại, giảm quantity, ghế đôi, xung đột, hết hold, back, payment success/failure; cập nhật 3 tài liệu flow/CTA/mapping và readiness | `dart analyze`, toàn bộ `flutter test`, build Flutter và kiểm tra thủ công trên thiết bị/emulator đạt; không phát sinh route/dead CTA cũ. |

Các file dự kiến chạm: `features/showtime/presentation/pages/showtimes_page.dart`, `features/seat/application/booking_entry_session.dart`, `features/seat/presentation/pages/seat_selection_page.dart`, `features/booking/application/booking_completion_controller.dart`, các page bắp nước/checkout/ticket/order, mock catalog/booking repositories, `app_routes.dart`, `app_router.dart`, và test booking. Giữ route `/seat-selection/:showtimeId` để tương thích; đổi nhãn UI của route thành **Vé & Ghế**. Không có route chọn loại vé riêng trong Flutter hiện tại để xóa.

## 6.1. Kết quả triển khai V2

| Chặng | Trạng thái | Kết quả chính |
| --- | --- | --- |
| V2.1 | ✅ Hoàn thành | Chọn suất trước khi nhấn CTA; một lần nhấn giữ ghế và sang Bắp nước; Back UI/hệ thống quay về đúng suất; progress 4 bước. |
| V2.2 | ✅ Hoàn thành mock | `seatId → ticketType` là nguồn chọn ghế; giới hạn 8; request gửi `viewerAge` mock hợp lệ; quote/hold/update/checkout giữ đúng mapping và giá theo ma trận suất chiếu. |
| V2.3 | ✅ Hoàn thành | Counter ba loại vé, loại active, xác nhận giảm vé đã gán, sơ đồ dùng `displayColumn`, màu theo loại vé, row label hai bên và summary theo nhóm. |
| V2.4 | ✅ Hoàn thành mock | Cart được giữ khi quay lại; muốn sửa hold phải xác nhận hủy hold cũ; checkout, vé điện tử và Đơn của tôi đọc mapping từ `booking.tickets`. |
| V2.5 | ✅ Tự động hóa; ⏳ manual QA | Analyzer sạch; test có one-tap, Back, max 8, mixed tickets, conflict, expiry và payment. Build/test và QA màn 320–430 px được ghi nhận ở cuối tài liệu sau mỗi lần chạy. |

Giới hạn có chủ đích: bản mock dùng tuổi đại diện `Adult=30`, `Student=20`, `Child=10`; form nhập tuổi/chính sách kiểm tra giấy tờ chỉ được mở khi product/backend chốt các điểm ở mục 7. QR hiện vẫn là minh họa mock. Việc kiểm thử thủ công trên thiết bị thật không được suy ra từ test tự động.

## 7. Những điểm cần backend/product chốt trước khi nối API thật

1. Giới hạn 8 vé có áp dụng phía server không; hiện chỉ là giới hạn UI V2.
2. Nguồn chuẩn cho `seatId → ticketType`: sửa `BookingSeat.ticketType` theo quote hoặc tuyên bố `BookingTicketResponse` là nguồn duy nhất; đồng thời bảo đảm ticket mapping không mất khi update/checkout.
3. Chính sách `viewerAge` theo từng vé, vé Adult cho người trên 59 tuổi, điều kiện Student/Child và kiểm tra phim T13/T16/T18.
4. Ghế đôi là hai physical seat IDs hay một đơn vị bán, và quy tắc chọn cặp/giá trong quote.
5. Giá dùng breakdown nào cho UI khi giá suất đã gồm phụ thu weekend/holiday/late-night; quote có cung cấp phần tách riêng đáng tin cậy hay chỉ tổng.
6. Quy trình sửa ghế đang hold: tiếp tục dùng cancel + hold mới hay bổ sung API đổi seat IDs nguyên tử.

Plan này không tự bật voucher, CineWallet hay cổng thanh toán trong prototype. Khi code V2 xong, cập nhật trạng thái thực hiện ở đây và sửa các mô tả R4/R5 cũ trong `CINEPREMIER_MOBILE_UI_FLOWS.md`, `BACKEND_ALIGNED_MOCK_UI_PLAN.md`, `MOBILE_CTA_ROUTE_REGISTRY.md` và `Flutter_UI_Feature_Mapping.md` cho nhất quán.

## 8. Kết quả kiểm chứng gần nhất

- `dart analyze lib test`: **No issues found**.
- `flutter test --no-pub`: **30/30 test pass**, gồm kiểm tra không overflow ở 320 px và 430 px trên đường vào Vé & Ghế.
- `flutter build apk --debug --no-pub`: thành công; artifact tại `build/app/outputs/flutter-apk/app-debug.apk`.
- Chưa ghi nhận QA thủ công trên thiết bị/emulator; cần kiểm tra thao tác và overflow thực tế ở 320/360/390/430 px trước khi coi visual V2 là sign-off cuối.
