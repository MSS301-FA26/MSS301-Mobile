# Kiểm toán BE–FE–Mobile và kế hoạch đóng gap Mobile

Ngày rà soát: **01/11/2026**. Baseline: Mobile `feat/vy-ui-refinement@2c49437`, FE `dev@131d247`, BE `dev@9921498`. BE có thay đổi local sẵn trong payment/docker/test; audit chỉ đọc và không sửa các thay đổi đó.

## 1. Kết luận điều hành

Mobile đã phủ phần lớn hành trình khách hàng: xác thực email/Google, catalog, tìm kiếm, chi tiết phim, rạp và lịch chiếu, ghế/hold, bắp nước gắn vé và độc lập, quote, VNPay, đơn/vé/QR, hồ sơ, đọc ví, CinePoints và PopBot. Không nên viết lại các luồng này chỉ để giống bố cục Web.

Các gap cần ưu tiên không nằm ở số lượng màn hình mà ở ba luồng đang thiếu hoặc chưa thật sự chạy:

1. **P0 — Rút tiền CineWallet:** Mobile đã hiển thị nút và form, nhưng `RemoteWalletRepository.createWithdrawal()` luôn trả lỗi `unsupported` dù Gateway và Payment Service đã có `POST /api/v1/wallet/withdrawals`.
2. **P0 nghiệp vụ — Single-seat-gap:** FE có validator, Mobile UI-23 chưa làm và BE chưa enforce nguyên tử; client khác vẫn có thể bypass.
3. **P1 — Tương tác review:** Mobile chỉ đọc summary/danh sách; BE và FE đã hỗ trợ kiểm tra điều kiện, tạo, sửa và báo cáo review.

Ngoài ra có một **gap contract Google ở cấp hệ thống**: FE có route setup dựa trên `passwordChangeRequired`, nhưng Identity Service hiện không trả cờ này, không gửi mật khẩu tạm và tạo password hash từ Google subject. Vì vậy không được sao chép route FE sang Mobile trước khi BE chốt cơ chế set-password an toàn.

Về thẩm mỹ, vấn đề lớn nhất là **shell/header thiếu nhất quán, mật độ thẻ quá lớn ở Discover/Orders/Account, phân cấp lỗi ví lấn át nội dung, và các batch UI-20–23 chưa có kết quả triển khai**. Home và movie detail đã có nền tảng hình ảnh tốt, không cần redesign toàn bộ.

## 2. Nguồn sự thật và phạm vi

Đã đối chiếu trực tiếp:

- Gateway microservice và controller customer hiện hành trong `BE/MSS301-Backend/cinema-services`.
- Monolith `cinemaAI` chỉ dùng để nhận diện contract cũ/chưa được route; không coi controller trong monolith là API Mobile có thể gọi nếu Gateway hiện hành chưa expose.
- Route, page và service trong `FE/MSS301-Frontend`.
- Route, repository production, widget/page, test, kết quả UI-01–19 và ảnh QA Android trong Mobile.

Phạm vi sản phẩm của Mobile hiện là **khách hàng**. Portal Admin/Manager/Staff của FE được phân loại `NOT_MOBILE_SCOPE`; không tính là Mobile thiếu. Nếu cần app vận hành riêng, phải lập product scope khác thay vì đưa các portal này vào app khách hàng.

## 3. Ma trận capability khách hàng hiện tại

