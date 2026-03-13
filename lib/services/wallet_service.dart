import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../services/auth_service.dart';
import '../models/transaction_model.dart';

class WalletService {
  final AuthService _authService = AuthService();

  // Lấy số dư ví
  Future<double> getBalance() async {
    try {
      final token = await _authService.getToken();
      
      if (token == null) {
        print('Error: Token not found');
        return 0.0;
      }

      // --- ĐÃ FIX: Xóa '/api' thừa ---
      final url = Uri.parse('${ApiConfig.baseUrl}/wallet'); 
      // -------------------------------
      
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // Parse an toàn hơn cho cả int và double
        return (data['balance'] is int) 
            ? (data['balance'] as int).toDouble() 
            : (data['balance'] as double);
      } else {
        print('Error getting wallet: ${response.statusCode} - ${response.body}');
        return 0.0;
      }
    } catch (e) {
      print('Exception getting wallet: $e');
      return 0.0;
    }
  }

  Future<List<TransactionModel>> getTransactionHistory() async {
    try {
      final token = await _authService.getToken();
      if (token == null) return [];

      // --- ĐÃ FIX: Xóa '/api' thừa ---
      final url = Uri.parse('${ApiConfig.baseUrl}/wallet/history');
      // -------------------------------

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => TransactionModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error getting history: $e');
      return [];
    }
  }
}