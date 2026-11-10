# UI-13 — Kết quả tổng thanh toán

Ngày: **16/10/2026**. Baseline: Mobile `21220a7` + diff local của batch này.
Trạng thái: **Hoàn tất triển khai và kiểm tra tự động; chờ người dùng review giao diện, QA iOS và sandbox E2E thật.**

## Đã triển khai

- Checkout booking: poster giữ tỷ lệ, tên phim đầy đủ, phân loại tuổi và giải thích, thời lượng, rạp/địa chỉ/phòng, giờ Việt Nam, số ghế và mã ghế.
- Vé được tách theo ghế, hiển thị loại vé, đơn giá × số lượng và thành tiền từ quote. Thiếu seat metadata có nhãn dự phòng, không gây lỗi trang.
- Món/combo có ảnh crop trong khung vuông, tên, số lượng, đơn giá và thành tiền. Ghép ảnh theo cả loại item/combo và ID để tránh trùng ID.
- Nút sửa bắp nước trở lại bước bắp nước hiện có, giữ mã đơn và deadline; khóa nút khi đang xử lý hoặc đã có payment. Thêm combo trực tiếp tại checkout thuộc UI-14.
- Giữ chi tiết tiền vé, món, phí/thuế/giảm giá nếu BE trả về; tổng và CTA cố định, countdown vẫn hiện khi cuộn. Không cộng phụ thu hoặc tính lại tổng từ catalog.
- Metadata phim thiếu được bổ sung qua catalog đúng movie ID; lỗi tải bổ sung không chặn checkout. Snapshot được ưu tiên, không thay tên/giá đơn bằng catalog mới.
- Đơn bắp nước riêng giữ ngữ cảnh đơn/món, bổ sung rạp/địa chỉ nhận hàng khi API snapshot có dữ liệu. Không tự gán rạp theo header hoặc tạo khung phim trống.
- Ảnh món của đơn riêng được bổ sung từ catalog; từng request có thể lỗi độc lập mà đơn vẫn hiển thị. Tên, số lượng, giá và tổng luôn lấy từ đơn.

## File chính

- `lib/features/booking/presentation/pages/checkout_page.dart`
- `lib/features/booking/presentation/widgets/checkout_order_summary.dart`
- `lib/features/food/presentation/pages/food_checkout_page.dart`
- `lib/features/food/presentation/widgets/checkout_food_images_provider.dart`
- `lib/features/food/data/models/food_order_dto.dart`
- `test/ui13_checkout_summary_test.dart`; điều chỉnh scroll tới QR trong `test/quick_action_pages_test.dart`.

Đối chiếu contract BE `FoodOrderResponse`/`FoodOrderItemResponse`: rạp có trong snapshot đơn riêng; ảnh không có trong item snapshot nên chỉ bổ sung ảnh qua catalog. Không sửa BE/DB.

## Kiểm chứng

- **56 test đạt**: UI-13 (11 ca), UI-06, layout booking, remote booking completion, quick actions, repository đơn riêng và completion/account.
- Bao gồm: 320/360/390/430 logical px ở cỡ chữ 1.6; 8 ghế, nhiều loại vé và cặp ghế đôi cùng loại; tên dài; metadata thiếu/lỗi; ID item/combo trùng; alias `foodItems`; giữ deadline khi sửa giỏ; giá catalog không ghi đè quote; phí/thuế/giảm giá; expired/conflict/giá đổi/resume và QR theo trạng thái.
- `flutter analyze --no-pub`: **No issues found**.
- `flutter build apk --debug --no-pub --dart-define=API_BASE_URL=http://10.0.2.2:8080 --dart-define=UI_PREVIEW=false`: **đạt**, APK đã cài thành công lên `emulator-5554`.
- Log: `D:/MSS/.qa-runtime/ui13-tests.log`, `ui13-analyze.log`, `ui13-build.log`. Chạy lại 11 ca UI-13 sau khi thêm kiểm tra deadline: đạt (`ui13-final-tests.log` còn có 1 ca xuất ảnh tạm).
- Ảnh layout 390×1000: `D:/MSS/.qa-runtime/ui13-fixture-movie.png`, `ui13-fixture-tickets.png`, `ui13-fixture-food-total.png`. Đây là **fixture test**, không phải đơn thật hoặc bằng chứng thanh toán BE. Ảnh mạng dùng placeholder; font trong test có thể khác thiết bị. File xuất ảnh tạm đã gỡ khỏi source.

## Còn QA / review

- Người dùng xem giao diện checkout với đơn thực tế trên emulator; chưa tạo đơn hoặc thanh toán mới chỉ để lấy ảnh.
- Sandbox thật xuyên luồng booking → sửa món → báo giá → thanh toán → xác nhận BE → QR; iOS và font lớn trên thiết bị thật.
- Chưa có bộ ảnh trước/sau cùng dữ liệu thật. Không dùng ảnh fixture để xác nhận E2E thành công.
- UI-14 (thêm/giảm combo ngay tại checkout) chưa triển khai trong batch này.
