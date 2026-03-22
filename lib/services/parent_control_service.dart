import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/parent_control_models.dart';
import 'auth_service.dart';

class ParentControlService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Chưa đăng nhập');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<LinkedStudent>> getLinkedStudents() async {
    final headers = await _headers();
    final url = Uri.parse('${ApiConfig.baseUrl}/parent-controls/students');
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      return [];
    }

    final list = jsonDecode(response.body) as List<dynamic>;
    return list
        .map((e) => LinkedStudent.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<Map<String, dynamic>> linkStudentByEmail(String studentEmail) async {
    final headers = await _headers();
    final url = Uri.parse('${ApiConfig.baseUrl}/parent-controls/link-student');

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'studentEmail': studentEmail.trim()}),
    );

    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': (decoded is Map<String, dynamic>)
            ? (decoded['message'] ?? 'Liên kết thành công').toString()
            : 'Liên kết thành công',
      };
    }

    return {
      'success': false,
      'message': (decoded is Map<String, dynamic>)
          ? (decoded['message'] ?? 'Liên kết thất bại').toString()
          : 'Liên kết thất bại',
    };
  }

  Future<ParentWalletControlSnapshot?> getSnapshot(int studentId) async {
    final headers = await _headers();
    final url = Uri.parse('${ApiConfig.baseUrl}/parent-controls/$studentId');
    final response = await http.get(url, headers: headers);

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body);
    if (data is! Map<String, dynamic>) {
      return null;
    }

    return ParentWalletControlSnapshot.fromJson(data);
  }

  Future<bool> updateControl({
    required int studentId,
    required bool isGuardianWalletEnabled,
    required double? dailySpendingLimit,
    required List<int> blockedItemIds,
  }) async {
    final headers = await _headers();
    final url = Uri.parse('${ApiConfig.baseUrl}/parent-controls/$studentId');

    final response = await http.put(
      url,
      headers: headers,
      body: jsonEncode({
        'isGuardianWalletEnabled': isGuardianWalletEnabled,
        'dailySpendingLimit': dailySpendingLimit,
        'blockedItemIds': blockedItemIds,
      }),
    );

    return response.statusCode == 204;
  }

  Future<bool> topUpForStudent({
    required int studentId,
    required double amount,
  }) async {
    final headers = await _headers();
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/wallet/topup-for-student/$studentId',
    );

    final response = await http.post(
      url,
      headers: headers,
      body: jsonEncode({'amount': amount}),
    );

    return response.statusCode == 200;
  }
}
