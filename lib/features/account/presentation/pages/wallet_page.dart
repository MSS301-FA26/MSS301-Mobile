import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/money/vnd_money.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../../auth/application/auth_session.dart';
import '../../application/wallet_bank_store.dart';
import '../../data/models/account_dto.dart';
import '../../data/models/account_enums.dart';
import '../../data/repositories/account_providers.dart';
import '../providers/account_summary_provider.dart';
import '../providers/wallet_overview_provider.dart';

enum _WalletTab { withdrawals, transactions }

enum _TransactionFilter { all, refunds, withdrawals }

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  final _amount = TextEditingController();
  final _phone = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  _WalletTab _tab = _WalletTab.withdrawals;
  _TransactionFilter _filter = _TransactionFilter.all;
  bool _submitting = false;
  bool _savingBank = false;
  bool _showWithdrawForm = false;
  int? _historyUserId;
  int _withdrawalPage = 0;
  int _transactionPage = 0;
  bool _moreWithdrawals = true;
  bool _moreTransactions = true;
  bool _loadingWithdrawals = false;
  bool _loadingTransactions = false;
  String? _withdrawalLoadError;
  String? _transactionLoadError;
  final _extraWithdrawals = <WithdrawalDto>[];
  final _extraTransactions = <WalletTransactionDto>[];

  void _resetPages() {
    _historyUserId = null;
    _withdrawalPage = 0;
    _transactionPage = 0;
    _moreWithdrawals = true;
    _moreTransactions = true;
    _withdrawalLoadError = null;
    _transactionLoadError = null;
    _extraWithdrawals.clear();
    _extraTransactions.clear();
  }

  @override
  void dispose() {
    _amount.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _notify(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _saveBank(int userId, SavedBankAccount? current) async {
    final account = await showModalBottomSheet<SavedBankAccount>(
      context: context,
      isScrollControlled: true,
      builder: (context) => _BankEditor(current: current),
    );
    if (account == null || !mounted || _savingBank) return;
    if (ref.read(authSessionProvider).session?.user.id != userId) return;
    setState(() => _savingBank = true);
    try {
      await ref.read(walletBankStoreProvider).write(userId, account);
      if (!mounted ||
          ref.read(authSessionProvider).session?.user.id != userId) {
        return;
      }
      ref.invalidate(savedBankAccountProvider(userId));
      _notify('Đã lưu thông tin ngân hàng trên thiết bị này.');
    } catch (_) {
      _notify('Chưa lưu được thông tin ngân hàng. Hãy thử lại.');
    } finally {
      if (mounted) setState(() => _savingBank = false);
    }
  }

  Future<void> _removeBank(int userId) async {
    if (_savingBank) return;
    setState(() => _savingBank = true);
    try {
      await ref.read(walletBankStoreProvider).clear(userId);
      if (!mounted ||
          ref.read(authSessionProvider).session?.user.id != userId) {
        return;
      }
      ref.invalidate(savedBankAccountProvider(userId));
      _notify('Đã xóa thông tin ngân hàng trên thiết bị này.');
    } catch (_) {
      _notify('Chưa xóa được thông tin ngân hàng. Hãy thử lại.');
    } finally {
      if (mounted) setState(() => _savingBank = false);
    }
  }

  Future<void> _withdraw(
    int userId,
    WalletOverview overview,
    SavedBankAccount bank,
  ) async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    final amount = int.parse(_amount.text.trim());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận yêu cầu rút'),
        content: Text(
          'Rút ${VndMoney(amount).format()} từ CineWallet về '
          '${bank.bankName} · ${bank.accountNumber}? '
          'Số tiền sẽ được giữ trong ví khi gửi yêu cầu và chờ xử lý.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted || _submitting) return;
    if (ref.read(authSessionProvider).session?.user.id != userId) return;
    setState(() => _submitting = true);
    try {
      await ref
          .read(walletRepositoryProvider)
          .createWithdrawal(
            userId,
            WithdrawalCreateRequestDto(
              amount: VndMoney(amount),
              bankName: bank.bankName,
              accountNumber: bank.accountNumber,
              accountHolder: bank.accountHolder,
              walletPhone: _phone.text.trim().isEmpty
                  ? null
                  : _phone.text.trim(),
            ),
          );
      if (!mounted ||
          ref.read(authSessionProvider).session?.user.id != userId) {
        return;
      }
      _amount.clear();
      setState(() {
        _resetPages();
        _tab = _WalletTab.withdrawals;
        _showWithdrawForm = false;
      });
      ref.invalidate(walletOverviewProvider(userId));
      ref.invalidate(accountSummaryProvider);
      ref.invalidate(accountWalletProvider);
      _notify('Đã gửi yêu cầu rút tiền. Theo dõi trạng thái bên dưới.');
    } catch (error) {
      if (mounted && ref.read(authSessionProvider).session?.user.id == userId) {
        if (error is! ApiException ||
            {
              ApiErrorType.network,
              ApiErrorType.timeout,
              ApiErrorType.server,
              ApiErrorType.unknown,
            }.contains(error.type)) {
          setState(_resetPages);
          ref.invalidate(walletOverviewProvider(userId));
        }
        _notify(_withdrawError(error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _refresh(int userId) async {
    setState(_resetPages);
    ref.invalidate(walletOverviewProvider(userId));
    ref.invalidate(savedBankAccountProvider(userId));
    try {
      await ref.read(walletOverviewProvider(userId).future);
    } catch (_) {}
  }

  Future<void> _loadMoreWithdrawals(int userId) async {
    if (_loadingWithdrawals) return;
    if (_historyUserId != userId) _resetPages();
    final page = _withdrawalPage + 1;
    setState(() {
      _historyUserId = userId;
      _loadingWithdrawals = true;
      _withdrawalLoadError = null;
    });
    try {
      final items = await ref
          .read(walletRepositoryProvider)
          .getWithdrawals(userId, page: page);
      if (!mounted ||
          ref.read(authSessionProvider).session?.user.id != userId) {
        return;
      }
      setState(() {
        final ids = _extraWithdrawals.map((item) => item.id).toSet();
        _extraWithdrawals.addAll(items.where((item) => ids.add(item.id)));
        _withdrawalPage = page;
        _moreWithdrawals = items.length == 30;
      });
    } catch (_) {
      if (mounted && ref.read(authSessionProvider).session?.user.id == userId) {
        setState(
          () => _withdrawalLoadError = 'Chưa tải thêm được yêu cầu rút.',
        );
      }
    } finally {
      if (mounted) setState(() => _loadingWithdrawals = false);
    }
  }

  Future<void> _loadMoreTransactions(int userId) async {
    if (_loadingTransactions) return;
    if (_historyUserId != userId) _resetPages();
    final page = _transactionPage + 1;
    setState(() {
      _historyUserId = userId;
      _loadingTransactions = true;
      _transactionLoadError = null;
    });
    try {
      final items = await ref
          .read(walletRepositoryProvider)
          .getTransactions(userId, page: page);
      if (!mounted ||
          ref.read(authSessionProvider).session?.user.id != userId) {
        return;
      }
      setState(() {
        final ids = _extraTransactions.map((item) => item.id).toSet();
        _extraTransactions.addAll(items.where((item) => ids.add(item.id)));
        _transactionPage = page;
        _moreTransactions = items.length == 30;
      });
    } catch (_) {
      if (mounted && ref.read(authSessionProvider).session?.user.id == userId) {
        setState(() => _transactionLoadError = 'Chưa tải thêm được giao dịch.');
      }
    } finally {
      if (mounted) setState(() => _loadingTransactions = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int?>(
      authSessionProvider.select((auth) => auth.session?.user.id),
      (previous, next) {
        if (previous == next) return;
        _amount.clear();
        _phone.clear();
        setState(() {
          _resetPages();
          _tab = _WalletTab.withdrawals;
          _filter = _TransactionFilter.all;
          _showWithdrawForm = false;
        });
      },
    );
    final userId = ref.watch(
      authSessionProvider.select((auth) => auth.session?.user.id),
    );
    return AppShell(
      currentIndex: 4,
      showBottomNavigation: false,
      bookingTitle: 'CineWallet',
      onBookingBack: () => context.go(AppRoutes.account),
      body: userId == null
          ? const Center(child: Text('Vui lòng đăng nhập để xem ví.'))
          : _buildWallet(userId),
    );
  }

  Widget _buildWallet(int userId) {
    final overview = ref.watch(walletOverviewProvider(userId));
    final savedBank = ref.watch(savedBankAccountProvider(userId));
    return overview.when(
      loading: () => const RepositoryStatePane.loading(title: 'Đang tải ví…'),
      error: (_, _) => RepositoryStatePane.error(
        title: 'Chưa tải được CineWallet',
        message: 'Hãy kiểm tra kết nối và thử lại.',
        onRetry: () => ref.invalidate(walletOverviewProvider(userId)),
      ),
      data: (data) => RefreshIndicator(
        onRefresh: () => _refresh(userId),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: const Color(0xFF100E06),
                border: Border.all(color: AppColors.goldBorder),
                borderRadius: AppRadii.card,
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.goldSurface,
                      border: Border.all(color: AppColors.goldBorder),
                      borderRadius: AppRadii.control,
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CINEWALLET',
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.gold,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          data.wallet.balance.format(),
                          key: const ValueKey('wallet-balance'),
                          style: AppTextStyles.sectionTitle.copyWith(
                            color: AppColors.text,
                          ),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    key: const ValueKey('wallet-toggle-withdraw'),
                    onPressed: () =>
                        setState(() => _showWithdrawForm = !_showWithdrawForm),
                    icon: Icon(
                      _showWithdrawForm
                          ? Icons.close_rounded
                          : Icons.north_east_rounded,
                      size: 16,
                    ),
                    label: Text(_showWithdrawForm ? 'Đóng' : 'Rút tiền'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.gold,
                      side: const BorderSide(color: AppColors.goldBorder),
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_showWithdrawForm)
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  border: Border.all(color: AppColors.goldBorder),
                  borderRadius: AppRadii.card,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '↗  TẠO YÊU CẦU RÚT TIỀN VỀ NGÂN HÀNG',
                      style: AppTextStyles.label.copyWith(
                        color: AppColors.gold,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Số dư khả dụng: ${data.wallet.balance.format()}',
                      style: AppTextStyles.caption,
                    ),
                    const Divider(height: AppSpacing.lg),
                    const Text(
                      'Ngân hàng nhận tiền',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Thông tin này chỉ lưu trên thiết bị. Yêu cầu rút chỉ được gửi sau khi bạn xác nhận.',
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    savedBank.when(
                      loading: () =>
                          const ListTile(title: Text('Đang đọc ngân hàng…')),
                      error: (_, _) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const ListTile(
                            title: Text('Chưa đọc được thông tin ngân hàng'),
                            subtitle: Text(
                              'Bạn có thể xóa dữ liệu lưu trên thiết bị rồi nhập lại.',
                            ),
                          ),
                          Wrap(
                            children: [
                              TextButton(
                                onPressed: () => ref.invalidate(
                                  savedBankAccountProvider(userId),
                                ),
                                child: const Text('Thử lại'),
                              ),
                              TextButton(
                                onPressed: _savingBank
                                    ? null
                                    : () => _removeBank(userId),
                                child: const Text('Xóa dữ liệu'),
                              ),
                            ],
                          ),
                        ],
                      ),
                      data: (bank) => bank == null
                          ? AppButton(
                              label: 'Thêm ngân hàng nhận tiền',
                              icon: Icons.account_balance_outlined,
                              variant: AppButtonVariant.secondary,
                              onPressed: _savingBank
                                  ? null
                                  : () => _saveBank(
                                      userId,
                                      _suggestedBank(data.withdrawals),
                                    ),
                            )
                          : Card(
                              child: Column(
                                children: [
                                  ListTile(
                                    leading: const Icon(
                                      Icons.account_balance_rounded,
                                    ),
                                    title: Text(bank.bankName),
                                    subtitle: Text(
                                      '${bank.accountNumber} · ${bank.accountHolder}',
                                    ),
                                  ),
                                  OverflowBar(
                                    children: [
                                      TextButton(
                                        onPressed: _savingBank
                                            ? null
                                            : () => _saveBank(userId, bank),
                                        child: const Text('Sửa'),
                                      ),
                                      TextButton(
                                        onPressed: _savingBank
                                            ? null
                                            : () => _removeBank(userId),
                                        child: const Text('Xóa khỏi thiết bị'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'Yêu cầu rút tiền',
                      style: AppTextStyles.sectionTitle,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            key: const ValueKey('wallet-withdraw-amount'),
                            controller: _amount,
                            enabled: !_submitting,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Số tiền rút (đ)',
                              helperText: 'Tối thiểu 10.000đ',
                            ),
                            validator: (value) {
                              final amount = int.tryParse(value?.trim() ?? '');
                              if (amount == null || amount < 10000) {
                                return 'Nhập ít nhất 10.000đ.';
                              }
                              if (amount > data.wallet.balance.amount) {
                                return 'Số tiền vượt quá số dư khả dụng.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: 6,
                            children: [
                              for (final amount in const [
                                50000,
                                100000,
                                200000,
                                500000,
                              ])
                                ActionChip(
                                  label: Text(VndMoney(amount).format()),
                                  onPressed:
                                      amount <= data.wallet.balance.amount
                                      ? () => _amount.text = '$amount'
                                      : null,
                                ),
                              if (data.wallet.balance.amount >= 10000)
                                ActionChip(
                                  label: const Text('Tất cả số dư'),
                                  onPressed: () => _amount.text =
                                      '${data.wallet.balance.amount}',
                                ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _phone,
                            enabled: !_submitting,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText:
                                  'Số điện thoại liên hệ (không bắt buộc)',
                            ),
                            validator: (value) =>
                                (value?.trim().length ?? 0) > 20
                                ? 'Số điện thoại tối đa 20 ký tự.'
                                : null,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            key: const ValueKey('wallet-withdraw-submit'),
                            label: _submitting
                                ? 'Đang gửi…'
                                : 'Gửi yêu cầu rút',
                            icon: Icons.arrow_upward_rounded,
                            fullWidth: true,
                            loading: _submitting,
                            onPressed:
                                savedBank.asData?.value == null ||
                                    data.wallet.balance.amount < 10000 ||
                                    _submitting
                                ? null
                                : () => _withdraw(
                                    userId,
                                    data,
                                    savedBank.requireValue!,
                                  ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    const Text(
                      'Quản trị viên sẽ xem xét và chuyển khoản thủ công trong 1–3 ngày làm việc.',
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
            SegmentedButton<_WalletTab>(
              segments: const [
                ButtonSegment(
                  value: _WalletTab.withdrawals,
                  label: Text('Rút gần đây'),
                ),
                ButtonSegment(
                  value: _WalletTab.transactions,
                  label: Text('Biến động gần đây'),
                ),
              ],
              selected: {_tab},
              onSelectionChanged: (values) =>
                  setState(() => _tab = values.first),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_tab == _WalletTab.withdrawals)
              _withdrawalHistory(
                userId,
                [
                  ...data.withdrawals,
                  if (_historyUserId == userId) ..._extraWithdrawals,
                ],
                data.withdrawals.length == 30 &&
                    (_historyUserId != userId || _moreWithdrawals),
              )
            else
              _transactionHistory(
                userId,
                [
                  ...data.transactions,
                  if (_historyUserId == userId) ..._extraTransactions,
                ],
                data.transactions.length == 30 &&
                    (_historyUserId != userId || _moreTransactions),
              ),
          ],
        ),
      ),
    );
  }

  Widget _withdrawalHistory(
    int userId,
    List<WithdrawalDto> items,
    bool hasMore,
  ) {
    if (items.isEmpty) {
      return const _WalletEmptyState(
        icon: Icons.credit_card_off_outlined,
        title: 'Chưa có yêu cầu rút tiền nào',
        message: 'Tiến trình và kết quả xử lý sẽ xuất hiện tại đây.',
      );
    }
    return Column(
      children: [
        for (final item in items)
          Card(
            child: ListTile(
              key: ValueKey('wallet-withdrawal-${item.id}'),
              leading: Icon(
                item.status == WithdrawalStatus.paid
                    ? Icons.check_circle_outline_rounded
                    : item.status == WithdrawalStatus.rejected
                    ? Icons.undo_rounded
                    : Icons.schedule_rounded,
                color: _statusColor(item.status),
              ),
              title: Text('${item.bankName} · ${item.amount.format()}'),
              subtitle: Text(
                '${_statusLabel(item.status)} · ${_date(item.createdAt)}',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _showWithdrawal(item),
            ),
          ),
        if (_historyUserId == userId && _withdrawalLoadError != null)
          Text(
            _withdrawalLoadError!,
            style: const TextStyle(color: AppColors.error),
          ),
        if (hasMore ||
            (_historyUserId == userId && _withdrawalLoadError != null))
          TextButton(
            onPressed: _loadingWithdrawals
                ? null
                : () => _loadMoreWithdrawals(userId),
            child: Text(
              _loadingWithdrawals ? 'Đang tải…' : 'Xem thêm yêu cầu rút',
            ),
          ),
      ],
    );
  }

  Widget _transactionHistory(
    int userId,
    List<WalletTransactionDto> items,
    bool hasMore,
  ) {
    final visible = items.where((item) {
      if (item.type == WalletTransactionType.withdrawalPaid ||
          item.amount == 0) {
        return false;
      }
      final refund =
          item.type == WalletTransactionType.refundCredit ||
          item.type == WalletTransactionType.withdrawalRefund;
      return switch (_filter) {
        _TransactionFilter.all => true,
        _TransactionFilter.refunds => refund,
        _TransactionFilter.withdrawals =>
          item.type == WalletTransactionType.withdrawalHold,
      };
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 6,
          children: [
            for (final (filter, label) in [
              (_TransactionFilter.all, 'Tất cả'),
              (_TransactionFilter.refunds, 'Hoàn tiền'),
              (_TransactionFilter.withdrawals, 'Rút tiền'),
            ])
              ChoiceChip(
                label: Text(label),
                selected: _filter == filter,
                onSelected: (_) => setState(() => _filter = filter),
              ),
          ],
        ),
        if (visible.isEmpty)
          const _WalletEmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Chưa có biến động số dư',
            message: 'Giao dịch hoàn vé và rút tiền sẽ hiển thị tại đây.',
          ),
        for (final item in visible)
          Card(
            child: ListTile(
              key: ValueKey('wallet-transaction-${item.id}'),
              title: Text(_transactionLabel(item.type)),
              subtitle: Text(_date(item.createdAt)),
              trailing: Text(
                '${item.amount > 0 ? '+' : '-'}${VndMoney(item.amount.abs()).format()}',
                style: TextStyle(
                  color: item.amount > 0 ? AppColors.success : AppColors.text,
                ),
              ),
              onTap: () => _showTransaction(item),
            ),
          ),
        if (_historyUserId == userId && _transactionLoadError != null)
          Text(
            _transactionLoadError!,
            style: const TextStyle(color: AppColors.error),
          ),
        if (hasMore ||
            (_historyUserId == userId && _transactionLoadError != null))
          TextButton(
            onPressed: _loadingTransactions
                ? null
                : () => _loadMoreTransactions(userId),
            child: Text(
              _loadingTransactions ? 'Đang tải…' : 'Xem thêm giao dịch',
            ),
          ),
      ],
    );
  }

  void _showWithdrawal(WithdrawalDto item) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _DetailSheet(
      title: 'Yêu cầu rút #WD-${item.id}',
      rows: [
        ('Trạng thái', _statusLabel(item.status)),
        ('Số tiền', item.amount.format()),
        ('Ngân hàng', item.bankName),
        ('Số tài khoản', item.accountNumber),
        ('Chủ tài khoản', item.accountHolder),
        ('Gửi lúc', _date(item.createdAt)),
        if (item.processedAt != null) ('Xử lý lúc', _date(item.processedAt!)),
        if (item.processedMethod?.isNotEmpty == true)
          ('Phương thức', item.processedMethod!),
        if (item.processedNote?.isNotEmpty == true)
          ('Ghi chú', item.processedNote!),
        if (item.status == WithdrawalStatus.rejected)
          ('Tiền đã giữ', 'Được cộng lại vào ví theo trạng thái BE'),
      ],
    ),
  );

  void _showTransaction(
    WalletTransactionDto item,
  ) => showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => _DetailSheet(
      title: 'Giao dịch #${item.id}',
      rows: [
        ('Loại', _transactionLabel(item.type)),
        (
          'Biến động',
          '${item.amount > 0 ? '+' : '-'}${VndMoney(item.amount.abs()).format()}',
        ),
        ('Số dư sau giao dịch', item.balanceAfter.format()),
        if (item.referenceCode?.isNotEmpty == true)
          ('Mã tham chiếu', item.referenceCode!),
        if (item.description?.isNotEmpty == true)
          ('Nội dung', item.description!),
        ('Thời gian', _date(item.createdAt)),
      ],
    ),
  );
}

class _WalletEmptyState extends StatelessWidget {
  const _WalletEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.lg,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
      borderRadius: AppRadii.card,
    ),
    child: Column(
      children: [
        Icon(icon, color: AppColors.textFaint, size: 30),
        const SizedBox(height: AppSpacing.sm),
        Text(title, textAlign: TextAlign.center, style: AppTextStyles.emphasis),
        const SizedBox(height: AppSpacing.xs),
        Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.caption,
        ),
      ],
    ),
  );
}

class _BankEditor extends ConsumerStatefulWidget {
  const _BankEditor({this.current});
  final SavedBankAccount? current;

  @override
  ConsumerState<_BankEditor> createState() => _BankEditorState();
}

class _BankEditorState extends ConsumerState<_BankEditor> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _bank;
  late final TextEditingController _number;
  late final TextEditingController _holder;

  @override
  void initState() {
    super.initState();
    _bank = TextEditingController(text: widget.current?.bankName ?? '');
    _number = TextEditingController(text: widget.current?.accountNumber ?? '');
    _holder = TextEditingController(text: widget.current?.accountHolder ?? '');
  }

  @override
  void dispose() {
    _bank.dispose();
    _number.dispose();
    _holder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final banks =
        ref.watch(bankDirectoryProvider).asData?.value ?? const <BankOption>[];
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ngân hàng nhận tiền',
                  style: AppTextStyles.sectionTitle,
                ),
                const SizedBox(height: AppSpacing.sm),
                const Text(
                  'Thông tin ngân hàng chỉ lưu trên thiết bị này; hệ thống sẽ nhận thông tin khi bạn gửi yêu cầu rút.',
                  style: AppTextStyles.caption,
                ),
                const SizedBox(height: AppSpacing.md),
                if (banks.isNotEmpty) ...[
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Chọn nhanh ngân hàng',
                    ),
                    items: [
                      for (final bank in banks)
                        DropdownMenuItem(
                          value: bank.shortName,
                          child: Text(
                            '${bank.shortName} · ${bank.fullName}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (value) {
                      if (value != null) _bank.text = value;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
                TextFormField(
                  key: const ValueKey('wallet-bank-name'),
                  controller: _bank,
                  decoration: const InputDecoration(labelText: 'Tên ngân hàng'),
                  validator: (value) {
                    final name = value?.trim() ?? '';
                    if (name.isEmpty) return 'Nhập tên ngân hàng.';
                    if (name.length > 100) {
                      return 'Tên ngân hàng tối đa 100 ký tự.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const ValueKey('wallet-bank-number'),
                  controller: _number,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(labelText: 'Số tài khoản'),
                  validator: (value) =>
                      RegExp(r'^\d{8,15}$').hasMatch(value?.trim() ?? '')
                      ? null
                      : 'Số tài khoản cần 8–15 chữ số.',
                ),
                const SizedBox(height: AppSpacing.sm),
                TextFormField(
                  key: const ValueKey('wallet-bank-holder'),
                  controller: _holder,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Tên chủ tài khoản',
                  ),
                  validator: (value) {
                    final holder = value?.trim() ?? '';
                    if (holder.length < 2) return 'Nhập tên chủ tài khoản.';
                    if (holder.length > 120) return 'Tên tối đa 120 ký tự.';
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
                AppButton(
                  label: 'Lưu thông tin ngân hàng',
                  fullWidth: true,
                  onPressed: () {
                    if (!_formKey.currentState!.validate()) return;
                    Navigator.pop(
                      context,
                      SavedBankAccount(
                        bankName: _bank.text.trim(),
                        accountNumber: _number.text.trim(),
                        accountHolder: _holder.text.trim().toUpperCase(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailSheet extends StatelessWidget {
  const _DetailSheet({required this.title, required this.rows});
  final String title;
  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            for (final (label, value) in rows)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 130,
                      child: Text(label, style: AppTextStyles.caption),
                    ),
                    Expanded(child: SelectableText(value)),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/'
    '${value.month.toString().padLeft(2, '0')}/${value.year} '
    '${value.hour.toString().padLeft(2, '0')}:'
    '${value.minute.toString().padLeft(2, '0')}';

String _statusLabel(WithdrawalStatus value) => switch (value) {
  WithdrawalStatus.pending => 'Đang chờ duyệt',
  WithdrawalStatus.paid => 'Đã chuyển tiền',
  WithdrawalStatus.rejected => 'Bị từ chối · Đã hoàn ví',
  WithdrawalStatus.unknown => 'Chưa xác định',
};

Color _statusColor(WithdrawalStatus value) => switch (value) {
  WithdrawalStatus.pending => AppColors.gold,
  WithdrawalStatus.paid => AppColors.success,
  WithdrawalStatus.rejected => AppColors.error,
  WithdrawalStatus.unknown => AppColors.textMuted,
};

String _transactionLabel(WalletTransactionType value) => switch (value) {
  WalletTransactionType.refundCredit => 'Hoàn tiền vé',
  WalletTransactionType.withdrawalHold => 'Yêu cầu rút tiền',
  WalletTransactionType.withdrawalRefund => 'Hoàn tiền lệnh rút bị từ chối',
  WalletTransactionType.withdrawalPaid => 'Đã chuyển khoản',
  WalletTransactionType.bookingDebit => 'Thanh toán vé bằng ví',
  WalletTransactionType.topUp => 'Nạp tiền',
  WalletTransactionType.unknown => 'Giao dịch ví',
};

String _withdrawError(Object error) {
  if (error is! ApiException) {
    return 'Chưa xác định kết quả. Kiểm tra lịch sử rút trước khi gửi lại.';
  }
  return switch (error.type) {
    ApiErrorType.unauthorized =>
      'Phiên đăng nhập đã hết hạn. Hãy đăng nhập lại.',
    ApiErrorType.forbidden => 'Tài khoản chưa được phép rút tiền.',
    ApiErrorType.badRequest || ApiErrorType.validation => error.message,
    ApiErrorType.network || ApiErrorType.timeout || ApiErrorType.server =>
      'Chưa xác định kết quả. Kiểm tra số dư và lịch sử rút trước khi gửi lại.',
    _ => 'Chưa xác định kết quả. Kiểm tra lịch sử rút trước khi gửi lại.',
  };
}

SavedBankAccount? _suggestedBank(List<WithdrawalDto> withdrawals) {
  for (final item in withdrawals) {
    if (item.bankName.isNotEmpty &&
        RegExp(r'^\d{8,15}$').hasMatch(item.accountNumber) &&
        item.accountHolder.isNotEmpty) {
      return SavedBankAccount(
        bankName: item.bankName,
        accountNumber: item.accountNumber,
        accountHolder: item.accountHolder,
      );
    }
  }
  return null;
}
