/**
 * BUG FIX: Xử lý trùng lặp sản phẩm trong giỏ hàng
 * 
 * Vấn đề: Khi thêm cùng một sản phẩm với cùng options vào giỏ nhiều lần,
 *         nó tạo nhiều dòng riêng thay vì gộp số lượng.
 * 
 * Fix: So sánh options để gộp sản phẩm y hệt
 */

import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProviderFixed with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get tax {
    return subtotal * 0.05;
  }

  double get totalAmount {
    return subtotal + tax;
  }

  int get itemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // FIX: So sánh hai list options có giống nhau không
  bool _optionsEqual(List<String> options1, List<String> options2) {
    if (options1.length != options2.length) return false;
    
    // Sort trước khi so sánh để tránh thứ tự khác nhau gây lỗi
    final sorted1 = List.from(options1)..sort();
    final sorted2 = List.from(options2)..sort();
    
    for (int i = 0; i < sorted1.length; i++) {
      if (sorted1[i] != sorted2[i]) return false;
    }
    return true;
  }

  // FIX: Thêm hàm tìm sản phẩm trùng lặp
  bool _itemExists(MenuItem menuItem, List<String> options) {
    return _items.any((item) =>
        item.menuItem.id == menuItem.id &&
        _optionsEqual(item.selectedOptions, options));
  }

  void addItem(
    MenuItem menuItem,
    int quantity,
    List<String> options,
    double priceWithOptions, {
    String? otherNote,
  }) {
    // FIX: Kiểm tra xem sản phẩm này đã tồn tại chưa
    final existingIndex = _items.indexWhere((item) =>
        item.menuItem.id == menuItem.id &&
        _optionsEqual(item.selectedOptions, options));

    if (existingIndex >= 0) {
      // Nếu tồn tại, chỉ tăng số lượng
      _items[existingIndex].quantity += quantity;
    } else {
      // Nếu không tồn tại, thêm mới
      _items.add(CartItem(
        id: DateTime.now().toString(),
        menuItem: menuItem,
        quantity: quantity,
        selectedOptions: options,
        otherNote: otherNote,
        pricePerItem: priceWithOptions,
      ));
    }
    notifyListeners();
  }

  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, int change) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _items[index].quantity += change;
      if (_items[index].quantity <= 0) {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
