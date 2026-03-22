import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/menu_item_customization.dart';

class MenuItemCustomizationService {
  Future<MenuItemCustomization?> getCustomizations(int menuItemId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.getMenu}/$menuItemId/customizations');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          return MenuItemCustomization.fromJson(decoded);
        }
        if (decoded is Map) {
          return MenuItemCustomization.fromJson(Map<String, dynamic>.from(decoded));
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
