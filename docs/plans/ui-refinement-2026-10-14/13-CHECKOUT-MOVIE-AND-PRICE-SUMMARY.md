# UI-13 — Tổng thanh toán có poster và chi tiết vé

Ngày lập: **15/10/2026**. Trạng thái: **planned — sau UI-10, UI-11 và UI-12**.
Thứ tự trong đợt mới: **3**. Tham chiếu: tổng thanh toán ảnh 1 và ảnh 2.

## Mục tiêu và bố cục

Phát triển UI-06 bằng tóm tắt giàu hình ảnh, để kiểm tra đúng phim/suất/ghế trước khi trả tiền. Giữ thanh tổng/CTA và quy tắc xác nhận BE đã triển khai.

1. Header và countdown gọn, ổn định; không thay thời gian giữ ghế thành thời gian ví dụ trong ảnh.
2. Tóm tắt poster + tên đầy đủ, phân loại tuổi có giải thích, rạp/phòng, ngày giờ Việt Nam, số ghế và loại vé. Tên dài wrap, không đặt chữ lên vùng ảnh khó đọc.
3. Thông tin vé dạng chip/dòng theo ghế: mã ghế, loại vé, đơn giá/thành tiền. Ghế đôi vẫn là hai ghế cùng loại và tối đa 8 ghế/đơn.
4. Bắp nước đã chọn: ảnh nhỏ, tên, số lượng, giá; sửa giỏ theo luồng đã có. Vị trí hàng combo thêm nhanh được dành cho UI-14, chưa hiển thị nút thêm không hoạt động.
5. Chi tiết tiền vé, bắp nước, phụ thu/phí/thuế/giảm giá nếu API cung cấp, tổng cuối cùng. Giá vé đã bao gồm phụ thu không được cộng phụ thu lần nữa. Nếu API chỉ trả đơn giá gồm phụ thu, không tự bịa phân rã chi tiết.
6. Tổng BE và CTA cố định có SafeArea; giá mới cần xác nhận lại sát CTA. Không lấy giá từ poster/catalog để ghi đè quote.

## Nguồn dữ liệu và giới hạn

- `CheckoutQuoteDto` đã có `movie` (posterUrl/ageRating/durationMinutes), `showtime`, `cinema`, `seats`, `tickets`, `foods`, các subtotal/discount/fees/tax/total.
- Snapshot booking/quote là nguồn thông tin cho đơn hiện tại. Thiếu metadata phụ có thể tải bổ sung từ catalog nhưng không đổi showtime/ghế/giá snapshot theo catalog mới.
- Ảnh món có thể join theo `(isCombo, productId)` từ catalog để trình bày; catalog lỗi không được thay giá hoặc làm mất món trong quote.
- Chỉ thể hiện phương thức BE hỗ trợ đang hoạt động. Không đưa OnePay/thẻ quốc tế/voucher/coupon/thẻ ưu tiên vào chỉ vì có trong ảnh tham khảo. Voucher/điểm vẫn theo plan chức năng 10–11 và cần tích hợp thật.
- Đơn bắp nước riêng không có phim/ghế: giữ tóm tắt rạp/đơn/món đúng ngữ cảnh; không ép dùng khung phim trống. Trường rạp chỉ hiện khi snapshot/API đã có, không tự gán theo header.

## File dự kiến và QA

`checkout_page.dart`, `food_checkout_page.dart`, `checkout_summary.dart`, widget tóm tắt phim/ghế/món.

- Đơn 8 ghế, ghế đôi cùng loại, nhiều loại vé; tên phim/rạp/món dài; poster ngang/dọc/thiếu ảnh, quote thiếu metadata.
- Đối chiếu dòng tiền và tổng trả từ BE; phụ thu suất đêm/cuối tuần không bị tính hai lần; báo giá đổi phải dừng trước tạo payment.
- Màn 320–430 px, chữ lớn, cuộn cuối danh sách vẫn thấy tổng/CTA/countdown; expired/failed/unknown/resume không tạo QR sớm.
- Ghi `UI13-RESULTS.md`, review ảnh trước/sau và QA sandbox thật riêng.
