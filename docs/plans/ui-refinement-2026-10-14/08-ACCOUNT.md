# UI-08 — Tài khoản, hồ sơ và thẻ thành viên

Trạng thái: **pending**. Ưu tiên: **trung bình**. Liên quan: plan chức năng 02, 10.

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