| Capability | BE/Gateway | FE | Mobile hiện tại | Kết luận |
| --- | --- | --- | --- | --- |
| Đăng ký, OTP email, login, quên mật khẩu | Có | Có | Có | Đạt |
| Google login + thiết lập password email | `AuthResponse` không có cờ; Google user không biết old password | Có route `/setup-password` nhưng điều kiện/“mật khẩu tạm” không khớp BE | Không có setup route | **SYSTEM_CONTRACT_GAP — P1** |
| Hồ sơ, đổi mật khẩu, avatar | Có | Có | Có, nhưng avatar nhập URL thủ công | Đạt chức năng; **UX cần sửa** |
| Rạp ưu tiên | Có `/users/me/cinema` | Dùng theo tài khoản | Mobile chỉ lưu local theo user/guest | **PARTIAL — P2** |
| Home, banner, now/upcoming | Có | Có | Có | Đạt |
| Impression/click banner | Có | Có | Chưa gọi | **MISSING — P2** |
| Đề xuất cá nhân/trending và click telemetry | Có qua AI Gateway | Có | Chỉ có related movie ở chi tiết | **PARTIAL — P2** |
| Discover/search/genre | Có | Có | Có | Đạt; cần giảm mật độ thẻ |
| Chi tiết phim/trailer/cast/related | Có | Có | Có | Đạt; còn polish UI-21 |
| Đọc review | Có | Có | Có | Đạt |
| Eligibility/tạo/sửa/báo cáo review | Có | Có | Chưa có repository/UI mutation | **MISSING — P1** |
| Xóa review | Không có ở microservice controller hiện hành | FE có lời gọi | Không | **Không triển khai cho tới khi contract được chốt** |
| Danh sách rạp/chi tiết/lịch chiếu/bộ lọc | Có | Có | Có qua UI-18/19 | Đạt |
| Seat map/refresh/hold/conflict | Có | Có | Có qua UI-16 | Đạt phía Mobile; còn rủi ro BE che lỗi occupancy |
| Quy tắc không để một ghế trống lẻ | Chưa enforce nguyên tử | FE có validator | UI-23 mới planned | **MISSING — P0 nghiệp vụ**, cần cả BE và Mobile |
| Bắp nước gắn booking | Có | Có | Có | Đạt |
| Bắp nước độc lập và lịch sử | Có | Có | Có | Đạt |
| Quote/checkout/payment/VNPay return | Có | Có | Có | Đạt chức năng; UI-20 còn planned |
| Đơn, vé, QR, trạng thái refund do hệ thống | Có | Có | Có | Đạt; cần tinh gọn UI |
| Customer tự yêu cầu refund | Gateway microservice chưa có contract customer ổn định | FE có service/fallback cũ | Preview | **BLOCKED_BY_BE** |
| Wallet balance/transactions/withdrawal history | Có | Có | Có | Đạt |
| Tạo yêu cầu rút tiền | Có | Có | UI có nhưng remote repository luôn fail | **BROKEN — P0** |
| CinePoints read/config/redeem | Có | Có | Có, có test redeem | Đạt; audit 09/10 đã lỗi thời |
| Watchlist | Gateway microservice chưa route; monolith có controller | FE chỉ localStorage | Mobile preview mock | **PARTIAL/BLOCKED**; quyết định local hay remote |
| Notification | Gateway microservice chưa route; monolith có controller | Không có customer page hoàn chỉnh | Preview mock | **BLOCKED_BY_BE** |
| Voucher/promotion customer | Gateway microservice chưa expose contract đầy đủ | Một phần trong checkout/legacy | Preview; quote gửi `voucherCode: null` | **BLOCKED_BY_BE** |
| PopBot chat | Gateway có `/api/v1/chat/**` | Có | Có chat thật | Đạt; còn QA 2xx và context phim |
| Adaptive AI search | AI service có nhưng Gateway chưa route `/api/v1/search/**` | Service có | Không | **BLOCKED_BY_GATEWAY** |

## 4. Những gì không nên đưa vào Mobile customer

- Toàn bộ dashboard Admin/Manager: quản lý phim, diễn viên, đạo diễn, rạp/phòng/suất, giá, food inventory, banner, loyalty, wallet, audit và report.
- Staff check-in vé, pickup food, in vé và tra cứu vận hành.
- Các endpoint internal giữa service.

Nếu có yêu cầu nghiệp vụ cho nhân viên dùng điện thoại, nên tạo app/role shell riêng với threat model, navigation và QA riêng; không nhét route ẩn vào app khách hàng.

## 5. Audit UI từ ảnh Android và code hiện tại

### Điểm đang tốt

- Hệ đen–vàng nhất quán về nhận diện; ảnh phim và CTA chính nổi bật.
- Home có hero, quick booking và coverflow tạo cảm giác sản phẩm điện ảnh rõ.
- Movie detail có hero/trailer, poster, age notice và CTA sticky hợp lý.
- Các màn đã có component chung cho loading/error/empty, tiền, badge và button; không cần tạo design system mới.

