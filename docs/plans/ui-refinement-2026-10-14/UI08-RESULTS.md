# UI-08 — Tài khoản, hồ sơ và thẻ thành viên

Ngày: **15/10/2026**. Trạng thái: **hoàn tất triển khai, kiểm thử và cài Android; chờ review/iOS**.

## Thay đổi

- `account_profile_card.dart`: avatar 52 px, tên/email có thể wrap đầy đủ, bỏ badge tranh chỗ với tên; năm tham gia chỉ hiển thị một lần.
- `membership_card.dart`: không cố định 208 px, bỏ tên chủ thẻ và nhận diện lặp; giữ hạng, điểm có phân cách nghìn, mã hội viên; không ép co chữ điểm bằng FittedBox. QR chỉ xuất hiện khi có callback thực hiện được.
- `account_menu.dart`: ví có giá trị rõ ràng, nút Quản lý ví dạng phụ, retry cạnh lỗi; menu label/giá trị phụ xếp dọc, không cắt tên một dòng.
- `account_page.dart`: bỏ nút Tải lại điểm và số dư ví toàn chiều ngang, gắn retry vào vùng lỗi, khóa retry khi đang tải, bỏ số điểm lặp trong menu. Retry vẫn invalidate accountSummaryProvider hiện có, không thêm endpoint hay thay cách tính số dư.
- `account_detail_pages.dart`: skeleton/error dùng state chung; SafeArea cho nội dung form, validation tối đa ba dòng, dialog avatar cuộn được khi bàn phím/chữ lớn. Giữ nguyên field, validator, payload, thao tác save/avatar/password và kiểm tra tài khoản.
- Lỗi tải/null không biến thành 0; lúc đang tải phân biệt với lỗi. Ví lỗi không làm mất hồ sơ và điểm đã tải được.

## Kiểm chứng

- `flutter analyze --no-pub`: **No issues found**.
- **23 test pass**: `ui08_account_test`, `plan02_profile_test`, `remote_account_repository_test`.
- 8 ca UI-08: 320/360/390/430 px với text scale 1.6, tên/email dài, điểm/số dư lớn, ảnh lỗi; null khác số 0 thật, retry đúng vị trí; hồ sơ/mật khẩu cuộn đến CTA với bàn phím mô phỏng, avatar dialog mở/hủy và không submit.
- Test hồi quy: hồ sơ theo JWT, cập nhật session sau save trong mock, lỗi password không báo thành công, avatar URL đúng contract, double save bị chặn, logout/đổi tài khoản không áp dụng response cũ, lỗi ví/điểm vẫn giữ hồ sơ và không bịa số dư.
- Log local: `D:\MSS\.qa-runtime\ui08-tests.log`.
- Build debug Android API `http://127.0.0.1:8080`, UI_PREVIEW=false; cài giữ đăng nhập.
- Đọc dữ liệu thật trên emulator: hồ sơ Vy, 6.460 CinePoints; ví chưa tải được, hiển thị lỗi cùng retry, không hiển thị 0. Đã mở form hồ sơ và đọc thông tin từ API; không bấm lưu/avatar/password, không đổi DB hoặc BE.

## Ảnh QA local

- `D:\MSS\.qa-runtime\ui08-account-before.png`.
- `D:\MSS\.qa-runtime\ui08-account-after.png`.
- `D:\MSS\.qa-runtime\ui08-profile-after.png`.

## Còn cần nghiệm thu

- Người dùng review giao diện và mật độ nội dung trên emulator.
- iOS/SafeArea/bàn phím thật chưa chạy. Keyboard/chữ lớn và avatar lỗi đã kiểm bằng widget test.
- Không đổi hồ sơ/mật khẩu thật chỉ để thử style. Các mutation trong test dùng backend giả lập; không suy ra đã E2E pass trên DB dùng chung.
- API ví hiện vẫn chưa tải được số dư trên tài khoản test; batch này xử lý cách hiển thị và retry, không sửa BE hay giả lập số dư thành công.
