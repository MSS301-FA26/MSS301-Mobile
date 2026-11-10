# UI-17 — Thanh toán VNPay quay lại app

Ngày lập: **17/10/2026**. Ưu tiên: **P0**. Trạng thái ngày 19/10: **đã triển khai Mobile bằng WebView; chờ QA sandbox thật trên Android/iOS**. Xem [UI17-RESULTS.md](UI17-RESULTS.md).

## Nguyên nhân hiện tại

`UrlPaymentLauncher` mở browser/custom tab (`LaunchMode.inAppBrowserView`), không phải WebView có NavigationDelegate. BE ký `vnp_ReturnUrl` từ `VNPAY_RETURN_URL`; `PaymentController.vnpayReturn` thử xử lý kết quả rồi redirect theo `PAYMENT_SUCCESS_REDIRECT_URL`. Người dùng quan sát trang FE `localhost:3000` là browser redirect, không phải Mobile chủ động gọi API FE để xác nhận thành công.

Mobile hiện refresh khi resume/poll nhưng chưa có receiver link để định tuyến cold start/warm start trở lại đúng giao dịch.

**Phương án đã chọn:** VNPay xác nhận [MobileApp có thể mở URL thanh toán trong WebView và đóng WebView để về app](https://sandbox.vnpayment.vn/apis/docs/faqs/). Mobile dùng WebView cho vé và đơn bắp nước. BE vẫn xử lý URL return đã ký, rồi 302 tới FE redirect; Mobile chặn đúng origin + path của FE redirect trước khi WebView tải trang FE. Chặn URL này chỉ là tín hiệu quay về; trạng thái giao dịch luôn đọc lại từ BE.

`PAYMENT_REDIRECT_URL` trong Mobile phải khớp `PAYMENT_SUCCESS_REDIRECT_URL` của payment-service; mặc định `http://localhost:3000/payment-callback` cho môi trường hiện tại. Nếu BE đổi redirect, truyền `--dart-define=PAYMENT_REDIRECT_URL=<URL>` khi build/chạy. Trên emulator, BE return `localhost:8080` cần `adb reverse tcp:8080 tcp:8080`. Thiết bị thật cần return HTTPS truy cập được từ thiết bị.

## Phương án triển khai và điều kiện

1. Lưu checkpoint trước mở cổng: user hiện tại, paymentId, loại BOOKING/FOOD_ORDER và ID đơn; không lưu token vào URL hoặc log payment URL đã ký.
2. Ưu tiên trải nghiệm thanh toán có nút **Quay lại ứng dụng** luôn tìm được. Khảo sát VNPay/bank có cho embedded WebView không trước khi chọn plugin; kiểm tra Android/iOS, OTP, bank app và 3DS nếu có.
3. Nếu WebView được hỗ trợ: triển khai màn handoff có header/back. Nhận diện đúng origin/path return BE và redirect FE đã cấu hình bằng navigation delegate; xử lý chuyển về app trước khi browser cố tải localhost:3000. Gọi đồng bộ trạng thái BE và đóng màn handoff, không parse query thành trạng thái SUCCESS.
4. Nếu phải dùng external browser/custom tab: thêm App Links/Universal Links hoặc scheme receiver được validate; cần landing HTTPS trả kết quả có nút Quay lại app và fallback khi chưa cài app. Phần landing/return routing thuộc chủ thể BE/FE, có contract phân biệt client Web/Mobile. Không đổi redirect toàn cục thành scheme làm mất luồng Web.
5. Route vào đúng booking payment hoặc food order; restore warm/cold start, kiểm tra ownership hiện tại. Link lặp/sai ID/đổi tài khoản không truy cập đơn người khác và không tạo payment mới.
6. Khi trở lại: payment lookup/sync → đọc lại booking/food order. Payment SUCCESS nhưng booking chưa PAID hiển thị đang xác nhận; chỉ mở QR khi điều kiện BE của từng loại đơn đạt. Có retry/back-to-orders và xử lý app bị kill.
7. Giữ đường quay lại thủ công trên app cho trường hợp hệ điều hành không tự mở app. Nút nằm trên trang web đòi hỏi landing thực sự; Mobile đơn lẻ không thể chèn nút vào trang VNPay/FE trong external browser.

## Quy tắc bảo vệ

- Không sửa URL VNPay đã ký, không tự thay `vnp_ReturnUrl`, không tắt xác thực checksum/IPN.
- Không coi query `responseCode=00`, browser đóng, event resume hoặc deep link là bằng chứng đã trả tiền.
- Không hủy đơn đã thanh toán khi event booking cập nhật chậm. Không kéo dài hold vì quay lại app, không gửi lặp checkout/create-payment.
- Không sửa source/runtime BE/FE trong batch Mobile nếu chưa có phạm vi cụ thể được chốt.

## File / nghiệm thu

`payment_launcher.dart`, checkpoint và payment/order controllers, router, Android manifest/iOS URL/app-link config; handoff UI mới nếu được hỗ trợ. Cập nhật tài liệu return contract trước khi tích hợp phía server.

QA sandbox thật cho vé và food: success/fail/cancel/timeout, return mất mạng, app mở/đóng/bị kill, đổi user, link giả/lặp, event chậm, bank app quay lại. Web tiếp tục hoạt động; Mobile không mắc kẹt ở localhost:3000. Kết quả `UI17-RESULTS.md` phân biệt Mobile-only fallback và automatic return end-to-end.
