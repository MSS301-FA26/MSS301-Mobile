# CINEPREMIER Mobile — Backend-aligned Mock UI Plan

> Phiên bản: 1.0  
> Ngày đối chiếu contract: 2026-09-25  
> Phạm vi: `Mobile/MSS301-Mobile` đối chiếu với `BE/MSS301-Backend/cinema-services`  
> Trạng thái: kế hoạch triển khai; chưa cho phép kết nối API thật

## 1. Mục tiêu

Mục tiêu của giai đoạn này là làm cho code Flutter có thể ánh xạ trực tiếp sang contract backend hiện tại nhưng vẫn chạy hoàn toàn bằng mock data. Sau giai đoạn này, nhóm có thể đánh giá và điều chỉnh toàn bộ UI/UX trước, rồi thay từng mock repository bằng remote repository mà không phải viết lại presentation flow.

Kết quả cần đạt:

- model, enum, ID, tiền, ngày giờ và trạng thái của Flutter tương thích với request/response Java hiện tại;
- màn hình chỉ phụ thuộc repository interface và state/notifier, không đọc trực tiếp danh sách mock toàn cục;
- mock data mô phỏng được happy path và các lỗi nghiệp vụ quan trọng;
- UI vẫn chạy offline, không cần khởi động bất kỳ service backend nào;
- các chức năng chưa có API backend được nhận diện rõ, không giả vờ là đã tích hợp được;
- visual hiện tại được giữ ổn định trong lúc thay lớp dữ liệu, trừ các lỗi navigation/state bắt buộc phải sửa để đánh giá UI.

## 2. Phạm vi và điều không làm

### 2.1. Trong phạm vi

1. Đọc contract từ controller, request/response DTO, enum và business state hiện có trong backend.
2. Tạo Dart DTO/model, mapper, repository interface và mock repository tương ứng.
3. Refactor các màn đang có sang dữ liệu từ Riverpod/repository mock.
4. Bổ sung mock flow cho movie detail, lịch chiếu, ghế, booking, payment result, vé, account, wallet và loyalty theo mức cần thiết để review UI.
5. Chuẩn hóa navigation, loading, empty, error, disabled và timeout state.
6. Viết test cho mapper, state machine và các navigation path chính.

### 2.2. Ngoài phạm vi

- Không thêm `dio`, `http`, Retrofit hoặc API client.
- Không gọi endpoint thật, không dùng JWT thật và không lưu credential thật.
- Không mở WebView/deep link VNPay thật.
- Không sửa backend trong task triển khai mobile này.
- Không tạo schema riêng khác với backend để “làm UI cho nhanh”.
- Không refactor đồng loạt tên folder/route hiện tại chỉ vì khác tên chuẩn trong tài liệu.
- Không tạo sẵn các lớp `remote`, interceptor hoặc use case rỗng chưa được dùng.

## 3. Nguồn sự thật và nguyên tắc mapping

Thứ tự ưu tiên khi có khác biệt:

1. Request/response DTO và enum public trong backend là nguồn sự thật cho contract tích hợp.
2. Business rule đang chạy trong service backend là nguồn sự thật tạm thời cho state transition và timeout.
3. `CINEPREMIER_MOBILE_UI_FLOWS.md` là nguồn sự thật cho hành vi UI và navigation.
4. `Flutter_UI_Feature_Mapping.md` là nguồn sự thật cho phạm vi màn hình/trạng thái implementation.
5. AI Studio/prototype là nguồn tham chiếu visual, không phải API contract.

Flutter không ánh xạ trực tiếp JPA entity vào widget. Dart DTO bám public request/response; mapper chuyển DTO sang presentation model. Chỉ dùng entity để hiểu quan hệ và trạng thái khi public DTO chưa diễn đạt đủ.

Nếu backend thay đổi contract, phải cập nhật theo thứ tự: fixture JSON → DTO/enum → mapper → repository test → notifier/widget test → tài liệu flow nếu hành vi thay đổi.

