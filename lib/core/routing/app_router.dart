import 'package:go_router/go_router.dart';

import '../../features/account/presentation/pages/account_page.dart';
import '../../features/discover/presentation/pages/discover_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/movie/presentation/pages/movie_detail_placeholder.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/showtime/presentation/pages/showtimes_page.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(path: '/', redirect: (context, state) => '/home'),
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: '/discover',
      name: 'discover',
      builder: (context, state) => const DiscoverPage(),
    ),
    GoRoute(
      path: '/showtimes',
      name: 'showtimes',
      builder: (context, state) => const ShowtimesPage(),
    ),
    GoRoute(
      path: '/orders',
      name: 'orders',
      builder: (context, state) => const OrdersPage(),
    ),
    GoRoute(
      path: '/account',
      name: 'account',
      builder: (context, state) => const AccountPage(),
    ),
    GoRoute(
      path: '/movie/:id',
      name: 'movieDetail',
      builder: (context, state) =>
          MovieDetailPlaceholder(movieId: state.pathParameters['id']!),
    ),
  ],
);
