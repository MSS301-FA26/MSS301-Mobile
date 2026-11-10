# UI-17 — Kết quả quay lại app sau VNPay

Ngày triển khai: **19/10/2026**. Phạm vi sửa: Mobile. Không sửa BE, FE, DB hay URL VNPay đã ký.

## Đã làm

- Vé và đơn bắp nước mở URL VNPay do BE trả về trong WebView có thanh điều hướng, nút **Về ứng dụng**, **Kiểm tra đơn** và phương án mở trình duyệt ngoài.
- WebView để callback `/api/v1/payments/vnpay/return` đến BE xử lý trước. Chỉ sau khi BE chuyển hướng sang URL FE đúng origin/path mới đóng WebView; không coi query VNPay là bằng chứng thanh toán.
- Khi đóng WebView, vé tra lại payment và booking; chỉ mở vé QR khi payment SUCCESS và booking PAID/USED. Đơn bắp nước gọi sync để lấy trạng thái và mã QR từ BE.
- Trước khi mở VNPay, lưu checkpoint theo user gồm paymentId, loại đơn và orderId trong secure storage. Khi app khởi động lại, xác minh payment/order và user với BE rồi đưa về đúng màn giao dịch; link/ID không thuộc user bị chặn. Giao dịch cuối cùng xóa checkpoint tương ứng.
- `PAYMENT_REDIRECT_URL` mặc định `http://localhost:3000/payment-callback`, cần khớp `PAYMENT_SUCCESS_REDIRECT_URL` của BE. Browser ngoài vẫn là đường dự phòng; quay lại app thủ công sẽ kích hoạt đồng bộ trạng thái.

## Đã kiểm tra

- Tài liệu [FAQ VNPay](https://sandbox.vnpayment.vn/apis/docs/faqs/) xác nhận cách mở URL thanh toán trong WebView cho MobileApp.
- **46 test liên quan đạt** trong lần chạy đầu; sau khi thêm ca chặn payment của user khác, **24 test payment/booking đạt**. Test URL matcher xác nhận chỉ nhận FE redirect đã cấu hình, không chặn callback BE hay domain khác. `flutter analyze` sạch; build APK debug Android và cài trên `emulator-5554` thành công.
- Emulator có `adb reverse tcp:8080 tcp:8080` cho BE return local.

## Còn mở để nghiệm thu

- Chưa chạy giao dịch VNPay sandbox thật cho cả vé và bắp nước: success/fail/cancel/timeout, OTP, bank app, 3DS, mạng lỗi, callback chậm, app bị kill, iOS và nhiều tài khoản. Không ghi nhận Plan 17 hoàn tất E2E trước khi các ca này đạt.
- Khi chọn **Mở trình duyệt** ngoài, BE vẫn chuyển tới FE `localhost:3000`; Mobile không chèn được nút lên trang đó. Muốn browser tự quay lại app trên thiết bị thật cần landing HTTPS/App Links do BE/FE cung cấp, với contract riêng cho Mobile mà không đổi redirect toàn cục của Web.
- Với `VNPAY_RETURN_URL=http://localhost:8080/...`, emulator cần adb reverse; thiết bị thật cần callback HTTPS truy cập từ Internet. Đây là điều kiện môi trường để WebView nhận redirect hoàn chỉnh.
