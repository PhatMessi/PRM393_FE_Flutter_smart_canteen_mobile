import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import mới
import '../config/api_config.dart';
import '../models/user_model.dart'; // Import Model mới

class AuthService {
  
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
        
        // 1. Parse sang Model (để đảm bảo data đúng chuẩn)
        // Lưu ý: Tùy cấu trúc JSON server trả về mà 'data' hay 'data['user']'
        User user = User.fromJson(data); 

        // 2. Lưu Token vào máy (QUAN TRỌNG)
        if (user.token != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('user_token', user.token!);
        }

        return {'success': true, 'user': user}; // Trả về User object
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
        return {'success': true, 'message': 'Email sent'};
      } else {
        try {
           final body = jsonDecode(response.body);
           return {'success': false, 'message': body['message'] ?? 'Failed'};
        } catch (_) {
           return {'success': false, 'message': response.body};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Connection error: $e'};
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