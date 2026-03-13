import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../models/notification_model.dart';
import '../services/auth_service.dart';

class NotificationService {
  final AuthService _authService = AuthService();

  Future<Map<String, String>> _authHeaders() async {
    final token = await _authService.getToken();
    if (token == null) {
      throw Exception('User not logged in');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  List<NotificationModel> _parseNotificationList(dynamic data) {
    if (data is List) {
      return data
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    // Some backends wrap in { items: [...] }
    final items = (data is Map<String, dynamic>)
        ? (data['items'] ?? data['Items'])
        : null;
    if (items is List) {
      return items
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    return [];
  }

  Future<List<NotificationModel>> getAllNotifications() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/notifications/all');
    final response = await http.get(url, headers: await _authHeaders());

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: please log in again');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load notifications: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    return _parseNotificationList(data);
  }

  Future<List<NotificationModel>> getUnreadNotifications() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/notifications/unread');
    final response = await http.get(url, headers: await _authHeaders());

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: please log in again');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load unread notifications: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    return _parseNotificationList(data);
  }

  Future<int> getUnreadCount() async {
    final url = Uri.parse('${ApiConfig.baseUrl}/notifications/unread/count');
    final response = await http.get(url, headers: await _authHeaders());

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: please log in again');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load unread notification count: ${response.statusCode} ${response.body}',
      );
    }

    final data = jsonDecode(response.body);
    if (data is Map<String, dynamic>) {
      final count = data['count'] ?? data['Count'];
      if (count is int) return count;
      return int.tryParse(count?.toString() ?? '') ?? 0;
    }
    return 0;
  }

  Future<void> markAllAsRead() async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/notifications/mark-all-as-read',
    );
    final response = await http.post(url, headers: await _authHeaders());

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw Exception('Unauthorized: please log in again');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to mark notifications as read: ${response.statusCode} ${response.body}',
      );
    }
  }
}
