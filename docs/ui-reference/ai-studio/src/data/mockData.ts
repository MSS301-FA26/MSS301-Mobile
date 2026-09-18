import { Movie, MovieShowtime, ConcessionItem, TicketOrder, WalletTransaction } from '../types';
import { CINEMA_CONFIG, CINEMAS } from './cinemaConfig';

export { CINEMA_CONFIG, CINEMAS };

export const MOVIES: Movie[] = [
  {
    id: 'inception',
    title: 'INCEPTION',
    originalTitle: 'Inception',
    ageRating: 'T13',
    ageRatingBg: 'bg-[#F5B800] text-black font-bold',
    duration: '148 phút',
    durationMinutes: 148,
    rating: 8.8,
    ratingCount: '12.4k đánh giá',
    formats: ['IMAX Laser', 'Dolby Atmos', '2D Phụ đề'],
    genres: ['Hành Động', 'Khoa Học Viễn Tưởng', 'Kịch Tính'],
    audioInfo: 'Tiếng Anh - Phụ đề TV',
    tagline: 'Giấc mơ trong giấc mơ - Đỉnh cao điện ảnh của Christopher Nolan.',
    synopsis:
      'Dom Cobb (Leonardo DiCaprio) là một nghệ nhân siêu việt chuyên về trích xuất thông tin bí mật sâu thẳm trong tiềm thức khi đối tượng đang chìm trong giấc mơ. Kỹ năng phi thường biến anh thành lính đánh thuê đắt giá nhất giới gián điệp tập đoàn, nhưng cũng khiến anh mất đi tất cả những gì yêu thương nhất. Để có cơ hội chuộc lại cuộc đời và trở về với các con, Cobb phải thực hiện phi vụ cuối cùng gần như bất khả thi: “Inception” – gieo cấy một ý tưởng mới vào tâm trí kẻ thừa kế tập đoàn quyền lực thay vì đánh cắp nó.',
    posterUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDwTrsHxNqpRGlfuwHetB0WPAEjvcvkAAIXRaXPWsf52HrgdeoLozwqLs4kHaqFJ-GRq4nisAK_XAzdTP94D-Oep6ylsP_07EfXzsgbat1La-WpNL9a3Mz1N4NJPtGBJTSPf7cD6HYMjPXCQj-il6tGMiuzjH4TQcpXLzq8IMzbJWATqqGe-A3-Wwea6H00O34BpvNuSe92LKq8Vqtr15AfDJ_OLmHvruQ0boHB4cC_4hkNVUMv0WMi',
    bannerUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuALrn8YQrG5SCX_RasRsBCVQsm39-2KdXhLFOlgiQOJPwXEumR78Mi--NDU9xaos_efGod65CMjA61fov-HJf8v1jkCgcHsgLmT4Cu9mSypMvgKX5Z6OjE85ePfIUeV7PccY9hBt-sapCJLfyG4bgHW2KrTqi1QDMxJrziWmpucF7fUgEjHwsCZFEElzuw4VZZfja9qvSpVhHMGmkFRH7VZ72_LDthObGY15R-Nw94dpwxhpd1ruzny',
    trailerUrl: 'https://www.youtube.com/watch?v=YoHD9XEInc0',
    isNowShowing: true,
    stats: {
      cineScore: 95,
      boxOfficeRank: 'TOP 1',
      formatDisplay: '2D IMAX',
    },
    director: {
      name: 'C. Nolan',
      role: 'Đạo diễn',
      avatarUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuD__vBDH2n7iu9sF2i4eYF1YkOJn8gR8MldMnlb_cHnT20V8l47mXARpt8puY_FTsonxWxLIv79EzGoLVB9eNutHxA9t0VXz2JG2g7vLlp3tJVEtlYCPk3eoEDIwB7_ZsVTmtFFG7ki9bLHP5FQabm4iRfWuy6Qw736CnAYRM_RSQelZn2OxnBL-pU-XXa2RqI0MdwJDyHsVaG2Tewg5bF7NsmJw-f4AwynEgAEXc8TTzFxLUkuXPmW',
    },
    cast: [
      {
        name: 'L. DiCaprio',
        character: 'Dom Cobb',
        avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDAmkLO5g0sqKphfdMFAru71-0V_3Vzr0kn1NwyUr4DspSiVMpbOgLNxHZphJ37B1Aa0hj0P2Cmyj2SwJzcTCRF7fXQ2MpaC0DNKHGqK_mI4WO_kkDBcRVExaL9kSk_0b8-6Ny-hq9lN7gbR5whZ0mxSohmCSF8ppYmXdJ41nVu54uzHIxHuXK-FfoH8gMxposvevCpvwbukeDBfYARFJKE5hmaIoXFZQAiSG2Bo6qIJsHiB9poo5k2',
      },
      {
        name: 'J. Gordon-Levitt',
        character: 'Arthur',
        avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDjm_giyuYEVNTD9TRfJz0lMsQjNEwGes5rFQfqI33E1ieEaBtTTcPZcW9z4H0v50YhS0YNa4e90ytndebFl2nkg1SviB1ETNmbiBrSviwCE0o4LxgRdm03ix4RPHEaYfDmXp2g2_0DJ9MVLfEAl4sjdixQqA5-EAd4GjDDKopQxZzFEc9rRwB13lUg0y77MhX9JGq3njHN92pZa5U-3U-QZZi3d6Iwj5WB2Lbx7Ux-ElSfQZpNgTIl',
      },
      {
        name: 'Elliot Page',
        character: 'Ariadne',
        avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuA8qHgnkHve_y5x6UAboJ5A7xicrwPrKxiYxw9r4bZEq42hskpPqinempsBqUSLnVjykJCJruQO0Z-GUsPPyEdQzjAOfsApmpOWr6QrpVJO8gWIZbaHHDSaOieznCxkdLmSLyngspRsSAZS3HYPtIkirQrlJUu0I7ql3XRLy3rkKkdRepk9nh416cHO-9mqSQCJ4p8V4nD5IP-6Y0ijvjvfhbBbHLppeaedNdituO442wyv31sqcwDz',
      },
      {
        name: 'Tom Hardy',
        character: 'Eames',
        avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuBmh11koZFb0N-9RsNk6k8bosXSWxRilF62-JVoJ_n5drdc9SvnAw99j4O3lVXk4cFWkND-VLSDGnE12kSNcTiOf1ZZhECGw4SKdVJH3UdCNOe4rx9S_DwGgbnn3bKIW8IZzecLwuPPX9K1CaiSELfL4C0fpUkGGxIR10JX970DYx6OG9EtQAtIo1jTSrlK1zKjxzu-2om6xcRU0QlmyczPAyymhHDZEwcNQD_UKCkgMdOaiW_aEugg',
      },
    ],
    reviews: [
      {
        id: 'r1',
        userName: 'Vy Nguyễn',
        userAvatarBg: 'bg-secondary-container text-secondary',
        date: 'Hôm qua',
        location: 'Chiếu tại CineAI Central',
        rating: 10,
        verifiedTicket: true,
        comment:
          'Xem lại trên màn chiếu IMAX vẫn choáng ngợp như lần đầu tiên năm 2010. Âm thanh nhạc nền của Hans Zimmer rung chuyển cả lồng ngực!',
      },
      {
        id: 'r2',
        userName: 'Tuấn Anh Trịnh',
        userAvatarBg: 'bg-surface-container-high text-on-surface-variant',
        date: '2 ngày trước',
        location: 'Ghế VIP đôi',
        rating: 9.5,
        verifiedTicket: true,
        seatInfo: 'Ghế VIP đôi',
        comment:
          'Kịch bản đa tầng vô cùng chặt chẽ. Kết phim con quay vẫn xoay làm cả rạp nín thở bàn tán sôi nổi. Rất đáng tiền trải nghiệm.',
      },
    ],
  },
  {
    id: 'avengers-endgame',
    title: 'AVENGERS: ENDGAME',
    originalTitle: 'Avengers: Endgame',
    ageRating: '13+',
    ageRatingBg: 'bg-[#F5B800]/20 text-[#F5B800]',
    duration: '181 phút',
    durationMinutes: 181,
    rating: 9.4,
    ratingCount: '12.8k',
    formats: ['IMAX 3D', 'Standard 2D', 'Dolby Atmos'],
    genres: ['Hành động', 'Siêu anh hùng', 'Viễn tưởng'],
    audioInfo: 'Tiếng Anh - Phụ đề tiếng Việt',
    tagline: 'Một phần của hành trình chính là hồi kết. Cuộc hội ngộ định mệnh của vũ trụ.',
    synopsis:
      'Sau những sự kiện tàn khốc của Avengers: Infinity War, vũ trụ bị hủy hoại do hành động của Thanos. Với sự trợ giúp của các đồng minh còn lại, biệt đội Avengers phải tập hợp một lần nữa nhằm đảo ngược hậu quả và khôi phục lại trật tự vũ trụ.',
    posterUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCoibEVTPnD-Vv77RVMI1jJcGp1zV4MpFDvPXSjikGPSQZ7vDWTb6sbxNSgFuJQ953nCWgRK6SJ_wqWe9YCx7SRPmCeMgMu85QheBpGv5AgCiI-Y6vzUv2sCVVpLv5zHqqBUuOCn1spOHRckVSOIYARKYzIar-Ybj1C6P1wbUp4aKiv_HarzpWQeHGK6dPGe0-clLr88MwSr05PXWfAAPLT0y_etGbW_fYoD1FfuVySPp12798yHbGL',
    bannerUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD0ReogOOTaEbfC8hz_cZdEJEyxtkKpcYKe5taunOhvynEB_6_-8E1R1zwEUF7F0JkPe_55-bmJJCJ7ZcHMS4rs2sFSD9fPV3J-noLU0Mce3WC9PgFWHJHalL69iDoVmyV5mt9HiEnqCTgdI6yxLGuz0bKltGE9U4eQFs2kL9WEpOv7L7lbkyKvQE80v19RxE9PaNWFq3XR3o0uSDWzbVBqkGz3SaobDWD-RvUwxi2O1YLw0DEqFPlO',
    isNowShowing: true,
    director: {
      name: 'Anthony & Joe Russo',
      role: 'Đạo diễn',
      avatarUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuD__vBDH2n7iu9sF2i4eYF1YkOJn8gR8MldMnlb_cHnT20V8l47mXARpt8puY_FTsonxWxLIv79EzGoLVB9eNutHxA9t0VXz2JG2g7vLlp3tJVEtlYCPk3eoEDIwB7_ZsVTmtFFG7ki9bLHP5FQabm4iRfWuy6Qw736CnAYRM_RSQelZn2OxnBL-pU-XXa2RqI0MdwJDyHsVaG2Tewg5bF7NsmJw-f4AwynEgAEXc8TTzFxLUkuXPmW',
    },
    cast: [
      {
        name: 'Robert Downey Jr.',
        character: 'Tony Stark / Iron Man',
        avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDAmkLO5g0sqKphfdMFAru71-0V_3Vzr0kn1NwyUr4DspSiVMpbOgLNxHZphJ37B1Aa0hj0P2Cmyj2SwJzcTCRF7fXQ2MpaC0DNKHGqK_mI4WO_kkDBcRVExaL9kSk_0b8-6Ny-hq9lN7gbR5whZ0mxSohmCSF8ppYmXdJ41nVu54uzHIxHuXK-FfoH8gMxposvevCpvwbukeDBfYARFJKE5hmaIoXFZQAiSG2Bo6qIJsHiB9poo5k2',
      },
      {
        name: 'Chris Evans',
        character: 'Steve Rogers / Captain America',
        avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDjm_giyuYEVNTD9TRfJz0lMsQjNEwGes5rFQfqI33E1ieEaBtTTcPZcW9z4H0v50YhS0YNa4e90ytndebFl2nkg1SviB1ETNmbiBrSviwCE0o4LxgRdm03ix4RPHEaYfDmXp2g2_0DJ9MVLfEAl4sjdixQqA5-EAd4GjDDKopQxZzFEc9rRwB13lUg0y77MhX9JGq3njHN92pZa5U-3U-QZZi3d6Iwj5WB2Lbx7Ux-ElSfQZpNgTIl',
      },
    ],
  },
  {
    id: 'joker',
    title: 'Joker',
    originalTitle: 'Joker',
    ageRating: '18+',
    ageRatingBg: 'bg-rose-600/90 text-on-surface',
    duration: '122p',
    durationMinutes: 122,
    rating: 8.9,
    ratingCount: '9.8k',
    formats: ['2D Digital', 'IMAX'],
    genres: ['Tội phạm', 'Tâm lý'],
    audioInfo: 'Tiếng Anh - Phụ đề tiếng Việt',
    tagline: 'Hãy luôn giữ nụ cười trên môi trong thành phố Gotham tăm tối.',
    synopsis:
      'Arthur Fleck, một diễn viên hài thất bại luôn bị cô lập và ruồng bỏ bởi xã hội Gotham, dần chìm sâu vào sự điên loạn và trở thành kẻ chủ mưu tội ác khét tiếng mang danh Joker.',
    posterUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAxJ08o5aHGf7JtcRQeOXPndwuURBJqoodykZU5qVsVB94BJA0mt2LS1nG21HVK4B5gzcXHkKUik2AlYRnRx1mJSD0WL5KKic9apeiBPAbCZXOYvPSJpDrHybOXFzag-odPwlKT6cdD9Gk4rpZpe-4NQE7492lYyni1UtUZ8oDk2qspaEbL6y_oQZgGSSDc8pd9j7e4pVqnTTaRKx02keqlK3-ZsYd6XCyNyke0E5BQzWrLqhYPiK8d',
    bannerUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAxJ08o5aHGf7JtcRQeOXPndwuURBJqoodykZU5qVsVB94BJA0mt2LS1nG21HVK4B5gzcXHkKUik2AlYRnRx1mJSD0WL5KKic9apeiBPAbCZXOYvPSJpDrHybOXFzag-odPwlKT6cdD9Gk4rpZpe-4NQE7492lYyni1UtUZ8oDk2qspaEbL6y_oQZgGSSDc8pd9j7e4pVqnTTaRKx02keqlK3-ZsYd6XCyNyke0E5BQzWrLqhYPiK8d',
    isNowShowing: true,
    director: {
      name: 'Todd Phillips',
      role: 'Đạo diễn',
      avatarUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuD__vBDH2n7iu9sF2i4eYF1YkOJn8gR8MldMnlb_cHnT20V8l47mXARpt8puY_FTsonxWxLIv79EzGoLVB9eNutHxA9t0VXz2JG2g7vLlp3tJVEtlYCPk3eoEDIwB7_ZsVTmtFFG7ki9bLHP5FQabm4iRfWuy6Qw736CnAYRM_RSQelZn2OxnBL-pU-XXa2RqI0MdwJDyHsVaG2Tewg5bF7NsmJw-f4AwynEgAEXc8TTzFxLUkuXPmW',
    },
    cast: [
      {
        name: 'Joaquin Phoenix',
        character: 'Arthur Fleck / Joker',
        avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDAmkLO5g0sqKphfdMFAru71-0V_3Vzr0kn1NwyUr4DspSiVMpbOgLNxHZphJ37B1Aa0hj0P2Cmyj2SwJzcTCRF7fXQ2MpaC0DNKHGqK_mI4WO_kkDBcRVExaL9kSk_0b8-6Ny-hq9lN7gbR5whZ0mxSohmCSF8ppYmXdJ41nVu54uzHIxHuXK-FfoH8gMxposvevCpvwbukeDBfYARFJKE5hmaIoXFZQAiSG2Bo6qIJsHiB9poo5k2',
      },
    ],
  },
  {
    id: 'spider-verse',
    title: 'Spider-Verse',
    originalTitle: 'Spider-Man: Into the Spider-Verse',
    ageRating: 'P',
    ageRatingBg: 'bg-emerald-500/90 text-black',
    duration: '117p',
    durationMinutes: 117,
    rating: 9.1,
    ratingCount: '15.2k',
    formats: ['IMAX Laser', '2D Lồng tiếng'],
    genres: ['Hoạt hình', 'Hành động', 'Phiêu lưu'],
    audioInfo: 'Lồng tiếng chuẩn rạp',
    tagline: 'Bất cứ ai cũng có thể đeo mặt nạ người nhện.',
    synopsis:
      'Thiếu niên Brooklyn Miles Morales bất ngờ có siêu năng lực và nhận ra rằng có vô số vũ trụ đa chiều cùng những Người Nhện khác cùng tồn tại.',
    posterUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuB7tFJgBIqVsvLNTdABQVJmNSvPEna_prFOMEgROW9D0uv1u9KvaZoK9IaU88uWncGE4LPGhgSzvt7JC_AfqqOJy9W72PyPvzdPuvI9VLPnSCcTOTM6OW2MGzmIE7MKN7JPusdypLnl110j-GsK3MiN3hzDUjr7XU2kuogZuc_2iL7jrdbDpOrb2r7dzkl7OFzIqmHazBjpV-IeJ2yrRqQxVE2N2X_c-Hz-CPhBTSlpE4NPl8p2bHbT',
    bannerUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCD5d8xFskvd9l-7xHbFtlZmx-9W78KUEs8c1DVcYpVLNyZje7LSCGOXszK_gB4vGSx8O4Wv0NfaE7tvuCfAtUxU9cIVkjrKzSKnZdbCLha8oCAdK7-uFq87bFDscjK-WmUxFsRwQpcnNxQ_XecdQ9xc-rFaOsMAiN9ZkzUwrKZ1tzHxI9n0ixORgjdHNOtWWy9NaNgwwog67WCdRW83uLbhBXmx-p_Km5lBcivuQFVtpi1e18R7oKL',
    isNowShowing: true,
    director: {
      name: 'Bob Persichetti, Peter Ramsey',
      role: 'Đạo diễn',
      avatarUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuD__vBDH2n7iu9sF2i4eYF1YkOJn8gR8MldMnlb_cHnT20V8l47mXARpt8puY_FTsonxWxLIv79EzGoLVB9eNutHxA9t0VXz2JG2g7vLlp3tJVEtlYCPk3eoEDIwB7_ZsVTmtFFG7ki9bLHP5FQabm4iRfWuy6Qw736CnAYRM_RSQelZn2OxnBL-pU-XXa2RqI0MdwJDyHsVaG2Tewg5bF7NsmJw-f4AwynEgAEXc8TTzFxLUkuXPmW',
    },
    cast: [
      {
        name: 'Shameik Moore',
        character: 'Miles Morales',
        avatarUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuDAmkLO5g0sqKphfdMFAru71-0V_3Vzr0kn1NwyUr4DspSiVMpbOgLNxHZphJ37B1Aa0hj0P2Cmyj2SwJzcTCRF7fXQ2MpaC0DNKHGqK_mI4WO_kkDBcRVExaL9kSk_0b8-6Ny-hq9lN7gbR5whZ0mxSohmCSF8ppYmXdJ41nVu54uzHIxHuXK-FfoH8gMxposvevCpvwbukeDBfYARFJKE5hmaIoXFZQAiSG2Bo6qIJsHiB9poo5k2',
      },
    ],
  },
  {
    id: 'coco',
    title: 'Coco',
    originalTitle: 'Coco',
    ageRating: 'P',
    ageRatingBg: 'bg-emerald-500/90 text-black',
    duration: '105p',
    durationMinutes: 105,
    rating: 9.3,
    ratingCount: '11.1k',
    formats: ['2D Lồng tiếng', 'Dolby Atmos'],
    genres: ['Gia đình', 'Âm nhạc'],
    audioInfo: 'Lồng tiếng Việt',
    tagline: 'Âm nhạc mở lối trở về cội nguồn yêu thương.',
    synopsis:
      'Cậu bé Miguel ấp ủ ước mơ trở thành nghệ sĩ guitar tài hoa bất chấp sự cấm đoán của gia đình. Chuyến phiêu lưu kỳ diệu vào Vùng Đất Linh Hồn hé lộ những bí ẩn gia đình nhiều thế hệ.',
    posterUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDmHzD_4m5tXtS5vLBwzzY4KmQhE-jWKpciRoqTs06v2ZBi8uTXGuCJg9o8lDiw5UNKMjeU_3-crRYuVelf7dmsCLfGpmpjHkLQ0CWz3wGBx43cbl_R2uqMezKXBXwgKDQRNpwCNRPUTiIjo4Fn_fsYxXE8wEI6X9cEjteJ82ctpHxrGs-CAyW02CJ2lyr3izu4ERRxJxEjd1nwz98TiFyq5J73UacsisQgEFqqm-Q1CbkmGwa5gJlr',
    bannerUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDmHzD_4m5tXtS5vLBwzzY4KmQhE-jWKpciRoqTs06v2ZBi8uTXGuCJg9o8lDiw5UNKMjeU_3-crRYuVelf7dmsCLfGpmpjHkLQ0CWz3wGBx43cbl_R2uqMezKXBXwgKDQRNpwCNRPUTiIjo4Fn_fsYxXE8wEI6X9cEjteJ82ctpHxrGs-CAyW02CJ2lyr3izu4ERRxJxEjd1nwz98TiFyq5J73UacsisQgEFqqm-Q1CbkmGwa5gJlr',
    isNowShowing: true,
    director: {
      name: 'Lee Unkrich',
      role: 'Đạo diễn',
      avatarUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuD__vBDH2n7iu9sF2i4eYF1YkOJn8gR8MldMnlb_cHnT20V8l47mXARpt8puY_FTsonxWxLIv79EzGoLVB9eNutHxA9t0VXz2JG2g7vLlp3tJVEtlYCPk3eoEDIwB7_ZsVTmtFFG7ki9bLHP5FQabm4iRfWuy6Qw736CnAYRM_RSQelZn2OxnBL-pU-XXa2RqI0MdwJDyHsVaG2Tewg5bF7NsmJw-f4AwynEgAEXc8TTzFxLUkuXPmW',
    },
    cast: [],
  },
  {
    id: 'the-green-mile',
    title: 'The Green Mile',
    originalTitle: 'The Green Mile',
    ageRating: '16+',
    ageRatingBg: 'bg-surface-container-lowest/80 text-primary',
    duration: '189 phút',
    durationMinutes: 189,
    rating: 8.6,
    ratingCount: '8.4k',
    formats: ['Restored 4K'],
    genres: ['Tội phạm', 'Kịch tính', 'Kỳ ảo kinh điển'],
    audioInfo: 'Phụ đề tiếng Việt',
    tagline: 'Điều kỳ diệu xảy ra ở những nơi bạn ít ngờ tới nhất.',
    synopsis:
      'Cuộc sống của các quản giáo tại khu tử tù Cold Mountain đảo lộn hoàn toàn khi tiếp nhận John Coffey – một người đàn ông da đen to lớn mang trái tim thánh thiện cùng năng lực chữa lành siêu nhiên.',
    posterUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuB0TEqvv177B43UkfhKkSafyLTNZCkF7A14hnGuxxU_cCwk1s5MWAS-0t6ZS64Ny367pbUkGwb4_UH6fQzdQvPR0W25HKBZ9YLoRCxXgu4k3Ol6-7t8YdvjljGjoOtBTs7GDjR8VPqHaqNmKFNaSOmZ1uFU8D0oSLtpsfiX6J4rhRfY1TpwvLJIkO3i74xYLJ74v2cQC2wSwedTdIX5u6BBKhYsEPlBZ4H1IhRnl3p9BdXVWi8_Ulpe',
    bannerUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuB0TEqvv177B43UkfhKkSafyLTNZCkF7A14hnGuxxU_cCwk1s5MWAS-0t6ZS64Ny367pbUkGwb4_UH6fQzdQvPR0W25HKBZ9YLoRCxXgu4k3Ol6-7t8YdvjljGjoOtBTs7GDjR8VPqHaqNmKFNaSOmZ1uFU8D0oSLtpsfiX6J4rhRfY1TpwvLJIkO3i74xYLJ74v2cQC2wSwedTdIX5u6BBKhYsEPlBZ4H1IhRnl3p9BdXVWi8_Ulpe',
    isNowShowing: false,
    isComingSoon: true,
    releaseDate: 'Khởi chiếu 28.10',
    director: {
      name: 'Frank Darabont',
      role: 'Đạo diễn',
      avatarUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuD__vBDH2n7iu9sF2i4eYF1YkOJn8gR8MldMnlb_cHnT20V8l47mXARpt8puY_FTsonxWxLIv79EzGoLVB9eNutHxA9t0VXz2JG2g7vLlp3tJVEtlYCPk3eoEDIwB7_ZsVTmtFFG7ki9bLHP5FQabm4iRfWuy6Qw736CnAYRM_RSQelZn2OxnBL-pU-XXa2RqI0MdwJDyHsVaG2Tewg5bF7NsmJw-f4AwynEgAEXc8TTzFxLUkuXPmW',
    },
    cast: [],
  },
  {
    id: 'parasite',
    title: 'Parasite (Ký Sinh Trùng)',
    originalTitle: 'Parasite',
    ageRating: '18+',
    ageRatingBg: 'bg-rose-600/90 text-on-surface',
    duration: '132 phút',
    durationMinutes: 132,
    rating: 8.5,
    ratingCount: '14.6k',
    formats: ['Digital 4K'],
    genres: ['Hài đen kịch tính', 'Đoạt giải Oscar'],
    audioInfo: 'Phụ đề tiếng Việt',
    tagline: 'Khi lòng tham và sự dối trá xâm lấn một ngôi biệt thự xa hoa.',
    synopsis:
      'Gia đình nghèo khó Kim dần tìm cách thâm nhập vào cuộc sống của gia đình giàu có Park qua các danh phận giả, khởi đầu cho một chuỗi bi kịch không ai lường trước.',
    posterUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBRMT_iG2LA8qHUazNXlzDyM9bNVJM-Z0ryLXuX5WFAJ0qikUBYcNva6logCr3RNv63yi3WG65SIH7msyWKREmyHzN-c7rAX7h1dF9jOTWoa5p38cAnYFnX9OZI6BiB1XT5ceFAwaTSb4jvxrwfwVjHO_zvuKZOGymJLVMgl0ZMG_uPJvMjBk2TX2Vvl7KgmhvdJTzJO94EeOvPx_FOCN7FTdlVf5mn54WCb-uqoyknl96zWi5nY7J3',
    bannerUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBRMT_iG2LA8qHUazNXlzDyM9bNVJM-Z0ryLXuX5WFAJ0qikUBYcNva6logCr3RNv63yi3WG65SIH7msyWKREmyHzN-c7rAX7h1dF9jOTWoa5p38cAnYFnX9OZI6BiB1XT5ceFAwaTSb4jvxrwfwVjHO_zvuKZOGymJLVMgl0ZMG_uPJvMjBk2TX2Vvl7KgmhvdJTzJO94EeOvPx_FOCN7FTdlVf5mn54WCb-uqoyknl96zWi5nY7J3',
    isNowShowing: false,
    isComingSoon: true,
    releaseDate: 'Khởi chiếu 05.11',
    director: {
      name: 'Bong Joon-ho',
      role: 'Đạo diễn',
      avatarUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuD__vBDH2n7iu9sF2i4eYF1YkOJn8gR8MldMnlb_cHnT20V8l47mXARpt8puY_FTsonxWxLIv79EzGoLVB9eNutHxA9t0VXz2JG2g7vLlp3tJVEtlYCPk3eoEDIwB7_ZsVTmtFFG7ki9bLHP5FQabm4iRfWuy6Qw736CnAYRM_RSQelZn2OxnBL-pU-XXa2RqI0MdwJDyHsVaG2Tewg5bF7NsmJw-f4AwynEgAEXc8TTzFxLUkuXPmW',
    },
    cast: [],
  },
  {
    id: 'la-la-land',
    title: 'La La Land',
    originalTitle: 'La La Land',
    ageRating: 'P',
    ageRatingBg: 'bg-emerald-500/90 text-black',
    duration: '128 phút',
    durationMinutes: 128,
    rating: 8.9,
    ratingCount: '19.3k',
    formats: ['4K Remastered', 'Dolby Atmos'],
    genres: ['Âm nhạc lãng mạn', 'Tái chiếu bản 4K'],
    audioInfo: 'Phụ đề tiếng Việt',
    tagline: 'Dành cho những kẻ dại khờ dám ước mơ giữa thành phố Los Angeles hoa lệ.',
    synopsis:
      'Chuyện tình ngọt ngào nhưng đầy trăn trở giữa chàng nhạc sĩ Jazz tài hoa Sebastian và nữ diễn viên trẻ đầy khát vọng Mia tại kinh đô điện ảnh.',
    posterUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuC_SKwkFfGbiwRRn2RMgxpW85bDIXBaP-PDaz34mCNvnbkbD82Dk6sle6ctKFAEHjn8edToE359769a3I2MicXcuPj73ZuLBnoH8-tfH0Uk_IONA2PVsyZBzhVRBQDg8B4vbDVRWwrM_4Dzohn3p6ceJlpUjQMFZMbAGQXwgT4-aOzjBMrAuDjlzjMmHDW26uGwjr3uEjZhFbFtCRGTSX-ZtithCD-zsIL4ZS8MMWLFD6hw1T9EdB6m',
    bannerUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuC_SKwkFfGbiwRRn2RMgxpW85bDIXBaP-PDaz34mCNvnbkbD82Dk6sle6ctKFAEHjn8edToE359769a3I2MicXcuPj73ZuLBnoH8-tfH0Uk_IONA2PVsyZBzhVRBQDg8B4vbDVRWwrM_4Dzohn3p6ceJlpUjQMFZMbAGQXwgT4-aOzjBMrAuDjlzjMmHDW26uGwjr3uEjZhFbFtCRGTSX-ZtithCD-zsIL4ZS8MMWLFD6hw1T9EdB6m',
    isNowShowing: false,
    isComingSoon: true,
    releaseDate: 'Khởi chiếu 12.11',
    director: {
      name: 'Damien Chazelle',
      role: 'Đạo diễn',
      avatarUrl:
        'https://lh3.googleusercontent.com/aida-public/AB6AXuD__vBDH2n7iu9sF2i4eYF1YkOJn8gR8MldMnlb_cHnT20V8l47mXARpt8puY_FTsonxWxLIv79EzGoLVB9eNutHxA9t0VXz2JG2g7vLlp3tJVEtlYCPk3eoEDIwB7_ZsVTmtFFG7ki9bLHP5FQabm4iRfWuy6Qw736CnAYRM_RSQelZn2OxnBL-pU-XXa2RqI0MdwJDyHsVaG2Tewg5bF7NsmJw-f4AwynEgAEXc8TTzFxLUkuXPmW',
    },
    cast: [],
  },
];

