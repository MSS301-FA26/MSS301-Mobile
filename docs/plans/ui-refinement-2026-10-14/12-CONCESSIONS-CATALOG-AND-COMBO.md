# UI-12 — Danh mục bắp nước và trình bày combo

Ngày lập: **15/10/2026**. Cập nhật: **16/10/2026**. Trạng thái: **đã triển khai; analyzer/59 test/build Android đạt; đã kiểm tra catalog thật trên emulator, chờ review và iOS/E2E**.
Thứ tự trong đợt mới: **2**. Tham chiếu: danh sách combo ảnh 3.

Kết quả: [UI12-RESULTS.md](UI12-RESULTS.md). Đã có nhóm Tất cả/Combo/Sản phẩm dùng chung, sheet chi tiết, ảnh lớn hơn, tóm tắt booking và tách tiền vé khỏi tạm tính bắp nước. Giữ nguyên API đặt hàng, giới hạn 8 và deadline BE.

## Mục tiêu

Phát triển từ UI-05 đã được người dùng duyệt: sản phẩm có ảnh rõ hơn, đọc được nội dung combo và chọn nhanh. Giữ các hành vi đã được duyệt: chọn rạp từ CTA, giỏ không mất khi đổi rạp, tổng cố định và bắp nước kèm vé có thể bỏ qua.

## Thiết kế dự kiến

- Nhóm Combo / Sản phẩm bằng dữ liệu `isCombo`; chỉ thêm tab danh mục chi tiết khi DTO/API có category thật. Không suy đoán danh mục từ tên món.
- Thẻ ảnh bên trái, tên/giá/mô tả bên phải, bộ chọn số lượng gọn ở dưới. Trên màn hẹp/chữ lớn tự xuống dòng; ảnh chứa trọn sản phẩm, không crop mất hộp/nước.
- Mô tả dài có Xem chi tiết hoặc bottom sheet. Phần gồm những món gì lấy từ description hoặc dữ liệu thành phần đã xác minh; không tự bịa số bắp/nước hay lựa chọn vị/size.
- Thẻ đang chọn dễ nhận ra, giới hạn 8 được giải thích tại chỗ, hàng hết vẫn giảm/xóa được khỏi giỏ. Trạng thái khả dụng giữ theo BE tại thời điểm triển khai.
- Booking có tóm tắt phim/rạp/suất ngắn và countdown ngoài vùng cuộn. Thanh cuối hiển thị tiền vé và tiền bắp nước riêng khi đã có số authoritative; phần tạm tính món phải ghi rõ.
- Đơn độc lập giữ rạp nhận hàng và tổng tiền dễ thấy. Không tự chọn rạp từ header khi chưa có xác nhận của người dùng.

## API và phạm vi

- Đã có trong `RemoteCatalogRepository`: `GET /api/v1/foods/items`, `GET /api/v1/foods/combos` với phân trang; các trường name/price/description/imageUrl/status/isCombo đã được map.
- Đã có `FoodProductCard`, `FoodCartBar` và luồng tạo đơn độc lập. Ưu tiên tái sử dụng thay vì tạo hai catalog/giỏ khác nhau.
- Hiện DTO sản phẩm Mobile chưa có cấu trúc thành phần combo hay tuỳ chọn vị/size. Nếu muốn chọn cấu hình combo, phải xác minh contract và khả năng tính giá/đặt hàng trước; đó là scope bổ sung, không chỉ đổi UI.
- Không triển khai voucher/điểm trong batch này. `LOW_STOCK` phải kiểm tra lại contract BE trước khi đổi hành vi; hiện Mobile chỉ cho thêm ACTIVE.

## QA và nghiệm thu

- Món/combo cùng ID, tối đa 8 mỗi loại, giảm về 0, chuyển tab không mất giỏ, đổi rạp không lẫn thông tin nhận hàng.
- Ảnh chậm/hỏng/thiếu, mô tả dài, giá lớn, danh sách rỗng hoặc phân trang lỗi; trạng thái đang xử lý khóa thao tác tạo đơn lặp.
- 320–430 px và chữ lớn; nội dung chi tiết cuộn được, nút đóng sheet và CTA không bị SafeArea/bàn phím che.
- Bảo toàn luồng booking → bắp nước → checkout và tạo đơn riêng. Ghi kết quả thực tế vào `UI12-RESULTS.md`, không suy ra E2E pass từ review UI.
