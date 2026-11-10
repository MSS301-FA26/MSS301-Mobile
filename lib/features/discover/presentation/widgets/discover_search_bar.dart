import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class DiscoverSearchBar extends StatelessWidget {
  const DiscoverSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => TextField(
        key: const ValueKey('discover-search'),
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        onSubmitted: (_) => FocusScope.of(context).unfocus(),
        style: AppTextStyles.body.copyWith(color: AppColors.text),
        decoration: InputDecoration(
          hintText: 'Tìm phim, diễn viên, đạo diễn…',
          hintStyle: AppTextStyles.body,
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: AppSizes.iconMedium,
            color: AppColors.textMuted,
          ),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  key: const ValueKey('discover-search-clear'),
                  tooltip: 'Xóa tìm kiếm và bộ lọc',
                  onPressed: onClear,
                  icon: const Icon(Icons.close_rounded),
                  color: AppColors.textMuted,
                ),
          constraints: const BoxConstraints(minHeight: AppSizes.inputHeight),
        ),
      ),
    );
  }
}
