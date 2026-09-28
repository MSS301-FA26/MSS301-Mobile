import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/models/payment_dto.dart';

enum PaymentLaunchMode { deepLink, inAppWebView }

enum PaymentLaunchStatus { opened, simulated, missingUrl, invalidUrl, failed }

class PaymentLaunchResult {
  const PaymentLaunchResult({required this.status, required this.message});

  final PaymentLaunchStatus status;
  final String message;

  bool get isUsable =>
      status == PaymentLaunchStatus.opened ||
      status == PaymentLaunchStatus.simulated;
}

abstract interface class PaymentLauncher {
  Future<PaymentLaunchResult> open(
    PaymentDto payment, {
    PaymentLaunchMode mode,
  });
}

class UrlPaymentLauncher implements PaymentLauncher {
  const UrlPaymentLauncher();

  @override
  Future<PaymentLaunchResult> open(
    PaymentDto payment, {
    PaymentLaunchMode mode = PaymentLaunchMode.inAppWebView,
  }) async {
    final rawUrl = payment.paymentUrl;
    if (rawUrl == null || rawUrl.trim().isEmpty) {
      return const PaymentLaunchResult(
        status: PaymentLaunchStatus.missingUrl,
        message: 'Giao dịch chưa có paymentUrl từ Payment Service.',
      );
    }

    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) {
      return const PaymentLaunchResult(
        status: PaymentLaunchStatus.invalidUrl,
        message: 'paymentUrl không hợp lệ.',
      );
    }

    if (uri.scheme == 'mock') {
      return const PaymentLaunchResult(
        status: PaymentLaunchStatus.simulated,
        message:
            'Đã mở VNPay Mock. Hãy dùng callback mô phỏng để hoàn tất test.',
      );
    }

    try {
      final launched = await launchUrl(
        uri,
        mode: mode == PaymentLaunchMode.deepLink
            ? LaunchMode.externalApplication
            : LaunchMode.inAppBrowserView,
      );
      return PaymentLaunchResult(
        status: launched
            ? PaymentLaunchStatus.opened
            : PaymentLaunchStatus.failed,
        message: launched
            ? 'Đã mở cổng thanh toán VNPay.'
            : 'Thiết bị không mở được cổng thanh toán.',
      );
    } catch (_) {
      return const PaymentLaunchResult(
        status: PaymentLaunchStatus.failed,
        message: 'Không thể mở cổng thanh toán trên thiết bị này.',
      );
    }
  }
}

final paymentLauncherProvider = Provider<PaymentLauncher>(
  (ref) => const UrlPaymentLauncher(),
);
