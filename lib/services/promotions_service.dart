import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/promotion_model.dart';
import 'auth_service.dart';

class PromotionsService {
  final AuthService _authService = AuthService();

  String _extractErrorMessage(String body) {
    if (body.trim().isEmpty) return 'Loi khong xac dinh';
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final msg = data['message'] ?? data['Message'] ?? data['error'] ?? data['Error'];
        if (msg != null) return msg.toString();
      }
    } catch (_) {}
    return body;
  }

  Future<List<PromotionModel>> getActivePromotions() async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.promotionsActive);
    final response = await http.get(url);
    if (response.statusCode != 200) return [];

    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.whereType<Map<String, dynamic>>().map(PromotionModel.fromJson).toList();
  }

  Future<List<PromotionModel>> getSavedPromotions() async {
    final token = await _authService.getToken();
    if (token == null) return [];

    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.promotionsSaved);
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200) return [];
    final List<dynamic> data = jsonDecode(response.body) as List<dynamic>;
    return data.whereType<Map<String, dynamic>>().map(PromotionModel.fromJson).toList();
  }

  Future<(bool success, String message)> savePromotion(String code) async {
    final token = await _authService.getToken();
    if (token == null) return (false, 'Vui long dang nhap truoc!');

    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.promotionsSave);
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'code': code}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final msg = (data is Map<String, dynamic> ? (data['message'] ?? data['Message']) : null);
      return (true, (msg ?? 'Da luu voucher.').toString());
    }

    return (false, _extractErrorMessage(response.body));
  }

  Future<(bool success, ApplyPromotionResult? result, String message)> applyPromotion({
    required String code,
    required List<CartLineDto> items,
  }) async {
    final token = await _authService.getToken();
    if (token == null) return (false, null, 'Vui long dang nhap truoc!');

    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.promotionsApply);
    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'code': code,
        'items': items.map((e) => e.toJson()).toList(),
      }),
    );

    if (response.statusCode == 200) {
      return (true, ApplyPromotionResult.fromJson(jsonDecode(response.body) as Map<String, dynamic>), '');
    }

    return (false, null, _extractErrorMessage(response.body));
  }
}
