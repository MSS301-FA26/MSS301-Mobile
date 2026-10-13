# Plan 02 — Kết quả triển khai và kiểm chứng

Ngày 13/10/2026. Baseline Mobile `c7e9edd`, BE `9921498`; code Plan 02 là thay đổi local chưa commit.

## Phạm vi đã triển khai

Hồ sơ `/users/me` theo phiên đăng nhập, cập nhật họ tên/điện thoại/năm sinh, avatar bằng URL ảnh và đổi mật khẩu. Không sửa BE, DB hoặc UI đăng nhập–đăng ký. AuthSession chỉ thêm cập nhật thông tin người dùng, giữ token và roles hiện tại.

Tách lỗi ví/điểm khỏi hiển thị hồ sơ. Dữ liệu tài chính không tải được giữ null và hiển thị thông báo; không tạo số dư/điểm giả. Request bị hủy khi đổi user/logout, phản hồi cũ không cập nhật phiên mới. Mật khẩu được thêm vào danh sách che thông tin của logger.

## Kiểm chứng tự động

| Kiểm tra | Expected | Actual |
| --- | --- | --- |
| `flutter analyze --no-pub` | Không lỗi/cảnh báo | PASS — No issues found |
| `flutter test --no-pub --reporter expanded` | Toàn bộ test đạt | PASS — 121 tests |
| `flutter build apk --debug --dart-define=API_BASE_URL=http://127.0.0.1:8080` | Build Android thành công | PASS — app-debug.apk |

Logs tại folder này: `analyze.log`, `tests.log`, `build.log` (gitignore *.log).

9 test mới trong `test/plan02_profile_test.dart` dùng HTTP adapter/fake providers, không dùng database thật:

1. GET/PUT đúng `/me`, cập nhật session và giữ token, gửi null cho trường tùy chọn trống.
2. Payload đổi mật khẩu đúng DTO; BE từ chối không báo thành công, acknowledgement null hợp lệ.
3. Avatar multipart; logout giữa bước kiểm tra ảnh không gửi POST.
4. Chặn submit lặp và bỏ phản hồi sau logout.
5. Ví/loyalty lỗi vẫn lấy được hồ sơ, không có số dư/điểm giả.
6. Đổi tài khoản giữa bước kiểm tra ảnh không gửi avatar cho tài khoản mới.
7. Validation và che các trường mật khẩu trong logger.
8. Widget hồ sơ giữ dữ liệu khi lưu thất bại ở chiều rộng 320 px.
9. Widget đổi mật khẩu yêu cầu xác nhận và không báo thành công khi BE trả 400.

## Contract avatar và giới hạn

BE nhận `avatarUrl` hoặc `file`. Nhánh file hiện chỉ dựng `/uploads/avatars/...`, chưa lưu file thực tế. Mobile triển khai URL ảnh http/https: kiểm tra tải/giải mã ảnh trước POST, tối đa 5 MB dữ liệu tải; không gửi authorization tới host ảnh. Avatar lỗi có fallback và không xóa avatar cũ khi cập nhật thất bại.

Chưa có chọn ảnh từ thư viện/upload file. Việc URL tải được tại thời điểm cập nhật không đảm bảo host ngoài luôn phục vụ ảnh về sau.

## QA thật còn cần trước DONE

- GET hồ sơ bằng CUSTOMER đang đăng nhập trên môi trường BE hiện tại; kiểm tra cả trạng thái 401/403, timeout và lỗi dịch vụ.
- Lưu hồ sơ, mở lại màn hình, restart ứng dụng và đăng nhập lại: dữ liệu còn đúng.
- Avatar URL tải được sau lưu/restart; URL ảnh hỏng, mạng lỗi và response BE thất bại giữ avatar cũ.
- Trên tài khoản test: mật khẩu cũ sai thất bại; đổi đúng rồi đăng nhập bằng mật khẩu mới. Không tự đổi mật khẩu tài khoản thật của người dùng trong phiên này.
- Đổi tài khoản A/B và logout trên thiết bị: không còn hồ sơ/ảnh của user trước.
- QA Android thực tế và iOS: form, keyboard, loading, điều hướng và fallback ví/điểm.

Chưa chạy QA mutation trên tài khoản thật; chưa build/QA iOS. Trạng thái Plan 02 là **hoàn thành code Mobile và kiểm chứng tự động, chờ QA thật**, chưa đánh dấu DONE.