### Điểm cần cải thiện

| Khu vực | Vấn đề quan sát được | Hướng sửa |
| --- | --- | --- |
| App shell/header | Home dùng logo chữ lớn; Discover/Orders dùng logo CP + rạp; Account lại gần như không có header. Nhịp top bar thay đổi giữa tab. | Chốt một `CustomerTopBar`: logo gọn, rạp ưu tiên, search, notification/account; biến thể tối thiểu theo màn. |
| Bottom nav | Nhãn dài, mật độ sát mép và badge/label cạnh tranh; ở ảnh nhỏ chữ có cảm giác bị cắt. | Chuẩn hóa chiều cao SafeArea, cỡ nhãn, icon/badge và test 320–430 px + text scale 1.6. |
| Home | Quick booking chiếm gần một màn hình trước khi thấy phim; hero + form + coverflow đều rất nặng thị giác. | Cho phép thu gọn quick booking sau khi cuộn/đã chọn; giảm chiều cao hàng và khoảng trống, không bỏ luồng. |
| Discover | Hai cột nhưng card rất cao; title, genre và CTA làm mỗi hàng quá dài. Header + search + segmented + genres chiếm nhiều vùng đầu. | Poster 2:3 nhỏ hơn, title 2 dòng, metadata 1 dòng, CTA compact; sticky search/filter và bottom sheet filter. |
| Showtimes | Chức năng lọc đã tốt nhưng nhiều cấp rạp → phim → phòng → giờ có thể dài. | Collapsible group, nhớ group đang mở, CTA chọn suất rõ nhưng không lặp metadata. |
| Orders | Card vé lặp nhiều metadata và CTA lớn; danh sách dài khó quét. Tên tab “Sắp chiếu” chưa bao quát các trạng thái đang thanh toán/đã trả. | Card compact + expand detail; status/date/QR là 3 ưu tiên; đổi taxonomy tab theo nghiệp vụ. |
| Account | Membership, lỗi ví và menu đều là card lớn; lỗi ví có thể chiếm vị trí nổi bật hơn hành động chính. | Header/profile compact, wallet skeleton/error inline, nhóm menu theo “Thanh toán”, “Tài khoản”, “Hỗ trợ”. |
| Profile/avatar | Yêu cầu người dùng nhập URL ảnh là UX kỹ thuật, không phù hợp app thật. | Dùng gallery/camera + upload contract; nếu BE chưa có upload customer thì ẩn action thay vì hỏi URL. |
| Wallet withdrawal | Dialog hard-code “Ngân hàng Mock” và tên chủ tài khoản; production repository lại fail. | Form thật có ngân hàng, chủ tài khoản, số tài khoản, số tiền; validation và trạng thái pending/success. |
| Checkout/payment | UI-20 chưa có result; màn fixture dày thông tin, nhiều khối có trọng số ngang nhau. | Giữ snapshot/quote nhưng progressive disclosure; tổng tiền và CTA sticky, trạng thái callback tách rõ. |
| Movie detail | Bản hiện tại đẹp hơn baseline nhưng chưa có save/review action và phần dưới dài. | Hoàn tất UI-21 cùng review mutation/watchlist decision; dùng anchor/tab nhỏ cho Nội dung/Review/Liên quan. |
| Preview routes | Voucher/favorite/notification/refund còn mock/provisional. | Release-like build không được tạo cảm giác feature thật; hiển thị “Sắp có” hoặc bỏ entry cho tới khi contract sẵn sàng. |

## 6. Kế hoạch triển khai đề xuất

### Wave 0 — Chốt contract và lỗi chức năng trước khi polish

#### SYS-24 — Chốt Google password setup contract — P1

