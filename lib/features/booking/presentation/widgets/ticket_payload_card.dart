import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/app_section_header.dart';
import '../../../../shared/widgets/app_surface.dart';

/// Shows the supplied payload as text; it does not generate a scannable QR.
class TicketPayloadCard extends StatelessWidget {
  const TicketPayloadCard({super.key, required this.payload});

  final String payload;

  @override
  Widget build(BuildContext context) => AppSurface(
    borderColor: AppColors.goldBorder,
    child: Semantics(
      container: true,
      label: 'Dữ liệu mã vé / QR từ hệ thống',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppSectionHeader(title: 'Dữ liệu vé / QR'),
          const SizedBox(height: AppSpacing.md),
          SelectableText(
            payload,
            key: const ValueKey('ticket-payload'),
            style: AppTextStyles.body.copyWith(
              fontFamily: 'monospace',
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Payload nguyên bản từ hệ thống, không phải ảnh QR để quét.',
            style: AppTextStyles.caption,
          ),
        ],
      ),
    ),
  );
}
