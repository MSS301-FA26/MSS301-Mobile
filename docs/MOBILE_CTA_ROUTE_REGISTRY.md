# CINEPREMIER Mobile — CTA and Route Registry

> Phiên bản: 1.0
> Phạm vi: R1 — F1A Navigation contract
> Chế độ: Backend-aligned Mock UI, không gọi API thật
> Trạng thái: hoàn thành ngày 2026-09-25

## 1. Trạng thái action

| Mã | Ý nghĩa | Quy tắc UI |
| --- | --- | --- |
| `core-active` | Route/action lõi đã tồn tại | Control active và phải có navigation test |
| `local-active` | Tương tác chỉ thay đổi state local hợp lệ | Control active; không được giả là backend đã ghi dữ liệu |
| `modal-active` | Mở dialog/bottom sheet có nội dung mock hợp lệ | Control active và đóng được |
| `core-blocked` | Core action có route đích trong flow nhưng màn đích chưa được triển khai | Control disabled và có dấu hiệu “đang khóa”; không mở placeholder |
| `preview-disabled` | Feature F7 chưa có contract/route đầy đủ | Control disabled hoặc ẩn; không có badge/count giả |
| `external` | Mở ứng dụng hoặc URL ngoài | Chỉ active khi đã xử lý trường hợp không mở được |

Không dùng snackbar “sẽ có sau” để thay thế navigation. Một action chỉ được chuyển từ `core-blocked`/`preview-disabled` sang active khi route đích tồn tại và có test.

## 2. Route hiện tại

| Route | Tên | Parameter | Trạng thái |
| --- | --- | --- | --- |
| `/home` | `home` | Không | `core-active` |
| `/discover` | `discover` | Không | `core-active`; alias hiện tại của `/search` |
| `/showtimes` | `showtimes` | Query `movieId` tùy chọn | `core-active`; alias hiện tại của `/showtime` |
| `/orders` | `orders` | Không | `core-active` |
| `/account` | `account` | Không | `core-active`; alias hiện tại của `/profile` |
| `/movie/:id` | `movieDetail` | Path `id` | `core-active` |
| `/seat-selection/:showtimeId` | Chưa tạo | Path `showtimeId` | `core-blocked`, dự kiến R4 |
| `/ticket/:bookingId` | Chưa tạo | Path `bookingId` | `core-blocked`, dự kiến R5 |

Route path được khai báo tập trung tại `lib/core/routing/app_routes.dart`. Từ R3, `movieId` được parse tại router boundary và dùng kiểu `int` trong ứng dụng.

## 3. Header và app shell

| Control | Hành vi | Trạng thái |
| --- | --- | --- |
| Logo CP | Đi `/home` | `core-active` |
| Tên CineAI Central | Mở `CinemaInfoSheet` | `modal-active` |
| Search | Đi `/discover` | `core-active` |
| Notification | Không có route/contract | `preview-disabled`, không hiển thị unread badge |
| Account | Đi `/account` | `core-active` |
| Bottom nav Home/Discover/Showtimes/Orders/Account | Đi root route tương ứng | `core-active` |

Quy tắc cần triển khai khi R4 có booking session đang hoạt động:

- nếu người dùng nhấn logo CP khi chưa có booking draft/hold, đi thẳng về `/home`;
- nếu đang chọn ghế hoặc đã có booking `HOLDING`/`PENDING_PAYMENT`, không điều hướng ngay mà mở dialog hỏi **“Bạn có muốn dừng đặt vé và quay lại Trang chủ không?”**;
- nút **Không** là primary, có độ nhấn thị giác cao hơn và chỉ đóng dialog để tiếp tục đặt vé;
- nút **Có** là secondary, ít nổi bật hơn; khi xác nhận phải giải phóng hold/session theo state hiện tại rồi mới về `/home`;
- dialog không được tự hủy booking đã `PAID` và không được làm mất pending action ngoài ý muốn.

## 4. Home

| Control | Hành vi | Trạng thái |
| --- | --- | --- |
| Hero image/title area | `/movie/:id` | `core-active` |
| Hero **Đặt vé ngay** | `/showtimes?movieId=:movieId` | `core-active` |
| Hero **Xem trailer** | Mở trailer mock dialog | `modal-active` |
| Hero indicator | Đổi hero local | `local-active` |
| Bắp & Nước | Chưa có customer order route | `preview-disabled` |
| PopBot AI | Chưa có chat route/contract | `preview-disabled` |
| Ưu đãi VIP | Chưa có membership route/contract | `preview-disabled` |
| CinePoints | Chưa có màn points | `core-blocked` |
| Phim đang chiếu — Xem tất cả | Đi `/discover` | `core-active` |
| Movie card content | `/movie/:id` | `core-active` |
| Movie card **Đặt vé** | `/showtimes?movieId=:movieId` | `core-active` |
| PopBot banner/prompt | Chưa có chat route | `preview-disabled` |
| Genre chip | Lọc danh sách local | `local-active` |
| Phim sắp chiếu — Xem lịch | Đi `/showtimes` | `core-active` |
| Coming-soon card | `/movie/:id` | `core-active` |
| Nhắc mở bán | Notification/favorite contract chưa có | `preview-disabled` |

