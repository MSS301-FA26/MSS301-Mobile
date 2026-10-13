# Tích hợp các thẻ tiện ích Trang chủ — 14/10/2026

## Thay đổi Mobile

- Khôi phục bố cục bốn thẻ trên một hàng với màu/icon ban đầu.
- Bắp & Nước mở màn hình đặt riêng: chọn rạp nhận hàng, sản phẩm/combo, tối đa 8 mỗi loại. Dùng catalog thật; chỉ cho chọn trạng thái ACTIVE theo quy tắc checkout BE hiện tại. Không tự thay thế danh mục lỗi bằng dữ liệu mẫu.
- Tạo đơn qua `POST /api/v1/food-orders`, gửi định danh sản phẩm/combo và số lượng, không gửi giá từ Mobile. Đơn nhận lại giá từ BE; nếu khác ước tính, nút thanh toán yêu cầu xác nhận giá mới.
- Chi tiết đơn hỗ trợ VNPay, tái sử dụng payment đang chờ, đồng bộ trạng thái, hủy đơn chưa thanh toán, thời gian hết hạn và lịch sử. QR chỉ hiện khi BE trả trạng thái PAID và mã QR. Không đánh dấu thành công chỉ vì đã mở cổng thanh toán.
- Khi kết quả tạo đơn không xác định do mất kết nối/lỗi máy chủ, chặn gửi lại và hướng người dùng kiểm tra lịch sử để tránh trùng đơn.
- PopBot AI và CTA trong banner mở chat, gọi `POST /api/v1/chat/message`. Giữ conversationId từ server, retry không nhân đôi câu hỏi, reset/hủy request và bỏ phản hồi cũ sau đổi tài khoản. Không tạo câu trả lời giả.
- CinePoints mở màn hình điểm hiện có, dùng đúng tài khoản đăng nhập và xóa trạng thái cũ khi đổi tài khoản. Không gắn voucher/điểm vào đơn bắp nước.
- Ưu đãi VIP vẫn "Sắp có": chưa tìm thấy API danh sách ưu đãi/VIP dành cho CUSTOMER trong các microservice đang được gateway định tuyến.

## Runtime được người dùng cho phép

Áp dụng `D:\MSS\.qa-runtime\quick-api-runtime.yaml` và recreate gateway/payment. Secret lấy từ môi trường container đang chạy, không ghi giá trị secret vào tài liệu/cấu hình. Payment tắt Flyway cho lần chạy này và chỉ validate schema. Không sửa source BE, không chạy migration hoặc cập nhật DB thủ công.

## Kết quả kiểm tra trực tiếp

| API | Kết quả |
| --- | --- |
| `GET /api/v1/loyalty/me` | 200; CinePoints hiển thị điểm và cấu hình trên emulator |
| `GET /api/v1/loyalty/config` | 200 |
| `GET /api/v1/food-orders/my` | 200 |
| `GET /api/v1/foods/items` | 500 |
| `GET /api/v1/foods/combos` | 500 |
| `GET /api/v1/cinema` | 500 |
| `POST /api/v1/chat/message` | 404; Mobile hiển thị lỗi và nút thử lại |

Catalog vẫn khởi động lại do thiếu `food_categories` và lịch sử migration V14 không khớp source mới. Chưa xử lý schema vì chưa được cho phép.

Source `cinema-services/ai-service` đã có chat, nhưng image `recommendation-service` đang chạy không có đường dẫn chat trong OpenAPI. Compose vẫn trỏ tới thư mục recommendation-service cũ. Đồng bộ secret đã loại bỏ lỗi 403; cần triển khai image AI đúng phiên bản để chat trả lời được. Chưa triển khai image AI mới trong phạm vi đồng bộ gateway/payment này.

## Kiểm chứng mã

- Bộ test hiện có và test contract mới: 142 PASS.
- Thêm 5 test màn hình: retry/reset chat, QR và nút thanh toán theo trạng thái đơn; 5 PASS.
- Kiểm tra tĩnh Flutter, build APK debug, cài giữ dữ liệu trên emulator.
- Home bật UI_PREVIEW để chỉnh style; các màn hình Bắp nước, PopBot, CinePoints vẫn gọi API thật.
- Không tạo đơn thật, không thanh toán VNPay hoặc đổi điểm trong QA này. Luồng mua bắp nước từ đầu đến cuối chưa kiểm thử được do catalog lỗi; chat trả lời thành công chưa kiểm thử được do image AI cũ.
- Không thay đổi UI đăng nhập/đăng ký hoặc tài liệu cũ của người khác.