- BE phải chọn cơ chế rõ ràng: endpoint set-password bằng phiên Google gần nhất, hoặc cấp one-time token; không bắt người dùng nhập “old password” mà họ không thể biết.
- Nếu sản phẩm bắt buộc hoàn tất ngay, thêm cờ contract vào `AuthResponse` và giữ qua refresh; nếu không bắt buộc, bỏ dead guard/copy “mật khẩu tạm” ở FE.
- Sau khi contract chốt, FE và Mobile cùng có route/guard, back/deep-link protection, show/hide, validation và recovery.
- Test Google user mới/cũ, refresh token, session restart, replay/expired one-time token và login email sau khi set password.

#### MOB-25 — Kích hoạt rút tiền CineWallet thật — P0

- Thay `_unsupported` bằng `POST /api/v1/wallet/withdrawals` và map `WithdrawalResponse`.
- Bỏ `DemoIds.user`, “Ngân hàng Mock”, tên chủ tài khoản hard-code khỏi production flow.
- Form thật: amount, bankName, accountNumber, accountHolder, walletPhone khi cần; validate theo DTO BE và số dư.
- Khóa double-submit, refresh balance/history sau thành công, hiển thị trạng thái pending/rejected/approved và processed note.
- Test request body, 400/401/409/5xx, insufficient balance, pagination và account switching.

#### SYS-26 — Enforce single-seat-gap — P0 nghiệp vụ

- Mobile hoàn tất UI-23 để cảnh báo ngay và preflight trước hold.
- BE phải validate nguyên tử trong transaction hold trên occupancy mới nhất, trả error code + hàng/ghế.
- FE/Mobile dùng cùng bảng quy tắc cho lối đi, ghế OFF, ghế đôi và orphan gap có sẵn.
- Không đánh dấu hệ thống đạt nếu mới chỉ có validator client.

### Wave 1 — Đóng capability đã có contract

#### MOB-27 — Review actions — P1

- Thêm eligibility, `GET /reviews/me`, create, update và report vào repository.
- CTA chỉ hiện khi auth/eligibility cho phép; điều hướng login rồi quay lại đúng phim.
- UI form rating 1–10, nội dung, giới hạn thời gian sửa theo response; report dùng reason/comment.
- Không làm nút delete cho tới khi microservice controller có contract chính thức.

#### MOB-28 — Preferred cinema account sync — P1/P2

- Đọc `preferredCinemaId` từ profile/auth response và đồng bộ `PUT /api/v1/users/me/cinema`.
- Guest tiếp tục dùng local; khi login phải có quyết định merge rõ và không ghi đè server âm thầm.
- Header, Home cinema section, quick booking, showtimes và banner query dùng cùng một nguồn.

#### MOB-29 — Banner/recommendation analytics — P2

- Gửi impression chỉ khi banner thật sự visible; click khi CTA được kích hoạt, best-effort và không chặn UI.
- Thêm personalized/trending shelf trên Home qua `/api/v1/recommendations/**`; giữ fallback catalog minh bạch.
- Lưu `setId` và gửi click telemetry; reset/không rò dữ liệu khi đổi tài khoản.

### Wave 2 — Làm đẹp có trọng tâm

#### UI-24 — App shell, header và bottom navigation — P1

- Chuẩn hóa top bar giữa 5 tab, SafeArea, logo, rạp, search, account và trạng thái notification chưa khả dụng.
- Chuẩn hóa bottom nav ở 320/360/390/430 px, text scale 1.0/1.3/1.6, gesture navigation và TalkBack.

#### UI-25 — Discover + Showtimes density — P1

- Giảm chiều cao card, đưa filter phụ vào sheet, giữ keyword/genre/status trong route/state.
- Collapsible grouping cho lịch chiếu; test tên dài, nhiều phòng, ngày không có suất và late response.

#### UI-26 — Orders + Ticket information hierarchy — P1

- Card compact mặc định; mở rộng mới thấy food/chi tiết tiền.
- Ưu tiên status, thời gian, rạp/phòng/ghế và CTA QR; phân biệt pending/paid/used/cancelled/refunded/expired.
- Giữ QR chỉ khi BE xác nhận điều kiện.

#### UI-27 — Account/Profile/Wallet — P1

- Giảm kích thước membership card, lỗi ví inline, nhóm menu, skeleton thay cho card lỗi lớn.
- Thay avatar URL bằng native picker sau khi upload contract được xác nhận.
- Tích hợp form withdrawal thật từ MOB-25.

