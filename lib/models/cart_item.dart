import 'menu_item.dart';

class CartItem {
  final String id; // ID riêng cho dòng này trong giỏ (để phân biệt cùng 1 món nhưng khác topping)
  final MenuItem menuItem;
  int quantity;
  final List<String> selectedOptions; // Lưu tên sốt và các món thêm (VD: "Spicy Mayo", "Extra Cheese")
  final double pricePerItem; // Giá của 1 item bao gồm cả extras

  CartItem({
    required this.id,
    required this.menuItem,
    required this.quantity,
    required this.selectedOptions,
    required this.pricePerItem,
  });

  double get totalPrice => pricePerItem * quantity;
}