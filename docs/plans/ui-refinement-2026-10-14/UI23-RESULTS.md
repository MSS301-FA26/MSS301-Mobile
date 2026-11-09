# UI-23 — Kết quả triển khai

Ngày: **01/11/2026**. Phạm vi: **Mobile UX**, diff local chưa commit.

## Đã làm

- Validator thuần xét từng hàng và segment theo tọa độ hiển thị; lối đi/OFF/maintenance chia segment, ghế đôi được tính bằng hai ghế vật lý. Ghế booked/held là ranh giới có người.
- Kiểm tra lựa chọn dự kiến khi chọn/bỏ ghế, giảm số vé và trước khi gửi hold bằng seat map mới. Nếu tạo ghế trống đơn lẻ, giữ lựa chọn trước đó và hiện thông báo chỉ rõ ghế.
- Không quy lỗi cho khoảng trống đơn lẻ đã tồn tại trước thao tác của người dùng. Các rule cũ về 8 ghế, ghế đôi và loại vé vẫn ở controller hiện hành.

## Kiểm chứng và giới hạn

- Unit test bao phủ 1/2 ghế trống, mép hàng, lối đi, maintenance, hàng khác, ghế đôi và orphan có sẵn; nhóm UI-06/UI-11/UI-22/UI-23 đạt **31/31 test**, analyzer và build Android đạt.
- **Hệ thống chưa đạt enforcement**: BE hiện chưa từ chối request hold trực tiếp tạo ghế lẻ. Plan này giới hạn sửa Mobile; cần BE kiểm tra nguyên tử trong `holdSeats`, trả lỗi có hàng/ghế, rồi kiểm thử hai khách và bypass frontend. Chưa chạy E2E race.
