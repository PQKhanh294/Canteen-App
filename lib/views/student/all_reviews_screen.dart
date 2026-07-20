import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

// ============================================================
// VIEW: views/student/all_reviews_screen.dart
// Owner: Member 2 — Hài
// ============================================================

class AllReviewsScreen extends StatelessWidget {
  const AllReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Tất cả đánh giá'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: 10,
        separatorBuilder: (context, index) => const Divider(height: 32),
        itemBuilder: (context, index) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar giả
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  'S${index + 1}',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              
              // Nội dung đánh giá
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sinh viên ${index + 1}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const Text(
                          'Hôm nay',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (starIndex) => Icon(
                          starIndex < 5 - (index % 2) ? Icons.star : Icons.star_border,
                          size: 14,
                          color: AppColors.star,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Món ăn rất ngon, nóng hổi. Giá cả hợp lý. Giao hàng nhanh. Sẽ ủng hộ lần sau!',
                      style: TextStyle(color: AppColors.textSecondary, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
