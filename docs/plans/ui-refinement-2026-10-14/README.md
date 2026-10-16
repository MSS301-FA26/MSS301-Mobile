# Kế hoạch tinh chỉnh UI Mobile

Ngày lập: **14/10/2026**. Người yêu cầu: **Tzee314**.
Trạng thái: **UI-01–10 đã triển khai/QA và được người dùng xác nhận UI ổn ngày 16/10. UI-11 đã triển khai, 40 test/analyzer/build Android đạt, chờ review. Các ca tích hợp còn mở được giữ riêng: iOS, chat/ví/recommendation và E2E payment/QR.**
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

- Ngày 16/10, người dùng xác nhận “các plan khác đã chỉnh đã oke rồi” và yêu cầu chuyển sang UI-11. Ghi nhận duyệt giao diện các batch đã chỉnh trước UI-11; các dòng chờ review trong kết quả lịch sử được cập nhật bởi xác nhận này. Không coi đây là bằng chứng QA API/iOS/E2E thành công.

- Poster Home: đã thử nền blur, ảnh chính giữ tỷ lệ; tiếp tục chờ phản hồi thẩm mỹ. Chỉ chuyển sang crop khi người dùng yêu cầu.
- Banner Home: crop phủ kín khung, dùng focalPoint; ưu tiên ảnh desktop.
- Logic banner và map 17 ảnh cố định đã đồng bộ FE theo lựa chọn của người dùng. Giữ lựa chọn này trong đợt UI; map ID có thể lệch tên phim trên DB khác.
- Các thay đổi trên đã có code local và bản Android để xem thử; không đồng nghĩa toàn bộ UI-02 đã hoàn thành.

## Thứ tự thực hiện

| Thứ tự | Plan | Mục tiêu | Trạng thái |
| --- | --- | --- | --- |
| 1 | [UI-01](01-SHARED-STATES-AND-TYPOGRAPHY.md) | Loading/error/empty, chữ, spacing và nút dùng chung | Code/analyzer/155 test/build đạt; chờ review và QA thật/iOS |
| 2 | [UI-04](04-BOOKING-HEADER-AND-SEATS.md) | Header booking gọn, thẻ vé và sơ đồ ghế | Code/21 test/analyzer đạt; chờ QA booking thật, review và iOS |
| 3 | [UI-05](05-CONCESSIONS.md) | Ảnh bắp nước, giá và bộ chọn số lượng | UI được người dùng duyệt 15/10; code/test/build đạt, còn QA iOS/E2E |
| 4 | [UI-06](06-CHECKOUT-AND-PAYMENT.md) | Tổng tiền, countdown và thao tác thanh toán | UI được người dùng duyệt 15/10; analyzer/34 test/build đạt, còn QA iOS/sandbox E2E |
| 5 | [UI-02](02-HOME.md) | Giảm khoảng trống, cân đối khối PopBot | Analyzer/28 test/build/Android đạt; chờ phản hồi UI và iOS |
| 6 | [UI-03](03-DISCOVER-AND-SHOWTIMES.md) | Thẻ phim dễ đọc, giờ chiếu/trạng thái chọn rõ | Người dùng xác nhận danh sách phim khá ổn; còn QA suất thật và iOS |
| 7 | [UI-07](07-ORDERS-AND-TICKET.md) | Tên dài, màu trạng thái, vé QR | Analyzer/30 test/build Android đạt; chờ review và QA thiết bị/check-in |
| 8 | [UI-08](08-ACCOUNT.md) | Thu gọn thông tin trùng, tên dài và retry | Hoàn tất code/analyzer/23 test/build Android; chờ review và iOS |
| 9 | [UI-09](09-POPBOT-CHAT.md) | Nhận diện bot, gợi ý, chờ/retry | Analyzer/19 test/build Android đạt; API chat thật trả 403, còn QA AI thành công và iOS |
| Xuyên suốt, chốt đợt UI-01–10 | [UI-10](10-DEVICE-REVIEW.md) | So sánh trước/sau, thiết bị và phản hồi | Đã QA: 218 test/analyzer/build đạt, Android có ảnh; nghiệm thu toàn bộ còn mở, xem UI10-RESULTS |

## Đợt tiếp theo sau UI-10 — tham khảo ảnh ngày 15/10

**UI-11 đã triển khai ngày 16/10; UI-12–14 chưa triển khai.** Theo dõi kết quả UI-11 và các ca tích hợp còn mở trong UI10-RESULTS trước khi nghiệm thu toàn bộ. Đây là số thứ tự **UI**, không thay thế plan chức năng 11–12 hiện có.

