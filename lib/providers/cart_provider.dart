import 'package:flutter/material.dart';
import '../models/cart_item.dart';
import '../models/menu_item.dart';

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];

  String? _promotionCode;
  double _promotionDiscount = 0.0;

  static const double _vatRate = 0.10;

  List<CartItem> get items => _items;

  String? get promotionCode => _promotionCode;
  double get promotionDiscount => _promotionDiscount;

  // Tổng thanh toán (giá món đã bao gồm VAT 10%)
  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  // Tổng thanh toán sau khi áp voucher (giá đã gồm VAT)
  double get finalTotal {
    final total = totalAmount;
    final discounted = total - _promotionDiscount;
    return discounted < 0 ? 0.0 : discounted;
  }

  // Tạm tính (giá trước VAT)
  double get subtotal {
    final total = finalTotal;
    if (total <= 0) return 0.0;
    return (total / (1 + _vatRate)).roundToDouble();
  }

  // Thuế VAT (đã nằm trong totalAmount)
  double get tax {
    final total = finalTotal;
    if (total <= 0) return 0.0;
    return total - subtotal;
  }

  void setPromotion({String? code, required double discount}) {
    final normalized = (code ?? '').trim();
    _promotionCode = normalized.isEmpty ? null : normalized;
    _promotionDiscount = discount < 0 ? 0.0 : discount;
    notifyListeners();
  }

  void clearPromotion() {
    _promotionCode = null;
    _promotionDiscount = 0.0;
    notifyListeners();
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
    _promotionCode = null;
    _promotionDiscount = 0.0;
    notifyListeners();
  }
}
