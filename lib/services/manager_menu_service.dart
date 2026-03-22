import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/menu_item.dart';

class ManagerMenuService {
  Future<MenuItem?> createMenuItem({
    required String token,
    required String name,
    required String description,
    required double price,
    required int inventoryQuantity,
    required int categoryId,
    String? imageUrl,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getMenu}');
    final request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['Name'] = name;
    request.fields['Description'] = description;
    request.fields['Price'] = price.toString();
    request.fields['InventoryQuantity'] = inventoryQuantity.toString();
    request.fields['CategoryId'] = categoryId.toString();
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      request.fields['ImageUrl'] = imageUrl.trim();
    }

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 201 || streamed.statusCode == 200) {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) return MenuItem.fromJson(decoded);
      if (decoded is Map) return MenuItem.fromJson(Map<String, dynamic>.from(decoded));
    }

    return null;
  }

  Future<bool> updateMenuItem({
    required String token,
    required int itemId,
    required String name,
    required String description,
    required double price,
    required int inventoryQuantity,
    required int categoryId,
    required bool isAvailable,
    String? imageUrl,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getMenu}/$itemId');
    final request = http.MultipartRequest('PUT', url);
    request.headers['Authorization'] = 'Bearer $token';

    request.fields['Name'] = name;
    request.fields['Description'] = description;
    request.fields['Price'] = price.toString();
    request.fields['InventoryQuantity'] = inventoryQuantity.toString();
    request.fields['CategoryId'] = categoryId.toString();
    request.fields['IsAvailable'] = isAvailable.toString();
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      request.fields['ImageUrl'] = imageUrl.trim();
    }

    final streamed = await request.send();
    return streamed.statusCode == 204;
  }

  Future<bool> deleteMenuItem({
    required String token,
    required int itemId,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getMenu}/$itemId');
    final response = await http.delete(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );
    return response.statusCode == 204;
  }

  Future<bool> replaceCustomizations({
    required String token,
    required int itemId,
    required Map<String, dynamic> payload,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getMenu}/$itemId/customizations');
    final response = await http.put(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(payload),
    );
    return response.statusCode == 204;
  }
}
