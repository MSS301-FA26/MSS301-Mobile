# UI-08 — Tài khoản, hồ sơ và thẻ thành viên

Trạng thái: **đã hoàn tất triển khai; analyzer/23 test/build Android đạt, chờ người dùng review và QA iOS** (15/10/2026). Ưu tiên: **trung bình**. Liên quan: plan chức năng 02, 10.

Kết quả: [UI08-RESULTS.md](UI08-RESULTS.md).

## Đã triển khai

- Hồ sơ cho tên/email xuống dòng đầy đủ, avatar gọn; badge hạng chỉ ở thẻ thành viên.
- Thẻ thành viên bỏ chiều cao cố định và thông tin tên lặp; giữ hạng, điểm, mã hội viên. Không hiện nút QR chưa có chức năng.
- Điểm/ví có thông báo chưa tải và retry nhỏ cạnh vùng lỗi, phân biệt với số 0 thật. Quản lý ví chuyển sang nút phụ; bỏ giá trị điểm lặp trong menu.
- Menu tự xuống dòng, nội dung phụ không chiếm ngang tên mục. Form có SafeArea, thông báo validation nhiều dòng, dialog avatar cuộn khi bàn phím/chữ lớn.
- Không đổi login/register, credential, API cập nhật hồ sơ/mật khẩu hoặc repository/provider nghiệp vụ.

## Việc cần làm

- Thu gọn phần hồ sơ và thẻ thành viên để giảm thông tin lặp.
- Tên dài được xuống dòng hoặc phân bố lại badge, không cắt sớm vì MEMBER chiếm ngang.
- Giảm độ nổi bật của Tải lại điểm và số dư ví; dùng hành động retry nhỏ gắn với vùng lỗi.
- Giữ điểm/số dư rõ ràng, không coi lỗi tải là 0. Lỗi ví không che hồ sơ.
- Thống nhất menu/icon/khoảng cách; kiểm tra form hồ sơ, avatar và đổi mật khẩu ở chữ lớn.
- Không chỉnh login/register, không đổi cơ chế lưu hồ sơ hoặc credential.

## File dự kiến

`lib/features/account/presentation/pages/account_page.dart`, `account_detail_pages.dart`, `widgets/account_profile_card.dart`, `membership_card.dart`, `account_menu.dart`.

## Tiêu chí hoàn thành và QA

Đọc đủ tên/email trên màn nhỏ; menu quan trọng dễ tìm. Kiểm tra ảnh lỗi, ví/điểm lỗi, dữ liệu dài, bàn phím và tài khoản A/B. Không thực hiện mutation hồ sơ/mật khẩu chỉ để kiểm tra style nếu không cần.

