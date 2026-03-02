import 'dart:convert';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'auth_service.dart';

class ApiService {
  static Future<Map<String, String>> _getHeaders() async {
    final token = await AuthService.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Admin: Get all teams
  static Future<List<dynamic>> getAllTeams() async {
    final response = await http.get(
      Uri.parse('${Constants.baseUrl}/admin/teams'),
      headers: await _getHeaders(),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Failed to load teams');
  }

  // Admin: Create Team
  static Future<Map<String, dynamic>> createTeam(String teamName, List<dynamic> members) async {
    final response = await http.post(
      Uri.parse('${Constants.baseUrl}/admin/create-team'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'teamName': teamName,
        'members': members,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to create team');
  }

  // Admin: Update Attendance
  static Future<void> updateAttendance(String teamId, String round, List<Map<String, dynamic>> memberUpdates) async {
    final response = await http.put(
      Uri.parse('${Constants.baseUrl}/admin/update-attendance/$teamId'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'round': round,
        'members': memberUpdates,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update attendance');
    }
  }

  // Admin: Update Judging
  static Future<void> updateJudging(String teamId, String round, String status) async {
    final response = await http.put(
      Uri.parse('${Constants.baseUrl}/admin/update-judging/$teamId'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'round': round,
        'status': status,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to update judging status');
    }
  }

  // Admin: Edit Team
  static Future<Map<String, dynamic>> editTeam(String teamId, String teamName, List<dynamic> members) async {
    final response = await http.put(
      Uri.parse('${Constants.baseUrl}/admin/edit-team/$teamId'),
      headers: await _getHeaders(),
      body: jsonEncode({
        'teamName': teamName,
        'members': members,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to edit team');
  }

  // Admin: Delete Team
  static Future<void> deleteTeam(String teamId) async {
    final response = await http.delete(
      Uri.parse('${Constants.baseUrl}/admin/delete-team/$teamId'),
      headers: await _getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception(jsonDecode(response.body)['message'] ?? 'Failed to delete team');
    }
  }

}