## 4. Hiện trạng đối chiếu

### 4.1. Backend có thể dùng để mapping

| Domain | Contract hiện có | Mức sẵn sàng cho mock UI |
| --- | --- | --- |
| Identity | register, login, Google login, refresh, logout, OTP, reset password | Đủ để dựng auth state và form mock |
| Profile | xem/sửa hồ sơ, đổi mật khẩu, avatar | Đủ để dựng account/profile mock |
| Catalog | movie, cinema, room, showtime, seat map | Đủ cho discover, detail, lịch chiếu và chọn ghế |
| Catalog food | item, combo, checkout quote | Đủ cho bắp nước kèm booking ở mức catalog/quote |
| Booking | hold ghế, cập nhật item, checkout, danh sách/chi tiết, hủy khi còn hiệu lực | Đủ cho booking flow mock |
| Payment | tạo VNPay/mock payment, tra cứu payment theo booking/id | Đủ để mô phỏng payment state; chưa mở VNPay thật |
| Wallet | số dư, giao dịch, yêu cầu rút tiền | Đủ cho wallet mock; không hiển thị nạp tiền |
| Loyalty | số dư, config, redeem | Đủ cho màn điểm; dùng điểm trong checkout còn cần backend thống nhất |
| Recommendation | endpoint recommendation placeholder | Chưa đủ cho PopBot chat |
| Food order độc lập | Có entity nhưng thiếu public customer flow hoàn chỉnh | UI preview/feature flag |
| Refund/đổi vé | Có field/status liên quan nhưng thiếu public request flow | UI preview/feature flag |
| Voucher, VIP, favorite, review, notification | Chưa có module/contract public đầy đủ | UI preview/feature flag |

### 4.2. Flutter hiện tại

- Code mới có lớp `presentation` và dữ liệu mock trực tiếp cho Home, Discover, Movie, Showtime, Orders và Account.
- Route đang hoạt động là `/home`, `/discover`, `/showtimes`, `/orders`, `/account`, `/movie/:id`.
- Movie, showtime slot và order đang dùng ID dạng `String`; date/time, price và status còn thiên về chuỗi hiển thị.
- Showtime đang giữ lựa chọn cục bộ và có dữ liệu ngày/suất chọn sẵn, chưa tạo booking hold hoặc điều hướng ghế.
- Order status mới biểu diễn được nhóm đơn giản như upcoming/completed, chưa ánh xạ đủ `BookingStatus`.
- Account đang gộp profile, membership, points và wallet vào một mock presentation object.
- Một số quick action/menu chỉ phản hồi bằng snackbar, nên chưa đủ để xem là flow UI hoàn chỉnh.
- `Flutter_UI_Feature_Mapping.md` vẫn mô tả snapshot Phase 1/2 cũ. Khi bắt đầu M1 phải cập nhật trạng thái màn hình theo code thực tế, nhưng không được ghi các màn hiện có là backend-integrated.

## 5. Kiến trúc Flutter mục tiêu của giai đoạn mock

### 5.1. Luồng phụ thuộc

```text
Page/Widget
    ↓ watch/read
Notifier / AsyncNotifier
    ↓ depends on
Repository interface
    ↓ implemented by
Mock repository
    ↓ reads/writes
Typed fixture + in-memory state + AppClock
```

Widget không import file fixture và không tự parse enum/string. Mock repository phải trả cùng kiểu dữ liệu mà remote repository tương lai sẽ trả.

### 5.2. Cấu trúc đề xuất

Chỉ tạo folder khi có class thực sự được dùng:

```text
lib/
  core/
    contracts/
      api_response.dart
      page_response.dart
    time/
      app_clock.dart
    money/
      vnd_money.dart
  features/
    movie/
      data/models/
      data/mappers/
      data/repositories/
      data/mock/
      presentation/
    showtime/
      data/models/
      data/mappers/
      data/repositories/
      data/mock/
      presentation/
    orders/
      data/models/
      data/mappers/
      data/repositories/
      data/mock/
      presentation/
    account/
      data/models/
      data/mappers/
      data/repositories/
      data/mock/
      presentation/
```

