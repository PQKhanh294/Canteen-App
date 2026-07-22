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
    final List<Map<String, dynamic>> realReviews = [
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
      {
        'name': 'Lê Minh Hoàng',
        'avatar': 'M',
        'time': '2 ngày trước',
        'rating': 4,
        'comment': 'Phục vụ chu đáo, đóng gói sạch sẽ cẩn thận. Món ăn lúc nhận vẫn còn nóng hổi.',
      },
      {
        'name': 'Nguyễn Thu Trang',
        'avatar': 'T',
        'time': '2 ngày trước',
        'rating': 5,
        'comment': 'Bánh flan caramen béo mịn thơm phức vị trứng dừa, ăn tráng miệng giải nhiệt tuyệt vời.',
      },
      {
        'name': 'Đặng Anh Tuấn',
        'avatar': 'T',
        'time': '3 ngày trước',
        'rating': 5,
        'comment': 'Khoai tây chiên sốt phô mai giòn rụm béo ngậy, các bạn căn tin thân thiện nhiệt tình.',
      },
      {
        'name': 'Hoàng Mỹ Linh',
        'avatar': 'L',
        'time': '3 ngày trước',
        'rating': 4,
        'comment': 'Mì Quảng tôm thịt chuẩn vị miền Trung, nước dùng thanh ngọt đậm đà vừa miệng.',
      },
      {
        'name': 'Bùi Đức Nam',
        'avatar': 'N',
        'time': '4 ngày trước',
        'rating': 5,
        'comment': 'Cơm gà xối mỡ da giòn rụm thơm lừng, phần ăn đùi góc tư siêu bự ngon chất lượng.',
      },
      {
        'name': 'Nguyễn Khánh Linh',
        'avatar': 'L',
        'time': '5 ngày trước',
        'rating': 5,
        'comment': 'Nước mía vắt tắc mát lạnh sảng khoái sau giờ học căng thẳng. Cực kỳ ủng hộ canteen!',
      },
    ];

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
        itemCount: realReviews.length,
        separatorBuilder: (context, index) => const Divider(height: 32),
        itemBuilder: (context, index) {
          final review = realReviews[index];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primaryLight,
                child: Text(
                  review['avatar'] as String,
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
                          review['name'] as String,
                          style: const TextStyle(fontWeight: FontWeight.bold),
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
                          starIndex < (review['rating'] as int) ? Icons.star : Icons.star_border,
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
      ),
    );
  }
}
