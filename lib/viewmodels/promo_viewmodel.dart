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
    await _subscription?.cancel();
    _subscription = null;
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
