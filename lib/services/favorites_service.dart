import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/menu_item.dart';

class FavoritesService {
  Future<List<MenuItem>> getMyFavorites(String token) async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.getFavorites);

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to load favorites: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    if (data is! List) return <MenuItem>[];

    return data
        .whereType<Map<String, dynamic>>()
        .map(MenuItem.fromJson)
        .toList(growable: false);
  }

  Future<void> addFavorite(String token, int itemId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.favorites}/$itemId');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to add favorite: ${response.statusCode}');
    }
  }

  Future<void> removeFavorite(String token, int itemId) async {
    final url = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.favorites}/$itemId');

    final response = await http.delete(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200 && response.statusCode != 404) {
      throw Exception('Failed to remove favorite: ${response.statusCode}');
    }
  }

  Future<bool> isFavorite(String token, int itemId) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.favorites}/$itemId/is-favorite',
    );

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode != 200) {
      return false;
    }

    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) {
      return data['isFavorite'] == true;
    }

    return false;
  }
}
