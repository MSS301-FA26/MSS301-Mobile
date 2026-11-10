# UI-05 — Kết quả bắp nước

Ngày: **15/10/2026**. Trạng thái: **UI được người dùng duyệt; code/test/build Android đạt; iOS và E2E thật còn mở**.

Phản hồi sau bản sửa chọn rạp từ CTA: **“plan 5 đã ổn”**. Ghi nhận hoàn tất phần điều chỉnh và review UI-05; không suy ra đã kiểm chứng thanh toán thật hoặc iOS.

## Phạm vi

- Sửa Mobile: `concessions_page.dart`, `standalone_food_page.dart`.
- Thêm `food_product_card.dart`, `food_cart_bar.dart` dùng chung trong hai luồng.
- Giữ API, nguồn giá và khả dụng theo BE. Chỉ sản phẩm ACTIVE được thêm theo contract hiện tại; món hết hàng vẫn có thể giảm/xóa khỏi giỏ.
- Không đổi UI đăng nhập/đăng ký, source BE/FE hoặc schema DB.

## Thay đổi

1. Ảnh từ `imageUrl`, khung cố định 80×80, contain; fallback đúng loại món khi thiếu, URL không hợp lệ hoặc tải lỗi. Không thay bằng ảnh món khác.
2. Tên tối đa 3 dòng, mô tả 2 dòng; giá tách khỏi bộ chọn số lượng. Vùng chạm +/- 48 px, tăng bị khóa ở 8 hoặc khi không khả dụng/đang xử lý.
3. Thẻ đang chọn có viền/nền vàng và số lượng đã chọn; item và combo vẫn dùng khóa riêng.
4. Thanh tổng giỏ cố định có số lượng, tạm tính, CTA; màn hẹp/chữ lớn xếp dọc. Đơn độc lập hiển thị cả rạp nhận hàng, giữ giỏ khi đổi rạp.
5. Booking ghi rõ bắp nước tùy chọn và nút bỏ qua khi chưa chọn món, countdown giữ ở trên danh sách. Empty/error dùng state pane chung; CTA khóa trong trạng thái chưa sẵn sàng.

## Kiểm chứng

- `flutter analyze --no-pub`: **No issues found**.
- **37 test pass** trong `ui05_concessions_test`, `ui04_booking_layout_test`, `remote_booking_completion_test`, `quick_action_api_test`, `quick_action_pages_test`.
- 7 ca mới: 320/360/390/430 px với text scale 1.6, tên dài/giá lớn; món hết hàng được giảm nhưng không thêm; ảnh hỏng giữ khung; item/combo trùng ID độc lập và giỏ giữ nguyên khi đổi rạp.
- Các ca hồi quy có sẵn: giá đổi chặn trước tạo payment, hết hàng giữ giỏ để sửa, tùy chọn bỏ qua, tối đa 8 mỗi item/combo, deadline qua các bước và tránh tạo payment lặp.
- Cập nhật kỳ vọng deadline trong fixture `quick_action_api_test` theo Payment UTC+7 đã được áp dụng ở batch trước; không đổi parser trong UI-05.
- Build debug Android thành công; cài lên emulator bằng `adb install -r`, API `http://127.0.0.1:8080`, UI_PREVIEW=false.
- API thật: phiên cũ nhận 401; đăng nhập lại tài khoản test đã cấp, màn tải được sản phẩm và ảnh. Chọn CinemaAI Central - Q.1, thêm một bắp 45.000đ: thẻ đã chọn, tổng 45.000đ và CTA bật đúng. Chưa bấm xác nhận tạo đơn.

## Ảnh QA local

- `D:\MSS\.qa-runtime\ui05-food-before.png`: trạng thái lỗi trước khi đăng nhập lại, **không phải baseline có sản phẩm để so sánh thẩm mỹ**.
- `D:\MSS\.qa-runtime\ui05-food-after.png`: danh sách mới với ảnh API và giỏ trống.
- `D:\MSS\.qa-runtime\ui05-food-selected.png`: chọn rạp và một bắp 45.000đ.

## Bổ sung sau phản hồi nút xác nhận (15/10)

- Trên emulator có 1 món 45.000đ nhưng chưa chọn rạp nhận, nên CTA cũ bị disabled khi người dùng đang ở giữa danh sách.
- Khi giỏ có món nhưng chưa có rạp, CTA nay là `Chọn rạp nhận`, mở bottom sheet chọn rạp ngay tại vị trí cuộn hiện tại. Chọn xong đổi lại `Xác nhận đơn`, không tự tạo đơn và giữ giỏ.
- Dropdown ở đầu danh sách đồng bộ rạp vừa chọn. Giỏ trống/không có rạp khả dụng/đang xử lý vẫn khóa CTA theo điều kiện tương ứng.
- 8 test UI-05 pass, gồm ca mới tái hiện thiếu rạp và chọn qua CTA; analyzer không lỗi.

## QA còn mở

- iOS chưa kiểm tra.
- Luồng booking kèm vé đã kiểm bằng widget/controller test; chưa tạo hold/đơn/thanh toán mới trên DB dùng chung trong batch này.
- Hết hàng/giá đổi giữa lúc đặt đã kiểm bằng mock contract, chưa thay dữ liệu shared DB để giả lập trên môi trường thật.
