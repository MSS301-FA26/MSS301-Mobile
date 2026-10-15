# UI-11 — Chi tiết phim và phim liên quan

Ngày lập: **15/10/2026**. Trạng thái: **planned — thực hiện sau UI-10**.
Thứ tự trong đợt mới: **1**. Tham chiếu: ảnh chi tiết phim Shaun the Sheep người dùng gửi (ảnh 4).

## Mục tiêu và bố cục

Giữ đen–vàng CinePremier. Tham khảo cách gom thông tin trong ảnh, dùng dữ liệu và ảnh của hệ thống.

1. Header gọn, quay lại đúng màn trước; tên đầy đủ nằm trong nội dung, không chỉ dựa vào tiêu đề một dòng.
2. Banner ngang có gradient nhẹ và nút trailer; poster nhỏ giữ tỷ lệ, ảnh ngang không bị ép thành ảnh dọc. Có fallback khi thiếu ảnh/trailer.
3. Tên phim, phân loại tuổi kèm giải thích, thời lượng, ngày khởi chiếu và thể loại đặt gần nhau; wrap khi chữ lớn. Chỉ hiển thị định dạng/ngôn ngữ khi dữ liệu đủ tin cậy, không tự gán format đặc biệt.
4. Nội dung phim rút gọn với Xem thêm/Thu gọn; đạo diễn, diễn viên, ngôn ngữ chia thành các dòng dễ đọc. Thiếu trường thì ẩn hoặc ghi chưa cập nhật.
5. Đánh giá khán giả và hàng poster **Phim liên quan** tách rõ, đặt sau phần nội dung chính. Không hiện 0.0 như điểm đánh giá thật khi chưa có đánh giá.
6. Nút Đặt vé cố định có SafeArea, trạng thái phù hợp phim/khả năng có suất. Phim liên quan mở trang chi tiết đúng ID, quay lại giữ vị trí cuộn của phim cũ.

## Nguồn dữ liệu đã có trong Mobile

- `CatalogRepository.getMovie(movieId)` → dữ liệu chi tiết phim.
- `MovieEngagementRepository.getRecommendations` → `GET /api/v1/recommendation/content/{movieId}`.
- `GET /api/v1/reviews/movies/{movieId}/summary` và danh sách reviews đã được repository sử dụng.
- `movie_detail_page.dart` **đã có** provider gợi ý và `_RecommendationSection`; đây là cải thiện phần có sẵn, không mặc định xây API mới.
- DTO gợi ý có ID, tên, poster, điểm nullable và reason. Loại phim hiện tại, khử ID trùng; không tự chế điểm/lý do gợi ý. Trường phụ không có thì bỏ qua hoặc lấy chi tiết qua repository khi cần, tránh gọi hàng loạt không giới hạn.
- Tải/lỗi gợi ý không được làm hỏng chi tiết phim. Hiện skeleton/retry nhỏ; kết quả rỗng hợp lệ có thể ẩn cả khối. Không thay lỗi AI bằng danh sách được gắn nhãn “AI gợi ý”.

## Phụ thuộc cần xác minh lúc triển khai

- Kiểm tra response và khả năng truy cập recommendation trên gateway đang dùng; source có API không đồng nghĩa runtime luôn hoạt động.
- Khối tin mới/ưu đãi trong ảnh chỉ thêm khi đã xác minh API, dữ liệu và trang đích. Chưa có thì để ngoài batch; không tạo banner khuyến mãi hoặc số lượt thích giả.
- Không thêm các hành động chia sẻ/yêu thích chưa có luồng hoạt động chỉ để giống ảnh.

## File dự kiến và QA

`movie_detail_page.dart`, `movie_engagement_provider.dart`, widget banner/metadata/recommendation dùng riêng hoặc dùng lại từ Home.

- 320–430 px, chữ lớn, tên phim/diễn viên dài, poster ngang/dọc, banner thiếu/hỏng, trailer không mở được.
- Phim bị xóa/không còn công khai; recommendation chậm/lỗi/rỗng/trùng/chứa phim hiện tại; chuyển A → B → quay lại A không lẫn dữ liệu.
- CTA không che hàng phim liên quan; không mất chức năng reviews, lịch chiếu và trạng thái đăng nhập hiện có.
- Ghi ảnh trước/sau, analyzer, test routing/state cần thiết, Android/iOS và review người dùng vào `UI11-RESULTS.md` khi thực hiện.
