import { useState, useEffect } from 'react';
import { ScreenName, Movie, ShowtimeSlot, BookingState, TicketOrder, Voucher } from './types';
import { MOVIES, INITIAL_ORDERS, SHOWTIMES_DATA } from './data/mockData';
import { CINEMA_CONFIG } from './data/cinemaConfig';
import { INITIAL_VOUCHERS } from './data/vouchersData';
import { Header } from './components/Header';
import { BottomNav } from './components/BottomNav';
import { TrailerModal } from './components/TrailerModal';
import { CinemaPickerModal } from './components/CinemaPickerModal';

import { HomeScreen } from './screens/HomeScreen';
import { MovieDetailScreen } from './screens/MovieDetailScreen';
import { ShowtimesScreen } from './screens/ShowtimesScreen';
import { SeatsScreen } from './screens/SeatsScreen';
import { ConcessionsScreen } from './screens/ConcessionsScreen';
import { PaymentScreen } from './screens/PaymentScreen';
import { TicketDetailScreen } from './screens/TicketDetailScreen';
import { OrdersScreen } from './screens/OrdersScreen';
import { AccountScreen } from './screens/AccountScreen';
import { WalletScreen } from './screens/WalletScreen';
import { PopBotScreen } from './screens/PopBotScreen';
import { DiscoverScreen } from './screens/DiscoverScreen';
import { LoginScreen } from './screens/LoginScreen';
import { RegisterScreen } from './screens/RegisterScreen';
import { VouchersScreen } from './screens/VouchersScreen';
import { VoucherDetailScreen } from './screens/VoucherDetailScreen';
import { HelpScreen } from './screens/HelpScreen';

