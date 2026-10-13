# 02 — Hồ sơ, avatar và đổi mật khẩu thật

Cập nhật 13/10/2026 theo BE `9921498`, Mobile `c7e9edd` và thay đổi local Plan 02. Trạng thái: **đã triển khai Mobile, đạt test tự động; chờ QA thật**.

## Kết quả triển khai 13/10/2026

- Hồ sơ production dùng GET/PUT `/api/v1/users/me` theo JWT. Cho phép sửa họ tên, điện thoại và năm sinh theo DTO BE; email chỉ hiển thị.
- Form có validation, loading, chống gửi lặp, giữ dữ liệu khi lỗi. Sau lưu thành công cập nhật session và tải lại hồ sơ/Account.
- Hủy request khi logout hoặc đổi tài khoản; loại phản hồi cũ và kiểm tra chủ sở hữu profile.
- Avatar dùng URL http/https qua multipart `avatarUrl`. Mobile tải và giải mã ảnh trước khi gửi, giới hạn tải 5 MB; request tải ảnh không mang token của BE. Có fallback khi ảnh lỗi.
- Chưa triển khai chọn file từ thư viện: nhánh file BE hiện chỉ dựng đường dẫn, chưa lưu/phục vụ file. Không thể đánh dấu upload file hoàn thành dựa trên URL trả về.
- Đổi mật khẩu qua POST `/api/v1/users/me/password`, gửi đủ `oldPassword`, `newPassword`, `confirmPassword`; kiểm tra độ mạnh, xác nhận và khác mật khẩu cũ. Chỉ báo thành công khi BE xác nhận; xóa form sau thành công.
- BE hiện không thu hồi token trong xử lý đổi mật khẩu; Mobile giữ phiên hiện tại. Không thay UI đăng nhập–đăng ký.
- Lỗi wallet/loyalty không chặn hồ sơ. Số dư/điểm chưa tải được hiển thị trạng thái lỗi, không thay bằng số 0 giả.
- Analyzer: PASS. Toàn bộ 121 test: PASS, gồm 9 test mới cho Plan 02. Android debug APK: build PASS.

Chi tiết bằng chứng và QA còn lại: [PLAN02-IMPLEMENTATION.md](../plan02-qa-2026-10-13/PLAN02-IMPLEMENTATION.md).

Các mục dưới đây là phạm vi và tiêu chí gốc để đối chiếu. Phần mô tả mock trong hiện trạng là **trước triển khai**.

## Hiện trạng đã đối chiếu

- profileRepositoryProvider còn trỏ MockAccountStore; profile page gọi DemoIds.user.
- SecurityPage còn hiển thị đổi mật khẩu mock thành công.
- BE customer endpoints vẫn có GET/PUT /api/v1/users/me, POST /api/v1/users/me/password và POST /api/v1/users/me/avatar; lần pull này chưa đổi contract customer trực tiếp của các API trên.
- API hồ sơ nội bộ và quyền Manager xem CUSTOMER là thay đổi phục vụ quản trị/loyalty; không dùng chúng thay cho endpoint /me của Mobile customer.
- Màn Account đang phụ thuộc profile + wallet + loyalty. Wallet GET 500 có thể chặn việc xem hồ sơ; không coi đây là profile API thất bại.

## Việc cần làm

### A. Hồ sơ thật và phiên người dùng

- Triển khai RemoteProfileRepository, bind profileRepositoryProvider vào remote cho production.
- GET /me và PUT /me dựa vào JWT; bỏ DemoIds.user khỏi flow profile production.
- Đối chiếu UserProfileResponse/UserProfileUpdateRequest trước khi thêm trường sửa; email, roles và trạng thái không tự đưa vào payload chỉnh sửa nếu contract không cho phép.
- Validation theo contract hiện tại; bỏ giới hạn năm sinh cố định 2020 trên Mobile, dùng quy tắc BE và năm hiện tại cho dữ liệu được phép sửa.
- Submit có loading, chống gửi lặp, giữ form khi lỗi; chỉ thông báo đã lưu khi nhận response BE hợp lệ.
- Sau lưu, cập nhật profile/Account/session hiển thị; đổi tài khoản hoặc logout phải hủy/loại phản hồi cũ và cache của user trước.
- Tách tải hồ sơ khỏi lỗi wallet/loyalty để người dùng vẫn xem/sửa profile khi dịch vụ ví lỗi; không dựng số dư giả.

### B. Avatar

- Đối chiếu chế độ file multipart hoặc avatarUrl của POST /me/avatar; xử lý hủy chọn ảnh, lỗi quyền, loading và lỗi mạng.
- Controller BE hiện có thể dựng đường dẫn /uploads/avatars/... từ tên file. Phải kiểm tra ảnh thực sự được lưu/phục vụ và tải được sau restart; response URL đơn thuần chưa là bằng chứng upload thành công.
- Nếu endpoint nhận URL hợp lệ và phục vụ ảnh ổn, dùng contract đó. Nếu file chưa được lưu/phục vụ, ghi phụ thuộc BE; không sửa BE/DB trong plan Mobile này.
- Normalize URL tương đối theo API origin; lỗi upload không xóa avatar đang dùng.

### C. Đổi mật khẩu

- POST /me/password với đúng old/new/confirm theo DTO BE; xử lý tài khoản không có password theo contract được xác minh.
- Mật khẩu cũ sai, confirm sai hoặc BE từ chối không được báo thành công.
- Xác minh token/session sau đổi password: BE có yêu cầu đăng nhập lại hay thu hồi token không; Mobile áp dụng đúng hành vi thực tế.
- Không chỉnh UI đăng nhập–đăng ký đang do người khác phụ trách; dùng flow hiện có để QA mật khẩu mới.

## Scope

lib/features/account/data/, account_summary_provider.dart, account_detail_pages.dart, mapping AuthUser/profile và cache tài khoản. Chỉ cập nhật phần liên quan hồ sơ/bảo mật.

## Kiểm chứng và tiêu chí DONE

- Unit/HTTP adapter: mapping /me, update/avatar/password, 400/401/403/500/timeout, chống submit lặp, loại phản hồi sau logout/đổi user.
- Widget: form lỗi giữ dữ liệu; profile vẫn hiển thị khi wallet lỗi; Account refresh đúng sau save; không còn nhãn mock.
- QA thật: tài khoản A/B; cập nhật còn sau restart/login lại; avatar GET thực sự tải được; mật khẩu cũ sai thất bại và mật khẩu mới đăng nhập được.
- Analyzer/test/build phù hợp PASS, có actual/expected và commit/runtime cụ thể theo Plan 12. Chưa DONE nếu avatar chỉ trả URL nhưng không phục vụ được ảnh.

## Phụ thuộc

Lỗi wallet read-only transaction cần BE xử lý riêng. Không tạo ví bằng SQL để làm xanh QA hồ sơ.
