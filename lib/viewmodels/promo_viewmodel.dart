import 'dart:async';
import 'package:flutter/material.dart';
import '../models/promo_model.dart';
import '../services/firestore_service.dart';

// ============================================================
// VIEWMODEL: PromoViewModel
// Owner: Member 3 — An
// Mô tả: Quản lý danh sách Voucher hoạt động và tìm kiếm voucher theo code
// ============================================================

class PromoViewModel extends ChangeNotifier {
  PromoViewModel({required FirestoreService firestoreService})
    : _firestoreService = firestoreService;

  final FirestoreService _firestoreService;

  List<PromoModel> _promos = <PromoModel>[];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<PromoModel>>? _subscription;

  List<PromoModel> get promos => List<PromoModel>.unmodifiable(_promos);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void listenPromos() {
    if (_subscription != null) {
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    _subscription = _firestoreService.getActivePromos().listen(
      (promosList) {
        _promos = promosList;
        _isLoading = false;
        _errorMessage = null;
        debugPrint('Realtime promos loaded: ${promosList.length}');
        notifyListeners();
      },
      onError: (Object error, StackTrace stackTrace) {
        debugPrint('Could not load promos: $error\n$stackTrace');
        _isLoading = false;
        _errorMessage = 'Không thể tải mã giảm giá.';
        notifyListeners();
      },
    );
  }

  Future<void> reloadPromos() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final promosList = await _firestoreService.getActivePromosOnce();
      _promos = promosList;
      _errorMessage = null;
      debugPrint('Promos refreshed from Firestore: ${promosList.length}');
    } catch (error, stackTrace) {
      debugPrint('Could not refresh promos: $error\n$stackTrace');
      if (_promos.isEmpty) {
        _errorMessage = 'Không thể tải mã giảm giá.';
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }

    // Không hủy/đăng ký lại listener mỗi lần mở VoucherScreen vì có thể tạo
    // một trạng thái danh sách rỗng tạm thời trong lúc chuyển subscription.
    listenPromos();
  }

  Future<PromoModel?> findPromoByCode(String code) async {
    try {
      _errorMessage = null;
      return await _firestoreService.getPromoByCode(code);
    } catch (error, stackTrace) {
      debugPrint('Could not find promo: $error\n$stackTrace');
      _errorMessage = 'Không thể kiểm tra mã giảm giá.';
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
