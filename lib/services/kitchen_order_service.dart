import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/order_model.dart';
import 'auth_service.dart';

class KitchenOrderService {
  final AuthService _authService = AuthService();

  Future<String> _requireToken() async {
    final token = await _authService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Chua dang nhap');
    }
    return token;
  }

  Future<List<OrderModel>> fetchUnconfirmed() async {
    final token = await _requireToken();
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.kitchenUnconfirmedOrders}');

    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Khong the tai don cho xac nhan: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body);
    if (data is List) {
      return data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const [];
  }

  Future<List<OrderModel>> fetchCooking() async {
    final token = await _requireToken();
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.kitchenCookingOrders}');

    final res = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Khong the tai don cooking: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body);
    if (data is List) {
      return data.map((e) => OrderModel.fromJson(e as Map<String, dynamic>)).toList();
    }
    return const [];
  }

  Future<void> accept(int orderId) async {
    final token = await _requireToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/kitchen/orders/$orderId/accept');

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Xac nhan don that bai: ${res.statusCode} ${res.body}');
    }
  }

  Future<void> complete(int orderId) async {
    final token = await _requireToken();
    final url = Uri.parse('${ApiConfig.baseUrl}/kitchen/orders/$orderId/complete');

    final res = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (res.statusCode != 200) {
      throw Exception('Hoan thanh don that bai: ${res.statusCode} ${res.body}');
    }
  }
}
