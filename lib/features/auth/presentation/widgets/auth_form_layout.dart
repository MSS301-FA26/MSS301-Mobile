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
  });

  final String title;
  final String description;
  final VoidCallback onBack;
  final Widget form;
  final Widget submitButton;
  final String? message;
  final List<Widget> secondaryActions;

  @override
  Widget build(BuildContext context) {
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
                    if (message != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Semantics(
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
                                style: AppTextStyles.body.copyWith(
                                  color: AppColors.gold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
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
