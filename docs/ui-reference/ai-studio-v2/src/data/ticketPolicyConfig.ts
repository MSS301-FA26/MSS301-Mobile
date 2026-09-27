import { TicketTypeItem } from '../types';

export const MAX_TICKETS_PER_BOOKING = 8;

export interface SeatSurchargeConfig {
  standard: number;
  vip: number;
  couple: number;
}

export const SEAT_SURCHARGES: SeatSurchargeConfig = {
  standard: 0,
  vip: 20000,
  couple: 60000, // Phụ thu cho ghế đôi (cặp 2 người)
};

export interface TicketPolicyConfig {
  maxTicketsPerBooking: number;
  surcharges: SeatSurchargeConfig;
  defaultTypes: Omit<TicketTypeItem, 'unitPrice'>[];
  calculateUnitPrice: (code: 'ADULT' | 'STUDENT' | 'CHILD', basePrice: number) => number;
}

export const TICKET_POLICY_CONFIG: TicketPolicyConfig = {
  maxTicketsPerBooking: MAX_TICKETS_PER_BOOKING,
  surcharges: SEAT_SURCHARGES,
  defaultTypes: [
    {
      id: 'ticket-adult',
      code: 'ADULT',
      name: 'Người lớn',
      description: 'Vé tiêu chuẩn',
      policyDescription:
        'Vé tiêu chuẩn áp dụng cho mọi đối tượng khán giả từ 13 tuổi trở lên phù hợp với phân loại độ tuổi của bộ phim.',
      isAvailable: true,
      requiresVerification: false,
      icon: 'person',
    },
    {
      id: 'ticket-student',
      code: 'STUDENT',
      name: 'Sinh viên',
      description: 'Xuất trình thẻ sinh viên còn hiệu lực khi được yêu cầu',
      policyDescription:
        'Áp dụng cho học sinh, sinh viên các trường THPT, trung cấp, cao đẳng, đại học trên toàn quốc có thẻ HSSV còn thời hạn hoặc CCCD/VNeID thể hiện dưới 22 tuổi. Vui lòng xuất trình thẻ gốc hoặc giấy tờ hợp lệ khi nhân viên soát vé yêu cầu.',
      isAvailable: true,
      requiresVerification: true,
      icon: 'school',
    },
    {
      id: 'ticket-child',
      code: 'CHILD',
      name: 'Trẻ em',
      description: 'Theo quy định độ tuổi và chiều cao tại rạp CineAI Central',
      policyDescription:
        'Áp dụng cho trẻ em có chiều cao dưới 1m30 hoặc dưới 13 tuổi đi cùng người lớn giám hộ. Không áp dụng cho các suất chiếu có phân loại độ tuổi T16, T18. Vui lòng xuất trình giấy khai sinh hoặc giấy tờ chứng minh độ tuổi khi nhân viên soát vé yêu cầu.',
      isAvailable: true,
      requiresVerification: true,
      icon: 'child_care',
    },
  ],
  calculateUnitPrice: (code: 'ADULT' | 'STUDENT' | 'CHILD', basePrice: number): number => {
    switch (code) {
      case 'ADULT':
        return Math.max(0, basePrice);
      case 'STUDENT':
        return Math.max(0, basePrice - 10000);
      case 'CHILD':
        return Math.max(0, basePrice - 20000);
      default:
        return Math.max(0, basePrice);
    }
  },
};
