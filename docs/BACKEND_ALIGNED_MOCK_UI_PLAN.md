# CINEPREMIER Mobile — Backend-aligned Mock UI Plan

> Phiên bản: 1.4
> Ngày đối chiếu contract: 2026-09-25  
> Phạm vi: `Mobile/MSS301-Mobile` đối chiếu với `BE/MSS301-Backend/cinema-services`  
> Trạng thái: R0–R4 hoàn thành; chưa cho phép kết nối API thật

## 1. Mục tiêu

Mục tiêu của giai đoạn này là làm cho code Flutter có thể ánh xạ trực tiếp sang contract backend hiện tại nhưng vẫn chạy hoàn toàn bằng mock data. Sau giai đoạn này, nhóm có thể đánh giá và điều chỉnh toàn bộ UI/UX trước, rồi thay từng mock repository bằng remote repository mà không phải viết lại presentation flow.

Mọi implementation trong kế hoạch này phải tuân theo tám quyết định F1–F8 đã chốt tại mục 1.3 của `CINEPREMIER_MOBILE_UI_FLOWS.md`. Khi plan và flow khác nhau về hành vi người dùng, flow specification được ưu tiên và plan phải được cập nhật theo.

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

## 12. Kế hoạch triển khai tổng thể

### 12.1. Cách đọc F và M

- `F1–F8` là các quyết định hành vi và tiêu chí UI trong flow specification. Chúng không phải tám phase code tuần tự.
- `M0–M5` là các phase implementation kỹ thuật của Backend-aligned Mock UI.
- Một phase M có thể hiện thực nhiều quyết định F; một quyết định F có thể kéo dài qua nhiều phase M.
- `F8` là yêu cầu chất lượng xuyên suốt, không để đến cuối mới bổ sung loading/error/test.

### 12.2. Roadmap bắt buộc từ đầu đến cuối

| Thứ tự | Work package | F/M liên quan | Đầu ra chính | Gate hoàn thành |
| --- | --- | --- | --- | --- |
| R0 ✅ | Baseline tài liệu | F1–F8 | Flow, contract plan, core/preview scope và feature flag đã chốt | Hai tài liệu không mâu thuẫn |
| R1 ✅ | Navigation contract | F1A, F7 | Danh mục CTA/route/parameter; tách active, disabled, hidden và preview | Không còn CTA active dẫn tới snackbar placeholder trên các màn hiện có |
| R2 ✅ | Contract foundation | M0, F6 | Primitive, DTO, enum, mapper, fixture, repository interface/mock và provider binding | Analyzer sạch; contract/mapper/repository test pass; app không gọi network |
| R3 ✅ | Existing UI migration | M1, F1B, F3, F8 | Home, Discover, Movie, Showtimes, Orders, Account đọc repository mock | Analyzer sạch; responsive/navigation/repository-state test pass; ID/date/money/status không còn dùng model cũ tại data boundary |
| R4 ✅ | Booking entry | M2, F2, F4, F5, F6, F8 | Movie detail → showtime → auth gate → seat → hold | Analyzer sạch; hold/conflict/expire/back/logo guard chạy bằng fake clock; timer chỉ bắt đầu khi `HOLDING` |
| R5 | Booking completion | M3, F2, F6, F8 | Food kèm vé → checkout → payment result → verify booking → ticket/order | Happy path và failure/expiry/retry chạy end-to-end offline; QR chỉ khi `PAID` |
| R6 | Account completion | M4, F5, F8 | Auth đầy đủ, profile, wallet, loyalty và guest/resume state | Không còn dead action trong feature đã bật; wallet/points tuân contract và product rule |
| R7 | Preview flows | M5, F7, F8 | Các màn chưa có contract đầy đủ, cô lập sau feature flag | Release-like build tắt toàn bộ preview; preview build không làm bẩn DTO chuẩn |
| R8 | Stabilization và handoff | F1–F8 | Regression, accessibility, responsive, docs và API-readiness report | Definition of Done mục 14.2 đạt; mock UI được coi là hoàn thành |

