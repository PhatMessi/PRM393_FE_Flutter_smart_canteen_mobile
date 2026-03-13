/**
 * BUG FIX: Xử lý lỗi tốt hơn khi lấy danh sách đơn hàng
 * 
 * Vấn đề: Khi network chậm, request này có thể timeout mà không có thông báo rõ
 *         Không có hàm retry tự động khi thất bại
 * 
 * Fix: Thêm timeout handling, retry logic, và cache dữ liệu
 */

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';

class OrderServiceFixed {
  final AuthService _authService = AuthService();
  static const String _cacheKey = 'cached_orders';
  static const int _maxRetries = 3;
  static const Duration _timeout = Duration(seconds: 15);

  // FIX: Hàm fetch với retry logic
  Future<List<OrderModel>> fetchMyOrdersWithRetry(
      {int retryCount = 0}) async {
    try {
      return await fetchMyOrders();
    } catch (e) {
      if (retryCount < _maxRetries) {
        print('[ORDER DEBUG] Retry ${retryCount + 1}/$_maxRetries: $e');
        // Chờ 2 giây trước khi retry
        await Future.delayed(Duration(seconds: 2 * (retryCount + 1)));
        return fetchMyOrdersWithRetry(retryCount: retryCount + 1);
      }
      rethrow;
    }
  }

  Future<List<OrderModel>> fetchMyOrders() async {
    // FIX: Kiểm tra token hợp lệ trước khi call API
    final token = await _authService.getToken();

    if (token == null) {
      print('[ORDER DEBUG] No valid token found');
      // FIX: Trả về cached data nếu có thay vì lỗi thẳng
      return _getCachedOrders();
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getMyOrders}');

    try {
      final response = await http
          .get(
            url,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(
            _timeout,
            onTimeout: () =>
                throw TimeoutException('Timeout fetching orders after 15s'),
          );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        final orders = data.map((json) => OrderModel.fromJson(json)).toList();
        
        // FIX: Cache data để sử dụng offline
        await _cacheOrders(orders);
        print('[ORDER DEBUG] Successfully fetched ${orders.length} orders');
        return orders;
      } else if (response.statusCode == 401) {
        print('[ORDER DEBUG] Unauthorized (401), token may be expired');
        throw Exception('Token hết hạn, vui lòng đăng nhập lại');
      } else {
        print('[ORDER DEBUG] Server error: ${response.statusCode}');
        // FIX: Trả về cached data nếu server error
        final cached = await _getCachedOrders();
        if (cached.isNotEmpty) {
          print('[ORDER DEBUG] Using cached orders as fallback');
          return cached;
        }
        throw Exception(
            'Không thể tải danh sách đơn hàng: ${response.statusCode}');
      }
    } on TimeoutException catch (e) {
      print('[ORDER DEBUG] Timeout: $e');
      // FIX: Trả về cached data nếu timeout
      final cached = await _getCachedOrders();
      if (cached.isNotEmpty) {
        print('[ORDER DEBUG] Using cached orders as fallback');
        return cached;
      }
      throw Exception('Kết nối quá chậm. Vui lòng kiểm tra mạng của bạn.');
    } catch (e) {
      print('[ORDER DEBUG] Unknown error: $e');
      // FIX: Trả về cached data cho bất kỳ error nào
      final cached = await _getCachedOrders();
      if (cached.isNotEmpty) {
        print('[ORDER DEBUG] Using cached orders as fallback');
        return cached;
      }
      rethrow;
    }
  }

  // FIX: Hàm cache orders
  Future<void> _cacheOrders(List<OrderModel> orders) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode(orders.map((o) => o.toJson()).toList());
      await prefs.setString(_cacheKey, json);
      print('[ORDER DEBUG] Orders cached successfully');
    } catch (e) {
      print('[ORDER DEBUG] Failed to cache orders: $e');
    }
  }

  // FIX: Hàm lấy cached orders
  Future<List<OrderModel>> _getCachedOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_cacheKey);
      if (json == null) return [];
      
      final List<dynamic> data = jsonDecode(json);
      return data.map((item) => OrderModel.fromJson(item)).toList();
    } catch (e) {
      print('[ORDER DEBUG] Failed to retrieve cached orders: $e');
      return [];
    }
  }

  // FIX: Xóa cache
  Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey);
      print('[ORDER DEBUG] Cache cleared');
    } catch (e) {
      print('[ORDER DEBUG] Failed to clear cache: $e');
    }
  }
}

// FIX: Custom exception cho timeout
class TimeoutException implements Exception {
  final String message;
  TimeoutException(this.message);

  @override
  String toString() => message;
}
