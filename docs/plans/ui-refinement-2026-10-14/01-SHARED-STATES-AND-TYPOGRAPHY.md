# UI-01 — Trạng thái dữ liệu và hệ thống trình bày

Trạng thái: **đã triển khai code, đạt kiểm chứng tự động; chờ phản hồi UI và QA dữ liệu thật/iOS**. Ưu tiên: **cao**. Liên quan: plan chức năng 03, 08, 10, 12.
Áp dụng phạm vi và tiêu chí chung trong [README](README.md).

## Hiện trạng

Nhiều màn dùng spinner giữa nền đen, thiếu cấu trúc khi chờ. Body 13 px, caption 11 px và meta 10 px; một số thông tin cần đọc dùng màu quá tối.

## Việc cần làm

- Tạo skeleton theo cấu trúc thực tế: thẻ phim, lịch chiếu, thẻ đơn và tài khoản. Giữ header, tab và bố cục trong lúc tải.
- Thiết kế error/empty riêng: icon, tiêu đề, giải thích ngắn và hành động phù hợp. Phân biệt không có dữ liệu với lỗi tải.
- Khi refresh/load more lỗi, giữ nội dung đã tải và cho thử lại tại vị trí lỗi.
- Thống nhất body, caption, khoảng cách, radius, viền và thứ bậc primary/secondary button.
- Giảm hiệu ứng khi thiết bị yêu cầu reduced motion; skeleton không cần shimmer liên tục.
- Không chuyển lỗi API thành số dư 0, danh sách rỗng hoặc thông báo thành công giả.

## File dự kiến

`lib/core/theme/`, `lib/shared/widgets/repository_state_pane.dart`, `app_button.dart` và các page sử dụng state pane.

## Tiêu chí hoàn thành và QA

Mỗi màn còn nhận diện được khi loading; error có retry, empty có hành động đúng flow. Đối chiếu dark theme, chữ lớn, mạng chậm/mất mạng và load more lỗi. Thay đổi token không làm hỏng booking, carousel hoặc form.

## Kết quả triển khai — 14/10/2026

Baseline Mobile `fcf3708`, các thay đổi UI-01 hiện là diff local.

- Skeleton tĩnh theo layout phim/lịch chiếu/đơn/tài khoản/poster/bắp nước; không chạy shimmer liên tục. Banner có placeholder giữ tỷ lệ.
- Khám phá giữ search/tabs, lịch chiếu giữ progress/ngày, Đơn giữ tabs khi chờ hoặc lỗi. Không hiển thị count 0 giả khi chưa tải được count.
- State lỗi/trống dùng icon và thông điệp/hành động thống nhất; Empty Home/Đơn có entry Khám phá, lịch sử bắp nước có entry Đặt bắp nước.
- Refresh lỗi có dữ liệu cũ: Home, Account, Orders, Discover, danh mục và lịch sử bắp nước giữ dữ liệu, có thông báo/retry. Lịch chiếu giữ dữ liệu nhưng khóa chọn/đi tiếp khi refresh lỗi.
- Discover load more lỗi giữ danh sách và retry đúng trang; request trước khi đổi bộ lọc không ghép vào query mới, loại trùng ID và không fetch lại trang đầu khi tải thêm.
- Ví lỗi không còn spinner vô hạn, có error/retry; không tạo số dư giả. Chưa triển khai withdrawal, vẫn thuộc plan chức năng 10.
- Body 14 px, caption 12 px; nút dùng chung tối thiểu 48 px, chiều cao theo text scale, loading chặn submit; trạng thái disabled của nút tím/danger rõ hơn.
- Không chỉnh file login/register, source BE/FE hoặc DB. Không thay deadline/giá authoritative/payload booking và payment.

Kiểm chứng: analyzer sạch, **155 test PASS**, APK debug build PASS. Bốn test mới kiểm tra query đổi lúc loading, load more lỗi/retry, request cũ và skeleton/error trên màn 320 px với text scale 1.8. Android đã cài giữ dữ liệu, quan sát skeleton Khám phá và controls trên emulator.

QA còn mở: nghiệm thu thẩm mỹ từ người dùng; rà soát có dữ liệu thật trên các màn/kích thước còn lại; iOS. Lúc QA cuối, API local chưa trả response trong 5 giây và app chuyển đến login khi mở Đơn, nên không lấy ảnh login làm bằng chứng QA Orders. Không đánh dấu toàn bộ plan Done từ test fixture.

Chi tiết: [UI01-RESULTS.md](UI01-RESULTS.md).

     