Đây là cấu trúc chuyển tiếp cho các feature **đang tồn tại**, không phải yêu cầu tạo trước toàn bộ folder. `orders/data` chứa contract booking phục vụ presentation hiện tại; `account/data` có các model/repository profile, wallet và loyalty tách biệt. Khi một màn mới như seat, food hoặc payment thật sự được triển khai, tạo feature chuẩn tương ứng tại thời điểm đó.

Fixture nằm cùng feature sở hữu contract. Nếu cần đồng bộ ID giữa nhiều feature, dùng một `DemoScenario` nhỏ chỉ khai báo seed/ID dùng chung; không tạo một kho map động toàn cục. Cách này tuân theo feature-first và quy tắc không tạo layer rỗng trong `MSS301_Mobile_Codex_Prompt_SOLID.md`.

### 5.3. Repository tối thiểu

- `AuthRepository`: session mock, login, register, OTP, reset password, logout.
- `CatalogRepository`: movies, movie detail, showtimes, showtime detail, seat map, food items, combos, checkout quote.
- `BookingRepository`: hold, update items, checkout, list, detail, cancel.
- `PaymentRepository`: create mock payment, get by booking, get by ID, simulate result.
- `ProfileRepository`: get/update profile, change password, update avatar metadata.
- `WalletRepository`: balance, transactions, withdrawal request/list.
- `LoyaltyRepository`: balance, config, history mock và redeem preview.

Provider chỉ bind mock implementation trong giai đoạn này. Việc bind remote implementation là task tích hợp API sau.

## 6. Quy ước kiểu dữ liệu

### 6.1. ID

- ID backend kiểu `Long` được biểu diễn bằng Dart `int`.
- Không dùng slug hoặc title làm ID nghiệp vụ.
- Chỉ chuyển ID sang chuỗi tại route parameter, serialization hoặc `ValueKey`.
- Các ID mock phải ổn định giữa các fixture liên quan.

### 6.2. Tiền

- Tiền VND trong presentation/state dùng số nguyên, không tính bằng `double`.
- Parser DTO chấp nhận JSON number nhưng phải chuẩn hóa về giá trị nguyên trước khi tính tổng.
- Format `90.000đ` nằm trong formatter dùng chung; widget không tự nối chuỗi giá.
- Quote từ repository là nguồn tổng tiền; UI có thể tính preview nhưng phải thay bằng quote khi bước checkout trả kết quả.

### 6.3. Ngày giờ

- `LocalDate` ánh xạ sang ngày theo local timezone; không tự chuyển UTC.
- `LocalDateTime` ánh xạ sang `DateTime` local theo contract hiện tại.
- Tất cả fixture “hôm nay/ngày mai” sinh từ `AppClock`; test dùng `FakeAppClock` cố định.
- Không hard-code ngày `14/09` hoặc tự chọn sẵn một suất khi mở màn hình.

### 6.4. Enum

- Giá trị serialize phải trùng chính xác với backend.
- Mỗi enum Dart có parser tập trung và fallback `unknown` để backend thêm giá trị không làm crash app.
- Nhãn tiếng Việt và màu UI nằm trong extension/presentation mapper, không thay đổi giá trị contract.

## 7. Contract mapping bắt buộc

### 7.1. Catalog

