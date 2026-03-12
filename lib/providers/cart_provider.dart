import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  // Tính tổng tiền hàng (chưa thuế)
  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Tính thuế 5% như trong hình
  double get tax {
    return subtotal * 0.05;
  }

  // Tổng thanh toán
  double get totalAmount {
    return subtotal + tax;
  }

  int get itemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Thêm món vào giỏ
  void addItem(
    MenuItem menuItem,
    int quantity,
    List<String> options,
    double priceWithOptions, {
    String? otherNote,
  }) {
    // Kiểm tra xem món này với các options y hệt đã có trong giỏ chưa
    // Nếu muốn đơn giản: Luôn thêm mới. Nếu muốn gộp: Phải so sánh list options.
    // Ở đây tôi làm cách đơn giản: Luôn thêm dòng mới để dễ quản lý topping.
    
    _items.add(CartItem(
      id: DateTime.now().toString(), // Tạo ID tạm thời
      menuItem: menuItem,
      quantity: quantity,
      selectedOptions: options,
      otherNote: otherNote,
      pricePerItem: priceWithOptions,
    ));
    notifyListeners();
  }

  // Xóa hẳn 1 món
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  // Tăng giảm số lượng
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

  // Xóa sạch giỏ hàng (sau khi checkout)
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}