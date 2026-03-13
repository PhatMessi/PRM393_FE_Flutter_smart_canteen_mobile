import 'menu_item.dart';

class CartItem {
  final String id; // ID riêng cho dòng này trong giỏ (để phân biệt cùng 1 món nhưng khác topping)
  final MenuItem menuItem;
  int quantity;
  final List<String> selectedOptions; // Lưu tên sốt và các món thêm (VD: "Spicy Mayo", "Extra Cheese")
  final String? otherNote; // Ghi chú tự do người dùng nhập ở phần Other
  final double pricePerItem; // Giá của 1 item bao gồm cả extras

  CartItem({
    required this.id,
    required this.menuItem,
    required this.quantity,
    required this.selectedOptions,
    this.otherNote,
    required this.pricePerItem,
  });

  double get totalPrice => pricePerItem * quantity;

  String? get orderItemNote {
    final parts = <String>[];
    if (selectedOptions.isNotEmpty) {
      parts.add("Options: ${selectedOptions.join(', ')}");
    }

    final cleanOther = otherNote?.trim();
    if (cleanOther != null && cleanOther.isNotEmpty) {
      parts.add("Other: $cleanOther");
    }

    if (parts.isEmpty) return null;
    return parts.join(' | ');
  }
}