import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import mới
import '../config/api_config.dart';
import '../models/user_model.dart'; // Import Model mới

class AuthService {
  Future<User?> getProfile(String token) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.getUserProfile);

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      return null;
    }

    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) {
      return User(
        fullName:
            (data['fullName'] ?? data['FullName'] ?? '').toString().isEmpty
            ? 'Nguoi dung'
            : (data['fullName'] ?? data['FullName']).toString(),
        email: (data['email'] ?? data['Email'] ?? '').toString(),
        role: (data['role'] ?? data['Role'] ?? 'Student').toString(),
        token: token,
      );
    }

    return null;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.login);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final token = (data is Map<String, dynamic>)
            ? data['token']?.toString()
            : null;
        final mustChangePassword = (data is Map<String, dynamic>)
            ? (data['mustChangePassword'] == true)
            : false;

        if (token == null || token.isEmpty) {
          return {'success': false, 'message': 'Phan hoi dang nhap thieu token'};
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_token', token);

        if (mustChangePassword) {
          return {
            'success': false,
            'message': 'Bạn cần đổi mật khẩu trước khi sử dụng hệ thống.',
          };
        }

        final profile = await getProfile(token);
        final user =
            profile ??
            User(fullName: 'Nguoi dung', email: email, role: 'Student', token: token);

        return {'success': true, 'user': user};
      } else {
        final errorData = jsonDecode(response.body);
        return {'success': false, 'message': errorData['message']};
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  // --- HÀM MỚI: QUÊN MẬT KHẨU ---
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    // Ghép URL chuẩn từ Config
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.forgotPassword);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200) {
        return {'success': true, 'message': 'Da gui email'};
      } else {
        try {
          final body = jsonDecode(response.body);
          return {'success': false, 'message': body['message'] ?? 'That bai'};
        } catch (_) {
          return {'success': false, 'message': response.body};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Loi ket noi: $e'};
    }
  }

  // Hàm đăng xuất (Xóa token)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_token');
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_token');
  }
}
