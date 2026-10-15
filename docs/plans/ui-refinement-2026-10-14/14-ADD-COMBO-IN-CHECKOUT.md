# UI-14 — Thêm combo ngay tại tổng thanh toán

Ngày lập: **15/10/2026**. Trạng thái: **planned — sau UI-10, UI-12 và UI-13**.
Thứ tự trong đợt mới: **4**. Tham chiếu: hàng “Thêm combo/bắp nước” ảnh 1.

## Trải nghiệm mong muốn

- Tại checkout vé, có hàng ngang combo với ảnh, tên, giá và nút +; có Xem tất cả để mở sheet sản phẩm. Hàng gợi ý không che tổng/CTA và không đẩy countdown vào vùng cuộn.
- Thêm/giảm tại đây dùng cùng giỏ với bước Bắp nước; món đã chọn hiển thị số lượng, không thêm thành dòng trùng. Không tự chọn món, không tự chuyển combo khác, không đổi rạp.
- Giữ tối đa 8 mỗi item/combo và contract khả dụng hiện tại. Không bắt buộc thêm bắp nước.
- Ghi rõ đang cập nhật giá, khóa nút thanh toán trong lúc xử lý. Giá/tổng mới được BE xác nhận rồi người dùng mới xác nhận thanh toán.

## API và controller hiện có

- Catalog món/combo: `GET /api/v1/foods/items`, `GET /api/v1/foods/combos`.
- Cập nhật booking: `PUT /api/v1/bookings/{bookingId}/items`.
- Báo giá: `POST /api/v1/catalog/checkout-quote`.
- Luồng checkout/payment vẫn sử dụng API và kiểm tra tổng hiện có.
- `BookingCompletionController.changeQuantity` hiện chỉ sửa khi `choosingFood`; `prepareCheckout` hiện cập nhật items rồi lấy quote. **Không thể chỉ đặt nút + vào checkout**: cần bổ sung hành vi sửa giỏ tại checkout và quản lý kết quả bất đồng bộ.
- Mặc định chỉ cho sửa khi booking HOLDING, chưa có payment và còn hạn; PENDING_PAYMENT/đã mở cổng/đã trả tiền là chỉ đọc. Muốn mở rộng phải xác minh contract BE riêng.

## Luồng cập nhật phải triển khai

1. Tạo draft từ giỏ hiện tại; thay đổi số lượng theo khóa `(isCombo, productId)`, giữ vé/ghế và viewerAge của luồng hiện hành, không yêu cầu người dùng nhập tuổi.
2. Gom thay đổi nhanh hoặc gửi tuần tự; có generation/token chống response cũ ghi đè giỏ mới. Không gửi lặp checkout/payment khi bấm nhanh.
3. Kiểm tra deadline từ BE; không tạo hold mới, không reset hoặc cộng thêm 3 phút vì thêm combo.
4. Gửi updateItems → nhận snapshot → lấy quote mới gắn đúng booking → đối chiếu tổng. Trong lúc này hiển thị tổng cũ là đang cập nhật, không coi tổng tự cộng local là giá xác nhận.
5. Khi thành công, đồng bộ booking/quantities/quote và màn Bắp nước nếu quay lại; yêu cầu người dùng kiểm tra tổng mới trước khi thanh toán.
6. Nếu updateItems thành công nhưng lấy quote lỗi, không giả định đã rollback BE. Khóa thanh toán, đọc lại snapshot và cho thử lấy báo giá hoặc sửa giỏ. Chỉ dùng tổng cũ để thanh toán khi đã xác minh vẫn còn đúng.
7. Món hết hàng/giá đổi: giữ lựa chọn để người dùng sửa, thông báo ngay gần món và tổng/CTA; không tự bỏ món khỏi đơn đã cập nhật hoặc tự chấp nhận giá mới.

## Phạm vi ngoài batch

- Đơn bắp nước độc lập đã tạo: không giả định có API sửa items. Chỉ thêm chức năng tương tự sau khi xác minh endpoint và quy tắc sửa đơn; nếu chưa có, vẫn chỉnh giỏ trước khi tạo đơn.
- Không thêm voucher/điểm, không đổi phương thức thanh toán, không sửa BE/DB trong plan UI này. Thiếu khả năng phía BE phải ghi rõ trước khi mở scope.
- Không gắn nhãn “combo bán chạy/AI gợi ý” nếu không có dữ liệu hỗ trợ; dùng danh sách combo khả dụng từ API, thứ tự xác định và không trùng.

## Nghiệm thu

- Thêm ở checkout → quay lại Bắp nước → trở lại checkout vẫn cùng giỏ và cùng deadline.
- Thêm nhanh/xóa trong lúc request chậm, response đến ngược thứ tự, logout/đổi booking trong lúc chờ không trộn dữ liệu.
- Item/combo trùng ID, giới hạn 8, sản phẩm không khả dụng; tổng tiền đúng BE và không cộng phụ thu vé lần nữa.
- Update thành công/quote lỗi, giá đổi, timeout, hết hold giữa request, payment đang tạo: không được trả tiền theo báo giá cũ hoặc gửi lặp payment.
- QR/vé chỉ xuất hiện sau xác nhận BE như luồng hiện tại. Test state/race cần thiết, Android/iOS/sandbox và review ghi tại `UI14-RESULTS.md`.
