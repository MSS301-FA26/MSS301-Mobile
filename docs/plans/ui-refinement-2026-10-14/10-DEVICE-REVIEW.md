# UI-10 — QA thiết bị và nghiệm thu giao diện

Trạng thái: **đã thực hiện đợt QA tổng hợp, cập nhật 16/10/2026**. Analyzer sạch, **218 test đạt**, build Android thành công. Android emulator đã kiểm tra ngày 15/10; **nghiệm thu toàn bộ còn mở** vì cần review, iOS, sandbox E2E và quét QR thật.
Liên quan: plan chức năng 12. Áp dụng tiêu chí chung trong [README](README.md).

Kết quả và các ca còn mở: [UI10-RESULTS.md](UI10-RESULTS.md).

## Đã thực hiện

- Rà toàn bộ test và kết quả UI-01–09; chạy analyzer, toàn bộ test và build Android trên source hiện tại.
- Sửa năm ca test cũ không còn khớp với UI: đợi báo giá ghế hoàn tất trước thao tác tiếp tục; xác định đúng badge trạng thái thay vì mọi dòng chữ; cập nhật nhãn mã đơn và tên phim theo dữ liệu hiển thị.
- Bổ sung 360/390 px vào test sơ đồ ghế và checkout, bên cạnh 320/430 px đã có.
- Kiểm tra dữ liệu thật trên Android: Home, Khám phá, Lịch chiếu, Đơn của tôi, Tài khoản, bắp nước và vé PAID hiện có.
- Kiểm tra emulator ở 320 logical px, font scale 1.6; lưu ảnh Home/Khám phá/Tài khoản. Đã trả density và font scale về cấu hình ban đầu.
- Tổng hợp ảnh minh chứng, phản hồi theo batch và danh sách việc còn lại. Không coi test dùng fixture là thanh toán hoặc check-in thật.

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

