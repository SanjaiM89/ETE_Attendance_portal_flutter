import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _role;
  bool _isLoading = true;

  bool get isAuthenticated => _isAuthenticated;
  String? get role => _role;
  bool get isLoading => _isLoading;

  AuthProvider() {
    checkAuthStatus();
  }

  Future<void> checkAuthStatus() async {
    final token = await AuthService.getToken();
    final role = await AuthService.getRole();
    if (token != null && role != null) {
      _isAuthenticated = true;
      _role = role;
    } else {
      _isAuthenticated = false;
      _role = null;
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loginTeam(String teamId, String otp) async {
    try {
      await AuthService.loginTeam(teamId, otp);
      await checkAuthStatus();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await AuthService.logout();
    await checkAuthStatus();
  }
}
