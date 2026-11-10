import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../movie/data/models/food_quote_dto.dart';

enum FoodCatalogGroup { all, combos, items }

List<FoodProductDto> foodProductsInGroup(
  List<FoodProductDto> products,
  FoodCatalogGroup group,
) => products
    .where(
      (product) => switch (group) {
        FoodCatalogGroup.all => true,
        FoodCatalogGroup.combos => product.isCombo,
        FoodCatalogGroup.items => !product.isCombo,
      },
    )
    .toList(growable: false);

class FoodCatalogGroups extends StatelessWidget {
  const FoodCatalogGroups({
    super.key,
    required this.products,
    required this.selected,
    required this.onSelected,
  });
  final List<FoodProductDto> products;
  final FoodCatalogGroup selected;
  final ValueChanged<FoodCatalogGroup>? onSelected;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      children: [
        for (final group in FoodCatalogGroup.values)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Semantics(
              selected: group == selected,
              child: OutlinedButton(
                key: ValueKey('food-group-${group.name}'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  foregroundColor: selected == group
                      ? Colors.black
                      : AppColors.text,
                  backgroundColor: selected == group
                      ? AppColors.gold
                      : AppColors.surface,
                  side: BorderSide(
                    color: selected == group
                        ? AppColors.gold
                        : AppColors.border,
                  ),
                ),
                onPressed: onSelected == null ? null : () => onSelected!(group),
                child: Text(
                  '${switch (group) {
                    FoodCatalogGroup.all => 'Tất cả',
                    FoodCatalogGroup.combos => 'Combo',
                    FoodCatalogGroup.items => 'Sản phẩm',
                  }} (${foodProductsInGroup(products, group).length})',
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
