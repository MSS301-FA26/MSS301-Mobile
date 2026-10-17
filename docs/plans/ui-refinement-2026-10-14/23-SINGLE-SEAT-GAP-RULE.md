# UI-23 — Không tạo ghế trống đơn lẻ ở giữa

Ngày lập: **17/10/2026**. Ưu tiên: **P1**. Trạng thái: **planned — Mobile UX + dependency BE enforcement**. Cần UI-16.

## Bằng chứng hiện tại

- FE: `src/utils/seatValidation.js` có `splitRowIntoSegments`, `buildLogicalUnits`, `hasSingleSeatGapInSegment`, `validateNoSingleSeatGap`; `BookingPage.jsx` gọi khi chọn/bỏ và trước tiếp tục.
- Mobile chưa thấy validator tương ứng.
- BE `BookingServiceImpl.holdSeats` kiểm tra ID trùng, conflict ghế đã bán/hold rồi quote; `CheckoutQuoteServiceImpl` kiểm tra ghế/phòng/trạng thái/loại vé/tuổi/giá. Chưa thấy rule ghế lẻ trong các luồng này. Đây là kết luận source baseline đã nêu, chưa là kiểm thử bypass trên runtime.

## Quy tắc đề xuất đồng bộ FE

| Trạng thái trong một segment liên tục | Kết quả |
| --- | --- |
| Chọn 1,2,4,5, ghế 3 còn trống | Chặn: tạo đúng một ghế trống bị kẹp |
| Chọn 1,2,5,6, ghế 3–4 còn trống | Cho phép: còn hai ghế liên tiếp |
| Ghế trống ở đầu/cuối hàng hoặc cạnh lối đi | Cho phép theo rule FE hiện tại |
| Hai nhóm ghế cách lối đi/khoảng layout/OFF | Xét thành segment riêng, không nối theo số ghế |
| Ghế đôi | Cặp hai ghế cùng loại vé; đếm số ghế trống thực tế, không coi cặp trống hai ghế là một ghế đơn |

Occupied gồm ghế đã mua/hold hợp lệ từ server và lựa chọn dự kiến hiện tại. Mỗi thao tác chọn **và bỏ** phải kiểm tra trạng thái dự kiến trước khi commit. Cần đối chiếu trường nào FE đưa vào `isBooked` để thống nhất held/maintenance/OFF, không sao chép boolean sai nghĩa.

## Các điểm phải xử lý khi triển khai

1. Validator thuần dựa tọa độ/layout, status, pair mapping và proposed selection. Giữ max 8, cùng loại cho cặp, hạn chế vé trẻ em hiện tại.
2. Cảnh báo ngay cạnh sơ đồ, chỉ ra hàng/ghế bị lẻ; giữ lựa chọn cũ nếu thao tác không hợp lệ, không tự thêm ghế 3, đổi vé hoặc cộng tiền.
3. Kiểm tra cả thao tác đơn/cặp, bỏ ghế/giảm số vé, sửa hold và trước quote/hold bằng seat-map mới. Cung cấp cách xóa/sửa nhóm lựa chọn mà không khiến người dùng kẹt vì từng thao tác trung gian.
4. Chốt cách xử lý ghế lẻ đã tồn tại do người khác: đề xuất không quy lỗi một khoảng B–trống–B có sẵn nếu thao tác của user không tạo khoảng mới. FE hiện duyệt cả segment ở hàng liên quan; cần đối chiếu và thống nhất trước khi gắn nhãn tương đương hoàn toàn.
5. Server cập nhật trong khi chọn có thể làm giỏ đang hợp lệ trở thành không hợp lệ: refresh, giải thích và yêu cầu chỉnh; không tiếp tục theo snapshot cũ.
6. Đề xuất BE kiểm tra nguyên tử trên trạng thái ghế mới nhất trong giao dịch hold, có mã lỗi và thông tin hàng/ghế; không dựa duy nhất vào validation client. Luồng checkout/retry cần xác minh rule có áp lại khi giỏ không đổi hay không.

## Phân biệt hoàn thành

- **Mobile UX đạt:** kiểm tra ngay khi chọn/bỏ, trước gửi hold, giữ đúng cặp/giá và dữ liệu lỗi; chưa thể ngăn client khác bỏ qua rule.
- **Hệ thống đạt:** BE reject request tạo ghế lẻ kể cả gọi trực tiếp/race, FE và Mobile cùng bảng quy tắc.

Test bảng đầy đủ 0/1/2 gap, mép/lối đi/OFF, cặp, hàng khác nhau, số ghế không liên tiếp nhưng tọa độ liên tục, dữ liệu có orphan sẵn, conflict hai user và request bypass frontend. Không tự sửa BE trong batch lập plan. Ghi `UI23-RESULTS.md` tách hai mức trên.