## 5. Discover và Movie Detail

| Control | Hành vi | Trạng thái |
| --- | --- | --- |
| Search input/clear | Lọc local | `local-active` |
| Đang chiếu/Sắp chiếu | Đổi tab local | `local-active` |
| Format chip | Lọc local | `local-active` |
| Movie card content | `/movie/:id` | `core-active` |
| Movie card **Đặt vé** | `/showtimes?movieId=:movieId` | `core-active` |
| Movie Detail — Back | Pop stack hoặc về `/home` | `core-active` |
| Movie Detail — Đặt vé | `/showtimes?movieId=:movieId` khi đang chiếu | `core-active` |
| Movie Detail — Chưa mở bán | Không action | disabled hợp lệ |

## 6. Showtimes

| Control | Hành vi | Trạng thái |
| --- | --- | --- |
| Thông tin rạp | Mở `CinemaInfoSheet` | `modal-active` |
| Date selector | Đổi ngày local | `local-active`; ngày động thuộc M1 |
| Format chip | Lọc phòng local | `local-active` |
| Suất hợp lệ | Đích `/seat-selection/:showtimeId` chưa tồn tại | `core-blocked`, dự kiến R4 |
| Suất hết chỗ | Không action | disabled hợp lệ |

Query `movieId` phải lọc danh sách về đúng phim. Không tự chọn sẵn suất; việc bỏ ngày hard-code và tạo ngày động thuộc M1/F4.

## 7. Orders

| Control | Hành vi | Trạng thái |
| --- | --- | --- |
| Upcoming/Completed tab | Đổi danh sách local | `local-active` |
| Hoàn/Đổi vé | Refund contract chưa có | `preview-disabled` |
| Mở mã vé | Route ticket chưa có | `core-blocked`, dự kiến R5 |
| Đặt lại vé | `/showtimes?movieId=:movieId` | `core-active` |
| Đánh giá | Review contract chưa có | `preview-disabled` |

## 8. Account

| Control | Hành vi | Trạng thái |
| --- | --- | --- |
| Mã VIP | Chưa có membership QR contract | `preview-disabled` |
| Quản lý ví | Chưa có wallet route | `core-blocked`, dự kiến R6 |
| Vé xem phim của tôi | Đi `/orders` | `core-active` |
| PopBot | Chưa có chat route/contract | `preview-disabled` |
| Voucher cá nhân | Chưa có voucher contract | `preview-disabled`; không hiển thị count giả |
| Thông tin rạp | Mở `CinemaInfoSheet` | `modal-active` |
| CSKH | Chưa có support route | `core-blocked`, dự kiến R7 |
| Đăng xuất | Chưa có session/auth state | Ẩn đến R6 |

## 9. Feature flag dự kiến

| Feature | Flag | Mặc định |
| --- | --- | --- |
| Bắp nước độc lập | `enableIndependentFoodOrderPreview` | `off` |
| Hoàn/đổi | `enableRefundPreview` | `off` |
| Voucher | `enableVoucherPreview` | `off` |
| VIP | `enableVipPreview` | `off` |
| Favorite/review/notification | `enableSocialMoviePreview` | `off` |
| PopBot | `enablePopBotPreview` | `off` |

R1 chỉ khóa classification và disabled state. Flag runtime/build-time được nối vào từng preview route khi triển khai M5; bật flag trước khi route sẵn sàng không được biến control thành active.

## 10. Gate R1

R1 hoàn thành khi:

- không còn `showSnackBar` dùng cho feature chưa triển khai;
- card content và CTA Đặt vé dùng callback khác nhau;
- Home/Discover/Movie Detail truyền `movieId` vào Showtimes;
- Search, Account, Orders, cinema info và bottom navigation đi đúng đích;
- action chưa có route ở trạng thái disabled/hidden;
- notification không hiển thị badge giả;
- có widget/navigation test cho core route và disabled preview action;
- `flutter analyze` và test liên quan pass.

Kết quả hiện tại: toàn bộ gate trên đã đạt. `dart analyze` không có issue và 8 widget/navigation test đã pass; thay đổi tiếp theo thuộc R2 — M0 Contract foundation.
