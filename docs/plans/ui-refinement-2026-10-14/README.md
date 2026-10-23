# Kế hoạch tinh chỉnh UI Mobile

Ngày lập: **14/10/2026**. Người yêu cầu: **Tzee314**.
Trạng thái: **UI-01–10 đã triển khai/QA và được người dùng xác nhận UI ổn ngày 16/10. UI-11/UI-12 đã triển khai, lần lượt 40/59 test cùng analyzer/build Android đạt, chờ review. Các ca tích hợp còn mở được giữ riêng: iOS, chat/ví/recommendation và E2E payment/QR.**
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

**UI-11/UI-12/UI-13 đã triển khai ngày 16/10; UI-14/UI-15 đã triển khai ngày 17/10, chờ review và QA thiết bị/tích hợp còn mở.** UI-15 có 42 test/analyzer/build Android đạt và đã kiểm tra emulator với API thật. UI-13 có 56 test liên quan, analyzer/build Android đạt, đã cài emulator; chờ review và QA iOS/sandbox thật. Theo dõi kết quả từng batch và các ca tích hợp còn mở trong UI10-RESULTS trước khi nghiệm thu toàn bộ. Đây là số thứ tự **UI**, không thay thế plan chức năng 11–12 hiện có.

| Thứ tự sau UI-10 | Plan | Điều chỉnh | Phụ thuộc chính |
| --- | --- | --- | --- |
| 1 | [UI-11](11-MOVIE-DETAIL-AND-RELATED.md) | Đã triển khai: banner/trailer thật, poster, metadata, nội dung mở rộng, phim liên quan | 40 test/analyzer/build Android đạt; recommendation 403, còn review/iOS |
| 2 | [UI-12](12-CONCESSIONS-CATALOG-AND-COMBO.md) | Đã triển khai: ảnh lớn, nhóm Combo/Sản phẩm, sheet chi tiết, tóm tắt booking | 59 test/analyzer/build Android đạt; catalog thật 200; còn review/iOS/E2E |
| 3 | [UI-13](13-CHECKOUT-MOVIE-AND-PRICE-SUMMARY.md) | Đã triển khai: poster + thông tin suất, vé theo ghế, ảnh món, sửa giỏ và dòng tiền | 56 test/analyzer/build Android đạt; chờ review/iOS/sandbox E2E |
| 4 | [UI-14](14-ADD-COMBO-IN-CHECKOUT.md) | Đã triển khai: thêm/giảm combo ở checkout, sheet toàn bộ món, cập nhật quote và khóa tổng cũ | 55 test liên quan; chờ review/iOS/sandbox E2E; xem UI14-RESULTS |
| 5 | [UI-15](15-HOME-3D-MOVIE-CAROUSEL.md) | Đã triển khai hai tab phim và coverflow 3D; giữ mua vé nhanh/rạp/hero | 42 test/analyzer/build đạt; emulator/API thật đã kiểm tra, chờ review/iOS/TalkBack |

## Bổ sung theo phản hồi ngày 17/10 — Plan 16–23

Trạng thái: **UI-16 và UI-17 đã triển khai phía Mobile ngày 19/10; UI-18 đã triển khai ngày 23/10, Android/API thật đã kiểm tra, còn QA iOS/thiết bị thật. UI-19–23 chưa triển khai.** Nhận xét, bằng chứng FE/BE và dependencies: [REVIEW-2026-10-17.md](REVIEW-2026-10-17.md).

| Plan | Ưu tiên | Nội dung |
| --- | --- | --- |
| [UI-16](16-REALTIME-SEAT-AVAILABILITY.md) | P0 | Mobile đã làm mới/chặn ghế, preflight và conflict; [kết quả](UI16-RESULTS.md), còn QA hai khách và BE occupancy |
| [UI-17](17-PAYMENT-RETURN-TO-APP.md) | P0 | WebView VNPay quay lại app cho vé và food; [kết quả](UI17-RESULTS.md), còn QA sandbox/iOS và browser landing |
| [UI-18](18-CINEMA-DIRECTORY.md) | P1 | Đã triển khai danh sách, chi tiết, rạp ưu tiên và lịch theo `cinemaId`; [kết quả](UI18-RESULTS.md) |
| [UI-19](19-UNIFIED-SHOWTIME-FILTERS.md) | P1 | Lịch chiếu chung với bộ lọc phim/rạp/ngày có thể xóa |
| [UI-20](20-PAYMENT-AND-SUCCESS-REDESIGN.md) | P1 | Bố cục thanh toán/kết quả thống nhất cho vé và food |
| [UI-21](21-MOVIE-DETAIL-REFINEMENT.md) | P2 | Chi tiết phim và entry lịch chiếu/watchlist |
| [UI-22](22-WATCHLIST.md) | P2 | Danh sách muốn xem; phân biệt local MVP và remote sync |
| [UI-23](23-SINGLE-SEAT-GAP-RULE.md) | P1 | Rule ghế trống đơn lẻ: UX Mobile và enforcement BE |

Thứ tự đề xuất: **16 → 17 → 18 → 19 → 23 → 20 → 22 → 21**. Các plan chức năng gốc đã được gom vào [functional-completion-2026-10-11](../functional-completion-2026-10-11/00-MOBILE-COMPLETION-ROADMAP.md), giữ nguyên nội dung lịch sử.

### Cách dùng ảnh tham khảo UI-11–14

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
Kết quả UI-12: [UI12-RESULTS.md](UI12-RESULTS.md).
Kết quả UI-13: [UI13-RESULTS.md](UI13-RESULTS.md).
Kết quả UI-14: [UI14-RESULTS.md](UI14-RESULTS.md).
Kết quả UI-15: [UI15-RESULTS.md](UI15-RESULTS.md).
Kết quả UI-16: [UI16-RESULTS.md](UI16-RESULTS.md).
Kết quả UI-17: [UI17-RESULTS.md](UI17-RESULTS.md).
Kết quả UI-18: [UI18-RESULTS.md](UI18-RESULTS.md).

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

