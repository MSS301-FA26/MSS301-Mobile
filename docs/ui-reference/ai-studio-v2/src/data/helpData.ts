import { HelpCategory, FAQItem, SupportContactConfig } from '../types';

export const SUPPORT_CONFIG: SupportContactConfig = {
  hotline: '19008888',
  hotlineDisplay: '1900 8888',
  email: 'cskh@cinepremier.vn',
  workingHours: '08:00 - 23:00 hàng ngày (kể cả Lễ, Tết)',
  isDemo: true,
  note: 'Đây là thông tin liên hệ dịch vụ khách hàng demo phục vụ trải nghiệm prototype.',
};

export const HELP_CATEGORIES: HelpCategory[] = [
  { id: 'all', name: 'Tất cả', icon: 'grid_view' },
  { id: 'booking', name: 'Đặt vé & Thanh toán', icon: 'payments' },
  { id: 'seats', name: 'Chọn & Đổi ghế', icon: 'chair' },
  { id: 'refund', name: 'Hoàn & Đổi vé', icon: 'currency_exchange' },
  { id: 'voucher', name: 'Voucher & Ưu đãi', icon: 'local_activity' },
  { id: 'account', name: 'Tài khoản & Điểm', icon: 'person' },
  { id: 'technical', name: 'Sự cố kỹ thuật', icon: 'build' },
];

