import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../services/firestore_service.dart';

// ============================================================
// LIB: viewmodels/review_viewmodel.dart
// Owner: Member 2 — Hài
// ============================================================

class ReviewViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;

  ReviewViewModel(this._firestoreService);

  bool _isSubmitting = false;
  String? _error;

  bool get isSubmitting => _isSubmitting;
  String? get error => _error;

  Stream<List<ReviewModel>> getReviewsStream(String foodId) =>
      _firestoreService.getReviewsByFoodStream(foodId);

  Future<bool> submitReview(ReviewModel review) async {
    _isSubmitting = true;
    _error = null;
    notifyListeners();
    try {
      if (review.orderId.isNotEmpty) {
        final alreadyReviewed = await _firestoreService.hasReviewed(
          review.userId,
          review.foodId,
          orderId: review.orderId,
        );
        if (alreadyReviewed) {
          _error = 'Bạn đã đánh giá món này cho đơn hàng này rồi';
          return false;
        }
      }
      await _firestoreService.addReview(review);
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isSubmitting = false;
      notifyListeners();
    }
  }
}
