import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/config/feature_flags.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../data/provisional_preview_repository.dart';

class PreviewFeaturePage extends ConsumerStatefulWidget {
  const PreviewFeaturePage({super.key, required this.feature, this.bookingId});

  final ProvisionalPreviewFeature feature;
  final int? bookingId;

  @override
  ConsumerState<PreviewFeaturePage> createState() => _PreviewFeaturePageState();
}

class _PreviewFeaturePageState extends ConsumerState<PreviewFeaturePage> {
  final Map<int, int> _quantities = {};
  final Set<int> _selected = {};
  String? _message;

  bool get _enabled => switch (widget.feature) {
    ProvisionalPreviewFeature.independentFood =>
      FeatureFlags.independentFoodOrderPreview,
    ProvisionalPreviewFeature.refund => FeatureFlags.refundPreview,
    ProvisionalPreviewFeature.vouchers => FeatureFlags.voucherPreview,
    ProvisionalPreviewFeature.vip => FeatureFlags.vipPreview,
    ProvisionalPreviewFeature.favorites ||
    ProvisionalPreviewFeature.notifications => FeatureFlags.socialMoviePreview,
  };

  String get _title => switch (widget.feature) {
    ProvisionalPreviewFeature.independentFood => 'Đặt bắp nước',
    ProvisionalPreviewFeature.refund => 'Hoàn / Đổi vé',
    ProvisionalPreviewFeature.vouchers => 'Voucher',
    ProvisionalPreviewFeature.vip => 'CinePremier VIP',
    ProvisionalPreviewFeature.favorites => 'Yêu thích',
    ProvisionalPreviewFeature.notifications => 'Thông báo',
  };

