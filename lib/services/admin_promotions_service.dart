import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/promotion_model.dart';
import 'auth_service.dart';

class AdminPromotionsService {
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

  Future<List<PromotionModel>> listPromotions() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('Vui long dang nhap truoc!');
    }

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminPromotions}');
    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode != 200) {
      throw Exception(_extractErrorMessage(response.body));
    }

    final data = jsonDecode(response.body);
    if (data is! List) return [];

    return data.whereType<Map<String, dynamic>>().map(PromotionModel.fromJson).toList();
  }

  Future<(bool success, String message)> updatePromotion(PromotionModel promo) async {
    final token = await _authService.getToken();
    if (token == null) return (false, 'Vui long dang nhap truoc!');

    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.adminPromotions}/${promo.promotionId}',
    );

    final body = <String, dynamic>{
      'promotionId': promo.promotionId,
      'code': promo.code,
      'description': promo.description,
      'type': promo.type,
      'discountPercentage': promo.discountPercentage,
      'discountAmount': promo.discountAmount,
      'minOrderAmount': promo.minOrderAmount,
      'maxDiscountAmount': promo.maxDiscountAmount,
      'buyItemId': promo.buyItemId,
      'buyQuantity': promo.buyQuantity,
      'getItemId': promo.getItemId,
      'getQuantity': promo.getQuantity,
      'comboRequirements': promo.comboRequirements.map((e) => e.toJson()).toList(),
      'startDate': promo.startDate.toUtc().toIso8601String(),
      'endDate': promo.endDate.toUtc().toIso8601String(),
      'isActive': promo.isActive,
    };

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final msg = decoded is Map<String, dynamic> ? (decoded['message'] ?? decoded['Message']) : null;
      return (true, (msg ?? 'Da cap nhat voucher.').toString());
    }

    return (false, _extractErrorMessage(response.body));
  }

  Future<(bool success, String message)> createPromotion({
    required String code,
    String? description,
    String type = 'PercentBill',
    num discountPercentage = 0,
    num? discountAmount,
    num? minOrderAmount,
    num? maxDiscountAmount,
    DateTime? startDate,
    DateTime? endDate,
    bool isActive = true,
  }) async {
    final token = await _authService.getToken();
    if (token == null) return (false, 'Vui long dang nhap truoc!');

    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminPromotions}');

    final body = <String, dynamic>{
      'code': code,
      'description': description ?? '',
      'type': type,
      'discountPercentage': discountPercentage,
      'discountAmount': discountAmount,
      'minOrderAmount': minOrderAmount,
      'maxDiscountAmount': maxDiscountAmount,
      'startDate': (startDate ?? DateTime.now()).toUtc().toIso8601String(),
      'endDate': (endDate ?? DateTime.now().add(const Duration(days: 30))).toUtc().toIso8601String(),
      'isActive': isActive,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final msg = decoded is Map<String, dynamic> ? (decoded['message'] ?? decoded['Message']) : null;
      return (true, (msg ?? 'Da tao voucher.').toString());
    }

    return (false, _extractErrorMessage(response.body));
  }

  Future<(bool success, String? payload, String message)> getQrPayload(int promotionId) async {
    final token = await _authService.getToken();
    if (token == null) return (false, null, 'Vui long dang nhap truoc!');

    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.adminPromotions}/$promotionId/qr',
    );

    final response = await http.get(url, headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    });

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final payload = decoded is Map<String, dynamic> ? decoded['payload']?.toString() : null;
      return (true, payload, '');
    }

    return (false, null, _extractErrorMessage(response.body));
  }
}
