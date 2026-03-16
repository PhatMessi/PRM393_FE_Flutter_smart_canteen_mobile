import 'package:flutter/foundation.dart'; // 1. Thêm thư viện này để check kIsWeb

class ApiConfig {
  // 2. Logic tự động:
  // - Nếu là Web: dùng localhost:5090
  // - Nếu là Android: dùng 10.0.2.2:5090
  static const String baseUrl = kIsWeb
      ? "http://localhost:5090/api"
      : "http://10.0.2.2:5090/api";

  // Các Endpoints
  static const String login = "/auth/login";
  static const String register = "/auth/register";
  static const String getUserProfile = "/auth/profile";
  static const String forgotPassword = "/Auth/forgot-password";
  static const String getMenu = "/Menu";
  static const String getCategories = "/Menu/categories";
  static const String getMyOrders = "/Orders/my-orders";

<<<<<<< HEAD
  // Favorites (per account)
  static const String favorites = "/Favorites";
  static const String getFavorites = favorites;

=======
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
  static const int receiveTimeout = 15000;
  static const int connectionTimeout = 15000;
}
