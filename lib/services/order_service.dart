import 'dart:convert';
import 'package:http/http.dart' as http;
// Bỏ import SharedPreferences thừa
import '../config/api_config.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart'; // Thêm import AuthService

class OrderService {
  final AuthService _authService = AuthService(); // Khởi tạo AuthService

  Future<List<OrderModel>> fetchMyOrders() async {
    // --- ĐÃ FIX: Dùng AuthService lấy token chuẩn ---
    final token = await _authService.getToken(); 
    // ------------------------------------------------

    if (token == null) {
      throw Exception('Người dùng chưa đăng nhập');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getMyOrders}');
    
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } else {
      throw Exception('Không thể tải danh sách đơn hàng: ${response.statusCode} ${response.body}');
    }
  }
}