Không chuyển sang work package tiếp theo khi gate của package trước chưa đạt, ngoại trừ việc chuẩn bị visual độc lập không thay đổi contract hoặc navigation.

### 12.3. R1 — F1A Navigation contract

Registry thực thi của R1 được quản lý tại `MOBILE_CTA_ROUTE_REGISTRY.md`.

> Trạng thái: **Hoàn thành**. Analyzer sạch và navigation contract được giữ bởi regression test.

1. Kiểm kê mọi CTA, card tap, icon action, menu item và bottom-nav item đang hiển thị.
2. Với mỗi action, ghi rõ route đích, path/query parameter, yêu cầu đăng nhập và feature flag.
3. Phân loại action thành `core active`, `preview active`, `disabled with reason`, `hidden` hoặc `external intent`.
4. Tách callback `onOpenDetails`, `onBook`, `onPlayTrailer` và các callback có ý nghĩa khác nhau.
5. Các route đích chưa tồn tại và thuộc F7 phải hidden/disabled; không tạo placeholder chỉ để hiện snackbar.
6. Thêm navigation test cho các route hiện có và test xác nhận preview action bị ẩn/tắt trong release-like configuration.

Điều kiện xong: mọi control đang hiển thị đều có hành vi xác định; chưa bắt buộc hoàn thiện toàn bộ màn hình đích.

### 12.4. R2 — M0 Contract foundation

> Trạng thái: **Hoàn thành**. M0A–M0C đã được triển khai và được giữ bởi contract/repository test.

Thực hiện theo lát cắt để tránh một pull request quá lớn:

#### M0A — Shared contract primitives

1. Tạo `AppClock`, `FakeAppClock`, money value/formatter và response/page wrapper thực sự được fixture sử dụng.
2. Chốt quy tắc ID `int`, local date/time và VND integer.
3. Tạo enum parser có `unknown`; không parse enum trong widget.
4. Tạo `DemoScenario` giữ ID/clock seed dùng chung, không chứa UI state.

#### M0B — Catalog và booking contracts

1. Tạo DTO, mapper và fixture cho movie, showtime, seat map, food catalog và checkout quote.
2. Tạo DTO, mapper và fixture cho hold request, booking response, booking seat/ticket/food.
3. Tạo `CatalogRepository` và `BookingRepository` cùng mock implementation in-memory.
4. Test `NORMAL → STANDARD`, physical/runtime seat status, quote và booking status.

#### M0C — Payment và account contracts

1. Tạo DTO, mapper và fixture cho payment, profile, wallet, withdrawal và loyalty.
2. Tạo repository interface/mock tương ứng và Riverpod binding.
3. Mô phỏng payment delay, wallet/loyalty state nhưng chưa dựng toàn bộ UI M4.
4. Không tạo contract giả cho voucher, VIP, refund request hoặc PopBot.

Điều kiện xong: fixture parse được, mapper/repository test pass, không widget nào import fixture trực tiếp và không phát sinh network request.

Kết quả thực thi:

- shared primitive nằm tại `lib/core/contracts`, `lib/core/money`, `lib/core/time` và `lib/core/demo`;
- catalog/showtime, booking, payment và account có DTO bám public response/request hiện tại, enum parser có `unknown`, repository interface và mock in-memory;
- Riverpod provider binding có cho từng nhóm repository; presentation hiện tại đã được chuyển sang dùng qua R3;
- mock scenario dùng ID `int`, VND integer, thời gian tương đối qua `AppClock`, hold 3 phút, xung đột/nhả ghế và payment/booking state tách biệt;
- `test/backend_aligned_contract_test.dart` khóa contract parsing, seat mapping, quote 269.000đ, lifecycle booking/payment, expiry và account state;
- không thêm HTTP client, remote data source hoặc network request.

### 12.5. R3 — M1 Existing UI migration

> Trạng thái: **Hoàn thành**. Mốc R3 có 16 test pass; hiện R4 cũng đã hoàn thành và R5 là work package kế tiếp.

