export interface CinemaRoomInfo {
  id: string;
  name: string;
  format: string;
  description: string;
}

export interface CinemaConfig {
  id: string;
  name: string;
  address: string;
  amenities: string[];
  features: string[]; // Alias for amenities
  rooms: CinemaRoomInfo[];
  operatingHours: string;
  hotline: string;
  statusText: string;
}

export const CINEMA_CONFIG: CinemaConfig = {
  id: 'central',
  name: 'CineAI Central',
  address: 'Tầng 5, 1 Nguyễn Huệ, P. Bến Nghé, Quận 1, TP.HCM',
  amenities: ['IMAX Laser', 'Dolby Atmos 7.1', 'Ghế VIP Bed'],
  features: ['IMAX Laser', 'Dolby Atmos 7.1', 'Ghế VIP Bed'],
  rooms: [
    {
      id: 'room-a',
      name: 'Phòng A',
      format: 'IMAX Laser',
      description: 'Màn chiếu 22m • Độ phân giải 4K Laser • Ghế VIP',
    },
    {
      id: 'room-b',
      name: 'Phòng B',
      format: 'Standard 2D',
      description: 'Màn chiếu Laser sắc nét • Phụ đề tiếng Việt chuẩn quốc tế',
    },
    {
      id: 'room-c',
      name: 'Phòng C',
      format: 'Dolby Atmos 7.1',
      description: 'Hệ thống âm thanh vòm 64 kênh • Ghế VIP Bed cao cấp',
    },
  ],
  operatingHours: '08:00 - 01:00 (Hàng ngày)',
  hotline: '1900 2026',
  statusText: 'Đang mở cửa • 08:00 - 01:00',
};

// Singleton array for components expecting an array of cinemas
export const CINEMAS: CinemaConfig[] = [CINEMA_CONFIG];
