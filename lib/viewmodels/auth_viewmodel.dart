import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';

// ============================================================
// LIB: viewmodels/auth_viewmodel.dart
// Owner: Member 1 — Khánh
// ============================================================

enum AuthStatus { initial, loading, authenticated, unauthenticated, error }

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService;
  final NotificationService _notificationService;

  AuthViewModel(this._authService, this._notificationService);

  AuthStatus _status = AuthStatus.initial;
  UserModel? _currentUser;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get isLoading => _status == AuthStatus.loading;

  Future<void> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading();
    try {
      _currentUser = await _authService.register(
        email: email,
        password: password,
        displayName: displayName,
      );
      await _notificationService.initialize(_currentUser!.uid);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _setError(e.toString());
    }
    notifyListeners();
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    _setLoading();
    try {
      _currentUser = await _authService.login(email: email, password: password);
      await _notificationService.initialize(_currentUser!.uid);
      _status = AuthStatus.authenticated;
    } catch (e) {
      _setError(e.toString());
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> resetPassword(String email) async {
    _setLoading();
    try {
      await _authService.resetPassword(email);
      _status = AuthStatus.unauthenticated;
    } catch (e) {
      _setError(e.toString());
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading() {
    _status = AuthStatus.loading;
    _errorMessage = null;
  }

  void _setError(String message) {
    _status = AuthStatus.error;
    _errorMessage = message;
  }
}