export const SHOWTIMES_DATA: MovieShowtime[] = [
  {
    movieId: 'inception',
    movieTitle: 'INCEPTION',
    ageRating: 'T13',
    genres: 'Khoa học viễn tưởng • Kịch tính',
    duration: '148 phút',
    rating: 8.8,
    posterUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBVsZVxRPoydKCiwLGtenEv_knzlZ_Y0MhcMHc8CveTvBbfaMj1gQQM6yFpIjAHt7QOdwHrjw2JGoQa9KLqXp_Aid369Z7gSmGZveH0SoGqf0n2Gup-w9xaoLvBkWfWgr07QAczo2Mmpbfgm_tYqqHlJAn7VG8FcvbCIU2PdmIc-mMhDOX_ANiaGi_LOMhnxyx_fGApAuYNJTwCPscF9-uUu7QR3d9XAzh0_tm93Rdviu0kGROfn6hR',
    rooms: [
      {
        id: 'room-a-imax',
        roomName: 'Phòng A',
        formatBadge: 'IMAX Laser',
        screenDetail: 'Màn chiếu 22m • Laser 4K',
        slots: [
          {
            id: 'slot-inc-a-1',
            time: '16:30',
            endTime: '~18:58',
            priceDisplay: 'Từ 110.000₫',
            price: 110000,
            roomName: 'Phòng A',
            formatBadge: 'IMAX Laser',
            formatBadgeType: 'secondary',
            screenDetail: 'Màn chiếu 22m • Laser 4K',
          },
          {
            id: 'slot-inc-a-2',
            time: '19:30',
            endTime: '~21:58',
            priceDisplay: 'Từ 130.000₫',
            price: 130000,
            roomName: 'Phòng A',
            formatBadge: 'IMAX Laser',
            formatBadgeType: 'secondary',
            screenDetail: 'Màn chiếu 22m • Laser 4K',
          },
          {
            id: 'slot-inc-a-3',
            time: '22:15',
            endTime: '~00:43',
            priceDisplay: 'Từ 95.000₫',
            price: 95000,
            roomName: 'Phòng A',
            formatBadge: 'IMAX Laser',
            formatBadgeType: 'secondary',
            screenDetail: 'Màn chiếu 22m • Laser 4K',
          },
        ],
      },
      {
        id: 'room-c-dolby',
        roomName: 'Phòng C',
        formatBadge: 'Dolby Atmos',
        screenDetail: 'Âm thanh 64 kênh 3D',
        slots: [
          {
            id: 'slot-inc-c-1',
            time: '18:00',
            endTime: '~20:28',
            priceDisplay: 'Từ 90.000₫',
            price: 90000,
            roomName: 'Phòng C',
            formatBadge: 'Dolby Atmos',
            formatBadgeType: 'primary',
            screenDetail: 'Âm thanh 64 kênh 3D',
          },
          {
            id: 'slot-inc-c-2',
            time: '20:30',
            endTime: '~22:58',
            priceDisplay: '90.000₫',
            price: 90000,
            isSelected: true,
            roomName: 'Phòng C',
            formatBadge: 'Dolby Atmos',
            formatBadgeType: 'primary',
            screenDetail: 'Âm thanh 64 kênh 3D',
          },
          {
            id: 'slot-inc-c-3',
            time: '23:00',
            endTime: 'Hết chỗ',
            priceDisplay: '0 ghế trống',
            price: 90000,
            isSoldOut: true,
            roomName: 'Phòng C',
            formatBadge: 'Dolby Atmos',
            formatBadgeType: 'neutral',
            screenDetail: 'Âm thanh 64 kênh 3D',
          },
        ],
      },
    ],
  },
  {
    movieId: 'avengers-endgame',
    movieTitle: 'AVENGERS: ENDGAME',
    ageRating: 'T13',
    genres: 'Hành động • Siêu anh hùng • Viễn tưởng',
    duration: '181 phút',
    rating: 8.4,
    posterUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCoibEVTPnD-Vv77RVMI1jJcGp1zV4MpFDvPXSjikGPSQZ7vDWTb6sbxNSgFuJQ953nCWgRK6SJ_wqWe9YCx7SRPmCeMgMu85QheBpGv5AgCiI-Y6vzUv2sCVVpLv5zHqqBUuOCn1spOHRckVSOIYARKYzIar-Ybj1C6P1wbUp4aKiv_HarzpWQeHGK6dPGe0-clLr88MwSr05PXWfAAPLT0y_etGbW_fYoD1FfuVySPp12798yHbGL',
    rooms: [
      {
        id: 'room-b-standard',
        roomName: 'Phòng B',
        formatBadge: 'Standard 2D',
        screenDetail: 'Phụ đề tiếng Việt',
        slots: [
          {
            id: 'slot-avg-b-1',
            time: '17:00',
            endTime: '~20:01',
            priceDisplay: '85.000₫',
            price: 85000,
            roomName: 'Phòng B',
            formatBadge: 'Standard 2D',
            formatBadgeType: 'neutral',
            screenDetail: 'Phụ đề tiếng Việt',
          },
          {
            id: 'slot-avg-b-2',
            time: '20:45',
            endTime: '~23:46',
            priceDisplay: '90.000₫',
            price: 90000,
            roomName: 'Phòng B',
            formatBadge: 'Standard 2D',
            formatBadgeType: 'neutral',
            screenDetail: 'Phụ đề tiếng Việt',
          },
        ],
      },
    ],
  },
  {
    movieId: 'spider-verse',
    movieTitle: 'SPIDER-MAN: INTO THE SPIDER-VERSE',
    ageRating: 'P',
    genres: 'Hoạt hình • Phiêu lưu • Hành động',
    duration: '117 phút',
    rating: 8.7,
    posterUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCD5d8xFskvd9l-7xHbFtlZmx-9W78KUEs8c1DVcYpVLNyZje7LSCGOXszK_gB4vGSx8O4Wv0NfaE7tvuCfAtUxU9cIVkjrKzSKnZdbCLha8oCAdK7-uFq87bFDscjK-WmUxFsRwQpcnNxQ_XecdQ9xc-rFaOsMAiN9ZkzUwrKZ1tzHxI9n0ixORgjdHNOtWWy9NaNgwwog67WCdRW83uLbhBXmx-p_Km5lBcivuQFVtpi1e18R7oKL',
    rooms: [
      {
        id: 'room-a-spiderman',
        roomName: 'Phòng A',
        formatBadge: 'IMAX Laser',
        screenDetail: 'Lồng tiếng chuẩn rạp',
        slots: [
          {
            id: 'slot-sp-a-1',
            time: '15:00',
            endTime: '~16:57',
            priceDisplay: '100.000₫',
            price: 100000,
            roomName: 'Phòng A',
            formatBadge: 'IMAX Laser',
            formatBadgeType: 'secondary',
            screenDetail: 'Lồng tiếng chuẩn rạp',
          },
          {
            id: 'slot-sp-a-2',
            time: '18:15',
            endTime: '~20:12',
            priceDisplay: '110.000₫',
            price: 110000,
            roomName: 'Phòng A',
            formatBadge: 'IMAX Laser',
            formatBadgeType: 'secondary',
            screenDetail: 'Lồng tiếng chuẩn rạp',
          },
        ],
      },
    ],
  },
];

