import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  // Khởi tạo Service
  final AuthService _authService = AuthService();

  // Các biến trạng thái (State)
  User? _user; // Lưu thông tin user sau khi login
  bool _isLoading = false; // Để hiện vòng xoay loading
  String? _errorMessage; // Để hiện lỗi nếu có

  // Getter để UI có thể đọc dữ liệu
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // --- [FIX] Thêm hàm kiểm tra đăng nhập tự động ---
  Future<bool> tryAutoLogin() async {
    final token = await _authService.getToken();
    if (token == null) {
      return false;
    }

    final profile = await _authService.getProfile(token);
    _user =
        profile ??
      User(fullName: "Nguoi dung", email: "", role: "Student", token: token);

    notifyListeners();
    return true;
  }
  // ------------------------------------------------

  // Hàm xử lý đăng nhập (Được gọi từ UI)
  Future<bool> login(String email, String password) async {
    // 1. Bắt đầu loading, reset lỗi
    _isLoading = true;
    _errorMessage = null;
    notifyListeners(); // Báo cho UI biết để vẽ lại (hiện vòng xoay)

    try {
      // 2. Gọi Service
      final result = await _authService.login(email, password);

      // 3. Xử lý kết quả
      if (result['success']) {
        _user = result['user']; // Lưu user vào provider
        _isLoading = false;
        notifyListeners();
        return true; // Báo về UI là thành công
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        return false; // Báo về UI là thất bại
      }
    } catch (e) {
      _errorMessage = "Đã xảy ra lỗi không mong muốn.";
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.forgotPassword(email);
      _isLoading = false;

      if (!result['success']) {
        _errorMessage = result['message'];
      }

      notifyListeners();
      return result['success'];
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Lỗi kết nối mạng";
      notifyListeners();
      return false;
    }
  }

  Future<bool> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.resetPasswordWithOtp(
        email: email,
        otp: otp,
        newPassword: newPassword,
      );
      _isLoading = false;

      if (!result['success']) {
        _errorMessage = result['message'];
      }

      notifyListeners();
      return result['success'] == true;
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Lỗi kết nối mạng';
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestRegisterOtp(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.requestRegisterOtp(email);
      _isLoading = false;

      if (!result['success']) {
        _errorMessage = result['message'];
      }

      notifyListeners();
      return result['success'] == true;
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Lỗi kết nối mạng';
      notifyListeners();
      return false;
    }
  }

  Future<bool> registerWithOtp({
    required String fullName,
    required String email,
    required String password,
    required String otp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.registerWithOtp(
        fullName: fullName,
        email: email,
        password: password,
        otp: otp,
      );

      _isLoading = false;
      if (!result['success']) {
        _errorMessage = result['message'];
      }

      notifyListeners();
      return result['success'] == true;
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Lỗi kết nối mạng';
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestChangePasswordOtp() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.requestChangePasswordOtp();
      _isLoading = false;

      if (!result['success']) {
        _errorMessage = result['message'];
      }

      notifyListeners();
      return result['success'] == true;
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Lỗi kết nối mạng';
      notifyListeners();
      return false;
    }
  }

  Future<bool> changePasswordWithOtp({
    required String oldPassword,
    required String newPassword,
    required String otp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.changePasswordWithOtp(
        oldPassword: oldPassword,
        newPassword: newPassword,
        otp: otp,
      );

      _isLoading = false;
      if (!result['success']) {
        _errorMessage = result['message'];
      }

      notifyListeners();
      return result['success'] == true;
    } catch (_) {
      _isLoading = false;
      _errorMessage = 'Lỗi kết nối mạng';
      notifyListeners();
      return false;
    }
  }

  // Hàm đăng xuất
  void logout() {
    _authService.logout();
    _user = null;
    notifyListeners();
  }
}
