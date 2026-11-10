# UI-15 — Khôi phục khu phim Home theo thiết kế 3D đã chốt

Ngày lập và triển khai: **17/10/2026**. Trạng thái: **đã triển khai; 42 test/analyzer/build Android đạt, đã kiểm tra emulator với API thật; chờ review người dùng và QA iOS/TalkBack**.
Kết quả: [UI15-RESULTS.md](UI15-RESULTS.md).
Người yêu cầu: **Tzee314**. Baseline khi lập: Mobile `42588fb`.

## Mục tiêu và thiết kế đã chốt

Khôi phục riêng phần phim đang chiếu/sắp chiếu theo Home trước khi merge dev. Giữ phong cách đen–vàng và carousel coverflow 3D đã được người dùng lựa chọn.

- Hai tab **Đang chiếu / Sắp chiếu**, tab chọn có gạch vàng; dùng chung một vùng carousel thay cho hai danh sách thẻ ngang riêng hiện tại.
- Poster chính lớn ở giữa, poster hai bên nghiêng theo chiều sâu; vuốt ngang chuyển phim và snap về vị trí trung tâm. Nội dung bên dưới luôn thuộc phim đang chọn.
- Nền mờ theo ảnh/màu poster; ảnh chính giữ đúng tỷ lệ trên nền blur như lựa chọn trước đó. Xử lý ảnh ngang/dọc, ảnh thiếu và ảnh lỗi; không kéo giãn ảnh.
- Tên phim, phân loại tuổi khi API có, thời lượng, ngày khởi chiếu và thể loại đặt dưới carousel, dễ đọc. Nút Đặt vé nổi bật; trailer chỉ mở khi có URL hợp lệ.
- Phim sắp chiếu mở chi tiết/trailer theo dữ liệu thật. CTA đặt vé chỉ dùng khi quy tắc mở bán và dữ liệu suất chiếu hiện hành cho phép; không tạo khả năng đặt vé giả.

Tham chiếu chính: `MovieCoverflow` và phần tab của `HomePage` tại commit `21220a7`, cùng ảnh Home 3D người dùng đã gửi trong hội thoại. Dùng lại bố cục/hiệu ứng đã chốt, thích nghi với model/theme hiện tại.

## Phạm vi thay đổi và các khối giữ nguyên

| Khối Home | Hành động |
| --- | --- |
| Hai heading/danh sách phim đang chiếu, sắp chiếu hiện tại | Thay bằng cụm hai tab + coverflow 3D |
| Mua vé nhanh `HomeQuickBooking` | Giữ UI, vị trí trước khu phim, dữ liệu, bộ chọn và điều hướng ghế/đăng nhập hiện tại |
| Rạp phim `HomeCinemasSection` | Giữ UI, vị trí sau khu phim, lựa chọn rạp và điều hướng hiện tại |
| Hero/banner trên cùng `HomeHeroCarousel` | Giữ phiên bản hiện tại trong batch này |
| Header, bottom navigation và các khối khác | Giữ phiên bản hiện tại trong batch này |

Thứ tự sau thay đổi: **hero hiện tại → mua vé nhanh hiện tại → tab phim + coverflow 3D → rạp phim hiện tại**.

Không khôi phục toàn bộ `HomePage` cũ bằng Git vì sẽ ghi đè các tính năng mới trên dev. Không đưa lại quick actions/PopBot/resume banner hay thay hero chỉ vì chúng có trong bản tham chiếu cũ.

## Dữ liệu và điều hướng

