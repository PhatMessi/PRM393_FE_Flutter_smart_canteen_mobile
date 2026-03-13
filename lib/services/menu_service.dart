import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/menu_item.dart';

class MenuService {
  // Lấy danh sách Category
  Future<List<Category>> getCategories() async {
    final url = Uri.parse(ApiConfig.baseUrl + ApiConfig.getCategories);
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Category.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching categories: $e");
      return [];
    }
  }

  // Lấy danh sách Món ăn (có thể lọc theo categoryId)
  Future<List<MenuItem>> getMenuItems({int? categoryId, String? searchTerm}) async {
    // Xây dựng URL có query parameters
    // Dùng StringBuffer để nối chuỗi hiệu quả hơn
    String query = "";
    if (categoryId != null) query += "categoryId=$categoryId&";
    if (searchTerm != null && searchTerm.isNotEmpty) query += "searchTerm=$searchTerm";
    
    // Nếu có query thì thêm dấu ? vào trước, nếu không thì thôi
    final fullUrlString = "${ApiConfig.baseUrl}${ApiConfig.getMenu}${query.isNotEmpty ? '?$query' : ''}";
    final url = Uri.parse(fullUrlString);
    
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => MenuItem.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      print("Error fetching menu: $e");
      return [];
    }
  }
}