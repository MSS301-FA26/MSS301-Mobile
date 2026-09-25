abstract final class AppRoutes {
  static const home = '/home';
  static const discover = '/discover';
  static const showtimes = '/showtimes';
  static const orders = '/orders';
  static const account = '/account';

  static String movieDetail(String movieId) => '/movie/$movieId';

  static String showtimesForMovie(String movieId) =>
      Uri(path: showtimes, queryParameters: {'movieId': movieId}).toString();
}
