import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/firestore_service.dart';

// ============================================================
// LIB: viewmodels/order_viewmodel.dart
// Owner: Member 3 — An
// ============================================================

class OrderViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService;

  OrderViewModel(this._firestoreService);

  Stream<List<OrderModel>> getOrdersStream(String userId) =>
      _firestoreService.getOrdersByUserStream(userId);
}
