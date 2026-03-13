/**
 * Validation Helpers
 * 
 * Tập hợp các hàm validate phổ biến
 * Giúp validate email, password, phone number, v.v.
 */

class ValidationHelper {
  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email không được để trống';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Email không hợp lệ';
    }

    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Mật khẩu không được để trống';
    }

    if (value.length < 6) {
      return 'Mật khẩu phải có ít nhất 6 ký tự';
    }

    // Check if has at least one uppercase letter
    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'Mật khẩu phải chứa ít nhất 1 chữ cái viết hoa';
    }

    // Check if has at least one number
    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'Mật khẩu phải chứa ít nhất 1 số';
    }

    return null;
  }

  /// Validate Vietnamese phone number
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Số điện thoại không được để trống';
    }

    // Vietnamese phone: 10 digits, starts with 0
    final phoneRegex = RegExp(r'^0\d{9}$');

    if (!phoneRegex.hasMatch(value)) {
      return 'Số điện thoại không hợp lệ (phải bắt đầu bằng 0, có 10 chữ số)';
    }

    return null;
  }

  /// Validate full name
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Tên không được để trống';
    }

    if (value.length < 3) {
      return 'Tên phải có ít nhất 3 ký tự';
    }

    if (value.length > 50) {
      return 'Tên không được vượt quá 50 ký tự';
    }

    return null;
  }

  /// Validate amount/price
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Số tiền không được để trống';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Số tiền phải là số hợp lệ';
    }

    if (amount <= 0) {
      return 'Số tiền phải lớn hơn 0';
    }

    return null;
  }

  /// Validate not empty
  static String? validateRequired(String? value, {String? fieldName}) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'Trường này'} không được để trống';
    }
    return null;
  }

  /// Check if email is valid format (without error message)
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Check if password is strong
  static bool isStrongPassword(String password) {
    return password.length >= 6 &&
        password.contains(RegExp(r'[A-Z]')) &&
        password.contains(RegExp(r'[0-9]'));
  }

  /// Check if phone number is valid
  static bool isValidPhoneNumber(String phone) {
    final phoneRegex = RegExp(r'^0\d{9}$');
    return phoneRegex.hasMatch(phone);
  }
}