export const CONCESSIONS_DATA: ConcessionItem[] = [
  {
    id: 'combo-couple',
    name: 'Combo Couple',
    description: '1 Bắp rang bơ lớn + 2 nước ngọt size L kèm ly thiết kế phim',
    price: 119000,
    category: 'combos',
    badge: 'HOT COMBO',
    quantity: 0,
    imageUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuB4v4tj5967br2Syjdx6v3NRmvQwrX_c5OA0_OR6Kz8FaPpZz0xzh9Tlag3t2O3s3KMnQcBYxAJsT2F9F_HN65y0tOnBRDaFZR6qDxl-xjquhdKKEkDwTI4Lg6TAw-31V8LzSMTf8xwYSmQpcqFehdnsWSiSRE1CuegoX21s53L8lo25ixmdLZPNzcaunG2v9v1cBwSmLm5RKLAzYcQCJP0_xQCKX3YqOuo1dgVw-6GKv-Lqw3W0iP8',
  },
  {
    id: 'bap-pho-mai',
    name: 'Bắp phô mai',
    description: 'Bắp rang nóng hổi phủ lớp bột phô mai Cheddar đậm đà thơm lừng',
    price: 55000,
    category: 'popcorn',
    badge: 'Đã chọn',
    quantity: 1,
    imageUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBY7LwpMXGz9LI6v3UcMcwNkUuB0VBbZUXr5oBJSq_INxRZQcM0by-aORo-P_eOk3DypZECscDeky6nLm3lpFeuGK7p2tMSDLher_Ik_8dhPH56tUW3a_RFPq1i4gLZABiXuKzDOKCOTHWEjGrqMF563G7L8tOyLBx5oOd4hsuBy55nyi4OU96ET3P0fd5dz0CRBAoPxleE3CLeKW4gz4rTsntKAfKRE90UvqHwPMMTgGKgoR9zUNwD',
  },
  {
    id: 'combo-solo',
    name: 'Combo Solo',
    description: '1 Bắp rang bơ vừa + 1 nước ngọt size L tùy chọn',
    price: 69000,
    category: 'combos',
    quantity: 0,
    imageUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBpitJkTowfP4NlJ-JWjp9n-RJ8DdAm9g1DMxsDc0h4f2iB_vf_ArM3d4BHV9Mph6jziIbJCQlakbszX6ekMTyhIuTKKmBWrir-NDHWBt7vXcMMgCsw6XPLXYonP6ewsJAMz1y-RhzMEiVOSSkuhhuQ4wGYoo36oeSKAomR5sM-pA8Tt7wApbSGS6OgtC9fAO_fkWfdt8vPYrt9qvmluKtcvcHBWmETsBU_j3lNqfoWiiYK_hNwnOEs',
  },
  {
    id: 'bap-bo',
    name: 'Bắp rang bơ',
    description: 'Bắp rang nổ tươi giòn rụm phủ bơ thơm ngọt ngào',
    price: 45000,
    category: 'popcorn',
    quantity: 0,
    imageUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAIieF321ouDD2Kt9vIz-QPP3ScixaKFn3y0dj9AC19829TtR5gXvSto2r_hYErh9ajyM-IpsjxAInfQQRU8aNDAYYQMvFqdWpSGJv7j9Z-o3MicObYDpDyQ4v3wA3DrDxxl3k9mT5zN33-h7mqTzTlFpylgKOfC6ufJtg3JTq0M9D-sRXHYNFBGdVnXpq5fWu2aztnAB1Eo_SyuCs9d5y003LEMo8550auFEGhxyHo76Yj50VpbN25',
  },
  {
    id: 'coca-cola',
    name: 'Coca-Cola (L)',
    description: 'Ly Coca-Cola có gas ướp đá mát lạnh sảng khoái size 32oz',
    price: 30000,
    category: 'drinks',
    quantity: 0,
    imageUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuAwazp8AOTI5XWJJYSEOvMI_SJXHE5oDN2Ntpoi2jml5sSibHkwfL5mRigD0dJnpaBuOF8F4Ctw82qI26zgmrV5JTova01OMaHZhqQSEeUM5vMt167hMJ4S6qP82ikSiGEn2ViXG9zmgo_g3d2ZAsPzcdSI9pnRvzJY6_5M8yZEVUU1IzE5C3o8TrtpsucCN25_7ski8xNa_dCs-OokAe1R7tb8lfuqIx7c8TlVKDiPBYXdt3lTYNqN',
  },
  {
    id: 'aquafina',
    name: 'Nước suối Aquafina',
    description: 'Nước tinh khiết đóng chai 500ml ướp lạnh tiện lợi',
    price: 20000,
    category: 'drinks',
    quantity: 0,
    imageUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBhXGtWke2t7TKvuDZnmvoQpBmxhAy2-L8nbpuX-9wR3ooEV1UvTdWW1OQtGtQ8xWxC_k30dt-vuEf0TLtSkpo1aDuQqPRR7qJOb2XJeYxWEBtpvPEBGvuvZXuvBzOQgNb5-L1ZCh7G-iGkBT9zL-XTwtLRrDZSCHuOcrAqUPjGiu2Fze4_9cXxVL8QdmOkQnlyaEDvC2XE_fl-hJJTAtxLpLKF9QLv0HxwnifxabuuiYUTME4Ge3q8',
  },
  {
    id: 'combo-family',
    name: 'Combo Family',
    description: '2 Bắp lớn (tự chọn vị) + 4 ly nước ngọt size L cực đã',
    price: 229000,
    category: 'combos',
    quantity: 0,
    imageUrl:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuDbMg7rBVPFASjZF6n4zcdFpTF4mpTbK4gFzzR5R8P0VHw3Umn9M4yMMW-koRM0NZlMo3PXcALGsBs5GcYDV-ZWRZXRIT4b--ZNyV-J9u4RVsalngs7J-BHWB4TmvtRIWrBl6mdso2Bz4L9Q32xfyb1fos0MCa6Pt16wey766N7GeLucAlbsfWmoP839vszxDhoIc2LuZnSJplplFrX4luH163VrxFymft1563s_UWL4YWOLUbXqLOR',
  },
];