| Contract | Trường/trạng thái chính cần giữ |
| --- | --- |
| `MovieResponse` | `id`, title, description, trailer/poster/avatar URL, duration, release/end date, language/subtitle, age rating, director, actors/cast, genres, status, timestamps |
| `MovieStatus` | `UPCOMING`, `NOW_SHOWING`, `ENDED`, `INACTIVE` |
| `ShowtimeResponse` | showtime/movie/cinema/room ID, snapshot name/title, start/end, các mức giá, surcharge, status, cancellation fields |
| `ShowtimeStatus` | `SCHEDULED`, `OPEN`, `CANCELLED`, `COMPLETED` |
| Seat map | showtime, row/column count, danh sách seat |
| Seat | seat/row ID, row label, order, seat number, display/start column, type, physical status, runtime status, hold expiry, unit price |
| `SeatStatus` | `AVAILABLE`, `UNAVAILABLE`, `MAINTENANCE` |
| Catalog `SeatType` | `NORMAL`, `STANDARD`, `VIP`, `COUPLE` |
| Ticket type | `ADULT`, `CHILD`, `STUDENT`; booking còn có `SENIOR` |
| `FoodItemStatus` | `ACTIVE`, `LOW_STOCK`, `INACTIVE`, `OUT_OF_STOCK` |

Mapper seat phải chuẩn hóa catalog `NORMAL` về presentation `STANDARD` nhưng vẫn giữ raw contract value khi cần debug. Runtime seat status quyết định held/booked; không suy ra chỉ từ `SeatStatus` vật lý.

### 7.2. Booking

`HoldSeatsRequest` cần biểu diễn được:

- `showtimeId`;
- `seatIds`;
- `holiday`;
- `tickets`;
- `foods`;
- `loyaltyPointsToRedeem`.

`BookingResponse` cần giữ:

- ID/code và các snapshot phim/rạp/phòng/suất;
- subtotal, discount, điểm dùng và total;
- `holdExpiresAt`, paid/check-in/cancel/refund timestamps;
- booking QR;
- danh sách seat, ticket và food;
- `createdAt`.

Enum chính xác:

```text
BookingStatus: HOLDING, PENDING_PAYMENT, PAID, USED, CANCELLED, EXPIRED, REFUNDED
BookingSeatStatus: HOLDING, BOOKED, CHECKED_IN, RELEASED
```

State `DRAFT`, `SELECTING_SEATS`, `PAYMENT_FAILED` là state UI/payment, không được thêm vào `BookingStatus`.

### 7.3. Payment

```text
PaymentStatus: PENDING, SUCCESS, FAILED, REFUNDED
PaymentProvider: VNPAY, MOCK, CINEWALLET
```

`PaymentResponse` giữ payment ID, booking/food-order/user ID, provider, transaction ID, amount, status, payment URL/account label, paid/refund/created timestamp.

Mock parser vẫn hiểu đủ enum provider để tương thích backend, nhưng UI chỉ hiển thị VNPay. `MOCK` là cơ chế test nội bộ; `CINEWALLET` không được hiển thị thành phương thức thanh toán vì trái với product rule hiện tại.

### 7.4. Profile, wallet và loyalty

- Profile: ID, email, full name, phone, avatar URL, birth year, status, verified flags, roles và timestamps.
- Wallet: ID, balance, created time.
- Wallet transaction type: `REFUND_CREDIT`, `BOOKING_DEBIT`, `TOP_UP`, `WITHDRAWAL_HOLD`, `WITHDRAWAL_PAID`, `WITHDRAWAL_REFUND`.
- Withdrawal status: `PENDING`, `PAID`, `REJECTED`.
- Loyalty: user ID, email, points, total points, status và config.

DTO có thể parse `TOP_UP` để tương thích dữ liệu backend, nhưng UI không cung cấp CTA nạp tiền.

### 7.5. Trường chỉ phục vụ presentation

Các trường prototype như rating, rating count, tagline, hero banner, format badge hoặc editorial label không được nhét vào `MovieDto` nếu backend không trả chúng. Tách thành `MoviePresentationMetadata` hoặc view model enrichment và join theo `movieId` trong mock mapper.

## 8. State machine mock

### 8.1. Booking và giữ ghế

