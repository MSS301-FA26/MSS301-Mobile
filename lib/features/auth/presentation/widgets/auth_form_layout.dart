import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_surface.dart';

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
    this.useLoginMapping = false,
    this.onLoginTabPressed,
    this.onRegisterTabPressed,
  });

  final String title;
  final String description;
  final VoidCallback onBack;
  final Widget form;
  final Widget submitButton;
  final String? message;
  final List<Widget> secondaryActions;
  final bool useLoginMapping;
  final VoidCallback? onLoginTabPressed;
  final VoidCallback? onRegisterTabPressed;

  @override
  Widget build(BuildContext context) {
    if (!useLoginMapping) return _buildStandardLayout(context);

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.pageGutter,
              vertical: AppSpacing.md,
            ),
            children: [
              _BrandHeader(onBack: onBack),
              const SizedBox(height: AppSpacing.xl),
              _AuthTabs(
                onLoginPressed: onLoginTabPressed,
                onRegisterPressed: onRegisterTabPressed,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(description, style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.xl),
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    key: const ValueKey('auth-form-panel'),
                    child: form,
                  ),
                  _Message(message: message),
                  const SizedBox(height: AppSpacing.xl),
                  submitButton,
                ],
              ),
              const SizedBox(height: AppSpacing.xl),
              const _OrDivider(),
              const SizedBox(height: AppSpacing.lg),
              const _UnavailableGoogleButton(),
              if (secondaryActions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                ...secondaryActions,
              ],
              const SizedBox(height: AppSpacing.xxl),
              const _TrustRow(),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStandardLayout(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(AppSpacing.pageGutter),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  tooltip: 'Quay lại',
                  constraints: const BoxConstraints(
                    minWidth: 48,
                    minHeight: 48,
                  ),
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Semantics(
                header: true,
                child: Text(title, style: AppTextStyles.displayTitle),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(description, style: AppTextStyles.body),
              const SizedBox(height: AppSpacing.xl),
              AppSurface(
                key: const ValueKey('auth-form-panel'),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    form,
                    _Message(message: message),
                    const SizedBox(height: AppSpacing.xl),
                    submitButton,
                  ],
                ),
              ),
              if (secondaryActions.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                ...secondaryActions,
              ],
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
        ),
        child: const Text(
          'C',
          style: TextStyle(
            color: AppColors.gold,
            fontSize: 20,
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
  const _AuthTabs({this.onLoginPressed, this.onRegisterPressed});

  final VoidCallback? onLoginPressed;
  final VoidCallback? onRegisterPressed;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(border: Border.all(color: AppColors.border)),
    child: Row(
      children: [
        _AuthTab(
          key: const ValueKey('auth-login-tab'),
          label: 'ĐĂNG NHẬP',
          selected: true,
          onPressed: onLoginPressed,
        ),
        _AuthTab(
          key: const ValueKey('auth-register-tab'),
          label: 'ĐĂNG KÝ',
          selected: false,
          onPressed: onRegisterPressed,
        ),
      ],
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
          height: 52,
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
            style: AppTextStyles.label.copyWith(
              color: selected ? AppColors.text : AppColors.textMuted,
              fontWeight: FontWeight.w800,
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
