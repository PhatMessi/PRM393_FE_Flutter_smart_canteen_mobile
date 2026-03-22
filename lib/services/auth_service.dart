import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // Import mới
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
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
        final decoded = _tryDecodeJson(response.body);
        return {
          'success': false,
          'message': _readMessage(decoded) ?? response.body,
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> loginWithGoogle() async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: const <String>['email', 'profile'],
        // If GOOGLE_WEB_CLIENT_ID is provided, request idToken for server verification.
        // With Firebase configured (google-services.json + Google provider enabled), Android can also work without this.
        serverClientId: ApiConfig.googleWebClientId.isNotEmpty ? ApiConfig.googleWebClientId : null,
      );

      final account = await googleSignIn.signIn();
      if (account == null) {
        return {'success': false, 'message': 'Đã hủy đăng nhập Google.'};
      }

      final auth = await account.authentication;
      final idToken = auth.idToken;
      final accessToken = auth.accessToken;

      final firebaseReady = Firebase.apps.isNotEmpty;
      if (firebaseReady && idToken != null && idToken.isNotEmpty && accessToken != null && accessToken.isNotEmpty) {
        try {
          final credential = fb_auth.GoogleAuthProvider.credential(
            idToken: idToken,
            accessToken: accessToken,
          );
          await fb_auth.FirebaseAuth.instance.signInWithCredential(credential);
        } catch (_) {
          // Ignore FirebaseAuth sign-in errors; server-side verification still uses idToken.
        }
      }

      if (idToken == null || idToken.isEmpty) {
        return {
          'success': false,
          'message':
              'Không lấy được Google idToken. Hãy kiểm tra: (1) Firebase Android đã cấu hình đúng (google-services.json đúng project, đã Enable Google Sign-In trong Firebase Auth, đã add SHA-1), hoặc (2) truyền Web Client ID qua `--dart-define=GOOGLE_WEB_CLIENT_ID=...`. Package hiện tại: com.example.smart_canteen_mobile.',
        };
      }

      final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.googleLogin);
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'idToken': idToken}),
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
          return {
            'success': false,
            'message': 'Phan hoi dang nhap Google thieu token',
          };
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
        final user = profile ??
            User(
              fullName: account.displayName ?? 'Nguoi dung',
              email: account.email,
              role: 'Student',
              token: token,
            );

        return {'success': true, 'user': user};
      }

      final decoded = _tryDecodeJson(response.body);
      return {
        'success': false,
        'message': _readMessage(decoded) ?? response.body,
      };
    } on PlatformException catch (e) {
      final text = (e.message?.isNotEmpty == true) ? e.message! : e.toString();
      if (text.contains('ApiException: 10') || text.contains('statusCode: 10')) {
        return {
          'success': false,
          'message':
              'Google Sign-In bị lỗi cấu hình (ApiException: 10). Kiểm tra lại OAuth Android Client trên Google Cloud: package name phải là com.example.smart_canteen_mobile và SHA-1 phải đúng (ví dụ: 23:E2:F8:4E:...).',
        };
      }

      return {
        'success': false,
        'message': 'Google Sign-In thất bại: ${e.message ?? e.code}',
      };
    } catch (e) {
      return {'success': false, 'message': 'Lỗi kết nối: $e'};
    }
  }

  Future<Map<String, dynamic>> requestRegisterOtp(String email) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.registerRequestOtp);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      final decoded = _tryDecodeJson(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': _readMessage(decoded) ?? 'Da gui OTP',
        };
      }

      return {
        'success': false,
        'message': _readMessage(decoded) ?? response.body,
      };
    } catch (e) {
      return {'success': false, 'message': 'Loi ket noi: $e'};
    }
  }

  Future<Map<String, dynamic>> registerWithOtp({
    required String fullName,
    required String email,
    required String password,
    required String otp,
  }) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.register);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'otp': otp,
        }),
      );

      final decoded = _tryDecodeJson(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': _readMessage(decoded) ?? 'Dang ky thanh cong',
        };
      }

      return {
        'success': false,
        'message': _readMessage(decoded) ?? response.body,
      };
    } catch (e) {
      return {'success': false, 'message': 'Loi ket noi: $e'};
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
        try {
          final body = jsonDecode(response.body);
          if (body is Map<String, dynamic>) {
            final msg = (body['message'] ?? body['Message'] ?? 'Da gui email').toString();
            return {'success': true, 'message': msg};
          }
        } catch (_) {}
        return {'success': true, 'message': 'Da gui email'};
      } else {
        try {
          final body = jsonDecode(response.body);
          return {
            'success': false,
            'message': (body['message'] ?? body['Message'] ?? 'That bai').toString(),
          };
        } catch (_) {
          return {'success': false, 'message': response.body};
        }
      }
    } catch (e) {
      return {'success': false, 'message': 'Loi ket noi: $e'};
    }
  }

  Future<Map<String, dynamic>> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.forgotPasswordConfirm);

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      final decoded = _tryDecodeJson(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': _readMessage(decoded) ?? 'Đặt lại mật khẩu thành công',
        };
      }

      return {
        'success': false,
        'message': _readMessage(decoded) ?? response.body,
      };
    } catch (e) {
      return {'success': false, 'message': 'Loi ket noi: $e'};
    }
  }

  Future<Map<String, dynamic>> requestChangePasswordOtp() async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Chua dang nhap'};
    }

    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.changePasswordRequestOtp);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final decoded = _tryDecodeJson(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': _readMessage(decoded) ?? 'Da gui OTP',
        };
      }

      return {
        'success': false,
        'message': _readMessage(decoded) ?? response.body,
      };
    } catch (e) {
      return {'success': false, 'message': 'Loi ket noi: $e'};
    }
  }

  Future<Map<String, dynamic>> changePasswordWithOtp({
    required String oldPassword,
    required String newPassword,
    required String otp,
  }) async {
    final token = await getToken();
    if (token == null || token.isEmpty) {
      return {'success': false, 'message': 'Chua dang nhap'};
    }

    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.changePassword);

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
          'otp': otp,
        }),
      );

      final decoded = _tryDecodeJson(response.body);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': _readMessage(decoded) ?? 'Doi mat khau thanh cong',
        };
      }

      return {
        'success': false,
        'message': _readMessage(decoded) ?? response.body,
      };
    } catch (e) {
      return {'success': false, 'message': 'Loi ket noi: $e'};
    }
  }

  dynamic _tryDecodeJson(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  String? _readMessage(dynamic decoded) {
    if (decoded is Map<String, dynamic>) {
      final v = decoded['message'] ?? decoded['Message'];
      if (v != null) return v.toString();
    }
    return null;
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