```text
UI local: BROWSING → SELECTING_SHOWTIME → SELECTING_SEATS
Booking:  HOLDING → PENDING_PAYMENT → PAID → USED
             │              │          └→ REFUNDED
             ├──────────────┴───────────→ CANCELLED
             └──────────────┴───────────→ EXPIRED
```

- Chọn ghế trên màn hình chưa tạo hold và chưa chạy timer.
- CTA Tiếp tục gọi mock `hold`; khi trả booking `HOLDING`, timer 3 phút bắt đầu từ `holdExpiresAt`.
- Mock repository phải phát conflict nếu seat đã held/booked trong scenario.
- Hết hạn làm booking thành `EXPIRED`, seat thành available lại và chặn checkout cũ.
- Chỉ `HOLDING`/`PENDING_PAYMENT` mới được cancel theo contract hiện tại.

### 8.2. Payment

```text
PENDING → SUCCESS / FAILED
SUCCESS → REFUNDED
```

Sau payment `SUCCESS`, mock chèn một độ trễ có kiểm soát trước khi booking thành `PAID`, để UI buộc hiển thị `processing` và kiểm tra lại booking. QR chỉ xuất hiện khi booking đã `PAID`.

## 9. Kịch bản mock chuẩn

Một `DemoScenario` dùng xuyên suốt các feature:

- cinema ID và room ID kiểu `int`, rạp CineAI Central, Phòng C;
- movie ID `1`, phim Inception;
- showtime ID ổn định, bắt đầu 20:30 theo ngày sinh từ `AppClock`;
- seat ID ổn định cho C4/C5, có thêm ghế held, booked và maintenance để review legend;
- giá vé 90.000đ/người, combo 89.000đ, tổng trước ưu đãi 269.000đ;
- profile, loyalty, wallet và booking cùng dùng một user ID;
- có fixture booking cho từng status chính và payment cho `PENDING`, `SUCCESS`, `FAILED`;
- có scenario network-like delay, empty, domain error, seat conflict, quote changed và timeout, dù không có network thật.

Mock repository in-memory được phép mutate để demo flow. Mỗi test phải tạo store mới để không phụ thuộc thứ tự chạy.

## 10. Điều chỉnh UI/UX bắt buộc trong giai đoạn này

1. Hero đầu trang dùng constraint/aspect ratio responsive, không dùng chiều cao/vị trí tuyệt đối gây crop hoặc overflow.
2. Tap vùng nội dung phim mở chi tiết; CTA **Đặt vé** mở lịch chiếu đã lọc theo phim.
3. Tap một suất hợp lệ đi thẳng sang chọn ghế; không cần thêm nút xác nhận suất.
4. Không preselect ngày, suất hoặc ghế nếu người dùng chưa thao tác.
5. Các quick action Bắp nước, PopBot, VIP, CinePoints và các menu Account phải có route thật trong mock UI, hoặc disabled/feature-flag rõ ràng; không dùng snackbar “sẽ có sau”.
6. Chỉ bắt đầu timer sau khi hold thành công; sticky action bar không che safe area.
7. Order card dùng `BookingStatus` thật thay vì chỉ `upcoming/completed`.
8. Booking QR là mã chính; trạng thái payment thành công một mình chưa đủ để hiện vé.
9. Loading, empty, error và retry được mô phỏng tại repository/notifier để review trực tiếp trên UI.

## 11. Route và feature alias trong code hiện tại

| Đích chuẩn | Alias hiện tại | Quyết định |
| --- | --- | --- |
| `/search` | `/discover` | Giữ trong giai đoạn mock mapping |
| `/showtime` | `/showtimes` | Giữ, không tạo root trùng |
| `/profile` | `/account` | Giữ trong giai đoạn mock mapping |
| `features/search` | `features/discover` | Không rename lúc thay data layer |
| `features/booking` | `features/orders` | Orders presentation đọc Booking model/repository |
| `features/profile` | `features/account` | Account compose profile, wallet, loyalty repositories |

