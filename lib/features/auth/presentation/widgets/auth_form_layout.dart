import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

enum AuthLayoutTab { login, register }

/// Native, scrollable presentation for the existing authentication stages.
class AuthFormLayout extends StatelessWidget {
  const AuthFormLayout({
    super.key,
    required this.title,
    required this.description,
    required this.onBack,
    required this.form,
    required this.submitButton,
    this.message,
    this.secondaryActions = const [],
    this.activeTab,
    this.onLoginTabPressed,
    this.onRegisterTabPressed,
    this.isRegisterEntry = false,
    this.isEmailVerification = false,
  });

  final String title;
  final String description;
  final VoidCallback onBack;
  final Widget form;
  final Widget submitButton;
  final String? message;
  final List<Widget> secondaryActions;
  final AuthLayoutTab? activeTab;
  final VoidCallback? onLoginTabPressed;
  final VoidCallback? onRegisterTabPressed;
  final bool isRegisterEntry;
  final bool isEmailVerification;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      if (activeTab != null)
        _AuthTabs(
          selectedTab: activeTab!,
          onLoginPressed: onLoginTabPressed,
          onRegisterPressed: onRegisterTabPressed,
        )
      else
        const _RecoveryHeader(),
      const SizedBox(height: AppSpacing.xl),
      if (!isRegisterEntry && !isEmailVerification) ...[
        if (activeTab != AuthLayoutTab.login) ...[
          Semantics(
            header: true,
            child: Text(title, style: AppTextStyles.displayTitle),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(description, style: AppTextStyles.body),
        const SizedBox(height: AppSpacing.xl),
      ],
      Container(key: const ValueKey('auth-form-panel'), child: form),
      _Message(message: message),
      const SizedBox(height: AppSpacing.xl),
      submitButton,
      if (activeTab == AuthLayoutTab.login) ...[
        const SizedBox(height: AppSpacing.xl),
        const _OrDivider(),
        const SizedBox(height: AppSpacing.lg),
        const _UnavailableGoogleButton(),
      ],
      if (secondaryActions.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.md),
        ...secondaryActions,
      ],
    ];
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageGutter,
            vertical: AppSpacing.md,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - AppSpacing.md * 2).clamp(
                0.0,
                double.infinity,
              ),
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Container(
                  key: const ValueKey('auth-panel'),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: AppColors.borderStrong),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        key: const ValueKey('auth-brand-header'),
                        constraints: const BoxConstraints(minHeight: 64),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: const BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: AppColors.border),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: _BrandHeader(onBack: onBack),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.lg,
                          AppSpacing.md,
                          AppSpacing.xl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: children,
                        ),
                      ),
                      Container(
                        key: const ValueKey('auth-trust-footer'),
                        constraints: const BoxConstraints(minHeight: 56),
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: const BoxDecoration(
                          color: AppColors.background,
                          border: Border(
                            top: BorderSide(color: AppColors.border),
                          ),
                        ),
                        alignment: Alignment.centerLeft,
                        child: const SizedBox(
                          width: double.infinity,
                          child: _TrustRow(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RecoveryHeader extends StatelessWidget {
  const _RecoveryHeader();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.md),
    decoration: BoxDecoration(
      color: AppColors.surfaceHigh,
      border: Border.all(color: AppColors.borderStrong),
    ),
    child: Row(
      children: [
        const Icon(Icons.lock_reset_rounded, color: AppColors.gold),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            'KHÔI PHỤC MẬT KHẨU',
            style: AppTextStyles.eyebrow.copyWith(color: AppColors.gold),
          ),
        ),
      ],
    ),
  );
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
        ),
        child: const Text(
          'C',
          textScaler: TextScaler.noScaling,
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      const SizedBox(width: AppSpacing.sm),
      const Expanded(
        child: Text(
          'CINEPREMIER',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
          ),
        ),
      ),
      IconButton(
        tooltip: 'Quay lại',
        constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textMuted),
      ),
    ],
  );
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({
    required this.selectedTab,
    this.onLoginPressed,
    this.onRegisterPressed,
  });

  final AuthLayoutTab selectedTab;
  final VoidCallback? onLoginPressed;
  final VoidCallback? onRegisterPressed;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppColors.surface,
      border: Border.all(color: AppColors.border),
    ),
    // Match both tab heights when larger text wraps one of the labels.
    child: IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _AuthTab(
            key: const ValueKey('auth-login-tab'),
            label: 'ĐĂNG NHẬP',
            selected: selectedTab == AuthLayoutTab.login,
            onPressed: onLoginPressed,
          ),
          _AuthTab(
            key: const ValueKey('auth-register-tab'),
            label: 'ĐĂNG KÝ',
            selected: selectedTab == AuthLayoutTab.register,
            onPressed: onRegisterPressed,
          ),
        ],
      ),
    ),
  );
}

class _AuthTab extends StatelessWidget {
  const _AuthTab({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Semantics(
      button: true,
      selected: selected,
      label: '$label${selected ? ', đang được chọn' : ''}',
      child: InkWell(
        onTap: onPressed,
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.sm,
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? AppColors.gold : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.label.copyWith(
              fontSize: 14,
              color: selected ? AppColors.text : AppColors.textMuted,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ),
    ),
  );
}

class _Message extends StatelessWidget {
  const _Message({this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Semantics(
        liveRegion: true,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColors.gold,
              size: AppSizes.iconMedium,
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                message!,
                key: const ValueKey('auth-message'),
                style: AppTextStyles.body.copyWith(color: AppColors.gold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(child: Divider(color: AppColors.border)),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Text(
          'HOẶC',
          style: AppTextStyles.meta.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      const Expanded(child: Divider(color: AppColors.border)),
    ],
  );
}

class _UnavailableGoogleButton extends StatelessWidget {
  const _UnavailableGoogleButton();

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Đăng nhập bằng Google hiện chưa khả dụng',
    enabled: false,
    child: SizedBox(
      width: double.infinity,
      height: AppSizes.buttonHeight,
      child: OutlinedButton(
        key: const ValueKey('auth-google-unavailable'),
        onPressed: null,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.borderStrong),
          shape: const RoundedRectangleBorder(borderRadius: AppRadii.small),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('G', style: TextStyle(fontWeight: FontWeight.w800)),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'ĐĂNG NHẬP BẰNG GOOGLE',
                style: AppTextStyles.label.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    crossAxisAlignment: WrapCrossAlignment.center,
    runSpacing: AppSpacing.xs,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shield_outlined,
            size: AppSizes.iconSmall,
            color: AppColors.gold,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text('AN TOÀN', style: AppTextStyles.meta),
        ],
      ),
      Text('CINEPREMIER CLUB', style: AppTextStyles.meta),
    ],
  );
}
