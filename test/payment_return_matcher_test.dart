import 'package:flutter_test/flutter_test.dart';
import 'package:mss301_mobile/features/payment/presentation/pages/payment_handoff_page.dart';

void main() {
  test('recognizes only the configured FE redirect after the BE return', () {
    final matcher = PaymentReturnMatcher(
      Uri.parse('http://localhost:3000/payment-callback'),
    );

    expect(
      matcher.matches(
        'http://localhost:3000/payment-callback?vnp_ResponseCode=00',
      ),
      isTrue,
    );
    expect(
      matcher.matches('http://localhost:8080/api/v1/payments/vnpay/return'),
      isFalse,
    );
    expect(matcher.matches('http://evil.test/payment-callback'), isFalse);
    expect(
      matcher.matches('http://localhost:3000/payment-callback-fake'),
      isFalse,
    );
    expect(matcher.matches('https://localhost:3000/payment-callback'), isFalse);
  });
}
