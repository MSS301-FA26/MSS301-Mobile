import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/demo/demo_scenario.dart';
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
import '../../../movie/presentation/providers/movie_engagement_provider.dart';
import '../../../../core/time/vietnam_time.dart';
import '../../../orders/data/models/booking_enums.dart';
import '../../../orders/presentation/providers/orders_provider.dart';

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
  bool _purgingAiData = false;

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
      if (!mounted ||
          userId != ref.read(authSessionProvider).session?.user.id) {
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
        scrollable: true,
        title: const Text('Đổi ảnh đại diện'),
        content: Form(
          key: form,
          child: TextFormField(
            onChanged: (value) => avatarUrl = value,
            key: const ValueKey('avatar-url'),
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              errorMaxLines: 3,
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

  Future<void> _purgeAiData() async {
    final userId = ref.read(authSessionProvider).session?.user.id;
    if (userId == null || _purgingAiData) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa dữ liệu đề xuất AI?'),
        content: const Text(
          'Toàn bộ lịch sử đề xuất và sở thích AI của bạn sẽ bị xóa. '
          'Các đề xuất sau đó sẽ trở về trạng thái mặc định theo quyền được lãng quên của GDPR.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xóa dữ liệu'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _purgingAiData = true);
    try {
      await ref
          .read(movieEngagementRepositoryProvider)
          .purgeUserRecommendationData(userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa toàn bộ dữ liệu đề xuất AI của bạn.'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể xóa dữ liệu AI: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _purgingAiData = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(
      authSessionProvider.select((auth) => auth.session?.user.id),
    );
    ref.watch(currentProfileProvider);
    final account = ref.watch(accountSummaryProvider).value;
    final watchedMovies = ref
        .watch(ordersProvider)
        .value
        ?.where((order) => order.status == BookingStatus.used)
        .length;
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
                ? RepositoryStatePane.error(
                    message: _loadError,
                    onRetry: () {
                      setState(() => _loadError = null);
                      _load(retry: true);
                    },
                  )
                : const RepositoryStatePane.loading(
                    layout: RepositorySkeleton.account,
                  )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _ProfileHero(
                    profile: _profile!,
                    memberSince: account?.joinYear ?? _profile!.createdAt.year,
                    onAvatar: mutation.busy ? null : _avatar,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _ProfileInformationGrid(profile: _profile!),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _ProfileMetric(
                          icon: Icons.local_fire_department_outlined,
                          label: 'CinePoints',
                          value: account?.points?.toString() ?? '—',
                          color: AppColors.gold,
                          onTap: () => context.go(AppRoutes.points),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: _ProfileMetric(
                          icon: Icons.movie_outlined,
                          label: 'Phim đã xem',
                          value: watchedMovies?.toString() ?? '—',
                          color: AppColors.textSecondary,
                          onTap: () => context.go(AppRoutes.orders),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const _ControlCenterHeader(),
                  const SizedBox(height: AppSpacing.sm),
                  _ProfileControlTile(
                    key: const ValueKey('profile-edit-section'),
                    icon: Icons.person_outline_rounded,
                    title: 'Chỉnh sửa hồ sơ VIP',
                    initiallyExpanded: true,
                    child: Column(
                      children: [
                        TextFormField(
                          key: const ValueKey('profile-name'),
                          controller: _name,
                          maxLength: 100,
                          readOnly: mutation.busy,
                          decoration: const InputDecoration(
                            errorMaxLines: 3,
                            labelText: 'Họ và tên',
                          ),
                          validator: (v) => profileNameError(v ?? ''),
                        ),
                        TextFormField(
                          initialValue: _profile!.email,
                          readOnly: true,
                          decoration: const InputDecoration(
                            labelText: 'Địa chỉ email liên hệ',
                            suffixIcon: Icon(Icons.lock_outline_rounded),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          key: const ValueKey('profile-phone'),
                          controller: _phone,
                          readOnly: mutation.busy,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            errorMaxLines: 3,
                            labelText: 'Số điện thoại',
                          ),
                          validator: (v) => profilePhoneError(v ?? ''),
                        ),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '10 số, bắt đầu 03/05/08/09',
                            style: AppTextStyles.caption,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextFormField(
                          key: const ValueKey('profile-birth-year'),
                          controller: _birthYear,
                          readOnly: mutation.busy,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            errorMaxLines: 3,
                            labelText: 'Năm sinh',
                          ),
                          validator: (v) => profileBirthYearError(
                            v ?? '',
                            vietnamCalendar(ref.read(appClockProvider).now())
                                .year,
                          ),
                        ),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Dùng để xác minh độ tuổi xem phim',
                            style: AppTextStyles.caption,
                          ),
                        ),
                        if (_loadError != null)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(
                              _loadError!,
                              style: AppTextStyles.caption,
                            ),
                          ),
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
                        const SizedBox(height: AppSpacing.md),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            key: const ValueKey('profile-save'),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.black,
                              minimumSize: const Size.fromHeight(48),
                            ),
                            icon: const Icon(Icons.save_outlined, size: 18),
                            label: Text(
                              mutation.busy
                                  ? 'Đang cập nhật…'
                                  : 'LƯU THAY ĐỔI HỒ SƠ',
                            ),
                            onPressed: mutation.busy ? null : _save,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ProfileNavigationTile(
                    icon: Icons.account_balance_outlined,
                    title: 'Tài khoản ngân hàng (Rút ví)',
                    onTap: () => context.go(AppRoutes.wallet),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ProfileNavigationTile(
                    icon: Icons.lock_outline_rounded,
                    title: 'Mật khẩu & bảo an',
                    onTap: () => context.go(AppRoutes.security),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _ProfileControlTile(
                    icon: Icons.auto_awesome_outlined,
                    title: 'Cá nhân hóa CineAI & quyền riêng tư',
                    child: _AiPrivacyPanel(
                      userId: userId,
                      purging: _purgingAiData,
                      onPurge: _purgeAiData,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  OutlinedButton.icon(
                    key: const ValueKey('profile-sign-out'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.adultBadge,
                      side: BorderSide(
                        color: AppColors.adultBadge.withValues(alpha: .35),
                      ),
                      minimumSize: const Size.fromHeight(52),
                    ),
                    onPressed: _confirmSignOut,
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('ĐĂNG XUẤT'),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất?'),
        content: const Text('Bạn có chắc muốn đăng xuất khỏi CinePremier?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ở lại'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      ref.read(authSessionProvider.notifier).signOut();
      context.go(AppRoutes.login);
    }
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.profile,
    required this.memberSince,
    required this.onAvatar,
  });

  final UserProfileDto profile;
  final int memberSince;
  final VoidCallback? onAvatar;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.lg),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.goldBorder),
      gradient: LinearGradient(
        colors: [
          AppColors.gold.withValues(alpha: .09),
          AppColors.surface,
          AppColors.surface,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ProfileAvatar(url: profile.avatarUrl, radius: 42),
            Positioned(
              right: -5,
              bottom: -5,
              child: Material(
                color: AppColors.surfaceHigh,
                shape: const CircleBorder(
                  side: BorderSide(color: AppColors.goldBorder),
                ),
                child: IconButton(
                  key: const ValueKey('profile-avatar'),
                  tooltip: 'Đổi ảnh đại diện',
                  visualDensity: VisualDensity.compact,
                  onPressed: onAvatar,
                  icon: const Icon(
                    Icons.photo_camera_outlined,
                    color: AppColors.gold,
                    size: 18,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.fullName, style: AppTextStyles.sectionTitle),
              const SizedBox(height: 5),
              Text(
                'THÀNH VIÊN TỪ $memberSince • ${profile.status.name.toUpperCase()}',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.gold,
                  letterSpacing: .7,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                profile.email,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _ProfileInformationGrid extends StatelessWidget {
  const _ProfileInformationGrid({required this.profile});

  final UserProfileDto profile;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = (constraints.maxWidth - AppSpacing.sm) / 2;
      return Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        children: [
          _ProfileInfoCell(
            width: width,
            icon: Icons.email_outlined,
            label: 'Email tài khoản',
            value: profile.email,
          ),
          _ProfileInfoCell(
            width: width,
            icon: Icons.phone_outlined,
            label: 'Số điện thoại',
            value: profile.phone?.trim().isNotEmpty == true
                ? profile.phone!
                : 'Chưa cập nhật',
          ),
          _ProfileInfoCell(
            width: width,
            icon: Icons.cake_outlined,
            label: 'Năm sinh',
            value: profile.birthYear?.toString() ?? 'Chưa cập nhật',
          ),
          _ProfileInfoCell(
            width: width,
            icon: Icons.verified_user_outlined,
            label: 'Xác thực',
            value: profile.emailVerified
                ? 'Email đã xác thực'
                : 'Email chưa xác thực',
            positive: profile.emailVerified,
          ),
        ],
      );
    },
  );
}

class _ProfileInfoCell extends StatelessWidget {
  const _ProfileInfoCell({
    required this.width,
    required this.icon,
    required this.label,
    required this.value,
    this.positive = false,
  });

  final double width;
  final IconData icon;
  final String label;
  final String value;
  final bool positive;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    constraints: const BoxConstraints(minHeight: 96),
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: AppColors.gold),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: AppTextStyles.caption.copyWith(fontSize: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          value,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.body.copyWith(
            color: positive ? AppColors.success : AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  style: AppTextStyles.caption.copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTextStyles.sectionTitle.copyWith(fontSize: 25)),
        ],
      ),
    ),
  );
}

class _ControlCenterHeader extends StatelessWidget {
  const _ControlCenterHeader();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.goldBorder),
      color: AppColors.gold.withValues(alpha: .05),
    ),
    child: const Row(
      children: [
        Icon(Icons.settings_outlined, color: AppColors.gold, size: 19),
        SizedBox(width: AppSpacing.sm),
        Text('TRUNG TÂM KIỂM SOÁT VIP', style: AppTextStyles.label),
      ],
    ),
  );
}

class _ProfileControlTile extends StatelessWidget {
  const _ProfileControlTile({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
    ),
    child: ExpansionTile(
      initiallyExpanded: initiallyExpanded,
      leading: Icon(icon, color: AppColors.gold),
      title: Text(title.toUpperCase(), style: AppTextStyles.label),
      childrenPadding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md,
      ),
      children: [child],
    ),
  );
}

class _AiPrivacyPanel extends StatelessWidget {
  const _AiPrivacyPanel({
    required this.userId,
    required this.purging,
    required this.onPurge,
  });

  final int? userId;
  final bool purging;
  final VoidCallback onPurge;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'CineAI phân tích lịch sử xem phim, đánh giá và tương tác để đưa ra '
        'đề xuất phù hợp. Dữ liệu được bảo vệ theo quyền riêng tư người dùng GDPR.',
        style: AppTextStyles.caption,
      ),
      const SizedBox(height: AppSpacing.md),
      Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            const _PrivacyStatusLine(
              label: 'Trạng thái mô hình',
              value: 'Đang hoạt động',
              valueColor: AppColors.success,
            ),
            const SizedBox(height: AppSpacing.sm),
            _PrivacyStatusLine(
              label: 'Mã người dùng',
              value: userId == null ? 'GUEST' : '#$userId',
            ),
            const SizedBox(height: AppSpacing.sm),
            const _PrivacyStatusLine(
              label: 'Quyền được lãng quên',
              value: 'GDPR Article 17',
              valueColor: AppColors.lavender,
            ),
          ],
        ),
      ),
      const SizedBox(height: AppSpacing.md),
      OutlinedButton.icon(
        key: const ValueKey('profile-purge-ai-data'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.adultBadge,
          side: BorderSide(color: AppColors.adultBadge.withValues(alpha: .4)),
          minimumSize: const Size.fromHeight(48),
        ),
        onPressed: purging || userId == null ? null : onPurge,
        icon: purging
            ? const SizedBox.square(
                dimension: 17,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.delete_outline_rounded),
        label: Text(
          purging ? 'ĐANG XÓA DỮ LIỆU…' : 'XÓA TOÀN BỘ DỮ LIỆU ĐỀ XUẤT AI',
        ),
      ),
    ],
  );
}

class _PrivacyStatusLine extends StatelessWidget {
  const _PrivacyStatusLine({
    required this.label,
    required this.value,
    this.valueColor = AppColors.text,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Text(label, style: AppTextStyles.caption)),
      const SizedBox(width: AppSpacing.sm),
      Flexible(
        child: Text(
          value,
          textAlign: TextAlign.right,
          style: AppTextStyles.caption.copyWith(
            color: valueColor,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

class _ProfileNavigationTile extends StatelessWidget {
  const _ProfileNavigationTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.surface,
    shape: const RoundedRectangleBorder(
      side: BorderSide(color: AppColors.border),
    ),
    child: ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.textMuted),
      title: Text(title.toUpperCase(), style: AppTextStyles.label),
      trailing: const Icon(Icons.chevron_right_rounded),
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
                    errorMaxLines: 3,
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
              decoration: const InputDecoration(
                errorMaxLines: 3,
                labelText: 'Mật khẩu hiện tại',
              ),
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
              decoration: const InputDecoration(
                errorMaxLines: 3,
                labelText: 'Mật khẩu mới',
              ),
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
                errorMaxLines: 3,
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
        Expanded(child: SafeArea(top: false, child: child)),
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