#### UI-28 — Payment/result redesign — P1

- Thực hiện nội dung UI-20: chung ngôn ngữ thị giác cho booking và food, nhưng không gộp nhầm lifecycle.
- Tách `pending provider`, `verifying`, `success`, `failed`, `cancelled`, `expired`, `unknown`; không tin callback URL thay BE.

#### UI-29 — Movie detail/watchlist/review — P2

- Gộp phần còn giá trị của UI-21 với MOB-27.
- Watchlist chỉ làm một trong hai phương án đã chốt: local và ghi rõ “trên thiết bị này”, hoặc remote sau khi Gateway expose. Không ship preview mock như feature thật.

### Wave 3 — Contract còn thiếu, chưa code Mobile trước

#### BEG-30 — Wishlist decision

- Chọn product rule: local như FE hiện tại hay sync account.
- Nếu sync: đưa wishlist vào microservice phù hợp, route Gateway, ownership, idempotent add/remove, list pagination và migration/test.
- Sau đó mới thay `/preview/favorites` bằng repository production.

#### BEG-31 — Notification, voucher và customer refund

- Notification: chốt list/unread/mark-one/mark-all/deep-link và Gateway route.
- Voucher: chốt active/list/validate/apply và snapshot giảm giá trong quote; Mobile không tự tính giảm giá.
- Refund: chốt eligibility/policy, request, trạng thái, ví/VNPay và idempotency cho customer.
- Gỡ preview mock hoặc giữ tắt trong release cho tới khi từng contract được chứng minh bằng integration test.

#### BEG-32 — AI adaptive search

- Chỉ triển khai Mobile khi Gateway route `/api/v1/search/**` và auth/rate-limit/error envelope được chốt.

### Wave 4 — Release gate

#### QA-33 — E2E và thiết bị thật

- Android + iOS thật; 320–430 logical px; chữ lớn; TalkBack/VoiceOver; dark contrast; keyboard; offline/slow network.
- Hai tài khoản cùng suất cho seat race; VNPay sandbox cho booking và food; app kill/resume; QR check-in/pickup.
- Sau khi SYS-24 chốt: Google mới → set password → relogin email; withdrawal lifecycle; review eligibility/create/update/report.
- Không nghiệm thu chỉ bằng widget test hoặc ảnh fixture.

## 7. Thứ tự thực hiện và Definition of Done

Thứ tự đề xuất:

1. **MOB-25 → SYS-26**.
2. **SYS-24 → MOB-27 → MOB-28**.
3. **UI-24 → UI-25 → UI-26 → UI-27 → UI-28**.
4. **MOB-29/UI-29** sau quyết định watchlist.
5. **BEG-30/31/32** khi owner BE/Gateway nhận scope.
6. **QA-33** là release gate, chạy xuyên từng wave và chốt cuối.

Mỗi batch chỉ `DONE` khi có đủ:

- Contract mapping endpoint/request/response/error và auth ownership.
- Unit/repository/widget test, `flutter analyze`, full relevant test và build Android.
- Ảnh trước/sau cho batch UI; test 320 px + text scale lớn.
- E2E API thật cho mutation/payment/seat; ghi rõ iOS hoặc sandbox chưa chạy nếu còn thiếu.
- Không dùng mock/provisional data trong production provider và không nuốt lỗi thành success/empty giả.

## 8. Các tài liệu cũ cần coi là lịch sử

- `09-FINAL-CUSTOMER-CLOSURE-AUDIT.md` ngày 09/10 không còn đúng ở kết luận loyalty redemption và chat; Mobile hiện đã có redeem và chat route thật.
- `02-WEB-MOBILE-PARITY-MATRIX.md` không còn đúng ở standalone food/cinema/showtime vì các phần này đã được triển khai sau đó.
- UI-20–23 vẫn là plan; chưa có `UI20-RESULTS.md` đến `UI23-RESULTS.md`, vì vậy không được tính hoàn tất.
- Controller wishlist/notification trong monolith không chứng minh Gateway microservice production đã hỗ trợ.
