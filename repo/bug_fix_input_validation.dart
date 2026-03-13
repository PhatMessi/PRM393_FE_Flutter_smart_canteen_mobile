/**
 * BUG FIX: Validation nhập liệu tốt hơn cho form đăng nhập và quên mật khẩu
 * 
 * Vấn đề: Không validate email format, password strength
 *         User có thể submit form với dữ liệu không hợp lệ
 * 
 * Fix: Thêm các hàm validation toàn diện
 */

import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProviderFixed extends ChangeNotifier {
  final AuthService _authService = AuthService();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, String?> _fieldErrors = {}; // FIX: Store lỗi từng field

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, String?> get fieldErrors => _fieldErrors;

  // FIX: Hàm validate email
  String? validateEmail(String email) {
    if (email.isEmpty) {
      return 'Email không được trống';
    }
    
    // Regex kiểm tra email hợp lệ
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(email)) {
      return 'Email không hợp lệ';
    }
    
    return null; // Hợp lệ
  }

  // FIX: Hàm validate mật khẩu
  String? validatePassword(String password, {bool isLogin = true}) {
    if (password.isEmpty) {
      return 'Mật khẩu không được trống';
    }
    
    if (password.length < 6) {
      return 'Mật khẩu phải ít nhất 6 ký tự';
    }
    
    // Chỉ check password strength khi sign up (không phải login)
    if (!isLogin) {
      if (!password.contains(RegExp(r'[A-Z]'))) {
        return 'Mật khẩu phải chứa ít nhất 1 chữ hoa';
      }
      if (!password.contains(RegExp(r'[0-9]'))) {
        return 'Mật khẩu phải chứa ít nhất 1 chữ số';
      }
    }
    
    return null;
  }

  // FIX: Hàm validate confirm password
  String? validateConfirmPassword(String password, String confirmPassword) {
    if (confirmPassword.isEmpty) {
      return 'Xác nhận mật khẩu không được trống';
    }
    
    if (password != confirmPassword) {
      return 'Mật khẩu không khớp';
    }
    
    return null;
  }

  // FIX: Clear field errors
  void clearFieldErrors() {
    _fieldErrors = {};
    notifyListeners();
  }

  // FIX: Set field error
  void setFieldError(String fieldName, String? error) {
    _fieldErrors[fieldName] = error;
    notifyListeners();
  }

  // FIX: Validate tất cả field trước khi submit
  bool validateForm({required String email, required String password}) {
    clearFieldErrors();
    
    final emailError = validateEmail(email);
    final passwordError = validatePassword(password);
    
    if (emailError != null) {
      setFieldError('email', emailError);
    }
    if (passwordError != null) {
      setFieldError('password', passwordError);
    }
    
    return emailError == null && passwordError == null;
  }

  Future<bool> tryAutoLogin() async {
    final token = await _authService.getToken();
    if (token == null) {
      return false;
    }

    final profile = await _authService.getProfile(token);
    _user = profile ??
        User(
          fullName: "Nguoi dung",
          email: "",
          role: "Student",
          token: token,
        );

    notifyListeners();
    return true;
  }

  Future<bool> login(String email, String password) async {
    // FIX: Validate trước khi call API
    if (!validateForm(email: email, password: password)) {
      _isLoading = false;
      _errorMessage = "Kiểm tra lại email và mật khẩu";
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _authService.login(email, password);

      if (result['success']) {
        _user = result['user'];
        _isLoading = false;
        clearFieldErrors();
        notifyListeners();
        print('[AUTH DEBUG] Login successful');
        return true;
      } else {
        _errorMessage = result['message'];
        _isLoading = false;
        notifyListeners();
        print('[AUTH DEBUG] Login failed: ${result['message']}');
        return false;
      }
    } catch (e) {
      _errorMessage = "Đã xảy ra lỗi không mong muốn.";
      _isLoading = false;
      notifyListeners();
      print('[AUTH DEBUG] Login exception: $e');
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    // FIX: Validate email trước
    final emailError = validateEmail(email);
    if (emailError != null) {
      _errorMessage = emailError;
      setFieldError('email', emailError);
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    clearFieldErrors();
    notifyListeners();

    try {
      final result = await _authService.forgotPassword(email);
      _isLoading = false;

      if (!result['success']) {
        _errorMessage = result['message'];
      } else {
        _errorMessage = null; // FIX: Clear error khi thành công
      }

      notifyListeners();
      print('[AUTH DEBUG] Forgot password result: ${result['success']}');
      return result['success'];
    } catch (e) {
      _isLoading = false;
      _errorMessage = "Lỗi kết nối mạng";
      notifyListeners();
      print('[AUTH DEBUG] Forgot password exception: $e');
      return false;
    }
  }

  void logout() {
    _authService.logout();
    _user = null;
    clearFieldErrors();
    _errorMessage = null;
    notifyListeners();
    print('[AUTH DEBUG] User logged out');
  }
}
