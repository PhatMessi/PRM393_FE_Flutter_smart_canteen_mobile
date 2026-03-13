class User {
  final int? id; // Có thể null nếu login không trả về ID
  final String fullName;
  final String email;
  final String role;
  final String? token; // Lưu token để dùng cho các request sau này

  User({
    this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.token,
  });

  // Factory để tạo User từ JSON trả về của Backend
  // Lưu ý: Backend C# thường trả về field viết hoa (PascalCase) hoặc thường (camelCase) tùy cấu hình
  // Code dưới đây handle cả 2 trường hợp cho chắc chắn.
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['UserId'] ?? 0,
      // Đây là dòng quan trọng để fix lỗi của bạn:
      fullName: json['fullName'] ?? json['FullName'] ?? 'Unknown User', 
      email: json['email'] ?? json['Email'] ?? '',
      role: json['role'] ?? json['Role'] ?? 'Student',
      token: json['token'],
    );
  }

  // Hàm chuyển đổi ngược lại thành JSON (nếu cần lưu xuống local storage)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'token': token,
    };
  }
}