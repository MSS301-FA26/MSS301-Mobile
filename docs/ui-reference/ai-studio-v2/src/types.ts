export type ScreenName =
  | 'home'
  | 'movie-detail'
  | 'showtimes'
  | 'ticket-types'
  | 'seats'
  | 'concessions'
  | 'payment'
  | 'payment-result'
  | 'ticket-detail'
  | 'orders'
  | 'wallet'
  | 'account'
  | 'popbot'
  | 'discover'
  | 'calendar'
  | 'login'
  | 'register'
  | 'vouchers'
  | 'voucher-detail'
  | 'help';

export interface Movie {
  id: string;
  title: string;
  originalTitle?: string;
  ageRating: string;
  ageRatingBg: string;
  duration: string;
  durationMinutes: number;
  rating: number;
  ratingCount: string;
  formats: string[];
  genres: string[];
  audioInfo: string;
  tagline: string;
  synopsis: string;
  posterUrl: string;
  bannerUrl: string;
  trailerUrl?: string;
  isNowShowing: boolean;
  isComingSoon?: boolean;
  releaseDate?: string;
  stats?: {
    cineScore: number;
    boxOfficeRank: string;
    formatDisplay: string;
  };
  director: {
    name: string;
    role: string;
    avatarUrl: string;
  };
  cast: Array<{
    name: string;
    character: string;
    avatarUrl: string;
  }>;
  reviews?: Review[];
}

export interface Review {
  id: string;
  userName: string;
  userAvatarBg?: string;
  date: string;
  location: string;
  rating: number;
  verifiedTicket: boolean;
  seatInfo?: string;
  comment: string;
}

export interface ShowtimeSlot {
  id: string;
  time: string;
  endTime: string;
  priceDisplay: string;
  price: number;
  isSoldOut?: boolean;
  isSelected?: boolean;
  roomName: string;
  formatBadge: string;
  formatBadgeType: 'secondary' | 'primary' | 'neutral';
  screenDetail: string;
}

export interface CinemaRoom {
  id: string;
  roomName: string;
  formatBadge: string;
  screenDetail: string;
  slots: ShowtimeSlot[];
}

export interface MovieShowtime {
  movieId: string;
  movieTitle: string;
  ageRating: string;
  genres: string;
  duration: string;
  rating: number;
  posterUrl: string;
  rooms: CinemaRoom[];
}

export type SeatType = 'standard' | 'vip' | 'couple';

export interface Seat {
  id: string; // e.g. "C4"
  row: string; // "A", "B", ...
  number?: string;
  col?: number;
  type: SeatType;
  price: number;
  isOccupied?: boolean;
  status?: 'available' | 'occupied' | 'selected';
  isSelected?: boolean;
}

export interface ConcessionItem {
  id: string;
  name: string;
  description: string;
  price: number;
  category: 'all' | 'combos' | 'popcorn' | 'drinks' | 'snacks';
  imageUrl: string;
  badge?: string;
  quantity: number;
}

export interface TicketTypeItem {
  id: string;
  code: 'ADULT' | 'STUDENT' | 'CHILD';
  name: string;
  description: string;
  unitPrice: number;
  policyDescription: string;
  isAvailable: boolean;
  requiresVerification: boolean;
  icon: string;
}

export interface TicketSelection {
  ticketTypeId: string;
  ticketTypeCode?: 'ADULT' | 'STUDENT' | 'CHILD'; // Compatibility alias
  code: 'ADULT' | 'STUDENT' | 'CHILD';
  name: string;
  ticketTypeName?: string; // Compatibility alias
  unitPrice: number;
  quantity: number;
  subtotal: number;
}

export interface SeatAssignment {
  seatId: string;
  seatLabel: string;
  ticketTypeId: string;
  ticketTypeCode: 'ADULT' | 'STUDENT' | 'CHILD';
  ticketTypeName: string;
  ticketPrice: number;
  seatSurcharge: number;
  finalPrice: number;
  assignedOrder: number;
  seatType?: SeatType;
}

