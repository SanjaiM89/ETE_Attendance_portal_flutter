import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';

class AuthService {
  static Future<dynamic> loginAdmin(String email, String password) async {
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/admin/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      // If MFA is required, return the necessary MFA setup/verification data
      if (data['mfaRequired'] == true) {
        return data; 
      }

      // Normal login (fallback, shouldn't happen with our updated backend but good for safety)
      final token = data['token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('role', 'admin');
        return token;
      }
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Login failed');
  }

  static Future<String?> verifyAdminMfa(String email, String password, String otp) async {
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/admin/verify-mfa'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'otp': otp,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final token = data['token'];
      if (token != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', token);
        await prefs.setString('role', 'admin');
        return token;
      }
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'MFA Verification failed');
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('role');
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('role');
  }
}