| Thứ tự sau UI-10 | Plan | Điều chỉnh | Phụ thuộc chính |
| --- | --- | --- | --- |
| 1 | [UI-11](11-MOVIE-DETAIL-AND-RELATED.md) | Đã triển khai: banner/trailer thật, poster, metadata, nội dung mở rộng, phim liên quan | 40 test/analyzer/build Android đạt; recommendation 403, còn review/iOS |
| 2 | [UI-12](12-CONCESSIONS-CATALOG-AND-COMBO.md) | Bắp nước: ảnh và nội dung combo rõ, nhóm Combo/Sản phẩm, chi tiết món | Giữ hành vi UI-05 đã duyệt; thành phần/tùy chọn combo chỉ khi có contract |
| 3 | [UI-13](13-CHECKOUT-MOVIE-AND-PRICE-SUMMARY.md) | Tổng thanh toán: poster + thông tin suất, vé theo ghế, món và dòng tiền | Phát triển UI-06; dữ liệu quote/snapshot BE |
| 4 | [UI-14](14-ADD-COMBO-IN-CHECKOUT.md) | Thêm/giảm combo ngay ở checkout, lấy báo giá và xác nhận lại | UI-12/UI-13; bổ sung state sửa giỏ, không reset hold hoặc sửa sau tạo payment |

### Cách dùng ảnh tham khảo

- Ảnh 4, chi tiết phim Shaun the Sheep: tham khảo banner/trailer, poster, metadata, mô tả và nút đặt vé cố định cho UI-11. Phim liên quan dùng API gợi ý đã có; ưu đãi chỉ thêm nếu có nguồn và trang đích thật.
- Ảnh 3, danh sách combo: tham khảo cách đặt ảnh, mô tả thành phần, giá và bộ chọn số lượng cho UI-12.
- Ảnh 1–2, tổng thanh toán CGV/Cinestar: tham khảo tóm tắt phim/vé, phân nhóm dòng tiền và hàng thêm combo cho UI-13/UI-14.
- Giữ nhận diện đen–vàng CinePremier và dữ liệu/ảnh sản phẩm của hệ thống. Không sao chép logo, giá, thời gian hold, chương trình giảm giá hoặc các phương thức thanh toán trong ảnh vào app.
- Sau mỗi plan mới vẫn có QA thiết bị và review người dùng; UI-10 là mốc chốt đợt đầu, không miễn QA cho đợt tiếp theo.

## Quy tắc nghiệm thu chung

Kết quả UI-06: [UI06-RESULTS.md](UI06-RESULTS.md).
Kết quả UI-07: [UI07-RESULTS.md](UI07-RESULTS.md).
Kết quả UI-08: [UI08-RESULTS.md](UI08-RESULTS.md).
Kết quả UI-09: [UI09-RESULTS.md](UI09-RESULTS.md).
Kết quả UI-10: [UI10-RESULTS.md](UI10-RESULTS.md).
Kết quả UI-11: [UI11-RESULTS.md](UI11-RESULTS.md).

- Kiểm tra chiều rộng 320, 360, 390, 430 logical px và tăng cỡ chữ: không overflow, không che CTA, không mất thông tin quan trọng.
- Vùng chạm tối thiểu 48 logical px; thân nút có thể gọn hơn nếu vùng chạm đủ lớn.
- Nội dung chính hướng tới 14–15 px; caption 11–12 px chỉ dùng cho thông tin phụ. Không tăng token toàn app mà chưa đối chiếu từng layout.
- Chữ cần đọc dùng màu đủ tương phản; màu disabled chỉ cho thành phần không thao tác được.
- UI giữ đầy đủ loading/error/empty/success và xử lý ảnh hỏng, tên dài, số tiền lớn.
- Chạy analyzer và build Android; chỉ bổ sung/chạy test liên quan nếu thay đổi state, routing hoặc nghiệp vụ. Không viết test chỉ để khẳng định padding/màu.
- Ghi ảnh trước/sau, màn hình/kích thước, dữ liệu và kết quả thực tế. QA iOS chưa chạy phải ghi rõ.
- Người dùng xem và phản hồi từng batch. Chỉ chốt Done sau khi đạt tiêu chí của plan và các ca QA còn mở đã được ghi rõ.

## Cách cập nhật kết quả

Mỗi plan ghi ngày, commit hoặc diff, file sửa, ảnh trước/sau và kết quả kiểm chứng. Kết quả: [UI01-RESULTS.md](UI01-RESULTS.md), [UI02-RESULTS.md](UI02-RESULTS.md), [UI03-RESULTS.md](UI03-RESULTS.md), [UI04-RESULTS.md](UI04-RESULTS.md), [UI05-RESULTS.md](UI05-RESULTS.md), cùng UI06–UI10-RESULTS ở trên. Trạng thái từng batch dựa vào bằng chứng và phản hồi thực tế; không tự duyệt batch khác từ việc dùng chung component.

