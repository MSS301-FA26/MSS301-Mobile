import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../data/models/payment_dto.dart';

/// The BE handles the signed VNPay return before redirecting to this FE URL.
/// Match the complete origin and path so an arbitrary page cannot end payment.
class PaymentReturnMatcher {
  const PaymentReturnMatcher(this.redirectUrl);

  final Uri redirectUrl;

  bool matches(String rawUrl) {
    final url = Uri.tryParse(rawUrl);
    return url != null &&
        url.scheme == redirectUrl.scheme &&
        url.host == redirectUrl.host &&
        url.port == redirectUrl.port &&
        url.path == redirectUrl.path;
  }
}

class PaymentHandoffPage extends ConsumerStatefulWidget {
  const PaymentHandoffPage({super.key, required this.payment});

  final PaymentDto payment;

  static Future<void> open(BuildContext context, PaymentDto payment) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(builder: (_) => PaymentHandoffPage(payment: payment)),
    );
  }

  @override
  ConsumerState<PaymentHandoffPage> createState() => _PaymentHandoffPageState();
}

class _PaymentHandoffPageState extends ConsumerState<PaymentHandoffPage> {
  static const _redirect = String.fromEnvironment(
    'PAYMENT_REDIRECT_URL',
    defaultValue: 'http://localhost:3000/payment-callback',
  );

  late final WebViewController _webView;
  bool _loading = false;
  bool _started = false;
  bool _returning = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final matcher = PaymentReturnMatcher(Uri.parse(_redirect));
    _webView = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            if (matcher.matches(request.url)) {
              _returnToApp();
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _loading = true);
          },
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() => _error = 'Không tải được trang thanh toán.');
            }
          },
        ),
      );
  }

  void _openInApp() {
    if (_started) return;
    setState(() {
      _started = true;
      _loading = true;
    });
    _webView.loadRequest(Uri.parse(widget.payment.paymentUrl!));
  }

  void _returnToApp() {
    if (_returning) return;
    _returning = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.of(context).pop();
    });
  }

  Future<void> _openExternally() async {
    final url = Uri.tryParse(widget.payment.paymentUrl ?? '');
    if (url == null) return;
    try {
      final opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!mounted) return;
      if (opened) {
        _returnToApp();
      } else {
        setState(
          () => _error = 'Không mở được trình duyệt. Hãy thử trong app.',
        );
      }
    } catch (_) {
      if (mounted) setState(() => _error = 'Không mở được trình duyệt.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Thanh toán VNPay'),
      leading: IconButton(
        tooltip: 'Quay lại ứng dụng',
        onPressed: _returnToApp,
        icon: const Icon(Icons.arrow_back),
      ),
      actions: [
        TextButton(
          key: const ValueKey('payment-return-app'),
          onPressed: _returnToApp,
          child: const Text('Về ứng dụng'),
        ),
      ],
    ),
    body: Column(
      children: [
        if (_loading) const LinearProgressIndicator(),
        Expanded(
          child: _started
              ? WebViewWidget(controller: _webView)
              : Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Text(
                      'Chọn nơi mở VNPay để thanh toán. Mỗi giao dịch chỉ nên mở ở một nơi.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body,
                    ),
                  ),
                ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_error != null) ...[
                  Text(_error!, style: AppTextStyles.body),
                  const SizedBox(height: AppSpacing.sm),
                ],
                const Text(
                  'Khi quay lại, ứng dụng sẽ kiểm tra kết quả từ hệ thống.',
                  style: AppTextStyles.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.sm),
                if (!_started)
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          key: const ValueKey('payment-open-browser'),
                          label: 'Mở trình duyệt',
                          variant: AppButtonVariant.secondary,
                          onPressed: _openExternally,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton(
                          key: const ValueKey('payment-open-in-app'),
                          label: 'Mở trong app',
                          onPressed: _openInApp,
                        ),
                      ),
                    ],
                  )
                else
                  AppButton(
                    key: const ValueKey('payment-check-result'),
                    label: 'Kiểm tra đơn',
                    onPressed: _returnToApp,
                    fullWidth: true,
                  ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
