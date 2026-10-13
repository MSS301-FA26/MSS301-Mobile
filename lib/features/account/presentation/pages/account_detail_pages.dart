import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/demo/demo_scenario.dart';
import '../../../../core/money/vnd_money.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_shell.dart';
import '../../../../shared/widgets/repository_state_pane.dart';
import '../../data/models/account_dto.dart';
import '../../data/repositories/account_providers.dart';
import '../providers/account_summary_provider.dart';
import '../../application/profile_controller.dart';
import '../../../auth/application/auth_session.dart';
import '../widgets/profile_avatar.dart';
import '../../../movie/data/repositories/catalog_providers.dart';
import '../../../../core/time/vietnam_time.dart';

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
  UserProfileDto? _profile;
  String? _loadError;
  bool _requested = false;
  int? _editingUser;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _birthYear.dispose();
    super.dispose();
  }

  Future<void> _load({bool retry = false}) async {
    final userId = ref.read(authSessionProvider).session?.user.id;
    if (retry) ref.invalidate(currentProfileProvider);
    try {
      final profile = await ref.read(currentProfileProvider.future);
      if (!mounted || userId != ref.read(authSessionProvider).session?.user.id) {
        return;
      }
      setState(() {
        _profile = profile;
        _loadError = null;
        _name.text = profile.fullName;
        _phone.text = profile.phone ?? '';
        _birthYear.text = profile.birthYear?.toString() ?? '';
      });
    } catch (error) {
      if (mounted && userId == ref.read(authSessionProvider).session?.user.id) {
        setState(() => _loadError = profileErrorMessage(error));
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final saved = await ref
        .read(profileMutationProvider.notifier)
        .save(
          UserProfileUpdateDto(
            fullName: _name.text.trim(),
            phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
            birthYear: int.tryParse(_birthYear.text.trim()),
          ),
        );
    if (saved && mounted) await _load();
  }

  Future<void> _avatar() async {
    var avatarUrl = '';
    final form = GlobalKey<FormState>();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đổi ảnh đại diện'),
        content: Form(
          key: form,
          child: TextFormField(
            onChanged: (value) => avatarUrl = value,
            key: const ValueKey('avatar-url'),
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'URL ảnh',
              hintText: 'https://...',
            ),
            validator: (value) {
              final uri = Uri.tryParse(value?.trim() ?? '');
              return uri == null ||
                      uri.host.isEmpty ||
                      !['http', 'https'].contains(uri.scheme)
                  ? 'Nhập URL ảnh http/https hợp lệ.'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () {
              if (form.currentState!.validate()) {
                Navigator.pop(context, avatarUrl.trim());
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
    if (url == null || !mounted) return;
    final saved = await ref.read(profileMutationProvider.notifier).avatar(url);
    if (saved && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(
      authSessionProvider.select((auth) => auth.session?.user.id),
    );
    ref.watch(currentProfileProvider);
    final mutation = ref.watch(profileMutationProvider);
    if (_editingUser != userId) {
      _editingUser = userId;
      _requested = false;
      _profile = null;
      _loadError = null;
      _name.clear();
      _phone.clear();
      _birthYear.clear();
    }
    if (!_requested) {
      _requested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    return _AccountScaffold(
      title: 'Hồ sơ cá nhân',
      child: _profile == null
          ? _loadError != null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_loadError!, textAlign: TextAlign.center),
                      TextButton(
                        onPressed: () {
                          setState(() => _loadError = null);
                          _load(retry: true);
                        },
                        child: const Text('Thử lại'),
                      ),
                    ],
                  )
                : const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  Center(
                    child: ProfileAvatar(url: _profile!.avatarUrl, radius: 42),
                  ),
                  TextButton(
                    key: const ValueKey('profile-avatar'),
                    onPressed: mutation.busy ? null : _avatar,
                    child: const Text('Đổi ảnh đại diện'),
                  ),
                  Text(
                    _profile!.email,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    key: const ValueKey('profile-name'),
                    controller: _name,
                    readOnly: mutation.busy,
                    decoration: const InputDecoration(labelText: 'Họ và tên'),
                    validator: (v) => profileNameError(v ?? ''),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    key: const ValueKey('profile-phone'),
                    controller: _phone,
                    readOnly: mutation.busy,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                    ),
                    validator: (v) => profilePhoneError(v ?? ''),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextFormField(
                    key: const ValueKey('profile-birth-year'),
                    controller: _birthYear,
                    readOnly: mutation.busy,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Năm sinh'),
                    validator: (v) => profileBirthYearError(
                      v ?? '',
                      vietnamCalendar(ref.read(appClockProvider).now()).year,
                    ),
                  ),
                  if (_loadError != null)
                    Text(_loadError!, style: AppTextStyles.caption),
                  if (mutation.message != null &&
                      mutation.operation != 'password')
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.sm,
                      ),
                      child: Text(
                        mutation.message!,
                        key: const ValueKey('profile-message'),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.lg),
                  AppButton(
                    key: const ValueKey('profile-save'),
                    label: mutation.busy ? 'Đang cập nhật…' : 'Lưu thay đổi',
                    onPressed: mutation.busy ? null : _save,
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

@Deprecated('Use PointsPage.')
class LegacyPointsPage extends ConsumerWidget {
  const LegacyPointsPage({super.key});

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

class PointsPage extends ConsumerStatefulWidget {
  const PointsPage({super.key});

  @override
  ConsumerState<PointsPage> createState() => _PointsPageState();
}

class _PointsPageState extends ConsumerState<PointsPage> {
  final _pointsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  Future<void> _redeem(LoyaltyDto loyalty) async {
    ref.read(loyaltyRedeemControllerProvider.notifier).resetMessage();
    if (!_formKey.currentState!.validate()) return;
    final points = int.parse(_pointsController.text.trim());
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận đổi điểm'),
        content: Text(
          'Đổi $points điểm từ số dư hiện tại ${loyalty.points} điểm?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Quay lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xác nhận đổi'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(loyaltyRedeemControllerProvider.notifier).redeem(points);
    if (!mounted) return;
    if (ref.read(loyaltyRedeemControllerProvider).status ==
        LoyaltyRedeemStatus.success) {
      _pointsController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final overview = ref.watch(loyaltyOverviewProvider);
    final redeemState = ref.watch(loyaltyRedeemControllerProvider);
    return _AccountScaffold(
      title: 'CinePoints',
      child: overview.when(
        loading: () => const RepositoryStatePane.loading(),
        error: (error, stack) => RepositoryStatePane.error(
          onRetry: () => ref.invalidate(loyaltyOverviewProvider),
        ),
        data: (data) {
          final (loyalty, config) = data;
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
              const SizedBox(height: AppSpacing.lg),
              const Text('Đổi điểm thưởng', style: AppTextStyles.sectionTitle),
              const SizedBox(height: AppSpacing.sm),
              Form(
                key: _formKey,
                child: TextFormField(
                  key: const ValueKey('loyalty-redeem-points'),
                  controller: _pointsController,
                  keyboardType: TextInputType.number,
                  enabled: !redeemState.isSubmitting,
                  decoration: const InputDecoration(
                    labelText: 'Số điểm muốn đổi',
                  ),
                  validator: (value) {
                    final points = int.tryParse(value?.trim() ?? '');
                    if (points == null) return 'Nhập số điểm nguyên hợp lệ.';
                    if (points <= 0) return 'Số điểm phải lớn hơn 0.';
                    if (points > loyalty.points) {
                      return 'Số điểm vượt quá số dư hiện tại.';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              AppButton(
                key: const ValueKey('loyalty-redeem-submit'),
                label: redeemState.isSubmitting ? 'Đang xử lý…' : 'Đổi điểm',
                onPressed: redeemState.isSubmitting
                    ? null
                    : () => _redeem(loyalty),
              ),
              if (redeemState.message != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  redeemState.message!,
                  key: const ValueKey('loyalty-redeem-message'),
                  style: TextStyle(
                    color: redeemState.status == LoyaltyRedeemStatus.error
                        ? AppColors.error
                        : AppColors.success,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              const Text('Lịch sử điểm', style: AppTextStyles.sectionTitle),
              const ListTile(
                leading: Icon(Icons.history_rounded),
                title: Text('Backend chưa cung cấp API lịch sử điểm.'),
              ),
            ],
          );
        },
      ),
    );
  }
}

class SecurityPage extends ConsumerStatefulWidget {
  const SecurityPage({super.key});
  @override
  ConsumerState<SecurityPage> createState() => _SecurityPageState();
}

class _SecurityPageState extends ConsumerState<SecurityPage> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  int? _userId;
  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _change() async {
    if (!_form.currentState!.validate()) return;
    final saved = await ref
        .read(profileMutationProvider.notifier)
        .password(_current.text, _next.text, _confirm.text);
    if (saved && mounted) {
      _current.clear();
      _next.clear();
      _confirm.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final id = ref.watch(
      authSessionProvider.select((auth) => auth.session?.user.id),
    );
    if (_userId != id) {
      _userId = id;
      _current.clear();
      _next.clear();
      _confirm.clear();
    }
    final mutation = ref.watch(profileMutationProvider);
    return _AccountScaffold(
      title: 'Bảo mật',
      child: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            TextFormField(
              key: const ValueKey('password-current'),
              controller: _current,
              obscureText: true,
              readOnly: mutation.busy,
              decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại'),
              validator: (v) => v == null || v.isEmpty
                  ? 'Vui lòng nhập mật khẩu hiện tại.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              key: const ValueKey('password-new'),
              controller: _next,
              obscureText: true,
              readOnly: mutation.busy,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
              validator: (v) => v == _current.text
                  ? 'Mật khẩu mới phải khác mật khẩu hiện tại.'
                  : newPasswordError(v ?? ''),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextFormField(
              key: const ValueKey('password-confirm'),
              controller: _confirm,
              obscureText: true,
              readOnly: mutation.busy,
              decoration: const InputDecoration(
                labelText: 'Xác nhận mật khẩu mới',
              ),
              validator: (v) => v != _next.text || v == null || v.isEmpty
                  ? 'Xác nhận mật khẩu chưa khớp.'
                  : null,
            ),
            if (mutation.message != null && mutation.operation == 'password')
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Text(
                  mutation.message!,
                  key: const ValueKey('password-message'),
                ),
              ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              key: const ValueKey('password-save'),
              label: mutation.busy ? 'Đang cập nhật…' : 'Đổi mật khẩu',
              onPressed: mutation.busy ? null : _change,
            ),
          ],
        ),
      ),
    );
  }
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