export interface BookingState {
  // Cinema
  cinemaId: string;
  cinemaName: string;
  // Movie
  movie: Movie;
  movieId: string;
  movieTitle: string;
  // Showtime
  date: string;
  selectedDate: string; // Alias for date
  selectedSlot?: ShowtimeSlot;
  showtimeId: string;
  time: string;
  auditoriumId: string;
  room: string;
  format: string;
  // Ticket types
  ticketSelections: TicketSelection[];
  totalTicketQuantity: number;
  ticketSubtotal: number;
  activeTicketType?: 'ADULT' | 'STUDENT' | 'CHILD';
  // Seats & Assignments
  ticketQuantity: number;
  selectedSeats: Seat[];
  seatAssignments?: SeatAssignment[];
  seatSurcharge: number;
  // Concessions
  concessions: ConcessionItem[];
  selectedConcessions: ConcessionItem[]; // Alias for concessions
  // Financials
  subtotal: number;
  discount: number;
  voucherCode?: string;
  total: number;
  totalPrice: number; // Alias for total
  grandTotal?: number;
  // Payment & Status
  paymentMethod: string;
  bookingStatus:
    | 'selecting_showtime'
    | 'selecting_ticket_types'
    | 'selecting_seats'
    | 'selecting_concessions'
    | 'review_order'
    | 'paying'
    | 'confirmed';
}

export interface TicketOrder {
  id: string;
  ticketCode: string;
  movieTitle: string;
  moviePoster: string;
  ageRating: string;
  format: string;
  cinemaLocation: string;
  roomName: string;
  dateTimeStr: string;
  seats: string[];
  seatsTypeLabel: string;
  ticketSelections?: TicketSelection[];
  seatAssignments?: SeatAssignment[];
  seatSurcharge?: number;
  ticketBreakdownDisplay?: string;
  concessionsSummary: string;
  totalPrice: number;
  status: 'upcoming' | 'completed' | 'cancelled';
  statusLabel: string;
  countdownMinutes?: number;
  userRating?: number;
}

export interface WalletTransaction {
  id: string;
  title: string;
  type: 'refund' | 'withdraw' | 'points' | 'gift' | 'deposit';
  dateStr: string;
  badgeText: string;
  amountDisplay: string;
  isPositive: boolean;
  isPoints?: boolean;
}

export interface PopBotMessage {
  id: string;
  sender: 'bot' | 'user' | 'popbot';
  text: string;
  timestamp?: string;
  timeStr?: string;
  suggestions?: string[];
  movieCard?: {
    movie: Movie;
    recommendedShowtime: string;
    matchReason: string;
  };
}

export interface UserProfile {
  id: string;
  name: string;
  initials: string;
  email: string;
  phone: string;
  membershipTier: 'Standard' | 'Gold VIP' | 'Diamond VIP';
  memberCode: string;
  joinDate: string;
  points: number;
  walletBalance: number;
}

export interface Voucher {
  id: string;
  code: string;
  title: string;
  shortDescription: string;
  discountDisplay: string;
  discountType: 'fixed' | 'percent' | 'gift';
  discountValue: number;
  expiryDate: string;
  startDate: string;
  status: 'available' | 'used' | 'expired';
  statusLabel: string;
  minOrderAmount?: number;
  minOrderDisplay?: string;
  applicableTo: string;
  usageLimit?: string;
  instructions: string[];
  terms: string[];
  icon: string;
}

export interface FAQItem {
  id: string;
  categoryId: string;
  question: string;
  answer: string;
}

export interface HelpCategory {
  id: string;
  name: string;
  icon: string;
}

export interface SupportContactConfig {
  hotline: string;
  hotlineDisplay: string;
  email: string;
  workingHours: string;
  isDemo: boolean;
  note: string;
}

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
  features: string[];
  rooms: CinemaRoomInfo[];
  operatingHours: string;
  hotline: string;
  statusText: string;
}

