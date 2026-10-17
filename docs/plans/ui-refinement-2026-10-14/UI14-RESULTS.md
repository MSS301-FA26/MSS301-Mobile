# UI-14 — Thêm combo ngay tại checkout

Ngày: **17/10/2026**. Baseline Mobile: `42588fb` + diff local.
Trạng thái: **đã triển khai; chờ người dùng review UI, QA iOS và sandbox E2E thật**.

## Kết quả triển khai

- Checkout vé có hàng combo cuộn ngang: ảnh crop, tên, giá catalog, số lượng và nút tăng/giảm. Chỉ hiển thị combo khả dụng hoặc combo đã chọn cần sửa; không gắn nhãn AI/bán chạy.
- “Xem tất cả” mở sheet cả combo và sản phẩm, dùng lại thẻ sản phẩm/crop/chi tiết món hiện có. Sheet có countdown và tổng báo giá để kiểm tra; checkout vẫn giữ tổng/CTA cố định.
- Mỗi thay đổi giữ cùng giỏ của bước Bắp nước, khóa theo `(isCombo, productId)`, số lượng 0–8. Có thể giảm món không còn khả dụng để sửa giỏ; bắp nước vẫn tùy chọn.
- Khả dụng dùng `FoodProductDto.isAvailable` hiện hành: chỉ ACTIVE; LOW_STOCK và các trạng thái khác chưa được BE quote chấp nhận. Không đổi contract sang cho mua LOW_STOCK trong batch này.
- Chỉ sửa ở checkout khi booking HOLDING, còn deadline và chưa có payment. PENDING_PAYMENT/đã có payment chỉ đọc; controller cũng kiểm tra trước request.
- Các thay đổi được gửi tuần tự bằng khóa busy; khóa +/- và thanh toán suốt `updateItems → quote`. Bấm chồng không gửi mutation song song.
- `quoteNeedsRefresh` đánh dấu giỏ chưa được xác nhận: update thành công/quote lỗi vẫn lưu snapshot server, giữ giỏ cần sửa và khóa thanh toán theo quote cũ. Hiển thị lỗi, tổng cũ chưa xác nhận và nút thử báo giá lại.
- Báo giá mới phải khớp tổng booking rồi mới mở thanh toán; thông báo người dùng kiểm tra tổng mới, thao tác thanh toán tiếp theo là xác nhận. Không cộng lại phụ thu hoặc tự lấy giá catalog làm tổng xác nhận.
- Giữ vé/ghế/viewerAge của flow hiện hành và deadline BE. Không gọi tạo hold mới, không cộng thời gian; kiểm tra hết hạn sau request cập nhật và sau request quote.
- Generation thay đổi khi nạp booking khác hoặc phiên auth đổi: response cũ không ghi đè booking/phiên mới. Không tự bỏ món khi hết hàng hoặc giả định rollback sau lỗi.
- Đơn bắp nước độc lập, login/register, BE/DB, voucher/điểm và UI Home không đổi trong batch này. Plan 15 mới ở trạng thái planned.

## File chính

- `lib/features/booking/application/booking_completion_controller.dart`: trạng thái quote cần cập nhật, thao tác sửa tại checkout, khóa request/thanh toán, giữ server snapshot và guard generation/deadline.
- `lib/features/booking/presentation/widgets/checkout_combo_picker.dart`: combo ngang, sheet món và trạng thái cập nhật/lỗi.
- `lib/features/booking/presentation/pages/checkout_page.dart`: tích hợp picker, nhãn cập nhật quote và điều kiện CTA.
- `test/remote_booking_completion_test.dart`: thêm 8 ca nghiệp vụ UI-14.
- `test/ui14_checkout_combo_test.dart`: 6 ca widget ở 320/360/390/430, chữ lớn, sheet và khóa busy/quote cũ.

## Kiểm chứng

- **55 test liên quan đạt**: UI-14 widget + remote booking completion + UI-13 + UI-06 + completion/account.
- Các ca mới: đồng bộ checkout/Bắp nước, deadline/vé không đổi, item/combo trùng ID, cap 8/xóa về 0, double tap/payment khi busy, update thành công/quote lỗi và retry, món hết giữa request và gỡ món, hết hạn giữa request, logout, đổi booking, payment chỉ đọc.
- Widget kiểm tra tăng từ checkout chặn CTA theo quote cũ, sheet có countdown/tổng và các khóa item/combo, 4 kích thước với text scale 1.6, không overflow.
- Analyzer sạch; build Android debug đạt. Các lần kiểm tra cuối được ghi ở `D:/MSS/.qa-runtime/ui14-analyze.log`, `ui14-build.log`, `ui14-tests.log`.
- Ảnh fixture đã kiểm tra bố cục: `D:/MSS/.qa-runtime/ui14-fixture-inline.png`, `ui14-fixture-sheet.png`; log xuất ảnh `ui14-capture.log`. Đây là dữ liệu test, ảnh mạng fallback và một số font nút không đại diện thiết bị thật. Không phải chứng cứ thanh toán BE; file capture tạm đã gỡ khỏi source.

## Còn QA / review

- Người dùng review checkout và sheet trên emulator với giỏ thực tế. Chưa có ảnh trước/sau cùng một đơn thật.
- Sandbox E2E thật: sửa món → tổng mới → thanh toán → xác nhận BE → QR, cùng tình huống hết hàng/giá đổi thật. Không tạo đơn hoặc thanh toán mới chỉ để lấy ảnh trong batch này.
- iOS, font lớn trên thiết bị thật và review chuyển động/ảnh sản phẩm qua mạng chậm.

Không tự đánh dấu nghiệm thu E2E chỉ từ test giả lập gateway hoặc build thành công.
