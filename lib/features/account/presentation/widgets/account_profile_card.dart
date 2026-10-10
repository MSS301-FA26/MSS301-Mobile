import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_surface.dart';
import '../models/account_summary.dart';

class AccountProfileCard extends StatelessWidget {
  const AccountProfileCard({super.key, required this.user});

  final AccountSummary user;

  @override
  Widget build(BuildContext context) => AppSurface(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(14) / 14;
        final vertical = constraints.maxWidth < 360 * textScale;
        final identity = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(
              header: true,
              child: Text(user.name, style: AppTextStyles.sectionTitle),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(user.email, style: AppTextStyles.body),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Thành viên CinePremier từ ${user.joinYear}',
              style: AppTextStyles.caption,
            ),
          ],
        );
        final avatar = ExcludeSemantics(
          child: Container(
            width: AppSpacing.headerHeight * textScale,
            height: AppSpacing.headerHeight * textScale,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.goldSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.goldBorder),
            ),
            child: Text(
              user.initials,
              style: AppTextStyles.displayTitle.copyWith(color: AppColors.gold),
            ),
          ),
        );
        return vertical
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatar,
                  const SizedBox(height: AppSpacing.md),
                  identity,
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  avatar,
                  const SizedBox(width: AppSpacing.md),
                  Expanded(child: identity),
                ],
              );
      },
    ),
  );
}