Migration route/folder là task độc lập sau khi UI flow ổn định. Deep link tương lai phải chọn một canonical route duy nhất trước khi tích hợp thật.

## 12. Kế hoạch triển khai

### M0 — Contract foundation

1. Tạo `AppClock`, money formatter và response/page wrapper dùng chung.
2. Tạo enum parser có `unknown` và test cho toàn bộ enum đang dùng.
3. Tạo DTO + mapper cho movie, showtime, seat, booking, payment, profile, wallet, loyalty.
4. Tạo fixture JSON/object bám contract và `DemoScenario` liên kết ID.
5. Tạo repository interface và Riverpod binding cho mock implementation.

Điều kiện xong: fixture parse được, mapper test pass, không widget nào cần import fixture trực tiếp.

### M1 — Refactor màn hình hiện có, không đổi visual chủ đích

1. Home/Discover/Movie đọc `CatalogRepository`.
2. Showtimes dùng `DateTime`, `ShowtimeStatus`, ID kiểu `int` và không preselect.
3. Orders dùng `BookingResponse` mapping và đầy đủ status.
4. Account tách profile, wallet, loyalty data thay vì một object mock tổng hợp.
5. Sửa callback navigation: `onOpenDetails` và `onBook` là hai hành động riêng.
6. Giữ screenshot/golden baseline để phát hiện thay đổi visual ngoài ý muốn.

Điều kiện xong: toàn bộ UI hiện có chạy offline qua repository mock và không còn model String-ID cũ ở ranh giới data.

### M2 — Movie detail, lịch chiếu và chọn ghế

1. Hoàn thiện movie detail từ DTO + presentation metadata.
2. Lịch chiếu lọc theo movie/date và điều hướng bằng `showtimeId`.
3. Seat map hỗ trợ standard/VIP/couple, physical/runtime status và legend accessible.
4. Tạo booking draft local, hold mock, conflict, timer 3 phút, expire và cancel confirmation.

Điều kiện xong: Home/Detail → Showtimes → Seat selection → hold chạy được bằng mock và test fake clock.

### M3 — Concessions, checkout, payment result và vé QR

1. Food item/combo và quantity state từ catalog mock.
2. Checkout quote, snapshot, total và quote-changed state.
3. Payment `PENDING/SUCCESS/FAILED`, processing delay và retry.
4. Booking chuyển `PAID` mới mở ticket; QR dùng booking contract.
5. Order list/detail phản ánh booking vừa tạo.

Điều kiện xong: happy path và failure/expiry path chạy end-to-end không cần backend.

### M4 — Auth, profile, wallet và loyalty

1. Auth gate giữ pending action và resume đúng route.
2. Profile edit/validation với mock repository.
3. Wallet balance, transaction, withdrawal states; không có top-up CTA.
4. Loyalty balance/history/config; checkout redemption mặc định tắt.

Điều kiện xong: guest/logged-in state nhất quán và account menu không còn dead action cho feature đã bật.

### M5 — Flow chưa có contract đầy đủ

Chỉ dựng để review UI sau feature flag:

- food order độc lập;
- refund/đổi vé;
- voucher và VIP;
- favorite, review và notification;
- PopBot chat.

Mỗi flow phải dùng model/repository tạm riêng, có nhãn `provisional`, và không được trộn field giả vào DTO backend đã chuẩn hóa.

## 13. Feature flag đề xuất

| Flag | Mặc định | Lý do |
| --- | --- | --- |
| `enableIndependentFoodOrderPreview` | off | Chưa có public customer API hoàn chỉnh |
| `enableRefundPreview` | off | Chưa có request/process refund API |
| `enableVoucherPreview` | off | Chưa có voucher contract |
| `enableVipPreview` | off | Chưa có membership contract |
| `enableSocialMoviePreview` | off | Favorite/review/notification chưa có contract |
| `enablePopBotPreview` | off | Recommendation service chưa phải chat API |
| `enableLoyaltyCheckoutRedemption` | off | Booking và loyalty chưa thống nhất trừ điểm |

