import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

/// Result data structure returned when payment completes
class PaymentCallbackResult {
  final bool isSuccess;
  final String? responseCode;
  final String? txnRef;
  final String? amount;
  final String? transactionNo;
  final String? orderInfo;

  const PaymentCallbackResult({
    required this.isSuccess,
    this.responseCode,
    this.txnRef,
    this.amount,
    this.transactionNo,
    this.orderInfo,
  });

  factory PaymentCallbackResult.fromUri(Uri uri) {
    final params = uri.queryParameters;
    final code = params['vnp_ResponseCode'];
    return PaymentCallbackResult(
      isSuccess: code == '00',
      responseCode: code,
      txnRef: params['vnp_TxnRef'],
      amount: params['vnp_Amount'],
      transactionNo: params['vnp_TransactionNo'],
      orderInfo: params['vnp_OrderInfo'],
    );
  }
}

/// In-App WebView for Payment Gateway (Option 1: Navigation Interception)
class PaymentWebviewPage extends StatefulWidget {
  final String paymentUrl;
  final String title;
  final String? orderId;
  final ValueChanged<PaymentCallbackResult>? onPaymentComplete;

  const PaymentWebviewPage({
    super.key,
    required this.paymentUrl,
    this.title = 'Thanh toán VNPay',
    this.orderId,
    this.onPaymentComplete,
  });

  @override
  State<PaymentWebviewPage> createState() => _PaymentWebviewPageState();
}

class _PaymentWebviewPageState extends State<PaymentWebviewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0.0;
  String? _errorMessage;
  bool _handled = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.background)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100.0;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
                _errorMessage = null;
              });
            }
            _checkInterceptUrl(url);
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _checkInterceptUrl(url);
          },
          onWebResourceError: (WebResourceError error) {
            // If the error occurred on our intercepted callback host (like localhost:3000),
            // it means the redirect was fired; we can safely ignore the web error if already handled.
            if (_handled) return;

            final failedUrl = error.url ?? '';
            if (_isCallbackUrl(failedUrl)) {
              _handleCallback(failedUrl);
              return;
            }

            if (mounted && error.isForMainFrame == true) {
              setState(() {
                _isLoading = false;
                _errorMessage = error.description;
              });
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            if (_isCallbackUrl(request.url)) {
              _handleCallback(request.url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    if (widget.paymentUrl.isNotEmpty) {
      _controller.loadRequest(Uri.parse(widget.paymentUrl));
    }
  }

  bool _isCallbackUrl(String url) {
    final lower = url.toLowerCase();
    return lower.contains('/payment-callback') ||
        lower.contains('/payments/vnpay/return') ||
        lower.contains('/vnpay/return') ||
        lower.contains('/vnpay/null');
  }

  void _checkInterceptUrl(String url) {
    if (_isCallbackUrl(url) && !_handled) {
      _handleCallback(url);
    }
  }

  void _handleCallback(String url) {
    if (_handled) return;
    _handled = true;

    final uri = Uri.tryParse(url);
    final result = uri != null
        ? PaymentCallbackResult.fromUri(uri)
        : const PaymentCallbackResult(isSuccess: false);

    if (widget.onPaymentComplete != null) {
      widget.onPaymentComplete!(result);
    }

    if (!mounted) return;

    _showResultDialog(result);
  }

  void _showResultDialog(PaymentCallbackResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: Row(
          children: [
            Icon(
              result.isSuccess ? Icons.check_circle : Icons.error_outline,
              color: result.isSuccess ? AppColors.allAgesBadge : AppColors.adultBadge,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                result.isSuccess ? 'Thanh toán thành công' : 'Thanh toán thất bại',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.isSuccess
                  ? 'Giao dịch qua cổng VNPay đã được xác nhận thành công.'
                  : 'Giao dịch bị huỷ hoặc xảy ra lỗi trong quá trình xử lý.',
              style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
            ),
            if (result.txnRef != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    _infoRow('Mã giao dịch:', result.txnRef!),
                    if (result.amount != null) ...[
                      const SizedBox(height: 6),
                      _infoRow(
                        'Số tiền:',
                        '${(int.tryParse(result.amount!) ?? 0) ~/ 100} đ',
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              Navigator.of(ctx).pop(); // Close dialog
              if (mounted) {
                // Navigate back to orders / tickets page
                context.go('/orders');
              }
            },
            child: const Text(
              'Xem đơn vé của tôi',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        Text(
          value,
          style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 12),
        ),
      ],
    );
  }

  Future<bool> _onWillPop() async {
    final shouldLeave = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.border),
        ),
        title: const Text(
          'Huỷ thanh toán?',
          style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Bạn có chắc chắn muốn rời khỏi trang thanh toán? Đơn vé của bạn có thể hết thời gian giữ ghế.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Tiếp tục thanh toán', style: TextStyle(color: AppColors.gold)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Rời khỏi', style: TextStyle(color: AppColors.textMuted)),
          ),
        ],
      ),
    );
    return shouldLeave ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: AppColors.text),
            onPressed: () async {
              if (await _onWillPop()) {
                if (mounted) context.pop();
              }
            },
          ),
          title: Text(
            widget.title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
              onPressed: () => _controller.reload(),
            ),
          ],
          bottom: _isLoading
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                  ),
                )
              : null,
        ),
        body: _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 56, color: AppColors.textDisabled),
                      const SizedBox(height: 16),
                      const Text(
                        'Không thể tải trang thanh toán',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _errorMessage!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                          foregroundColor: Colors.black,
                        ),
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _isLoading = true;
                          });
                          _controller.reload();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
              )
            : WebViewWidget(controller: _controller),
      ),
    );
  }
}