1. Home/Discover/Movie đọc `CatalogRepository` và giữ presentation metadata riêng.
2. Showtimes dùng `DateTime`, `ShowtimeStatus`, ID kiểu `int` và không preselect.
3. Orders dùng booking mapper và đầy đủ `BookingStatus`.
4. Account compose profile, wallet và loyalty repositories thay vì một mock object tổng hợp.
5. Hoàn thiện F1B: action core truyền đúng ID; action preview tuân feature flag.
6. Sửa hero responsive, tách card/booking callback và bổ sung loading/empty/error cơ bản.
7. Giữ screenshot/golden baseline để phát hiện thay đổi visual ngoài ý muốn.

Điều kiện xong: toàn bộ UI hiện có chạy offline qua repository mock, không còn String ID/date/price/status presentation cũ tại data boundary và không có regression navigation.

Kết quả thực thi:

- Home, Discover và Movie Detail đọc `CatalogRepository` qua `moviesProvider`/`movieProvider`; metadata rating, tagline, banner và format vẫn nằm riêng ở presentation mapper;
- Showtimes đọc catalog repository, dùng `int` ID, `DateTime`, `VndMoney`, `ShowtimeStatus`, ngày sinh theo `AppClock` và không preselect ngày/suất;
- Orders đọc `BookingRepository`, ánh xạ đủ `BookingStatus`, snapshot phim/rạp/phòng/ghế/F&B và giữ mock booking seed trong repository thay vì presentation provider;
- Account tổng hợp `ProfileRepository`, `WalletRepository` và `LoyaltyRepository`; presentation không còn import object profile tĩnh;
- route `movieId` được parse tại router boundary và dùng `int` trong ứng dụng;
- loading, empty, error/retry dùng chung qua `RepositoryStatePane`; Discover, Showtimes và Orders có empty state theo ngữ cảnh;
- các provider mock presentation cũ đã được loại bỏ; widget không import fixture trực tiếp;
- responsive test tại 360/390/412 px, navigation regression, repository-backed Account/Orders và error/retry đều pass;
- không thêm HTTP client, remote data source hoặc API call thật.

### 12.6. R4 — M2 Booking entry

> Trạng thái: **Hoàn thành**. Analyzer sạch và toàn bộ 22 test pass; R5 là work package kế tiếp.

1. Hoàn thiện movie detail từ DTO + presentation metadata.
2. Lịch chiếu lọc theo movie/date và điều hướng bằng `showtimeId`.
3. Thêm session mock tối thiểu và auth gate giữ pending action; form auth đầy đủ thuộc M4.
4. Seat map hỗ trợ standard/VIP/couple, physical/runtime status và legend accessible.
5. Tạo booking draft local, hold mock, conflict, timer 3 phút, expire và cancel confirmation.
6. Test back/resume, sold/past slot, seat conflict, couple seat và fake-clock expiry.

Điều kiện xong: Home/Detail → Showtimes → Auth gate → Seat selection → Hold chạy được bằng mock, không mất context và không tự chọn dữ liệu cho người dùng.

Kết quả thực thi:

- Movie Detail hiển thị nội dung, đạo diễn, diễn viên, ngôn ngữ/phụ đề và trailer từ DTO + presentation metadata;
- suất hợp lệ điều hướng bằng `showtimeId`; suất `COMPLETED`/không mở bán bị disabled và không có preselect ngày/suất;
- session mock tối thiểu giữ pending booking action, đăng nhập mock và resume đúng `showtimeId`; auth form đầy đủ vẫn thuộc R6/M4;
- `/seat-selection/:showtimeId` hiển thị tóm tắt suất, màn chiếu, sơ đồ zoom/pan, ghế thường/VIP/đôi, held/booked/maintenance và legend có semantic label;
- lựa chọn ghế là local state, giới hạn 6 ghế và ghế đôi chọn/bỏ theo cặp;
- nhấn **Tiếp tục** mới gọi hold; timer 3 phút chỉ xuất hiện sau booking `HOLDING`;
- conflict đánh dấu ghế vừa tranh chấp là unavailable; fake clock expiry giải phóng ghế và cho chọn lại/về lịch chiếu;
- back khi có lựa chọn/hold và logo khi có booking draft đều có confirmation; nút giữ người dùng ở lại là primary, hành động rời đi là secondary;
- mock booking conflict được khóa theo `(showtimeId, seatId)`, tránh xung đột sai giữa hai suất dùng cùng physical seat;
- `test/booking_entry_test.dart` khóa happy path, auth resume, couple seat, back confirmation, conflict, logo guard và expiry;
- R4 dừng sau hold; food, checkout, payment và ticket chưa được mở trước R5.