- Dùng catalog thật và trạng thái phim từ API; kiểm tra lại provider lọc theo `NOW_SHOWING`/`UPCOMING`. Không dựa vào ngày phát hành để tự suy diễn status, không giới hạn nhầm khiến tab sắp chiếu rỗng dù API có phim.
- Tách state khu phim khỏi mua vé nhanh/rạp: đổi tab hoặc retry phim không reset bộ chọn mua vé nhanh, không tải lại toàn bộ Home.
- Chọn phương án provider sau khi đối chiếu `homeCategoryMoviesProvider`, `moviesProvider` và contract repository hiện tại. Giữ các cập nhật model/auth đã merge từ dev.
- Mỗi tab lưu movie ID/vị trí đang chọn khi quay lại; nếu danh sách đổi và ID mất thì chọn phần tử hợp lệ. Hủy animation cũ khi dữ liệu/tab đổi; không để index vượt danh sách.
- Poster, tên, metadata, trailer và CTA phải cùng movie ID sau khi vuốt nhanh/chuyển tab/refresh.
- Giữ route chi tiết phim và route suất chiếu đã có. Đặt vé đi qua ranh giới đăng nhập/redirect hiện hành; không tạo đơn hoặc hold ngay khi vuốt poster.
- Không tự đổi map ảnh banner đã chốt trước đây. Không dùng dữ liệu mẫu để che lỗi API.

## Các bước triển khai

1. Chụp baseline Home hiện tại và ghi lại hoạt động mua vé nhanh/rạp phim trước khi sửa.
2. Đối chiếu bản cũ `21220a7` với source mới; tái sử dụng `MovieCoverflow`, palette/blur, metadata và trailer callback phù hợp.
3. Thay riêng hai khối `_MovieSection` bằng widget quản lý tab/carousel. Giữ nguyên wiring mua vé nhanh/rạp và các phần khác trong bảng phạm vi.
4. Hoàn thiện state loading/error/empty, ảnh fallback và retry trong khu phim; giữ dữ liệu đã tải khi refresh lỗi nếu có thể.
5. Điều chỉnh responsive, text scale, semantics và giảm chuyển động; kiểm tra cuộn dọc không bị carousel giữ gesture sai.
6. Chạy kiểm tra liên quan, build Android và review ảnh trước/sau; ghi `UI15-RESULTS.md` rồi để người dùng duyệt UI.

## File dự kiến

- `lib/features/home/presentation/pages/home_page.dart`
- `lib/features/home/presentation/widgets/movie_coverflow.dart`
- Widget tab/khu phim riêng nếu cần; provider khu phim liên quan.
- `test/home_redesign_test.dart`, `test/home_navigation_test.dart`, `test/home_wallet_ui_test.dart` và test hành vi carousel liên quan khi cần.

`home_movie_carousel.dart` có thể còn được dùng ở nơi khác; kiểm tra tham chiếu trước khi thay đổi. Không sửa theme toàn app chỉ để khớp riêng Home.

## Nghiệm thu

- [x] Hai tab dùng coverflow 3D như thiết kế chốt; không còn hai dải thẻ phim cũ trong cùng Home.
- [x] Vuốt/chọn poster/chuyển tab hoạt động; metadata và CTA đúng phim; trở về Home không mất vị trí vô lý.
- [x] Danh sách 0/1/nhiều phim, response chậm/lỗi, refresh đổi dữ liệu, ảnh ngang/dọc/thiếu/lỗi đều xử lý được qua các test liên quan.
- [x] Widget test 320/360/390/430 logical px, chữ lớn và tên phim dài không overflow; nút tab/CTA/trailer có vùng chạm tối thiểu 48 px.
- [ ] Giảm chuyển động, screen reader, gesture ngang/dọc và hiệu năng Android được kiểm tra; iOS chưa chạy ghi rõ.
- [x] Source mua vé nhanh/rạp và wiring login → ghế được giữ; test lựa chọn phim qua đổi tab, identity widget và regression booking đạt. QA đủ chuỗi bộ chọn với API thật còn theo dõi trong kết quả.
- [x] Hero/header/bottom navigation giữ như baseline hiện tại.
- [ ] Analyzer, test hành vi liên quan, build Android đạt; có ảnh trước/sau và phản hồi người dùng tại `UI15-RESULTS.md`.

Code đã triển khai trong batch này. Review thẩm mỹ cuối, iOS/TalkBack và các giới hạn QA được ghi riêng trong UI15-RESULTS; chưa tự đánh dấu nghiệm thu toàn bộ.
