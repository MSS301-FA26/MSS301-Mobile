import '../time/app_clock.dart';

abstract final class DemoIds {
  static const user = 1;
  static const movieInception = 1;
  static const movieAvengers = 2;
  static const cinemaCentral = 1;
  static const roomC = 3;
  static const showtimeInception = 1001;
  static const seatC4 = 3004;
  static const seatC5 = 3005;
  static const booking = 5001;
  static const payment = 6001;
  static const wallet = 7001;
}

class DemoScenario {
  const DemoScenario(this.clock);

  final AppClock clock;

  DateTime get showtimeStart {
    final current = clock.now();
    return DateTime(current.year, current.month, current.day + 1, 20, 30);
  }

  DateTime get showtimeEnd => showtimeStart.add(const Duration(minutes: 148));
}
