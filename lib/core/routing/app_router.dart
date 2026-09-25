import 'package:go_router/go_router.dart';

import '../../features/account/presentation/pages/account_page.dart';
import '../../features/discover/presentation/pages/discover_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/movie/presentation/pages/movie_detail_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
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
  ],
);