export const FAQ_ITEMS: FAQItem[] = [
  // 1. Đặt vé & Thanh toán
  {
    id: 'faq-1',
    categoryId: 'booking',
    question: 'Tôi có thể thanh toán vé xem phim qua những phương thức nào?',
    answer:
      'CinePremier hỗ trợ đa dạng phương thức thanh toán an toàn và tiện lợi: Ví nội bộ CineWallet, Thẻ ATM nội địa (qua cổng Napas), Thẻ quốc tế Visa/Mastercard/JCB, Ví điện tử MoMo, ZaloPay và chuyển khoản QR Code 24/7.',
  },
  {
    id: 'faq-2',
    categoryId: 'booking',
    question: 'Sau khi thanh toán thành công, tôi nhận vé bằng cách nào?',
    answer:
      'Ngay sau khi thanh toán thành công, mã vé điện tử kèm mã QR sẽ hiển thị tại màn hình "Vé Vào Rạp Điện Tử", đồng thời được lưu vào mục "Đơn Của Tôi" trong ứng dụng và gửi email xác nhận. Bạn chỉ cần xuất trình mã QR tại cổng kiểm soát vé hoặc kiosk in vé tự động.',
  },
  {
    id: 'faq-3',
    categoryId: 'booking',
    question: 'Thời gian tối đa để giữ ghế và hoàn tất thanh toán là bao lâu?',
    answer:
      'Hệ thống sẽ giữ ghế cho bạn trong vòng 10 phút kể từ khi bạn xác nhận chọn ghế. Nếu quá thời gian trên bạn chưa hoàn tất thanh toán, ghế sẽ tự động được mở lại cho người dùng khác.',
  },

  // 2. Chọn & Đổi ghế
  {
    id: 'faq-4',
    categoryId: 'seats',
    question: 'Tôi có thể đổi sang ghế khác sau khi đã thanh toán không?',
    answer:
      'Bạn có thể đổi ghế trước giờ chiếu ít nhất 60 phút thông qua tính năng "Đổi vé / Đổi ghế" trong chi tiết đơn hàng hoặc liên hệ trực tiếp quầy vé tại rạp. Ghế mới phải còn trống và cùng loại hoặc nâng cấp lên ghế VIP có bù chênh lệch.',
  },
  {
    id: 'faq-5',
    categoryId: 'seats',
    question: 'Ghế Couple (ghế đôi) và Ghế VIP khác gì so với ghế thường?',
    answer:
      'Ghế VIP được đặt ở khu vực trung tâm phòng chiếu (Sweet Spot) với góc nhìn và trường âm thanh hoàn hảo nhất, đệm da cao cấp êm ái. Ghế Couple đặt ở hàng cuối với không gian riêng tư, tay vịn có thể gập và trang bị gối tựa cao cấp.',
  },

  // 3. Hoàn & Đổi vé
  {
    id: 'faq-6',
    categoryId: 'refund',
    question: 'Chính sách hoàn tiền vé vào ví CineWallet như thế nào?',
    answer:
      'Đối với thành viên VIP CinePremier, bạn được hủy vé và hoàn tiền 100% vào ví CineWallet trước giờ chiếu ít nhất 120 phút. Số tiền hoàn về ví có thể dùng ngay để đặt vé cho bất kỳ suất chiếu nào khác mà không bị trừ phí.',
  },
  {
    id: 'faq-7',
    categoryId: 'refund',
    question: 'Nếu suất chiếu bị hủy vì lý do kỹ thuật của rạp thì sao?',
    answer:
      'Nếu suất chiếu bị hủy do sự cố bất khả kháng, hệ thống sẽ tự động hoàn 100% tiền vé kèm tặng voucher ưu đãi bắp nước cho lần xem kế tiếp, đồng thời gửi thông báo qua SMS và ứng dụng cho bạn.',
  },

  // 4. Voucher & Ưu đãi
  {
    id: 'faq-8',
    categoryId: 'voucher',
    question: 'Làm thế nào để áp dụng mã giảm giá / voucher khi đặt vé?',
    answer:
      'Tại bước Thanh Toán, bạn bấm vào ô "Nhập mã voucher hoặc chọn từ ví ưu đãi". Bạn có thể nhập mã trực tiếp hoặc chọn voucher khả dụng trong danh sách "Ưu đãi & Voucher cá nhân" để được áp dụng giảm giá tức thì.',
  },
  {
    id: 'faq-9',
    categoryId: 'voucher',
    question: 'Một đơn hàng có thể dùng nhiều voucher cùng lúc không?',
    answer:
      'Mỗi đơn hàng chỉ áp dụng 01 voucher giảm giá vé. Tuy nhiên, bạn có thể áp dụng đồng thời voucher giảm giá bắp nước và chương trình giảm trừ bằng điểm CinePoints.',
  },

  // 5. Tài khoản & CinePoints
  {
    id: 'faq-10',
    categoryId: 'account',
    question: 'Điểm tích lũy CinePoints được tính như thế nào và dùng để làm gì?',
    answer:
      'Với mỗi 10.000₫ chi tiêu, bạn nhận từ 5 đến 10 điểm CinePoints (tùy theo hạng thành viên Standard, Gold hoặc Diamond VIP). 1.000 điểm tương đương 10.000₫ tiền mặt, có thể dùng trực tiếp để thanh toán vé xem phim và combo bắp nước.',
  },
  {
    id: 'faq-11',
    categoryId: 'account',
    question: 'Làm thế nào để nâng cấp lên hạng thẻ Diamond VIP?',
    answer:
      'Hạng Diamond VIP được xét duyệt tự động khi tổng chi tiêu tích lũy trong năm đạt từ 3.000.000₫ hoặc xem từ 20 vé phim. Quyền lợi bao gồm hoàn vé 100%, ưu tiên quầy VIP Lounge, quà sinh nhật đặc quyền và nhân đôi điểm tích lũy.',
  },

  // 6. Sự cố kỹ thuật
  {
    id: 'faq-12',
    categoryId: 'technical',
    question: 'Tiền đã bị trừ trong tài khoản ngân hàng nhưng chưa có mã vé thì xử lý sao?',
    answer:
      'Đôi khi cổng thanh toán ngân hàng có độ trễ xác nhận từ 1–3 phút. Vui lòng kiểm tra lại mục "Đơn Của Tôi" sau ít phút. Nếu sau 5 phút vẫn chưa thấy vé, hãy liên hệ ngay hotline 1900 8888 hoặc chat với CSKH kèm mã giao dịch ngân hàng để được kích hoạt vé ngay lập tức.',
  },
  {
    id: 'faq-13',
    categoryId: 'technical',
    question: 'Ứng dụng không hiển thị mã QR vé khi tôi đến rạp?',
    answer:
      'Bạn có thể kiểm tra kết nối mạng internet hoặc mở email xác nhận vé có đính kèm mã QR. Ngoài ra, bạn chỉ cần đọc số điện thoại tài khoản đăng ký tại quầy vé để nhân viên hỗ trợ in vé vật lý trong 30 giây.',
  },
];