export default function App() {
  const [currentScreen, setCurrentScreen] = useState<ScreenName>('home');
  const [screenHistory, setScreenHistory] = useState<ScreenName[]>(['home']);
  const [selectedCinemaId, setSelectedCinemaId] = useState<string>('central');
  const [isCinemaPickerOpen, setIsCinemaPickerOpen] = useState<boolean>(false);

  // Default selected movie (Inception)
  const [selectedMovie, setSelectedMovie] = useState<Movie>(MOVIES[0]);

  // Active booking session
  const [bookingState, setBookingState] = useState<BookingState>({
    cinemaId: CINEMA_CONFIG.id,
    cinemaName: CINEMA_CONFIG.name,
    movie: MOVIES[0],
    selectedDate: 'Hôm nay, 14/09/2026',
    selectedSlot: SHOWTIMES_DATA[0].rooms[1].slots[1], // 20:30 Room C
    selectedSeats: [],
    selectedConcessions: [],
    totalPrice: 0,
  });

  // Ensure legacy localStorage values always default to single cinema
  useEffect(() => {
    try {
      const stored = localStorage.getItem('selectedCinemaId');
      if (stored && stored !== CINEMA_CONFIG.id) {
        localStorage.setItem('selectedCinemaId', CINEMA_CONFIG.id);
      }
    } catch {
      // Ignore storage errors
    }
  }, []);

  // User orders
  const [orders, setOrders] = useState<TicketOrder[]>(INITIAL_ORDERS);
  const [activeTicketOrder, setActiveTicketOrder] = useState<TicketOrder | null>(INITIAL_ORDERS[0]);

  // Selected voucher for voucher detail screen
  const [selectedVoucher, setSelectedVoucher] = useState<Voucher | null>(INITIAL_VOUCHERS[0]);

  // Trailer Modal
  const [trailerModal, setTrailerModal] = useState<{
    isOpen: boolean;
    movieTitle: string;
    posterUrl?: string;
  }>({
    isOpen: false,
    movieTitle: '',
  });

  // Scroll to top whenever screen changes
  useEffect(() => {
    window.scrollTo(0, 0);
  }, [currentScreen]);

  const navigateTo = (screen: ScreenName) => {
    setScreenHistory((prev) => [...prev, screen]);
    setCurrentScreen(screen);
  };

  const handleBack = () => {
    if (screenHistory.length > 1) {
      const newHistory = [...screenHistory];
      newHistory.pop(); // remove current
      const prevScreen = newHistory[newHistory.length - 1];
      setScreenHistory(newHistory);
      setCurrentScreen(prevScreen);
    } else {
      setCurrentScreen('home');
    }
  };

  const handleSelectMovie = (movie: Movie) => {
    setSelectedMovie(movie);
    navigateTo('movie-detail');
  };

  const handleStartBooking = (movie: Movie) => {
    setSelectedMovie(movie);
    const movieSt = SHOWTIMES_DATA.find((s) => s.movieId === movie.id) || SHOWTIMES_DATA[0];
    const defaultSlot = movieSt.rooms[0]?.slots[0] || SHOWTIMES_DATA[0].rooms[1].slots[1];

    setBookingState({
      cinemaId: CINEMA_CONFIG.id,
      cinemaName: CINEMA_CONFIG.name,
      movie,
      movieId: movie.id,
      movieTitle: movie.title,
      date: 'Hôm nay, 14/09/2026',
      selectedDate: 'Hôm nay, 14/09/2026',
      selectedSlot: defaultSlot,
      showtimeId: defaultSlot.id,
      time: defaultSlot.time,
      auditoriumId: defaultSlot.roomName,
      room: defaultSlot.roomName,
      format: defaultSlot.formatBadge,
      ticketQuantity: 0,
      selectedSeats: [],
      concessions: [],
      selectedConcessions: [],
      subtotal: 0,
      discount: 0,
      total: 0,
      totalPrice: 0,
      paymentMethod: 'cinewallet',
      bookingStatus: 'selecting_showtime',
    });
    navigateTo('showtimes');
  };

  const handleSelectSlot = (movie: Movie, slot: ShowtimeSlot, dateStr: string) => {
    setBookingState((prev) => ({
      ...prev,
      cinemaId: CINEMA_CONFIG.id,
      cinemaName: CINEMA_CONFIG.name,
      movie,
      movieId: movie.id,
      movieTitle: movie.title,
      date: dateStr,
      selectedDate: dateStr,
      selectedSlot: slot,
      showtimeId: slot.id,
      time: slot.time,
      auditoriumId: slot.roomName,
      room: slot.roomName,
      format: slot.formatBadge,
      ticketQuantity: prev.selectedSeats?.length || 0,
      selectedSeats: prev.selectedSeats || [],
      concessions: prev.concessions || prev.selectedConcessions || [],
      selectedConcessions: prev.concessions || prev.selectedConcessions || [],
      subtotal: (prev.selectedSeats || []).reduce((sum, s) => sum + s.price, 0),
      discount: prev.discount || 0,
      total: (prev.selectedSeats || []).reduce((sum, s) => sum + s.price, 0),
      totalPrice: (prev.selectedSeats || []).reduce((sum, s) => sum + s.price, 0),
      paymentMethod: prev.paymentMethod || 'cinewallet',
      bookingStatus: 'selecting_seats',
    }));
    navigateTo('seats');
  };

  const handleSeatsConfirmed = (updatedBooking: BookingState) => {
    setBookingState(updatedBooking);
    navigateTo('concessions');
  };

  const handleConcessionsConfirmed = (updatedBooking: BookingState) => {
    setBookingState(updatedBooking);
    navigateTo('payment');
  };

  const handlePaymentSuccess = (newOrder: TicketOrder) => {
    setOrders((prev) => [newOrder, ...prev]);
    setActiveTicketOrder(newOrder);
    navigateTo('ticket-detail');
  };

  const handleOpenTrailer = (movieTitle: string, posterUrl?: string) => {
    setTrailerModal({
      isOpen: true,
      movieTitle,
      posterUrl,
    });
  };

  const handleCancelOrder = (orderId: string) => {
    setOrders((prev) =>
      prev.map((ord) =>
        ord.id === orderId
          ? { ...ord, status: 'completed', statusLabel: 'Đã hoàn tiền (CineWallet)' }
          : ord
      )
    );
    alert('Đã hoàn 100% tiền vé vào ví CineWallet của bạn.');
  };

  // Screen Title for Header
  const getScreenTitle = (): string | undefined => {
    switch (currentScreen) {
      case 'movie-detail':
        return selectedMovie.title;
      case 'showtimes':
        return 'Chọn Suất Chiếu';
      case 'seats':
        return 'Chọn Ghế Ngồi';
      case 'concessions':
        return 'Combo Bắp & Nước';
      case 'payment':
        return 'Thanh Toán';
      case 'ticket-detail':
        return 'Vé Vào Rạp Điện Tử';
      case 'wallet':
        return 'Ví CineWallet & Điểm Thưởng';
      case 'popbot':
        return 'PopBot AI Assistant';
      case 'calendar':
        return 'Lịch Chiếu Phim';
      case 'discover':
        return 'Khám Phá Phim';
      case 'orders':
        return 'Đơn Của Tôi';
      case 'account':
        return 'Tài Khoản & VIP';
      case 'login':
        return 'Đăng Nhập';
      case 'register':
        return 'Đăng Ký Thành Viên';
      case 'vouchers':
        return 'Ưu Đãi & Voucher';
      case 'voucher-detail':
        return selectedVoucher?.title || 'Chi Tiết Voucher';
      case 'help':
        return 'Trung Tâm Trợ Giúp';
      default:
        return undefined;
    }
  };

  const cinema = CINEMA_CONFIG;

  // Check if current screen displays global bottom navigation
  const hasBottomNav = ![
    'movie-detail',
    'showtimes',
    'seats',
    'concessions',
    'payment',
    'payment-result',
    'ticket-detail',
    'popbot',
    'login',
    'register',
    'vouchers',
    'voucher-detail',
    'help',
  ].includes(currentScreen);

  // Check if current screen is authentication screen (login / register)
  const isAuthScreen = currentScreen === 'login' || currentScreen === 'register';

  return (
    <div className="min-h-screen w-full bg-[#0E0E0F] text-white flex flex-col items-center">
      {/* Container wrapper for mobile-first frame & desktop responsiveness */}
      <div className="w-full max-w-md md:max-w-4xl lg:max-w-7xl min-h-screen bg-[#0E0E0F] flex flex-col relative shadow-2xl">
        {/* Top Header (excluded on auth screens which have their dedicated AuthLayout topbar) */}
        {!isAuthScreen && (
          <Header
            currentScreen={currentScreen}
            onNavigate={navigateTo}
            onBack={handleBack}
            title={getScreenTitle()}
            onOpenCinemaPicker={() => setIsCinemaPickerOpen(true)}
            selectedCinemaName={cinema.name}
          />
        )}

        {/* Main Content Area: pb-bottom-nav ensures the last card & its buttons never get covered by BottomNav */}
        <main className={`flex-1 w-full ${!isAuthScreen ? 'pt-16' : ''} ${hasBottomNav ? 'pb-bottom-nav' : ''}`}>
          {currentScreen === 'home' && (
            <HomeScreen
              onNavigate={navigateTo}
              onSelectMovie={handleSelectMovie}
              onOpenTrailer={handleOpenTrailer}
              onStartBooking={handleStartBooking}
            />
          )}

          {currentScreen === 'movie-detail' && (
            <MovieDetailScreen
              movie={selectedMovie}
              onBack={handleBack}
              onStartBooking={handleStartBooking}
              onOpenTrailer={handleOpenTrailer}
            />
          )}

          {currentScreen === 'showtimes' && (
            <ShowtimesScreen
              currentMovie={selectedMovie}
              onNavigate={navigateTo}
              onSelectSlot={handleSelectSlot}
              selectedCinemaId={selectedCinemaId}
              onOpenCinemaPicker={() => setIsCinemaPickerOpen(true)}
              isCalendarTab={false}
            />
          )}

          {currentScreen === 'calendar' && (
            <ShowtimesScreen
              currentMovie={undefined}
              onNavigate={navigateTo}
              onSelectSlot={handleSelectSlot}
              selectedCinemaId={selectedCinemaId}
              onOpenCinemaPicker={() => setIsCinemaPickerOpen(true)}
              isCalendarTab={true}
            />
          )}

          {currentScreen === 'seats' && (
            <SeatsScreen
              booking={bookingState}
              onContinue={handleSeatsConfirmed}
              onBack={handleBack}
            />
          )}

          {currentScreen === 'concessions' && (
            <ConcessionsScreen
              booking={bookingState}
              onContinue={handleConcessionsConfirmed}
              onBack={handleBack}
            />
          )}

          {currentScreen === 'payment' && (
            <PaymentScreen
              booking={bookingState}
              onPaymentSuccess={handlePaymentSuccess}
              onBack={handleBack}
            />
          )}

          {currentScreen === 'ticket-detail' && activeTicketOrder && (
            <TicketDetailScreen
              order={activeTicketOrder}
              onBack={handleBack}
              onGoHome={() => navigateTo('home')}
              onViewOrders={() => navigateTo('orders')}
            />
          )}

          {currentScreen === 'orders' && (
            <OrdersScreen
              orders={orders}
              onSelectOrder={(ord) => {
                setActiveTicketOrder(ord);
                navigateTo('ticket-detail');
              }}
              onBookAgain={(movieTitle) => {
                const found = MOVIES.find((m) => m.title.toLowerCase().includes(movieTitle.toLowerCase())) || MOVIES[0];
                handleStartBooking(found);
              }}
              onCancelOrder={handleCancelOrder}
            />
          )}

          {currentScreen === 'account' && (
            <AccountScreen
              onNavigate={navigateTo}
              onOpenCinemaPicker={() => setIsCinemaPickerOpen(true)}
            />
          )}

          {currentScreen === 'wallet' && (
            <WalletScreen onBack={handleBack} />
          )}

          {currentScreen === 'popbot' && (
            <PopBotScreen
              onSelectMovie={handleSelectMovie}
              onStartBooking={handleStartBooking}
            />
          )}

          {currentScreen === 'discover' && (
            <DiscoverScreen
              onSelectMovie={handleSelectMovie}
              onStartBooking={handleStartBooking}
            />
          )}

          {currentScreen === 'login' && (
            <LoginScreen
              onNavigate={navigateTo}
              onBack={handleBack}
              onSuccess={() => {
                if (screenHistory.length > 1) {
                  handleBack();
                } else {
                  navigateTo('account');
                }
              }}
            />
          )}

          {currentScreen === 'register' && (
            <RegisterScreen
              onNavigate={navigateTo}
              onBack={handleBack}
              onSuccess={() => {
                navigateTo('account');
              }}
            />
          )}

          {currentScreen === 'vouchers' && (
            <VouchersScreen
              onNavigate={navigateTo}
              onBack={handleBack}
              onSelectVoucher={(voucher) => {
                setSelectedVoucher(voucher);
                navigateTo('voucher-detail');
              }}
              onUseVoucher={(voucher) => {
                setBookingState((prev) => ({
                  ...prev,
                  voucherCode: voucher.code,
                  discount: voucher.discountType === 'fixed' ? voucher.discountValue : 30000,
                }));
                navigateTo('calendar');
              }}
            />
          )}

          {currentScreen === 'voucher-detail' && selectedVoucher && (
            <VoucherDetailScreen
              voucher={selectedVoucher}
              onNavigate={navigateTo}
              onBack={handleBack}
              onApplyForBooking={(voucher) => {
                setBookingState((prev) => ({
                  ...prev,
                  voucherCode: voucher.code,
                  discount: voucher.discountType === 'fixed' ? voucher.discountValue : 30000,
                }));
              }}
            />
          )}

          {currentScreen === 'help' && (
            <HelpScreen
              onNavigate={navigateTo}
              onBack={handleBack}
            />
          )}
        </main>

        {/* Global Bottom Navigation */}
        <BottomNav
          currentScreen={currentScreen}
          onNavigate={navigateTo}
          orderCount={orders.filter((o) => o.status === 'upcoming').length}
        />

        {/* Trailer Modal */}
        <TrailerModal
          isOpen={trailerModal.isOpen}
          onClose={() => setTrailerModal({ ...trailerModal, isOpen: false })}
          movieTitle={trailerModal.movieTitle}
          posterUrl={trailerModal.posterUrl}
        />

        {/* Cinema Information Bottom Sheet Modal */}
        <CinemaPickerModal
          isOpen={isCinemaPickerOpen}
          onClose={() => setIsCinemaPickerOpen(false)}
          onViewShowtimes={() => navigateTo('calendar')}
        />
      </div>
    </div>
  );
}