export const INITIAL_ORDERS: TicketOrder[] = [
  {
    id: 'ord-1',
    ticketCode: 'CP-INC-20260914-C4C5',
    movieTitle: 'Inception',
    moviePoster:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuBTFOQzCtySnQLoevXA93FBIboO5mH5x6LQRl2oYg64AhwYJCPi-mDftP1I7xhFurqu3e528OPq1Siqa_fVA2wOTwEAma0CfbyEXLg1ugJNTGgd5AvOql8p64TT-xyFga6J-59Yf0-ZoYDI9btR1rcyHhn3ifRI_-W_7VtemfF6wl56oGT2eGefgUS-42xjKIQuP8f7PPezfkPBymjvCPyBENwlhDmpy-iXXvtmnhSjEDTPmqGUQfj4',
    ageRating: '16+',
    format: '2D Dolby Atmos • Phụ đề',
    cinemaLocation: 'CineAI Central • Phòng C',
    roomName: 'Phòng C',
    dateTimeStr: '20:30 • T.Hai, 14/09/2026',
    seats: ['C4', 'C5'],
    seatsTypeLabel: '2 vé (VIP)',
    concessionsSummary: '1x Combo Couple',
    totalPrice: 269000,
    status: 'upcoming',
    statusLabel: 'Sắp chiếu (Trong 45 phút)',
    countdownMinutes: 45,
  },
  {
    id: 'ord-2',
    ticketCode: 'CP-771204',
    movieTitle: 'Avengers: Endgame',
    moviePoster:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuD0mlrhnQsqf5B8-N5SGxaovpX1YSEWuUtzkL7fHBzndqUGyc2S2EKKTGyZzL7S5zqIJl9scz0vJlQiGRLeYKcUetYLCZBExmryD4Tjt1o7aJG5rYPQAmBVTNLlCoHi5DMM8-sCwkwf1cCETghl0_itgvhfm1dDVbnmrWXAFDlnmWevM6lky1xIstnb27Nres56U6IhUEeiZaTuJBvB1wwgYVIL2-D55vP8OluZBMNtRFYZRIP4c9LB',
    ageRating: '13+',
    format: '3D IMAX • Phụ đề',
    cinemaLocation: 'CineAI Central • Phòng A',
    roomName: 'Phòng A',
    dateTimeStr: '10/08/2026',
    seats: ['G12', 'G13'],
    seatsTypeLabel: '2 vé',
    concessionsSummary: 'Combo Solo',
    totalPrice: 340000,
    status: 'completed',
    statusLabel: 'Đã xem',
  },
  {
    id: 'ord-3',
    ticketCode: 'CP-639102',
    movieTitle: 'Spider-Man: Into the Spider-Verse',
    moviePoster:
      'https://lh3.googleusercontent.com/aida-public/AB6AXuCcXByI2sbNv1ol9_cy89db4Q0dtVi4PJxuLAdZVqRnm0z4SsQZfTYfAgtTUTyr8CsxFedJSAOXRcVajX08c7BSJNlUSooYTJUp8td3ARVNyEEnPfVCltPMjxlbVfAATClUc4MHSJgWM9B4FYgt8qA3SfNbgNm7Ixjb8cboXBZO1gTY-fgDDinWYQbdu7Kf2BbPk_EdHha4ffScvv_8HxxyeRC0ycK2yDa6uRjoHKbfyucQqsNCmSdZ',
    ageRating: 'P',
    format: '2D Lồng tiếng • Chuẩn rạp',
    cinemaLocation: 'CineAI Central • Phòng B',
    roomName: 'Phòng B',
    dateTimeStr: '28/07/2026',
    seats: ['E8'],
    seatsTypeLabel: '1 vé',
    concessionsSummary: 'Không kèm F&B',
    totalPrice: 115000,
    status: 'completed',
    statusLabel: 'Đã hoàn tất',
    userRating: 5,
  },
];

export const WALLET_TRANSACTIONS: WalletTransaction[] = [
  {
    id: 'tx-1',
    title: 'Hoàn vé phòng B - Inception',
    type: 'refund',
    dateStr: '14/09/2026 • 11:20',
    badgeText: 'Đã hoàn thành',
    amountDisplay: '+180.000 ₫',
    isPositive: true,
  },
  {
    id: 'tx-2',
    title: 'Rút tiền về Vietcombank',
    type: 'withdraw',
    dateStr: '10/09/2026 • 09:15',
    badgeText: 'Thành công',
    amountDisplay: '-200.000 ₫',
    isPositive: false,
  },
  {
    id: 'tx-3',
    title: 'Thưởng thành viên sinh nhật VIP',
    type: 'gift',
    dateStr: '02/09/2026',
    badgeText: 'CineGift',
    amountDisplay: '+100.000 ₫',
    isPositive: true,
  },
  {
    id: 'tx-4',
    title: 'Tích CinePoints từ vé #CP-892348',
    type: 'points',
    dateStr: 'Hôm nay • 14:05',
    badgeText: 'Vé CineAI Suite',
    amountDisplay: '+2.690 pts',
    isPositive: true,
    isPoints: true,
  },
];
