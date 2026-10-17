# 01 — Auth, đăng ký và khôi phục mật khẩu

Trạng thái: **pending**. Ưu tiên: cao.

## Việc cần làm

- Cho login bằng email hoặc username; bỏ email demo điền sẵn.
- Đồng bộ validation đăng ký/reset với request BE; thêm confirm password và thông báo lỗi theo field.
- Bổ sung trường đăng ký được product chọn: phone, birthYear, username, identityNumber, preferredCinemaId. Phân biệt trường bắt buộc và tùy chọn theo BE.
- Thêm gửi lại OTP, cooldown, OTP hết hạn và sửa email; giữ route tiếp tục sau auth.
- Khóa gửi lặp cho register/verify/reset; clear thông báo cũ khi bắt đầu thao tác mới.
- Sau verify email, đưa người dùng tới login với thông báo rõ hoặc tự đăng nhập qua contract được xác nhận.
- Tách batch Google login; đối chiếu `/auth/google`, `/auth/google/verify`, credential và cấu hình Android/iOS.
- Chốt trigger/response cho Google password setup; không suy ra bắt buộc setup chỉ vì endpoint đổi mật khẩu tồn tại.

## Scope dự kiến

`lib/features/auth/`, token/session và routing; platform config cho batch Google. Contract tại `identity-service` là nguồn đối chiếu.

## Tiêu chí hoàn thành và kiểm chứng

- Email/username login, đăng ký → verify → login và reset → login chạy qua Gateway.
- OTP sai/hết hạn, username trùng, password yếu và double submit được xử lý đúng.
- Có test contract/controller cho các nhánh thay đổi và kiểm thử auth continuation trên thiết bị.
- Google/setup chỉ đánh dấu done khi đã có contract, cấu hình và bằng chứng thực tế.
