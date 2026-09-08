import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/category_model.dart';

class CategoryChipsBar extends StatelessWidget {
  final List<CategoryModel> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onSelectCategory;

  const CategoryChipsBar({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onSelectCategory,
  });

  IconData _getIcon(String iconKey) {
    switch (iconKey.toLowerCase()) {
      case 'carrot':
        return Icons.eco;
      case 'sprout':
        return Icons.grass;
      case 'apple':
        return Icons.apple;
      case 'shopping-bag':
      case 'shoppingbag':
        return Icons.shopping_basket;
      default:
        return Icons.local_florist;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = selectedCategoryId == 'ALL';
            return _buildChip(
              label: 'All Produce',
              icon: Icons.grid_view_rounded,
              isSelected: isSelected,
              onTap: () => onSelectCategory('ALL'),
            );
          }

          final cat = categories[index - 1];
          final isSelected = selectedCategoryId == cat.id;

          return _buildChip(
            label: cat.name,
            icon: _getIcon(cat.icon),
            isSelected: isSelected,
            onTap: () => onSelectCategory(cat.id),
          );
        },
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isSelected ? AppTheme.primary : AppTheme.border,
            width: 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primary.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppTheme.textMuted,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
