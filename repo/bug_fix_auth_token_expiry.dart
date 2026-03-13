/**
 * BUG FIX: Xử lý token hết hạn và quản lý phiên đăng nhập
 * 
 * Vấn đề: Khi token hết hạn, app không tự động xử lý mà để user stuck
 *         Không có cơ chế retry hoặc refresh token
 * 
 * Fix: Thêm kiểm tra token expiration và debug logging
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthServiceFixed {
  static const String _tokenKey = 'user_token';
  static const String _tokenExpireKey = 'token_expire_time';

  // FIX: Thêm hàm kiểm tra token có hợp lệ không
  Future<bool> isTokenValid() async {
    final prefs = await SharedPreferences.getInstance();
    final expireTime = prefs.getString(_tokenExpireKey);
    
    if (expireTime == null) {
      // Nếu không có thời gian hết hạn, coi như token vẫn đang tốt
      return true;
    }

    try {
      final expireDateTime = DateTime.parse(expireTime);
      return DateTime.now().isBefore(expireDateTime);
    } catch (e) {
      print('[AUTH DEBUG] Error parsing token expiration: $e');
      return false;
    }
  }

  // FIX: Lấy token với kiểm tra hợp lệ
  Future<String?> getToken() async {
    final isValid = await isTokenValid();
    if (!isValid) {
      print('[AUTH DEBUG] Token expired, clearing session');
      await clearToken();
      return null;
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // FIX: Xóa token an toàn
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_tokenExpireKey);
  }

  Future<User?> getProfile(String token) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.getUserProfile);

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
      );

      // FIX: Xử lý 401 Unauthorized (token hết hạn)
      if (response.statusCode == 401) {
        print('[AUTH DEBUG] Token unauthorized (401), clearing session');
        await clearToken();
        return null;
      }

      if (response.statusCode != 200) {
        print('[AUTH DEBUG] Failed to get profile: ${response.statusCode}');
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
    } catch (e) {
      print('[AUTH DEBUG] Error getting profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    // FIX: Thêm validation
    if (email.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'message': 'Email và mật khẩu không được trống'
      };
    }

    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.login);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Request timeout'),
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
          print('[AUTH DEBUG] Login response missing token');
          return {
            'success': false,
            'message': 'Phản hồi đăng nhập thiếu token'
          };
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, token);
        
        // FIX: Lưu thời gian hết hạn token (24 giờ)
        final expireTime = DateTime.now().add(Duration(hours: 24));
        await prefs.setString(_tokenExpireKey, expireTime.toIso8601String());

        if (mustChangePassword) {
          return {
            'success': false,
            'message': 'Bạn cần đổi mật khẩu trước khi sử dụng hệ thống.',
          };
        }

        final profile = await getProfile(token);
        final user = profile ??
            User(
              fullName: 'Nguoi dung',
              email: email,
              role: 'Student',
              token: token,
            );

        print('[AUTH DEBUG] Login successful for $email');
        return {'success': true, 'user': user};
      } else {
        print('[AUTH DEBUG] Login failed: ${response.statusCode}');
        try {
          final errorData = jsonDecode(response.body);
          return {'success': false, 'message': errorData['message']};
        } catch (e) {
          return {
            'success': false,
            'message': 'Lỗi đăng nhập: ${response.statusCode}'
          };
        }
      }
    } catch (e) {
      print('[AUTH DEBUG] Login exception: $e');
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<void> logout() async {
    await clearToken();
    print('[AUTH DEBUG] User logged out');
  }
}
