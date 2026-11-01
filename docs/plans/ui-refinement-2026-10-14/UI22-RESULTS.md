# UI-22 — Kết quả triển khai

Ngày: **01/11/2026**. Phạm vi: **local MVP trên Mobile**, diff local chưa commit.

## Đã làm

- Lưu movie ID và thời điểm lưu vào secure storage theo user ID; chỉ cập nhật biểu tượng sau khi ghi thành công. Đổi user/logout không hiển thị danh sách user cũ.
- Route đăng nhập bảo vệ danh sách muốn xem, entry ở Tài khoản và chi tiết phim. Danh sách đọc lại dữ liệu phim từ catalog, có trạng thái trống/lỗi, retry, bỏ lưu và hoàn tác.
- Giao diện ghi rõ “Chỉ lưu trên thiết bị này”. Không tuyên bố đồng bộ web, nhiều thiết bị hay tài khoản từ BE.

## Kiểm chứng và giới hạn

- Test lưu rồi tạo lại provider, tách tài khoản và lỗi ghi persistence đạt; nhóm UI-06/UI-11/UI-22/UI-23 đạt **31/31 test**, analyzer và build Android đạt.
- Chưa QA restart ứng dụng trên thiết bị thật, offline/online, phim bị xóa từ API thật và chuyển tài khoản khi request đang bay.
- **Remote sync chưa có** vì Gateway/BE chưa cung cấp contract watchlist. Cần endpoint, ownership và kế hoạch migration riêng nếu muốn đồng bộ.
