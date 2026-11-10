# UI-12 — Danh mục bắp nước và combo

Ngày: **16/10/2026**. Trạng thái: **hoàn tất triển khai, chờ review UI và QA iOS/E2E**.

Baseline trước sửa: Mobile `1b06756`. Phạm vi thay đổi: Mobile và tài liệu trong folder UI của người dùng; không sửa BE/DB hoặc UI đăng nhập/đăng ký.

## Thay đổi

- Bộ lọc Tất cả / Combo / Sản phẩm kèm số lượng, dùng chung cho đơn độc lập và bắp nước kèm vé. Phân nhóm từ `isCombo`, không suy đoán theo tên hoặc tự tạo danh mục chi tiết.
- Chuyển nhóm chỉ lọc phần hiển thị. Số lượng và tạm tính vẫn tính toàn giỏ, giữ riêng khóa `item:id` và `combo:id`, kể cả khi hai loại trùng ID.
- Ảnh thẻ tăng lên 104 × 104; tên và giá đặt bên phải. Sau phản hồi ngày 16/10, chuyển từ contain sang **crop giữa ảnh phủ kín khung (`BoxFit.cover`)**, áp dụng cả ảnh lớn trong sheet chi tiết. Giữ fallback khi ảnh tải chậm/hỏng/thiếu, viền vàng khi đã chọn, giải thích giới hạn 8 và trạng thái khả dụng tại thẻ.
- Nút Xem chi tiết mở bottom sheet: ảnh lớn, tên đầy đủ, giá, trạng thái và mô tả đầy đủ từ API. Nội dung cuộn, nút đóng nằm ngoài vùng cuộn và có SafeArea. Không thêm tùy chọn vị/size hoặc tự diễn giải thành phần combo. Thiếu mô tả thì ghi đang cập nhật.
- Đơn độc lập giữ chọn rạp ở CTA khi chưa chọn; không tự lấy rạp từ header. Đổi nhóm/đổi rạp không xóa giỏ. Trong lúc tạo đơn khóa thay đổi và gửi lặp; từ chối tạo đơn giữ draft để sửa.
- Booking có tóm tắt phim/rạp/phòng/giờ Việt Nam trong nội dung. Countdown giữ ngoài vùng cuộn, không sửa hoặc gia hạn deadline.
- Thanh cuối booking tách **Tiền vé** (quote BE hoặc tổng `lineTotal` vé BE hiện có) và **tạm tính bắp nước** từ catalog. Không dựng tổng thanh toán cuối bằng cách cộng giá tạm tính. Nếu chưa có dòng vé/báo giá thì không tự gán tiền vé bằng 0.
- Giữ bắp nước kèm vé tùy chọn, tối đa 8 mỗi sản phẩm/combo. Món đã chọn nhưng ngừng bán vẫn giảm/xóa được.

## Contract BE đã đối chiếu

- `GET /api/v1/foods/items`, `GET /api/v1/foods/combos`: gateway đều HTTP 200 trong lần kiểm tra này.
- `FoodProductDto.isAvailable` giữ điều kiện ACTIVE. `cinema-services/catalog-service/src/main/java/com/cinemaai/catalog/service/impl/CheckoutQuoteServiceImpl.java` từ chối trạng thái khác ACTIVE tại phần báo giá món (dòng 125 ở source kiểm tra).
- LOW_STOCK giữ thông báo sắp hết/tạm ngừng đặt và chặn thêm; giảm hàng đã chọn vẫn được. Không đổi sang cho đặt LOW_STOCK trong batch UI.
- DTO hiện dùng name/price/description/imageUrl/status/isCombo. Không thêm cấu hình combo, voucher/điểm hoặc category khi Mobile chưa có contract và luồng tính giá tương ứng.

## File

- `lib/features/food/presentation/widgets/food_catalog_groups.dart`
- `lib/features/food/presentation/widgets/food_product_card.dart`
- `lib/features/food/presentation/widgets/food_cart_bar.dart`
- `lib/features/food/presentation/pages/standalone_food_page.dart`
- `lib/features/booking/presentation/pages/concessions_page.dart`
- `test/ui12_food_catalog_test.dart`
- `test/ui05_concessions_test.dart`: cuộn về trường rạp theo ListView thay vì giả định trường đó còn được dựng sau khi cuộn xuống combo.

## Kiểm chứng

- `flutter analyze --no-pub`: **No issues found**.
- **59 test đạt**: `ui12_food_catalog_test`, `ui05_concessions_test`, `remote_booking_completion_test`, `ui04_booking_layout_test`, `ui06_checkout_test`, `quick_action_pages_test`, `quick_action_api_test`.
- 9 ca UI-12 mới: sheet ở 320/360/390/430 px với chữ 1.6 lần, mô tả dài và ảnh lỗi; chuyển nhóm giữ giỏ/rạp/tổng và tách item/combo cùng ID; nhóm rỗng vẫn giữ giỏ, mô tả thiếu không bịa nội dung; LOW_STOCK không thêm nhưng giảm được; pending tạo đơn chỉ gọi một lần và giữ draft khi lỗi; booking giữ deadline qua đổi nhóm và tách tiền vé từ BE khỏi tạm tính món.
- Hồi quy có sẵn: giới hạn 8, đổi rạp giữ giỏ, checkout đổi giá/hết hàng, thanh toán chống tạo lặp, expiry/resume, giỏ tùy chọn và QR đúng trạng thái.
- Build Android debug thành công; cài lên `emulator-5554`. API `http://10.0.2.2:8080`, `UI_PREVIEW=false`.
- App thật: có **16 món = 11 sản phẩm + 5 combo**; ảnh/tên/giá/mô tả từ API tải được. Chuyển Combo → Xem chi tiết Combo Couple Sweet → đóng → tăng 1 → Sản phẩm vẫn giữ tạm tính **109.000đ**. CTA chọn rạp mở danh sách rạp; chọn CinemaAI Central - Q.1 giữ nguyên giỏ và chuyển sang Xác nhận đơn. Sau kiểm tra đã giảm combo về 0.
- Không bấm xác nhận tạo đơn thật hoặc tạo hold/payment mới trong batch này; phần booking tóm tắt/giá/deadline kiểm bằng widget/controller test.

Log local: `D:/MSS/.qa-runtime/ui12-tests.log`, `ui12-analyze.log`, `ui12-build.log`.

## Ảnh local

- `D:/MSS/.qa-runtime/ui12-food-before.png`
- `D:/MSS/.qa-runtime/ui12-food-after.png`
- `D:/MSS/.qa-runtime/ui12-combo-after.png`
- `D:/MSS/.qa-runtime/ui12-combo-details.png`
- `D:/MSS/.qa-runtime/ui12-cart-pickup.png`

## Còn mở

- Người dùng review thẩm mỹ, iOS/thiết bị thật, E2E booking → món → checkout và đơn độc lập trên runtime thật.
- Giá/tồn kho đổi trong lúc đặt và lỗi phân trang trên API thật chưa tái hiện trực tiếp trong đợt UI này; các nhánh từ chối/cập nhật giá được kiểm qua test.
- UI-13 (tóm tắt tổng thanh toán) và UI-14 (thêm combo ngay trong checkout) chưa triển khai trong UI-12.
