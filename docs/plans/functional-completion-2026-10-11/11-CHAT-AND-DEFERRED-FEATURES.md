# 11 — Chat, social, ưu đãi và hỗ trợ

Trạng thái: **pending**. Tách thành các batch độc lập; chưa coi tất cả API đã sẵn sàng.

| Batch | Việc cần làm | Dependency |
| --- | --- | --- |
| Chat AI | Remote repository/UI hội thoại, gửi/chờ/retry, session và điều hướng movie/showtime từ gợi ý; thay PopBot preview. | Gateway đã route `/api/v1/chat` tới `/api/v1/chat/message`; đối chiếu body, auth, response và conversation lifecycle. |
| AI search/personal recommendation | Map response, search results, cá nhân hóa và feedback nếu được yêu cầu. | Xác nhận Gateway route, user identity và endpoint từng loại; không suy ra từ route chat. |
| Watchlist | List/add/remove, trạng thái favorite đồng bộ Home/Discover/detail, persistence server. | Xác nhận customer controller, Gateway, ownership; kế hoạch B11 cũ còn phụ thuộc. |
| Notifications/reminders | List/read/unread, push token, quyền thiết bị, nhắc mở bán và deep link. | Chưa xác nhận customer API và delivery contract. |
| Vouchers | Danh sách cá nhân, điều kiện, validate/apply và lifecycle trong quote/checkout. | Customer contract trong `cinema-services`; không dùng API monolith/admin làm bằng chứng tự động. |
| VIP | Tier/quyền lợi/mã thành viên và chính sách áp dụng. | Chốt dữ liệu và quyền lợi sản phẩm; chưa coi preview là production. |
| Refund/đổi vé | Eligibility, quote, request, theo dõi trạng thái và tác động wallet/loyalty. | Endpoint admin refund không đủ quyền cho customer flow. |
| CSKH/thông tin | Hotline/email thật, mở tel/mailto có fallback, nội dung rạp/chính sách được xác nhận; request hỗ trợ nếu có API. | Cấu hình/nội dung sản phẩm và API hỗ trợ khi cần. |

## Scope dự kiến

Feature repository/state/page mới theo từng batch; cập nhật preview flags/routes và entry ở Home/Account sau khi đủ contract.

## Tiêu chí hoàn thành và kiểm chứng

- Mỗi batch có contract evidence, ownership/auth và loading/error/retry.
- Chat dùng API thật và giữ hội thoại theo contract; lỗi không giả phản hồi chatbot.
- Phần thiếu contract ghi rõ pending/blocked; không cấp quyền admin hoặc tự mô phỏng lưu dữ liệu.
- Tính năng chỉ chuyển khỏi preview sau test API/navigation và kiểm thử thiết bị phù hợp.
