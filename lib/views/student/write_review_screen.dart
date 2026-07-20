import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/review_model.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/review_viewmodel.dart';
import '../../widgets/canteen_button.dart';

// ============================================================
// VIEW: views/student/write_review_screen.dart
// Owner: Member 2 — Hài (Tích hợp & mở rộng bởi Member 3 — An)
// Mô tả: Giao diện viết đánh giá món ăn
// ============================================================

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({
    super.key,
    this.foodId,
    this.foodName,
    this.orderId,
  });

  final String? foodId;
  final String? foodName;
  final String? orderId;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  int _rating = 5;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Trích xuất tham số hỗ trợ cả Constructor trực tiếp và Route arguments
    final routeArgs = ModalRoute.of(context)?.settings.arguments;
    String? resolvedFoodId = widget.foodId;
    String? resolvedFoodName = widget.foodName;
    String? resolvedOrderId = widget.orderId;

    if (routeArgs is Map<String, dynamic>) {
      resolvedFoodId ??= routeArgs['foodId'] as String?;
      resolvedFoodName ??= routeArgs['foodName'] as String?;
      resolvedOrderId ??= routeArgs['orderId'] as String?;
    } else if (routeArgs is String) {
      resolvedFoodId ??= routeArgs;
    }

    final reviewVM = context.watch<ReviewViewModel>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Viết đánh giá'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textPrimary,
            size: 20,
          ),
          onPressed: reviewVM.isSubmitting
              ? null
              : () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Bạn thấy món “${resolvedFoodName ?? 'ăn này'}” thế nào?',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Chọn sao
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      size: 40,
                      color: AppColors.star,
                    ),
                    onPressed: reviewVM.isSubmitting
                        ? null
                        : () {
                            setState(() {
                              _rating = index + 1;
                            });
                          },
                  );
                }),
              ),
              const SizedBox(height: 32),

              // Ô nhập bình luận
              TextField(
                controller: _reviewController,
                maxLines: 5,
                enabled: !reviewVM.isSubmitting,
                decoration: InputDecoration(
                  hintText: 'Hãy chia sẻ cảm nhận của bạn về món ăn này nhé...',
                  hintStyle: const TextStyle(color: AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.divider),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Nút gửi
              CanteenButton(
                text: 'Gửi đánh giá',
                isLoading: reviewVM.isSubmitting,
                onPressed: reviewVM.isSubmitting
                    ? null
                    : () async {
                        final auth = context.read<AuthViewModel>();
                        final user = auth.currentUser;

                        if (user == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Vui lòng đăng nhập để đánh giá.'),
                            ),
                          );
                          return;
                        }

                        final review = ReviewModel(
                          id: '', // Tự động tạo ID trên Firestore
                          foodId: resolvedFoodId ?? '',
                          userId: user.uid,
                          userName: user.displayName,
                          orderId: resolvedOrderId ?? '',
                          rating: _rating,
                          comment: _reviewController.text.trim(),
                          createdAt: DateTime.now(),
                        );

                        final success = await reviewVM.submitReview(review);
                        if (!mounted) return;

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Cảm ơn bạn đã đánh giá!'),
                            ),
                          );
                          Navigator.pop(context, true);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                reviewVM.error ?? 'Không thể gửi đánh giá.',
                              ),
                              backgroundColor: AppColors.error,
                            ),
                          );
                        }
                      },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