Build dành cho review nội bộ có thể bật từng flag. Release-like build phải giữ off cho đến khi có contract hoặc quyết định sản phẩm rõ ràng.

## 14. Test và tiêu chí nghiệm thu

### 14.1. Test bắt buộc

- DTO parse test bằng fixture có hình dạng giống JSON backend.
- Enum test cho mọi giá trị hiện tại và giá trị lạ → `unknown`.
- Mapper test cho money/date/status và `NORMAL` → `STANDARD`.
- Repository test cho filter, hold conflict, expiry, cancel, checkout và payment transition.
- Notifier test bằng fake clock cho timer 3 phút, payment processing và auth resume.
- Widget/navigation test cho Home → Detail, Đặt vé → Showtimes, slot → Seats, Checkout → Result → Ticket.
- Responsive test ở width 360, 390, 412 và text scale phổ biến.

### 14.2. Definition of Done

- App chạy và review được khi tất cả backend service đều tắt.
- Không phát sinh network request.
- Không còn magic string status rải trong widget.
- ID nghiệp vụ trong data/domain boundary là `int`.
- Không có ngày demo quá khứ được gắn nhãn “Hôm nay”.
- Không có CTA active dẫn đến snackbar placeholder.
- Booking, payment và seat state là ba state machine tách biệt.
- Fixture liên kết đúng movie → showtime → seat → booking → payment → ticket.
- Tất cả test liên quan pass và `flutter analyze` không có lỗi mới.
- `Flutter_UI_Feature_Mapping.md` được cập nhật khi trạng thái màn hình thực sự thay đổi.

## 15. Blocker phải xử lý trước khi tích hợp API thật

Các điểm dưới đây không chặn mock UI, nhưng chặn hoặc làm rủi ro cho remote integration:

1. Booking hold hiện là 3 phút trong khi VNPay URL có thời hạn 15 phút; cần quy tắc rõ cho payment đến sau khi ghế đã được release.
2. Payment success event hiện có thể chuyển booking sang `PAID` mà chưa kiểm tra đầy đủ trạng thái hết hạn/release.
3. Callback mặc định đang hướng đến web localhost; mobile cần deep link/app link và quy trình verify server-side.
4. Gateway và downstream cần thống nhất trust boundary cho `X-User-Id`/roles; mobile không được tự gửi identity header đáng tin cậy.
5. Booking và loyalty chưa thống nhất việc kiểm tra số dư, reserve/deduct/rollback điểm.
6. `CINEWALLET` tồn tại trong payment provider enum nhưng product rule không cho dùng ví thanh toán vé.
7. Food order status vẫn là chuỗi và thiếu public customer lifecycle API.
8. Refund, voucher, membership, favorite, review, notification và PopBot chat cần public contract trước khi bỏ feature flag.

## 16. Chuyển sang API thật sau này

Thứ tự chuyển đổi đề xuất theo vertical slice, không thay toàn bộ cùng lúc:

1. Catalog read-only: movies → detail → showtimes → seat map.
2. Identity/profile và auth gate.
3. Booking hold/update/checkout.
4. Payment create/callback verification/result polling.
5. Orders/ticket QR.
6. Wallet/loyalty.
7. Các module mới khi backend có contract.

Mỗi slice thêm remote repository và contract test, sau đó đổi Riverpod binding theo environment. Mock repository vẫn được giữ cho widget test, demo offline và phát triển UI.

---

Tài liệu này quyết định cách tổ chức giai đoạn mock mapping. Hành vi người dùng chi tiết tiếp tục theo `CINEPREMIER_MOBILE_UI_FLOWS.md`; trạng thái implementation của từng màn hình tiếp tục theo `Flutter_UI_Feature_Mapping.md`.
