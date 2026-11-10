# 02 — Hồ sơ, avatar và đổi mật khẩu thật

Trạng thái: **pending**. Ưu tiên: cao.

## Việc cần làm

- Thay `profileRepositoryProvider` đang dùng `MockAccountStore` bằng remote repository: GET/PUT `/api/v1/users/me`.
- Bind hồ sơ theo phiên thật; bỏ `DemoIds.user` khỏi flow profile production và đồng bộ Account sau khi lưu.
- Map các trường mới theo `UserProfileResponse`; đối chiếu request update trước khi thêm field sửa.
- Thêm thay avatar qua `/api/v1/users/me/avatar`; xác nhận BE lưu/trả URL ảnh dùng được.
- Thay hành vi đổi mật khẩu mock bằng POST `/api/v1/users/me/password`, đủ old/new/confirm và validation BE.
- Thêm loading/error/retry cho profile; khóa submit và chỉ báo thành công khi BE xác nhận.

## Scope dự kiến

`lib/features/account/data/`, `account_summary_provider.dart`, `account_detail_pages.dart`, auth/session mapping.

## Tiêu chí hoàn thành và kiểm chứng

- Hồ sơ đúng người dùng; thay đổi còn sau restart và login lại.
- Mật khẩu cũ sai không được báo thành công; mật khẩu mới dùng để login được.
- Avatar hiển thị sau reload; failure không làm mất hồ sơ cũ.
- Có test remote mapping, lỗi mutation và kiểm thử hai tài khoản khác nhau.
