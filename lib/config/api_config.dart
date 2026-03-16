import 'package:flutter/foundation.dart'; // 1. Thêm thư viện này để check kIsWeb

class ApiConfig {
  // 2. Logic tự động:
  // - Nếu là Web: dùng localhost:5090
  // - Nếu là Android: dùng 10.0.2.2:5090
  static const String baseUrl = kIsWeb
      ? "http://localhost:5090/api"
      : "http://10.0.2.2:5090/api";

  // SignalR hub (không có /api)
  static const String realtimeHubUrl = kIsWeb
      ? "http://localhost:5090/hubs/realtime"
      : "http://10.0.2.2:5090/hubs/realtime";

  // Các Endpoints
  static const String login = "/auth/login";
  static const String register = "/auth/register";
  static const String registerRequestOtp = "/auth/register/request-otp";
  static const String getUserProfile = "/auth/profile";
  static const String forgotPassword = "/auth/forgot-password";
  static const String forgotPasswordConfirm = "/auth/forgot-password/confirm";
  static const String changePassword = "/auth/change-password";
  static const String changePasswordRequestOtp =
      "/auth/change-password/request-otp";
  static const String getMenu = "/Menu";
  static const String getCategories = "/Menu/categories";
  static const String getMyOrders = "/Orders/my-orders";

  // Kitchen
  static const String kitchenUnconfirmedOrders = "/kitchen/orders/unconfirmed";
  static const String kitchenCookingOrders = "/kitchen/orders/cooking";

  // Favorites (per account)
  static const String favorites = "/Favorites";
  static const String getFavorites = favorites;

  // Promotions / vouchers
  static const String promotionsActive = "/promotions/active";
  static const String promotionsSaved = "/promotions/saved";
  static const String promotionsSave = "/promotions/save";
  static const String promotionsApply = "/promotions/apply";
  static const String promotionsCheckinQr = "/promotions/qr/checkin";

    // Admin promotions (SystemAdmin)
    static const String adminPromotions = "/admin/promotions";

  static const int receiveTimeout = 15000;
  static const int connectionTimeout = 15000;
}
