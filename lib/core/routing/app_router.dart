import 'package:go_router/go_router.dart';

import '../../features/account/presentation/pages/account_page.dart';
import '../../features/account/presentation/pages/account_detail_pages.dart';
import '../../features/account/presentation/pages/information_pages.dart';
import '../../features/auth/presentation/pages/auth_page.dart';
import '../../features/auth/presentation/widgets/auth_guard.dart';
import '../../features/booking/presentation/pages/checkout_page.dart';
import '../../features/booking/presentation/pages/concessions_page.dart';
import '../../features/booking/presentation/pages/payment_result_page.dart';
import '../../features/booking/presentation/pages/ticket_page.dart';
import '../../features/discover/presentation/pages/discover_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/movie/presentation/pages/movie_detail_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/preview/data/provisional_preview_repository.dart';
import '../../features/preview/presentation/pages/preview_feature_page.dart';
import '../../features/seat/presentation/pages/seat_selection_page.dart';
import '../../features/showtime/presentation/pages/showtimes_page.dart';
import 'app_routes.dart';

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    GoRoute(path: '/', redirect: (context, state) => AppRoutes.home),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.discover,
      name: 'discover',
      builder: (context, state) => const DiscoverPage(),
    ),
    GoRoute(
      path: AppRoutes.showtimes,
      name: 'showtimes',
      builder: (context, state) => ShowtimesPage(
        movieId: int.tryParse(state.uri.queryParameters['movieId'] ?? ''),
      ),
    ),
    GoRoute(
      path: AppRoutes.orders,
      name: 'orders',
      builder: (context, state) => const OrdersPage(),
    ),
    GoRoute(
      path: AppRoutes.account,
      name: 'account',
      builder: (context, state) => const AccountPage(),
    ),
    GoRoute(
      path: '/movie/:id',
      name: 'movieDetail',
      builder: (context, state) => MovieDetailPage(
        movieId: int.tryParse(state.pathParameters['id'] ?? '') ?? -1,
      ),
    ),
    GoRoute(
      path: AppRoutes.seatSelectionPattern,
      name: 'seatSelection',
      builder: (context, state) => SeatSelectionPage(
        showtimeId:
            int.tryParse(state.pathParameters['showtimeId'] ?? '') ?? -1,
      ),
    ),
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const AuthPage(mode: AuthPageMode.login),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const AuthPage(mode: AuthPageMode.register),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      builder: (context, state) =>
          const AuthPage(mode: AuthPageMode.forgotPassword),
    ),
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const AuthGuard(child: ProfileEditPage()),
    ),
    GoRoute(
      path: AppRoutes.security,
      builder: (context, state) => const AuthGuard(child: SecurityPage()),
    ),
    GoRoute(
      path: AppRoutes.wallet,
      builder: (context, state) => const AuthGuard(child: WalletPage()),
    ),
    GoRoute(
      path: AppRoutes.points,
      builder: (context, state) => const AuthGuard(child: PointsPage()),
    ),
    GoRoute(
      path: AppRoutes.cinemaInfo,
      builder: (context, state) =>
          const InformationPage(type: InformationPageType.cinema),
    ),
    GoRoute(
      path: AppRoutes.policies,
      builder: (context, state) =>
          const InformationPage(type: InformationPageType.policies),
    ),
    GoRoute(
      path: AppRoutes.support,
      builder: (context, state) =>
          const InformationPage(type: InformationPageType.support),
    ),
    GoRoute(
      path: AppRoutes.concessionsPattern,
      name: 'concessions',
      builder: (context, state) => ConcessionsPage(
        bookingId: int.tryParse(state.pathParameters['bookingId'] ?? '') ?? -1,
      ),
    ),
    GoRoute(
      path: AppRoutes.checkoutPattern,
      name: 'checkout',
      builder: (context, state) => CheckoutPage(
        bookingId: int.tryParse(state.pathParameters['bookingId'] ?? '') ?? -1,
      ),
    ),
    GoRoute(
      path: AppRoutes.paymentPattern,
      name: 'payment',
      builder: (context, state) => PaymentResultPage(
        paymentId: int.tryParse(state.pathParameters['paymentId'] ?? '') ?? -1,
      ),
    ),
    GoRoute(
      path: AppRoutes.ticketPattern,
      name: 'ticket',
      builder: (context, state) => TicketPage(
        bookingId: int.tryParse(state.pathParameters['bookingId'] ?? '') ?? -1,
      ),
    ),
    GoRoute(
      path: AppRoutes.previewFood,
      builder: (context, state) => const PreviewFeaturePage(
        feature: ProvisionalPreviewFeature.independentFood,
      ),
    ),
    GoRoute(
      path: AppRoutes.previewRefundPattern,
      builder: (context, state) => PreviewFeaturePage(
        feature: ProvisionalPreviewFeature.refund,
        bookingId: int.tryParse(state.pathParameters['bookingId'] ?? '') ?? -1,
      ),
    ),
    GoRoute(
      path: AppRoutes.vouchers,
      builder: (context, state) =>
          const PreviewFeaturePage(feature: ProvisionalPreviewFeature.vouchers),
    ),
    GoRoute(
      path: AppRoutes.vip,
      builder: (context, state) =>
          const PreviewFeaturePage(feature: ProvisionalPreviewFeature.vip),
    ),
    GoRoute(
      path: AppRoutes.favorites,
      builder: (context, state) => const PreviewFeaturePage(
        feature: ProvisionalPreviewFeature.favorites,
      ),
    ),
    GoRoute(
      path: AppRoutes.notifications,
      builder: (context, state) => const PreviewFeaturePage(
        feature: ProvisionalPreviewFeature.notifications,
      ),
    ),
    GoRoute(
      path: AppRoutes.popBot,
      builder: (context, state) => const PopBotPreviewPage(),
    ),
  ],
);
