# UI-01 — Kết quả triển khai

Ngày: 14/10/2026. Baseline Mobile `fcf3708`, diff local chưa commit.

## Thay đổi

- `repository_skeleton.dart`: placeholder tĩnh theo layout, loại khỏi semantics để không đọc thông tin giả.
- `repository_state_pane.dart`: loading có cấu trúc; error/empty riêng; retry và CTA; error cuộn được trên màn thấp/chữ lớn, tránh thông báo screen reader lặp.
- Theme/body/caption, AppButton và tab controls: tăng độ dễ đọc, vùng chạm 48 px, chiều cao nút theo cỡ chữ, disabled rõ ràng.
- Home/Discover/Orders/Account/Showtimes/Food: skeleton theo màn; giữ controls và dữ liệu đã tải khi refresh lỗi; có retry tại vùng lỗi.
- Discover: sửa lifecycle pagination để load more/retry không fetch lại/trộn trang và không nhận kết quả query cũ.
- Wallet: nhận biết FutureBuilder error trước loading, retry thay cho spinner vô hạn. Không triển khai thao tác tài chính mới.

## Kiểm chứng

| Kiểm tra | Kết quả |
| --- | --- |
| Flutter analyze --no-pub | PASS — No issues found |
| Flutter test --no-pub | PASS — 155 tests |
| Bốn test UI-01 | PASS — retry/query cũ và layout nhỏ/chữ lớn |
| Android APK debug, UI_PREVIEW=false | Build PASS; cài -r giữ dữ liệu |
| Emulator Khám phá loading | Search/tabs còn thao tác được, skeleton phim hiển thị |
| QA màn có dữ liệu thật | Chưa hoàn tất do môi trường API local không trả dữ liệu lúc kiểm tra cuối |
| iOS | Chưa kiểm tra |

Logs: `D:\MSS\.qa-runtime\ui01-full-tests.log`, `ui01-build.log`, `ui01-target-tests.log`. Analyzer cuối chạy trực tiếp sau sửa lỗi const; log analyzer trước đó chứa lỗi đã sửa nên không dùng làm bằng chứng kết quả cuối.

Ảnh loading mới: [Khám phá](/D:/MSS/.qa-runtime/ui01-discover.png). Ảnh `ui01-orders.png` là trang login sau khi mở Orders và không được dùng xác nhận UI Orders.

## Giới hạn và việc còn chờ

Cập nhật sau đó ngày 14/10: đã xác định lỗi kết nối là WSL chiếm `[::1]:8080`. Mở thêm gateway runtime port 18081, cập nhật relay Mobile và kiểm tra phim/banner/rạp trả 200 qua relay; Home đã hiển thị dữ liệu thật trên emulator. Lỗi tải trước đó không phải do layout UI-01. Các ca nghiệm thu toàn bộ màn/kích thước và iOS dưới đây vẫn chưa chốt.

- Cần người dùng xem bản mới và phản hồi thẩm mỹ.
- QA đầy đủ màn có dữ liệu, Android ở các kích thước còn lại và iOS chưa hoàn tất.
- Unit/widget dùng fixture không xác nhận thanh toán, check-in, withdrawal hoặc chat AI thật đã hoạt động.
- Không sửa source BE/FE, schema DB hoặc các MD cũ ngoài folder UI do mình tạo.
- Các plan UI-02 đến UI-10 chưa được đánh dấu Done từ đợt này.
