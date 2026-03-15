/**
 * IMPROVED VERSION
 * - Clean code
 * - Reuse SharedPreferences
 * - Better error handling
 * - Token expiration check
 * - Safer JSON parsing
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/user_model.dart';

class AuthService {
  static const _tokenKey = 'user_token';
  static const _tokenExpireKey = 'token_expire_time';

  static const _timeout = Duration(seconds: 10);

  /// Lấy SharedPreferences một lần
  Future<SharedPreferences> get _prefs async =>
      await SharedPreferences.getInstance();

  // =========================================================
  // TOKEN MANAGEMENT
  // =========================================================

  Future<bool> isTokenValid() async {
    final prefs = await _prefs;
    final expireTime = prefs.getString(_tokenExpireKey);

    if (expireTime == null) return true;

    try {
      final expire = DateTime.parse(expireTime);
      return DateTime.now().isBefore(expire);
    } catch (_) {
      return false;
    }
  }

  Future<String?> getToken() async {
    final valid = await isTokenValid();

    if (!valid) {
      await clearToken();
      return null;
    }

    final prefs = await _prefs;
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await _prefs;

    await prefs.setString(_tokenKey, token);

    final expireTime = DateTime.now().add(const Duration(hours: 24));
    await prefs.setString(_tokenExpireKey, expireTime.toIso8601String());
  }

  Future<void> clearToken() async {
    final prefs = await _prefs;

    await Future.wait([
      prefs.remove(_tokenKey),
      prefs.remove(_tokenExpireKey),
    ]);
  }

  // =========================================================
  // API REQUEST HELPER
  // =========================================================

  Future<http.Response> _get(
    String endpoint,
    String token,
  ) async {
    final url = Uri.parse(ApiConfig.baseUrl + endpoint);

    return http
        .get(
          url,
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(_timeout);
  }

  Future<http.Response> _post(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final url = Uri.parse(ApiConfig.baseUrl + endpoint);

    return http
        .post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        )
        .timeout(_timeout);
  }

  // =========================================================
  // PROFILE
  // =========================================================

  Future<User?> getProfile(String token) async {
    try {
      final response = await _get(ApiConfig.getUserProfile, token);

      if (response.statusCode == 401) {
        await clearToken();
        return null;
      }

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) return null;

      return User(
        fullName: _getValue(data, 'fullName', 'FullName', 'Nguoi dung'),
        email: _getValue(data, 'email', 'Email', ''),
        role: _getValue(data, 'role', 'Role', 'Student'),
        token: token,
      );
    } catch (e) {
      print('[AUTH] getProfile error: $e');
      return null;
    }
  }

  // =========================================================
  // LOGIN
  // =========================================================

  Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    if (email.isEmpty || password.isEmpty) {
      return {
        'success': false,
        'message': 'Email và mật khẩu không được trống'
      };
    }

    try {
      final response = await _post(ApiConfig.login, {
        'email': email,
        'password': password,
      });

      if (response.statusCode != 200) {
        return _handleLoginError(response);
      }

      final data = jsonDecode(response.body);

      if (data is! Map<String, dynamic>) {
        return {
          'success': false,
          'message': 'Phản hồi server không hợp lệ'
        };
      }

      final token = data['token']?.toString();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'Server không trả token'
        };
      }

      final mustChangePassword =
          data['mustChangePassword'] == true;

      await saveToken(token);

      if (mustChangePassword) {
        return {
          'success': false,
          'message':
              'Bạn cần đổi mật khẩu trước khi sử dụng hệ thống.'
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

      return {
        'success': true,
        'user': user,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Lỗi kết nối: $e'
      };
    }
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> logout() async {
    await clearToken();
  }

  // =========================================================
  // HELPERS
  // =========================================================

  String _getValue(
    Map<String, dynamic> data,
    String key1,
    String key2,
    String defaultValue,
  ) {
    final value = data[key1] ?? data[key2];
    return value?.toString().isNotEmpty == true
        ? value.toString()
        : defaultValue;
  }

  Map<String, dynamic> _handleLoginError(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      return {
        'success': false,
        'message': data['message'] ?? 'Login thất bại'
      };
    } catch (_) {
      return {
        'success': false,
        'message': 'Lỗi đăng nhập (${response.statusCode})'
      };
    }
  }
}