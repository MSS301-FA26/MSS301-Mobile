# UI-22 — Danh sách phim muốn xem

Ngày lập: **17/10/2026**. Ưu tiên: **P2**. Trạng thái: **planned — cần chốt phạm vi lưu/sync**.

## Kết quả rà soát

Mobile chưa có watchlist. FE `src/services/wishlistService.js` dùng localStorage `cinepremier_wishlist_items`, không gọi API BE. Source BE hiện chỉ có chuỗi MessageTranslator và số thống kê gợi ý, chưa thấy API/controller/service/entity watchlist thực sự. Không suy ra có sync tài khoản từ tên hàm FE `addWishlist`.

## Phương án đề xuất

**MVP Mobile:** lưu cục bộ theo userId, tên rõ “Danh sách muốn xem trên thiết bị này”. Dùng repository có interface để chuyển sang remote sau; chưa hứa đồng bộ Web hoặc nhiều điện thoại. Nếu yêu cầu sync tài khoản ngay, backend phải cung cấp contract trước khi chốt hoàn thành.

## Luồng và triển khai

1. Trang danh sách muốn xem có entry dễ tìm từ Tài khoản; nút lưu/bỏ ở chi tiết phim, thẻ phim phù hợp và carousel 3D không che nút đặt vé/gesture.
2. Bấm lưu cập nhật đồng bộ icon ở các entry, chống double tap/ID trùng; bỏ lưu tại danh sách có thể undo. Refresh catalog không làm mất ID đã lưu.
3. Persist danh sách ID/thời điểm lưu, metadata cache chỉ phục vụ hiển thị. Khi mở lại tải dữ liệu phim thật; phim inactive/xóa vẫn có trạng thái và nút xóa khỏi danh sách, không crash hoặc tạo ID mới theo tên.
4. Khách chưa đăng nhập: đề xuất dẫn login rồi quay lại thao tác; không chỉnh thiết kế auth. Nếu cho guest lưu phải dùng namespace guest và chốt cách merge; không tự trộn vào tài khoản.
5. Logout/đổi user ngắt request cũ, không hiển thị danh sách user trước. Lỗi persistence không báo đã lưu bền vững; lỗi đọc cache có đường phục hồi, không xóa âm thầm.
6. Khi BE có API: xác minh GET/list phân trang, add/remove idempotent, ownership, duplicate, lỗi phim không tồn tại, schema response và migration kế hoạch riêng. Không tự gọi endpoint wishlist giả hoặc tạo DB trong batch Mobile.

## QA / kết quả

Restart app, offline/online, thêm trùng/bỏ nhanh/undo, phim bị xóa, đổi user và late response; consistency Home/Discover/detail/list, link đặt vé vào đúng phim. Kiểm tra local persistence bằng khởi động lại, không chỉ widget state. Ghi `UI22-RESULTS.md` với trạng thái **local MVP** và **remote sync** tách riêng.
