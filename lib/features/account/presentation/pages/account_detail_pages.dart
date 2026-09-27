import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/demo/demo_scenario.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../data/models/account_dto.dart';
import '../../data/repositories/account_providers.dart';
import '../providers/account_summary_provider.dart';

class ProfileEditPage extends ConsumerStatefulWidget {
  const ProfileEditPage({super.key});

  @override
  ConsumerState<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends ConsumerState<ProfileEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _birthYear = TextEditingController();
  var _loaded = false;
  var _saving = false;
  String? _message;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _birthYear.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final profile = await ref
        .read(profileRepositoryProvider)
        .getProfile(DemoIds.user);
    if (!mounted) return;
    _name.text = profile.fullName;
    _phone.text = profile.phone ?? '';
    _birthYear.text = profile.birthYear?.toString() ?? '';
    setState(() => _loaded = true);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _message = null;
    });
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            DemoIds.user,
            UserProfileUpdateDto(
              fullName: _name.text.trim(),
              phone: _phone.text.trim(),
              birthYear: int.tryParse(_birthYear.text.trim()),
            ),
          );
      ref.invalidate(accountSummaryProvider);
      if (mounted) setState(() => _message = 'Đã lưu hồ sơ.');
    } catch (error) {
      if (mounted) setState(() => _message = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_loaded) _load();
      });
    }
    return _AccountScaffold(
      title: 'Hồ sơ cá nhân',
      child: !_loaded
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  const CircleAvatar(
                    radius: 42,
                    child: Icon(Icons.person_rounded, size: 44),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                    validator: (value) => (value?.trim().length ?? 0) < 2
                        ? 'Họ tên không hợp lệ'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                    ),
                    validator: (value) {
                      final phone = value?.trim() ?? '';
                      return phone.isNotEmpty && phone.length < 9
                          ? 'Số điện thoại không hợp lệ'
                          : null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    controller: _birthYear,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Năm sinh'),
                    validator: (value) {
                      final year = int.tryParse(value ?? '');
                      return year != null && (year < 1900 || year > 2020)
                          ? 'Năm sinh không hợp lệ'
                          : null;
                    },
                  ),
                  if (_message != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      _message!,
                      style: const TextStyle(color: AppColors.gold),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    key: const ValueKey('profile-save'),
                    label: _saving ? 'Đang lưu…' : 'Lưu thay đổi',
                    onPressed: _saving ? null : _save,
                  ),
                ],
              ),
            ),
    );
  }
}

class WalletPage extends ConsumerStatefulWidget {
  const WalletPage({super.key});

  @override
  ConsumerState<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends ConsumerState<WalletPage> {
  late Future<(WalletDto, List<WalletTransactionDto>, List<WithdrawalDto>)>
  _data;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    final repository = ref.read(walletRepositoryProvider);
    _data = (
      repository.getWallet(DemoIds.user),
      repository.getTransactions(DemoIds.user),
      repository.getWithdrawals(DemoIds.user),
    ).wait;
  }