  @override
  Widget build(BuildContext context) {
    if (!_enabled) {
      return AppShell(
        currentIndex: 4,
        showBottomNavigation: false,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock_outline_rounded, size: 52),
                const SizedBox(height: AppSpacing.sm),
                Text('$_title đang tắt trong release-like build.'),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  label: 'Về Tài khoản',
                  onPressed: () => context.go(AppRoutes.account),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final items = ref.watch(provisionalPreviewItemsProvider(widget.feature));
    return AppShell(
      currentIndex: 4,
      showBottomNavigation: false,
      body: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: IconButton(
                tooltip: 'Quay lại',
                onPressed: () => context.go(AppRoutes.account),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: Text(_title, style: AppTextStyles.sectionTitle),
              subtitle: const Text(
                'PREVIEW • provisional model • chưa phải API contract',
                style: AppTextStyles.caption,
              ),
            ),
            Expanded(
              child: items.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(child: Text(error.toString())),
                data: (values) => ListView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  children: [
                    for (final item in values)
                      Card(
                        child: ListTile(
                          title: Text(item.title),
                          subtitle: Text(item.subtitle),
                          leading:
                              widget.feature ==
                                  ProvisionalPreviewFeature.favorites
                              ? IconButton(
                                  tooltip: 'Bỏ yêu thích',
                                  onPressed: () => setState(() {
                                    if (!_selected.add(item.id)) {
                                      _selected.remove(item.id);
                                    }
                                  }),
                                  icon: Icon(
                                    _selected.contains(item.id)
                                        ? Icons.favorite_border
                                        : Icons.favorite,
                                    color: AppColors.adultBadge,
                                  ),
                                )
                              : null,
                          trailing:
                              widget.feature ==
                                  ProvisionalPreviewFeature.independentFood
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      onPressed: (_quantities[item.id] ?? 0) > 0
                                          ? () => setState(() {
                                              _quantities[item.id] =
                                                  (_quantities[item.id] ?? 0) -
                                                  1;
                                            })
                                          : null,
                                      icon: const Icon(Icons.remove),
                                    ),
                                    Text('${_quantities[item.id] ?? 0}'),
                                    IconButton(
                                      onPressed: () => setState(() {
                                        _quantities[item.id] =
                                            (_quantities[item.id] ?? 0) + 1;
                                      }),
                                      icon: const Icon(Icons.add),
                                    ),
                                  ],
                                )
                              : Text(item.status ?? ''),
                          onTap: () => _handleItem(item.id),
                        ),
                      ),
                    if (_message != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _message!,
                        key: const ValueKey('preview-message'),
                        style: const TextStyle(color: AppColors.gold),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (widget.feature == ProvisionalPreviewFeature.refund ||
                widget.feature == ProvisionalPreviewFeature.independentFood)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: AppButton(
                    label: widget.feature == ProvisionalPreviewFeature.refund
                        ? 'Gửi yêu cầu hoàn mock'
                        : 'Xác nhận đơn preview',
                    onPressed: () => setState(() {
                      _message =
                          widget.feature == ProvisionalPreviewFeature.refund
                          ? 'Đã tạo yêu cầu preview cho booking ${widget.bookingId}. Không thay đổi booking thật.'
                          : 'Đã tạo đơn bắp nước preview. Không gắn vào booking vé.';
                    }),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _handleItem(int id) {
    switch (widget.feature) {
      case ProvisionalPreviewFeature.vouchers:
        context.go(AppRoutes.showtimes);
        return;
      case ProvisionalPreviewFeature.favorites:
        context.go(AppRoutes.movieDetail(id));
        return;
      case ProvisionalPreviewFeature.notifications:
        context.go(AppRoutes.orders);
        return;
      case ProvisionalPreviewFeature.vip:
        setState(() => _message = 'Quyền lợi VIP chỉ để review UI.');
        return;
      case ProvisionalPreviewFeature.independentFood:
      case ProvisionalPreviewFeature.refund:
        return;
    }
  }
}

class PopBotPreviewPage extends StatefulWidget {
  const PopBotPreviewPage({super.key});

  @override
  State<PopBotPreviewPage> createState() => _PopBotPreviewPageState();
}

class _PopBotPreviewPageState extends State<PopBotPreviewPage> {
  final _input = TextEditingController();
  final List<(bool, String)> _messages = [
    (false, 'Xin chào! Mình là PopBot bản preview. Bạn muốn xem phim gì?'),
  ];

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _send([String? prompt]) {
    final text = (prompt ?? _input.text).trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add((true, text));
      _messages.add((
        false,
        'Bạn có thể thử Inception. Gợi ý này là mock local, không phải phản hồi từ AI service.',
      ));
      _input.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!FeatureFlags.popBotPreview) {
      return const PreviewDisabledPage(title: 'PopBot AI');
    }
    return AppShell(
      currentIndex: 4,
      showBottomNavigation: false,
      body: SafeArea(
        child: Column(
          children: [
            ListTile(
              leading: IconButton(
                onPressed: () => context.go(AppRoutes.account),
                icon: const Icon(Icons.arrow_back_rounded),
              ),
              title: const Text('PopBot AI • Preview'),
            ),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('Phim hành động'),
                  onPressed: () => _send('Gợi ý phim hành động'),
                ),
                ActionChip(
                  label: const Text('Phim cho gia đình'),
                  onPressed: () => _send('Gợi ý phim gia đình'),
                ),
              ],
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  for (final message in _messages)
                    Align(
                      alignment: message.$1
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Card(
                        color: message.$1
                            ? AppColors.goldSurface
                            : AppColors.surface,
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.sm),
                          child: Text(message.$2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.sm,
              ),
              child: TextField(
                controller: _input,
                onSubmitted: (_) => _send(),
                decoration: InputDecoration(
                  hintText: 'Hỏi PopBot…',
                  suffixIcon: IconButton(
                    tooltip: 'Gửi',
                    onPressed: _send,
                    icon: const Icon(Icons.send_rounded),
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(AppSpacing.xs),
              child: Text(
                'Không dùng câu trả lời preview để quyết định giao dịch hoặc chính sách.',
                style: AppTextStyles.caption,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PreviewDisabledPage extends StatelessWidget {
  const PreviewDisabledPage({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => AppShell(
    currentIndex: 4,
    showBottomNavigation: false,
    body: Center(child: Text('$title đang tắt trong release-like build.')),
  );
}
