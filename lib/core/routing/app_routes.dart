abstract final class AppRoutes {
  static const home = '/home';
  static const discover = '/discover';
  static const showtimes = '/showtimes';
  static const orders = '/orders';
  static const account = '/account';
  static const login = '/auth/login';
  static const register = '/auth/register';
  static const forgotPassword = '/auth/forgot-password';
  static const profile = '/account/profile';
  static const security = '/account/security';
  static const wallet = '/account/wallet';
  static const points = '/account/points';
  static const foodOrders = '/account/food-orders';
  static const cinemaInfo = '/information/cinema';
  static const policies = '/information/policies';
  static const support = '/support';
  static const previewFood = '/preview/food';
  static const previewRefundPattern = '/preview/refund/:bookingId';
  static const vouchers = '/preview/vouchers';
  static const vip = '/preview/vip';
  static const favorites = '/preview/favorites';
  static const notifications = '/preview/notifications';
  static const popBot = '/preview/popbot';
  static const seatSelectionPattern = '/seat-selection/:showtimeId';
  static const concessionsPattern = '/booking/:bookingId/concessions';
  static const checkoutPattern = '/booking/:bookingId/checkout';
  static const paymentPattern = '/payment/:paymentId';
  static const ticketPattern = '/ticket/:bookingId';

  static String movieDetail(int movieId) => '/movie/$movieId';

  static String showtimesForMovie(int movieId) =>
      Uri(path: showtimes, queryParameters: {'movieId': '$movieId'}).toString();

  static String seatSelection(int showtimeId) => '/seat-selection/$showtimeId';

  static String concessions(int bookingId) => '/booking/$bookingId/concessions';

  static String checkout(int bookingId) => '/booking/$bookingId/checkout';

  static String payment(int paymentId) => '/payment/$paymentId';

  static String ticket(int bookingId) => '/ticket/$bookingId';

  static String previewRefund(int bookingId) => '/preview/refund/$bookingId';

  static String loginWithRedirect(String route) =>
      Uri(path: login, queryParameters: {'continue': route}).toString();
}
