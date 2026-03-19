/**
 * Constant Values
 * 
 * Centralize các giá trị constants cho toàn ứng dụng
 * API endpoints, timeouts, default values, v.v.
 */

class AppConstants {
  // ============ APP INFO ============
  static const String appName = 'Smart Canteen';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '1';

  // ============ API CONFIGURATION ============
  static const String baseUrl = 'https://api.smartcanteen.com';
  static const String apiVersion = '/api/v1';
  
  // Timeouts (in seconds)
  static const int connectionTimeout = 30;
  static const int receiveTimeout = 30;
  static const int sendTimeout = 30;

  // ============ AUTHENTICATION ============
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String refreshTokenKey = 'refresh_token';
  static const int tokenExpiryBuffer = 300; // 5 minutes in seconds

  // Default values
  static const int defaultPageSize = 20;
  static const int defaultCacheDuration = 3600; // 1 hour in seconds

  // ============ UI CONFIGURATION ============
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 8.0;
  static const duration = Duration(milliseconds: 300);

  // ============ VALIDATION ============
  static const int minPasswordLength = 6;
  static const int minNameLength = 3;
  static const int maxNameLength = 50;
  static const int phoneNumberLength = 10;

  // ============ TRANSACTION ============
  static const String currencyCode = 'VND';
  static const String currencySymbol = '₫';

  // Fees
  static const double taxRate = 0.05; // 5%
  static const double deliveryFee = 25000; // 25,000 VND
  static const double minimumOrderAmount = 50000; // 50,000 VND

  // ============ NOTIFICATION ============
  static const int notificationCheckInterval = 30; // seconds
  static const int maxNotificationCount = 100;

  // ============ CACHE ============
  // Cache keys
  static const String cacheKeyMenu = 'menu_cache';
  static const String cacheKeyOrders = 'orders_cache';
  static const String cacheKeyUser = 'user_cache';

  // Cache durations (in seconds)
  static const int menuCacheDuration = 3600; // 1 hour
  static const int ordersCacheDuration = 600; // 10 minutes
  static const int userCacheDuration = 1800; // 30 minutes

  // ============ STORAGE KEYS ============
  static const String storageKeyTheme = 'theme_mode';
  static const String storageKeyLanguage = 'language';
  static const String storageKeyNotifications = 'notifications_enabled';
  static const String storageKeyBiometric = 'biometric_enabled';
  static const String storageKeyRememberMe = 'remember_me';

  // ============ DEFAULT VALUES ============
  static const String defaultLanguage = 'vi';
  static const String defaultCountry = 'VN';
  static const String defaultTimeZone = 'Asia/Ho_Chi_Minh';

  // ============ ERROR CODES ============
  static const String errorCodeUnauthorized = '401';
  static const String errorCodeForbidden = '403';
  static const String errorCodeNotFound = '404';
  static const String errorCodeServerError = '500';
  static const String errorCodeNetworkError = 'NETWORK_ERROR';
  static const String errorCodeTimeoutError = 'TIMEOUT_ERROR';
  static const String errorCodeUnknownError = 'UNKNOWN_ERROR';

  // ============ PAGINATION ============
  static const int itemsPerPage = 20;
  static const int itemsPerPageSmall = 10;
  static const int itemsPerPageLarge = 50;

  // ============ ANIMATION DURATIONS ============
  static const int shortAnimationDuration = 200; // milliseconds
  static const int mediumAnimationDuration = 300; // milliseconds
  static const int longAnimationDuration = 500; // milliseconds

  // ============ DATE & TIME ============
  static const String dateFormat = 'dd/MM/yyyy';
  static const String timeFormat = 'HH:mm';
  static const String dateTimeFormat = 'dd/MM/yyyy HH:mm';

  // ============ IMAGE ============
  static const int imageQuality = 85;
  static const int thumbnailSize = 150;
  static const int mediumImageSize = 500;

  // ============ ORDER STATUS ============
  static const String orderStatusPending = 'pending';
  static const String orderStatusProcessing = 'processing';
  static const String orderStatusReady = 'ready';
  static const String orderStatusCompleted = 'completed';
  static const String orderStatusCancelled = 'cancelled';

  // ============ PAYMENT STATUS ============
  static const String paymentStatusPending = 'pending';
  static const String paymentStatusCompleted = 'completed';
  static const String paymentStatusFailed = 'failed';
  static const String paymentStatusRefunded = 'refunded';

  // ============ REGEX PATTERNS ============
  static const String emailPattern =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phonePattern = r'^0\d{9}$';
  static const String urlPattern =
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';

  // ============ ROUTE NAMES ============
  static const String routeSplash = '/splash';
  static const String routeLogin = '/login';
  static const String routeRegister = '/register';
  static const String routeForgotPassword = '/forgot-password';
  static const String routeHome = '/home';
  static const String routeProductDetail = '/product-detail';
  static const String routeCart = '/cart';
  static const String routeCheckout = '/checkout';
  static const String routeOrders = '/orders';
  static const String routeOrderDetail = '/order-detail';
  static const String routeProfile = '/profile';
  static const String routeSettings = '/settings';
  static const String routeNotifications = '/notifications';
  static const String routeChat = '/chat';
  static const String routeMap = '/map';
  static const String routeWallet = '/wallet';
  static const String routeWalletTopup = '/wallet-topup';
}

/// Environment configuration
class EnvironmentConfig {
  static const bool isProduction = bool.fromEnvironment('IS_PRODUCTION');
  static const bool isDevelopment = !isProduction;

  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: AppConstants.baseUrl);
}
