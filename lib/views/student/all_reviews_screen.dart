import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/review_model.dart';
import '../../viewmodels/review_viewmodel.dart';
import '../../widgets/shimmer_loading.dart';

// ============================================================
// VIEW: views/student/all_reviews_screen.dart
// Owner: Member 2 — Hài
// ============================================================

class AllReviewsScreen extends StatelessWidget {
  const AllReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    String? foodId;
    String? foodName;

    if (routeArgs is Map<String, dynamic>) {
      foodId = routeArgs['foodId'] as String?;
      foodName = routeArgs['foodName'] as String?;
    } else if (routeArgs is String) {
      foodId = routeArgs;
    }

    final reviewVM = context.watch<ReviewViewModel>();

    // Dữ liệu đánh giá mẫu mặc định
    final List<Map<String, dynamic>> defaultSampleReviews = [
      {
        'name': 'Phạm Quang Khánh',
        'avatar': 'K',
        'time': 'Hôm nay',
        'rating': 5,
        'comment': 'Cơm tấm sườn nướng siêu thơm ngon, sườn mỏng vừa ăn mà đậm đà mật ong. Nước mắm pha rất vừa vị. Rất đáng 5 sao!',
      },
      {
        'name': 'Trần Văn Hài',
        'avatar': 'H',
        'time': 'Hôm nay',
        'rating': 5,
        'comment': 'Đồ ăn giao nhanh nóng hổi, hẹn giờ lấy đồ chuẩn đét không phải xếp hàng chờ đợi lâu chút nào.',
      },
      {
        'name': 'Nguyễn Hoài An',
        'avatar': 'A',
        'time': 'Hôm qua',
        'rating': 5,
        'comment': 'Bún bò Huế nước dùng đậm đà sả ớt, thịt nạm dẻo mềm. Quá tuyệt vời cho bữa trưa tại căn tin.',
      },
      {
        'name': 'Vũ Đình Quý',
        'avatar': 'Q',
        'time': 'Hôm qua',
        'rating': 5,
        'comment': 'Trà sữa trân châu đường đen vừa vị không quá ngọt, trân châu dẻo thơm béo ngậy. Sẽ đặt lại tiếp!',
      },
    ];

    final dateFormatter = DateFormat('dd/MM/yyyy HH:mm');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(foodName != null ? 'Đánh giá: $foodName' : 'Tất cả đánh giá'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
      ),
      body: foodId == null || foodId.isEmpty
          ? _buildReviewList(defaultSampleReviews)
          : StreamBuilder<List<ReviewModel>>(
              stream: reviewVM.getReviewsStream(foodId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: ShimmerLoading(width: double.infinity, height: 100),
                  );
                }

                final firestoreReviews = snapshot.data ?? [];

                // Nếu có reviews thực từ Firestore
                if (firestoreReviews.isNotEmpty) {
                  final combinedList = <Map<String, dynamic>>[];

                  for (final r in firestoreReviews) {
                    final userName = (r.userName != null && r.userName!.trim().isNotEmpty)
                        ? r.userName!
                        : 'Sinh viên';
                    final avatarLetter = userName.isNotEmpty
                        ? userName.trim()[0].toUpperCase()
                        : 'U';
                    combinedList.add({
                      'name': userName,
                      'avatar': avatarLetter,
                      'time': dateFormatter.format(r.createdAt),
                      'rating': r.rating,
                      'comment': r.comment,
                      'isUserReview': true,
                    });
                  }

                  // Kèm thêm reviews mẫu
                  combinedList.addAll(defaultSampleReviews);

                  return _buildReviewList(combinedList);
                }

                // Nếu chưa có review trên Firestore, hiển thị mẫu
                return _buildReviewList(defaultSampleReviews);
              },
            ),
    );
  }

  Widget _buildReviewList(List<Map<String, dynamic>> reviews) {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: reviews.length,
      separatorBuilder: (context, index) => const Divider(height: 32),
      itemBuilder: (context, index) {
        final review = reviews[index];
        final isUserReview = review['isUserReview'] == true;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            CircleAvatar(
              radius: 20,
              backgroundColor: isUserReview ? AppColors.primary : AppColors.primaryLight,
              child: Text(
                review['avatar'] as String,
                style: TextStyle(
                  color: isUserReview ? Colors.white : AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
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
                      Row(
                        children: [
                          Text(
                            review['name'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isUserReview ? AppColors.primary : AppColors.textPrimary,
                            ),
                          ),
                          if (isUserReview) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Bạn',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        review['time'] as String,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      5,
                      (starIndex) => Icon(
                        starIndex < (review['rating'] as int)
                            ? Icons.star
                            : Icons.star_border,
                        size: 14,
                        color: AppColors.star,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    review['comment'] as String,
                    style: const TextStyle(color: AppColors.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
