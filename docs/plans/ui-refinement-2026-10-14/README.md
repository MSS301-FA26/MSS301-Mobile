# Kế hoạch tinh chỉnh UI Mobile

Ngày lập: **14/10/2026**. Người yêu cầu: **Tzee314**.
Trạng thái: **UI-01 đã triển khai code và kiểm chứng tự động; các batch còn lại chờ triển khai**.
Baseline: Mobile `3a67680` và các thay đổi local banner/poster; BE `9921498`.

## Mục tiêu và phạm vi

Giữ phong cách đen–vàng, tím cho PopBot và bố cục bốn thẻ tiện ích trên Home. Cải thiện độ dễ đọc, mật độ thông tin, trạng thái tải/lỗi/trống và sự nhất quán giữa các màn hình.

Đây là kế hoạch UI riêng, bổ sung cho 12 plan chức năng hiện có. Hoàn thành UI không tự xác nhận hoàn thành API, thanh toán, check-in hoặc QA tích hợp trong các plan đó.

- Chỉ chỉnh Mobile; không sửa source BE, FE hoặc DB trong đợt này.
- Không chỉnh UI đăng nhập/đăng ký đang do người khác phụ trách.
- Không đổi quy tắc booking: tối đa 8 ghế, ghế đôi cùng loại vé, hạn chế vé trẻ em theo phim, không nhập tuổi; giữ deadline BE xuyên các bước.
- Bắp nước tùy chọn, tối đa 8 mỗi item/combo; khả dụng theo contract BE hiện tại. Voucher/điểm trong checkout vẫn thuộc plan chức năng 10–11.
- Không thay dữ liệu lỗi bằng dữ liệu mẫu, không hiển thị thành công khi BE chưa xác nhận.
- Chỉ tạo tài liệu trong folder này; không sửa, xóa hoặc di chuyển các MD của người khác.

## Các quyết định đã có

- Poster Home: đã thử nền blur, ảnh chính giữ tỷ lệ; tiếp tục chờ phản hồi thẩm mỹ. Chỉ chuyển sang crop khi người dùng yêu cầu.
- Banner Home: crop phủ kín khung, dùng focalPoint; ưu tiên ảnh desktop.
- Logic banner và map 17 ảnh cố định đã đồng bộ FE theo lựa chọn của người dùng. Giữ lựa chọn này trong đợt UI; map ID có thể lệch tên phim trên DB khác.
- Các thay đổi trên đã có code local và bản Android để xem thử; không đồng nghĩa toàn bộ UI-02 đã hoàn thành.

## Thứ tự thực hiện

| Thứ tự | Plan | Mục tiêu | Trạng thái |
| --- | --- | --- | --- |
| 1 | [UI-01](01-SHARED-STATES-AND-TYPOGRAPHY.md) | Loading/error/empty, chữ, spacing và nút dùng chung | Code/analyzer/155 test/build đạt; chờ review và QA thật/iOS |
| 2 | [UI-04](04-BOOKING-HEADER-AND-SEATS.md) | Header booking gọn, thẻ vé và sơ đồ ghế | Pending |
| 3 | [UI-05](05-CONCESSIONS.md) | Ảnh bắp nước, giá và bộ chọn số lượng | Pending |
| 4 | [UI-06](06-CHECKOUT-AND-PAYMENT.md) | Tổng tiền, countdown và thao tác thanh toán | Pending |
| 5 | [UI-02](02-HOME.md) | Giảm khoảng trống, cân đối khối PopBot | Pending, có thay đổi ảnh trước đợt này |
| 6 | [UI-03](03-DISCOVER-AND-SHOWTIMES.md) | Thẻ phim dễ đọc, giờ chiếu/trạng thái chọn rõ | Pending |
| 7 | [UI-07](07-ORDERS-AND-TICKET.md) | Tên dài, màu trạng thái, vé QR | Pending |
| 8 | [UI-08](08-ACCOUNT.md) | Thu gọn thông tin trùng, tên dài và retry | Pending |
| 9 | [UI-09](09-POPBOT-CHAT.md) | Nhận diện bot, gợi ý, chờ/retry | Pending |
| Xuyên suốt, chốt cuối | [UI-10](10-DEVICE-REVIEW.md) | So sánh trước/sau, thiết bị và phản hồi | Pending |

## Quy tắc nghiệm thu chung

- Kiểm tra chiều rộng 320, 360, 390, 430 logical px và tăng cỡ chữ: không overflow, không che CTA, không mất thông tin quan trọng.
- Vùng chạm tối thiểu 48 logical px; thân nút có thể gọn hơn nếu vùng chạm đủ lớn.
- Nội dung chính hướng tới 14–15 px; caption 11–12 px chỉ dùng cho thông tin phụ. Không tăng token toàn app mà chưa đối chiếu từng layout.
- Chữ cần đọc dùng màu đủ tương phản; màu disabled chỉ cho thành phần không thao tác được.
- UI giữ đầy đủ loading/error/empty/success và xử lý ảnh hỏng, tên dài, số tiền lớn.
- Chạy analyzer và build Android; chỉ bổ sung/chạy test liên quan nếu thay đổi state, routing hoặc nghiệp vụ. Không viết test chỉ để khẳng định padding/màu.
- Ghi ảnh trước/sau, màn hình/kích thước, dữ liệu và kết quả thực tế. QA iOS chưa chạy phải ghi rõ.
- Người dùng xem và phản hồi từng batch. Chỉ chốt Done sau khi đạt tiêu chí của plan và các ca QA còn mở đã được ghi rõ.

## Cách cập nhật kết quả

Mỗi plan ghi ngày, commit hoặc diff, file sửa, ảnh trước/sau và kết quả kiểm chứng. Kết quả UI-01: [UI01-RESULTS.md](UI01-RESULTS.md). Các plan khác giữ pending, dù một số thành phần dùng chung đã được cải thiện từ UI-01.

