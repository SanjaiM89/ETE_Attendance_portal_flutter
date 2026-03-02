import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _role;
  bool _isLoading = true;

  bool _requiresMfa = false;
  bool _mfaIsSetup = false;
  String? _mfaQrCode;
  
  String? _tempEmail;
  String? _tempPassword;

  bool get isAuthenticated => _isAuthenticated;
  String? get role => _role;
  bool get isLoading => _isLoading;
  
  bool get requiresMfa => _requiresMfa;
  bool get mfaIsSetup => _mfaIsSetup;
  String? get mfaQrCode => _mfaQrCode;

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

  Future<void> loginAdmin(String email, String password) async {
    try {
      final response = await AuthService.loginAdmin(email, password);
      
      if (response is Map && response['mfaRequired'] == true) {
        _tempEmail = email;
        _tempPassword = password;
        
        _requiresMfa = true;
        _mfaIsSetup = response['isSetup'] ?? false;
        _mfaQrCode = response['qrCode'];
        notifyListeners();
        return;
      }
      
      await checkAuthStatus();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> verifyMfa(String otp) async {
    if (_tempEmail == null || _tempPassword == null) {
      throw Exception("Authentication session expired. Please log in again.");
    }
    
    try {
      await AuthService.verifyAdminMfa(_tempEmail!, _tempPassword!, otp);
      _requiresMfa = false;
      _mfaIsSetup = false;
      _mfaQrCode = null;
      _tempEmail = null;
      _tempPassword = null;
      await checkAuthStatus();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    _requiresMfa = false;
    _mfaIsSetup = false;
    _mfaQrCode = null;
    _tempEmail = null;
    _tempPassword = null;
    await AuthService.logout();
    await checkAuthStatus();
  }
}
