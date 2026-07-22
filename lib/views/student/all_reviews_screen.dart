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
    final sampleReviews = _getDishSpecificReviews(foodName);
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
          ? _buildReviewList(sampleReviews)
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

                // Chỉ hiển thị sample reviews nếu Firestore chưa có review nào VÀ là món mẫu sẵn có
                if (firestoreReviews.isEmpty && sampleReviews.isNotEmpty) {
                  combinedList.addAll(sampleReviews);
                }

                return _buildReviewList(combinedList);
              },
            ),
    );
  }

  /// Tạo đánh giá đặc trưng theo hương vị thực tế của từng món (chua, cay, mặn, ngọt, béo...)
  List<Map<String, dynamic>> _getDishSpecificReviews(String? foodName) {
    final name = (foodName ?? '').toLowerCase();

    if (name.contains('cơm tấm')) {
      return [
        {
          'name': 'Phạm Quang Khánh',
          'avatar': 'K',
          'time': 'Hôm nay',
          'rating': 5,
          'comment': 'Sườn nướng ướp mật ong thơm nức đậm đà vừa vị mặn ngọt, bì thính dai giòn sần sật. Nước mắm tỏi ớt chua ngọt hợp khẩu vị cực kỳ!',
        },
        {
          'name': 'Trần Văn Hài',
          'avatar': 'H',
          'time': 'Hôm qua',
          'rating': 5,
          'comment': 'Chả trứng hấp béo ngậy, cơm tấm hạt dẻo thơm. Dưa mỡ hành kèm dưa góp chua nhẹ giúp chống ngấy rất hiệu quả.',
        },
      ];
    } else if (name.contains('bún bò')) {
      return [
        {
          'name': 'Nguyễn Hoài An',
          'avatar': 'A',
          'time': 'Hôm nay',
          'rating': 5,
          'comment': 'Nước dùng hầm xương đượm vị mắm ruốc sả thơm nức cay nồng chuẩn Huế! Bạn nào thích ăn vị mặn cay đậm đà chắc chắn mê.',
        },
        {
          'name': 'Vũ Đình Quý',
          'avatar': 'Q',
          'time': 'Hôm qua',
          'rating': 5,
          'comment': 'Nạm bò dẻo ngon, chả cua thơm béo ngậy. Thêm chút ớt chưng cay xè với giấm tỏi chua nhẹ là chuẩn bài.',
        },
      ];
    } else if (name.contains('phở')) {
      return [
        {
          'name': 'Lê Minh Hoàng',
          'avatar': 'M',
          'time': 'Hôm nay',
          'rating': 5,
          'comment': 'Nước dùng ninh từ xương bò ngọt thanh trong vắt, thơm lừng mùi hoa hồi thảo quả. Thịt bò tái nạm dẻo ngọt rất vừa miệng.',
        },
        {
          'name': 'Bùi Đức Nam',
          'avatar': 'N',
          'time': 'Hôm qua',
          'rating': 4,
          'comment': 'Phở gà ta xé phay giòn da dẻo thịt, nước dùng trong ngọt thanh đạm không bị mỡ ngấy.',
        },
      ];
    } else if (name.contains('bánh tráng trộn')) {
      return [
        {
          'name': 'Nguyễn Thu Trang',
          'avatar': 'T',
          'time': 'Hôm nay',
          'rating': 5,
          'comment': 'Bánh tráng trộn đủ vị chua cay mặn ngọt: vị chua dịu của tắc, vị cay sa tế nồng nặc, bò khô ngọt mặn bùi béo. Ăn cực kỳ cuốn!',
        },
        {
          'name': 'Hoàng Mỹ Linh',
          'avatar': 'L',
          'time': 'Hôm qua',
          'rating': 5,
          'comment': 'Sốt me tắc thấm đượm bánh tráng, xoài bào sợi chua giòn giòn ăn kèm trứng cút bùi ngậy mê liền.',
        },
      ];
    } else if (name.contains('bò viên')) {
      return [
        {
          'name': 'Đặng Anh Tuấn',
          'avatar': 'T',
          'time': 'Hôm nay',
          'rating': 5,
          'comment': 'Bò viên sa tế tôm cay nồng thơm phức! Bò viên dai giòn sần sật đậm đà mặn ngọt, chấm sa tế cay xè sướng miệng.',
        },
        {
          'name': 'Phạm Quang Khánh',
          'avatar': 'K',
          'time': 'Hôm qua',
          'rating': 5,
          'comment': 'Nước sốt sa tế mặn ngọt đậm đà, viên bò to sần sật ăn siêu đã.',
        },
      ];
    } else if (name.contains('bánh xèo')) {
      return [
        {
          'name': 'Nguyễn Khánh Linh',
          'avatar': 'L',
          'time': 'Hôm nay',
          'rating': 5,
          'comment': 'Vỏ bánh xèo giòn rụm màu nghệ thơm phức, nhân tôm thịt ngọt béo bùi dẻo. Nước mắm tỏi ớt pha chua ngọt cuốn rau sống hết nấc!',
        },
        {
          'name': 'Vũ Đình Quý',
          'avatar': 'Q',
          'time': 'Hôm qua',
          'rating': 5,
          'comment': 'Bánh xèo nóng hổi giòn rụm, giá đỗ mập ngọt mát không bị đắng.',
        },
      ];
    } else if (name.contains('khoai tây')) {
      return [
        {
          'name': 'Trần Văn Hài',
          'avatar': 'H',
          'time': 'Hôm nay',
          'rating': 5,
          'comment': 'Khoai tây chiên vàng giòn rụm lớp vỏ outside, sốt phô mai béo ngậy mặn ngọt dịu ăn bơ tỏi thơm lừng ngất ngây!',
        },
      ];
    } else if (name.contains('trà sữa')) {
      return [
        {
          'name': 'Nguyễn Hoài An',
          'avatar': 'A',
          'time': 'Hôm nay',
          'rating': 5,
          'comment': 'Trà sữa đậm đà vị trà Earl Grey thơm lừng kết hợp trân châu đường đen dẻo quánh ngọt béo vừa phải, không bị ngọt gắt.',
        },
      ];
    } else if (name.contains('cà phê')) {
      return [
        {
          'name': 'Bùi Đức Nam',
          'avatar': 'N',
          'time': 'Hôm nay',
          'rating': 5,
          'comment': 'Đậm đà chuẩn vị cà phê phin Robusta nồng nặc đắng nhẹ, hòa quyện với sữa đặc ngọt béo ngậy ngắt đá mát lạnh.',
        },
      ];
    } else if (name.contains('nước mía')) {
      return [
        {
          'name': 'Hoàng Mỹ Linh',
          'avatar': 'L',
          'time': 'Hôm nay',
          'rating': 5,
          'comment': 'Nước mía vắt tắc thơm nức mũi! Vị ngọt tự nhiên thanh mát cộng thêm vị chua nhẹ của tắc giải nhiệt mùa hè siêu đỉnh.',
        },
      ];
    } else if (name.contains('flan')) {
      return [
        {
          'name': 'Nguyễn Thu Trang',
          'avatar': 'T',
          'time': 'Hôm nay',
          'rating': 5,
          'comment': 'Bánh flan caramen mềm mịn như lụa tan ngay trong miệng, vị ngọt béo ngậy của trứng sữa kết hợp lớp đắng nhẹ thơm bùi caramen dừa.',
        },
      ];
    } else if (name.contains('chè bưởi')) {
      return [
        {
          'name': 'Nguyễn Khánh Linh',
          'avatar': 'L',
          'time': 'Hôm nay',
          'rating': 5,
          'comment': 'Cùi bưởi giòn sần sật không hề bị đắng, đỗ xanh đồ sánh mịn bùi bùi hòa quyện nước cốt dừa béo ngậy béo thơm thanh mát.',
        },
      ];
    }

    // Mặc định cho các món khác
    return [
      {
        'name': 'Phạm Quang Khánh',
        'avatar': 'K',
        'time': 'Hôm nay',
        'rating': 5,
        'comment': 'Món ăn nêm nếm rất vừa vị, đậm đà tươi ngon. Hương vị chua mặn ngọt hài hòa phù hợp với khẩu vị sinh viên!',
      },
      {
        'name': 'Trần Văn Hài',
        'avatar': 'H',
        'time': 'Hôm qua',
        'rating': 5,
        'comment': 'Đồ ăn nóng hổi thơm nức, giao hàng nhanh đúng hẹn khung giờ đặt trước.',
      },
    ];
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