### 12.7. R5 — M3 Booking completion

1. Food item/combo và quantity state từ catalog mock; bước này được phép bỏ qua.
2. Checkout quote, snapshot, total, quote-changed và hold-expired state.
3. Payment `PENDING/SUCCESS/FAILED`, processing delay, unknown/cancelled presentation state và retry.
4. Sau payment `SUCCESS`, kiểm tra booking; chỉ booking `PAID` mới mở ticket.
5. Booking QR là mã chính; Order list/detail phản ánh booking vừa tạo.
6. Chạy E2E happy path, payment failure, payment success chờ booking, hold expiry và retry.

Điều kiện xong: core booking F2 hoạt động end-to-end khi backend tắt và các state machine F6 không bị trộn.

### 12.8. R6 — M4 Account completion

1. Hoàn thiện login, register, OTP, reset password, logout và session state bằng mock.
2. Pending action resume đúng route/ID hoặc về màn an toàn nếu context hết hạn.
3. Profile edit/validation, password và avatar metadata.
4. Wallet balance, transaction, withdrawal states; không có top-up CTA và không dùng wallet thanh toán vé.
5. Loyalty balance/history/config; checkout redemption tiếp tục mặc định tắt.
6. Hoàn thiện guest/loading/empty/error/submitting cho Account và Orders.

Điều kiện xong: guest/logged-in state nhất quán, auth resume có test và account không còn dead action đối với feature core đã bật.

### 12.9. R7 — M5 Preview flows

Chỉ thực hiện sau khi R5 và R6 ổn định. Thứ tự nội bộ đề xuất:

1. Thông tin rạp, chính sách và CSKH tĩnh/mock vì ít phụ thuộc contract.
2. Food order độc lập.
3. Refund/đổi vé.
4. Voucher và VIP.
5. Favorite, review và notification.
6. PopBot chat.

Mỗi flow phải dùng feature flag mặc định `off`, model/repository tạm có nhãn `provisional`, test riêng và không trộn field giả vào DTO backend đã chuẩn hóa.

Điều kiện xong: preview build review được từng flow; release-like build không hiển thị action active của các flow này.

### 12.10. R8 — Stabilization và handoff

1. Chạy toàn bộ analyze, unit, notifier, widget, navigation và E2E mock test.
2. Kiểm tra width 360/390/412, text scale, keyboard, safe area, scroll và accessibility label.
3. Kiểm tra toàn bộ CTA registry, feature flag matrix và auth resume.
4. Kiểm tra snapshot data xuyên suốt movie → booking → payment → ticket/order.
5. Cập nhật `Flutter_UI_Feature_Mapping.md` theo trạng thái code thực tế.
6. Cập nhật hai tài liệu này nếu implementation buộc thay đổi quyết định đã chốt.
7. Lập API-readiness report từ blocker mục 15; không tự bắt đầu remote integration.

Điều kiện xong: đạt Definition of Done, không còn lỗi blocker thuộc mock UI và có danh sách blocker backend rõ ràng cho phase tích hợp thật.

### 12.11. Ma trận F → work package

| Flow decision | Work package chính | Work package kiểm chứng |
| --- | --- | --- |
| F1 CTA/navigation | R1, R3 | R8 |
| F2 Core booking | R4, R5 | R8 |
| F3 Home | R3 | R8 |
| F4 Showtime/seat/hold | R4 | R5, R8 |
| F5 Auth gate/resume | R4, R6 | R8 |
| F6 State machine | R2, R4, R5 | R8 |
| F7 Preview isolation | R1, R7 | R8 |
| F8 Common UI states | R3–R7 | R8 |

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
