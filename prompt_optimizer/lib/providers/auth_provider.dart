import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  AuthStatus status = AuthStatus.unknown;
  UserModel? user;
  bool isLoading = false;
  String? error;

  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();

  /// Checks stored token and user on app startup.
  Future<void> checkAuthStatus() async {
    final token = await _storageService.getToken();
    final savedUser = await _storageService.getUser();

    if (token != null && savedUser != null) {
      user = savedUser;
      status = AuthStatus.authenticated;
    } else {
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Orchestrates the full Google Sign-In flow.
  Future<void> signInWithGoogle() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      final idToken = await _authService.signInWithGoogle();
      if (idToken == null) {
        // User cancelled — silent
        isLoading = false;
        notifyListeners();
        return;
      }

      final result = await _authService.sendTokenToBackend(idToken);
      final token = result['token']?.toString() ?? '';
      final userData = result['user'] as Map<String, dynamic>? ?? {};
      final userModel = UserModel.fromJson(userData);

      await _storageService.saveToken(token);
      await _storageService.saveUser(userModel);

      user = userModel;
      status = AuthStatus.authenticated;
      error = null;
    } catch (e) {
      error = e.toString().replaceFirst('Exception: ', '');
      status = AuthStatus.unauthenticated;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    isLoading = true;
    notifyListeners();

    try {
      await _authService.signOut();
    } catch (_) {}

    await _storageService.clearAll();
    user = null;
    status = AuthStatus.unauthenticated;
    error = null;
    isLoading = false;
    notifyListeners();
  }
}
