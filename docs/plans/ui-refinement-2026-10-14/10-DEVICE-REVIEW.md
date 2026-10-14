# UI-10 — QA thiết bị và nghiệm thu giao diện

Trạng thái: **pending**. Chạy cùng từng batch và chốt cuối.
Liên quan: plan chức năng 12. Áp dụng tiêu chí chung trong [README](README.md).

## Ma trận kiểm tra

| Nhóm | Ca bắt buộc |
| --- | --- |
| Kích thước | 320/360/390/430 logical px; chữ lớn, SafeArea và bàn phím |
| Home/ảnh | Banner crop LEFT/CENTER/RIGHT; poster ngang/dọc/hỏng; swipe/đổi tab và CTA |
| Dữ liệu | Loading, refresh, empty, lỗi mạng, load more lỗi; tên dài/số tiền lớn |
| Booking | Vé bị hạn chế, ghế đôi, 8 ghế, giữ deadline và leave guard qua các màn |
| Bắp nước | Ảnh lỗi, item/combo cùng ID, giỏ trống, giới hạn 8, không khả dụng và giá đổi |
| Payment/QR | Chờ xác minh, resume/expiry, QR chỉ đúng trạng thái; lưu/chia sẻ lỗi |
| Account/chat | Tên dài, ví lỗi; keyboard chat, pending/retry/reset và đổi user |
| Điều hướng | Back, tab, deep link hiện có; CTA không bị che hoặc đổi ý nghĩa |

## Bằng chứng cần lưu

- Ảnh trước/sau cùng kích thước, cùng dữ liệu và vị trí cuộn.
- Commit/diff, ngày, thiết bị, build flags và runtime. Phân biệt dữ liệu API với preview.
- Kết quả analyzer/build; test có ý nghĩa cho state/routing bị thay đổi.
- Phản hồi người dùng theo batch và lỗi còn mở, ghi rõ ca chưa chạy.

## Tiêu chí chốt

Mỗi plan UI đạt nghiệm thu riêng; các flow nghiệp vụ không regression trong phạm vi thay đổi. Android được kiểm tra thực tế; iOS chưa có thiết bị/build phải ghi chưa kiểm tra. Không dùng screenshot/fixture để kết luận VNPay hoặc check-in thật đã thành công.

