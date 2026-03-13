import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();
  
  List<OrderModel> _allOrders = [];
  bool _isLoading = false;
  String? _error;

  List<OrderModel> get orders => _allOrders;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Hàm lấy danh sách đơn hàng
  Future<void> loadMyOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _allOrders = await _orderService.fetchMyOrders();
      // Sắp xếp đơn mới nhất lên đầu
      _allOrders.sort((a, b) => b.orderDate.compareTo(a.orderDate));
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Hàm lọc danh sách theo Tab
  List<OrderModel> getOrdersByStatus(String tab) {
    if (tab == "Tat ca") return _allOrders;
    
    if (tab == "Cho xu ly") {
      // Backend statuses: "Pending Payment", "Paid"
      return _allOrders
          .where((o) => o.status == "Pending Payment" || o.status == "Paid")
          .toList();
    }
    
    if (tab == "San sang") {
      // Backend statuses: "Preparing", "Ready for Pickup"
      return _allOrders
          .where((o) => o.status == "Preparing" || o.status == "Ready for Pickup")
          .toList();
    }
    
    if (tab == "Lich su") {
      // Requirement: only completed orders appear in History.
      return _allOrders.where((o) => o.status == "Completed").toList();
    }
    
    return [];
  }
}