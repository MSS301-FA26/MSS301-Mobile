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
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 12, color: AppColors.text),
      decoration: InputDecoration(
        hintText: 'Tìm tên phim, diễn viên, đạo diễn Nolan...',
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textDisabled),
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: AppColors.textDisabled,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.cancel, size: 18),
                color: AppColors.textDisabled,
              ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        enabledBorder: const OutlineInputBorder(
          borderRadius: AppRadii.card,
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: AppRadii.card,
          borderSide: BorderSide(color: AppColors.gold),
        ),
      ),
    );
  }
}
