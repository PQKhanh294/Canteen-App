import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_colors.dart';
import '../viewmodels/menu_viewmodel.dart';
import 'canteen_button.dart';

// ============================================================
// WIDGET: FilterBottomSheet
// Owner: Member 2 — Hài
// ============================================================

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String _selectedSort = 'Mới nhất';
  String _selectedPriceRange = 'Tất cả';
  bool _availableOnly = false;

  final List<String> _sortOptions = ['Mới nhất', 'Giá tăng dần', 'Giá giảm dần', 'Đánh giá cao'];
  final List<String> _priceRanges = ['Tất cả', 'Dưới 20k', '20k - 50k', 'Trên 50k'];

  @override
  void initState() {
    super.initState();
    final menuVM = context.read<MenuViewModel>();
    _selectedSort = menuVM.selectedSort;
    _selectedPriceRange = menuVM.selectedPriceRange;
    _availableOnly = menuVM.availableOnly;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Bộ Lọc Tìm Kiếm',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Sắp xếp theo
            const Text(
              'Sắp xếp theo',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _sortOptions.map((option) {
                final isSelected = _selectedSort == option;
                return ChoiceChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedSort = option);
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                  backgroundColor: AppColors.surface,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // Khoảng giá
            const Text(
              'Khoảng giá',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _priceRanges.map((range) {
                final isSelected = _selectedPriceRange == range;
                return ChoiceChip(
                  label: Text(range),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() => _selectedPriceRange = range);
                  },
                  selectedColor: AppColors.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.textPrimary,
                  ),
                  backgroundColor: AppColors.surface,
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            
            // Trạng thái
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Chỉ hiển thị món còn hàng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Switch(
                  value: _availableOnly,
                  activeColor: AppColors.primary,
                  onChanged: (value) {
                    setState(() => _availableOnly = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),
            
            // Nút áp dụng
            Row(
              children: [
                 Expanded(
                  child: CanteenButton(
                    text: 'Thiết Lập Lại',
                    backgroundColor: AppColors.surfaceVariant,
                    textColor: AppColors.textPrimary,
                    onPressed: () {
                      context.read<MenuViewModel>().resetFilters();
                      setState(() {
                        _selectedSort = 'Mới nhất';
                        _selectedPriceRange = 'Tất cả';
                        _availableOnly = false;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: CanteenButton(
                    text: 'Áp Dụng',
                    onPressed: () {
                      context.read<MenuViewModel>().applyFilters(
                            sort: _selectedSort,
                            priceRange: _selectedPriceRange,
                            availableOnly: _availableOnly,
                          );
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
