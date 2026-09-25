abstract final class AppRoutes {
  static const home = '/home';
  static const discover = '/discover';
  static const showtimes = '/showtimes';
  static const orders = '/orders';
  static const account = '/account';
  static const seatSelectionPattern = '/seat-selection/:showtimeId';

  static String movieDetail(int movieId) => '/movie/$movieId';

  static String showtimesForMovie(int movieId) =>
      Uri(path: showtimes, queryParameters: {'movieId': '$movieId'}).toString();

  static String seatSelection(int showtimeId) => '/seat-selection/$showtimeId';
}
