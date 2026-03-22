import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

class ApiConfig {
  // API host can be overridden at build time for easy local testing:
  // - Web:   flutter run -d chrome --dart-define=API_HOST=http://localhost:5090
  // - Android emulator: flutter run --dart-define=API_HOST=http://10.0.2.2:5090
  // If not provided, defaults to local (web=localhost, others=10.0.2.2).
  // You can still set production explicitly via dart-define.
  static const String _prodHost =
      'https://prm393-be-smartcanteensystemwebapp.onrender.com';

  static const String _hostFromEnv = String.fromEnvironment(
    'API_HOST',
    defaultValue: '',
  );

  static String get _host {
    if (_hostFromEnv.isNotEmpty) return _hostFromEnv;
    if (kReleaseMode) return _prodHost;
    return kIsWeb ? 'http://localhost:5090' : 'http://10.0.2.2:5090';
  }

  // NOTE: baseUrl ends with `/api` (controllers), hub url does not.
  static String get baseUrl => '$_host/api';

  // SignalR hub (không có /api)
  static String get realtimeHubUrl => '$_host/hubs/realtime';

  // Google Sign-In (Android OAuth client id)
  static const String googleAndroidClientId =
      '76418536347-6snfceml5ei08mt84l6ocjbu9v8qreek.apps.googleusercontent.com';

  // Google Sign-In (Web OAuth client id) - dùng cho `serverClientId` để lấy idToken trên Android.
  // Khuyến nghị set bằng build flag để dễ đổi môi trường:
  // `--dart-define=GOOGLE_WEB_CLIENT_ID=xxxx.apps.googleusercontent.com`
  static const String googleWebClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  // Các Endpoints
  static const String login = "/auth/login";
  static const String googleLogin = "/auth/google";
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
