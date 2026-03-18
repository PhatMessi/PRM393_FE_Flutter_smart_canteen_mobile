class ApiConfig {
  // Backend Render
  // NOTE: baseUrl ends with `/api` (controllers), hub url does not.
  static const String baseUrl =
      "https://prm393-be-smartcanteensystemwebapp.onrender.com/api";

  // SignalR hub (không có /api)
  static const String realtimeHubUrl =
      "https://prm393-be-smartcanteensystemwebapp.onrender.com/hubs/realtime";

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