  Future<void> _withdraw() async {
    final amount = TextEditingController(text: '100000');
    final account = TextEditingController(text: '0123456789');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Yêu cầu rút tiền'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số tiền'),
            ),
            TextField(
              controller: account,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số tài khoản'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Gửi yêu cầu'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref
          .read(walletRepositoryProvider)
          .createWithdrawal(
            DemoIds.user,
            WithdrawalCreateRequestDto(
              amount: VndMoney(int.tryParse(amount.text) ?? 0),
              bankName: 'Ngân hàng Mock',
              accountNumber: account.text,
              accountHolder: 'NGUYEN MINH',
            ),
          );
      ref.invalidate(accountSummaryProvider);
      setState(_reload);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) => _AccountScaffold(
    title: 'CineWallet',
    child: FutureBuilder(
      future: _data,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final (wallet, transactions, withdrawals) = snapshot.requireData;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _BalanceCard(
              label: 'Số dư có thể rút',
              value: wallet.balance.format(),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text(
              'CineWallet chỉ nhận hoàn tiền/rút tiền. Không có nạp tiền và không dùng để thanh toán vé.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(label: 'Yêu cầu rút tiền', onPressed: _withdraw),
            const SizedBox(height: AppSpacing.lg),
            const Text('Giao dịch', style: AppTextStyles.sectionTitle),
            if (transactions.isEmpty)
              const ListTile(title: Text('Chưa có giao dịch'))
            else
              for (final item in transactions)
                ListTile(
                  title: Text(item.description ?? item.type.wireValue),
                  subtitle: Text(item.referenceCode ?? ''),
                  trailing: Text(item.amount.format()),
                ),
            const Text('Yêu cầu rút', style: AppTextStyles.sectionTitle),
            if (withdrawals.isEmpty)
              const ListTile(title: Text('Chưa có yêu cầu rút tiền'))
            else
              for (final item in withdrawals)
                ListTile(
                  title: Text(item.amount.format()),
                  subtitle: Text(item.bankName),
                  trailing: Text(item.status.wireValue),
                ),
          ],
        );
      },
    ),
  );
}

class PointsPage extends ConsumerWidget {
  const PointsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => _AccountScaffold(
    title: 'CinePoints',
    child: FutureBuilder(
      future: Future.wait<Object>([
        ref.read(loyaltyRepositoryProvider).getLoyalty(DemoIds.user),
        ref.read(loyaltyRepositoryProvider).getConfiguration(),
      ]),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final loyalty = snapshot.requireData[0] as LoyaltyDto;
        final config = snapshot.requireData[1] as LoyaltyConfigurationDto;
        return ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _BalanceCard(
              label: 'Điểm khả dụng',
              value: '${loyalty.points} điểm',
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Tổng điểm từng tích: ${loyalty.totalPoints}'),
            Text('Tỷ lệ tích điểm: ${config.earningRatePercent}%'),
            Text(
              '${config.redemptionPoints} điểm = ${config.redemptionValueVnd.format()}',
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('Lịch sử điểm', style: AppTextStyles.sectionTitle),
            const ListTile(
              leading: Icon(Icons.history_rounded),
              title: Text('Chưa có giao dịch điểm trong fixture hiện tại'),
            ),
            const Text(
              'Dùng điểm tại checkout đang tắt cho đến khi backend thống nhất quy tắc giữ, trừ và hoàn điểm.',
              style: AppTextStyles.caption,
            ),
          ],
        );
      },
    ),
  );
}

class SecurityPage extends StatefulWidget {
  const SecurityPage({super.key});

  @override
  State<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends State<SecurityPage> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  String? _message;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _AccountScaffold(
    title: 'Bảo mật',
    child: ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        TextField(
          controller: _current,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
        ),
        const SizedBox(height: AppSpacing.sm),
        TextField(
          controller: _next,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
        ),
        if (_message != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(_message!, style: const TextStyle(color: AppColors.gold)),
        ],
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Đổi mật khẩu',
          onPressed: () {
            setState(() {
              _message = _current.text.length >= 6 && _next.text.length >= 8
                  ? 'Đổi mật khẩu mock thành công.'
                  : 'Mật khẩu hiện tại tối thiểu 6 và mật khẩu mới tối thiểu 8 ký tự.';
            });
          },
        ),
      ],
    ),
  );
}

class _AccountScaffold extends StatelessWidget {
  const _AccountScaffold({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) => AppShell(
    currentIndex: 4,
    showBottomNavigation: false,
    body: Column(
      children: [
        SafeArea(
          bottom: false,
          child: ListTile(
            leading: IconButton(
              tooltip: 'Quay lại tài khoản',
              onPressed: () => context.go(AppRoutes.account),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            title: Text(title, style: AppTextStyles.sectionTitle),
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.goldSurface,
      borderRadius: AppRadii.card,
      border: Border.all(color: AppColors.goldBorder),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.caption),
        Text(value, style: AppTextStyles.heroTitle),
      ],
    ),
  );
}
