class OrderModel {
  final int orderId;
  final DateTime orderDate;
  final DateTime? pickupTime; // Có thể null
  final double totalPrice;
  final String status; // Pending, Ready, Completed, Rejected
  final String? rejectionReason; // Lý do từ chối
  final List<OrderItemModel> orderItems;

  OrderModel({
    required this.orderId,
    required this.orderDate,
    this.pickupTime,
    required this.totalPrice,
    required this.status,
    this.rejectionReason,
    required this.orderItems,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderId: json['orderId'],
      orderDate: DateTime.parse(json['orderDate']),
      pickupTime: json['pickupTime'] != null ? DateTime.parse(json['pickupTime']) : null,
      totalPrice: (json['totalPrice'] as num).toDouble(),
      status: json['status'],
      rejectionReason: json['rejectionReason'],
      orderItems: (json['orderItems'] as List)
          .map((item) => OrderItemModel.fromJson(item))
          .toList(),
    );
  }
}

class OrderItemModel {
  final int id;
  final String menuItemName; // Tên món
  final String? imageUrl; // Ảnh món
  final int quantity;
  final double price;
  final String? note; // Ghi chú (No Spicy...)

  OrderItemModel({
    required this.id,
    required this.menuItemName,
    this.imageUrl,
    required this.quantity,
    required this.price,
    this.note,
  });

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    // Lưu ý: Key ở đây phải khớp với JSON trả về từ Backend của bạn
    // Nếu OrderItem backend trả về object MenuItem lồng bên trong thì phải sửa đoạn này.
    // Code dưới đây giả định OrderItem DTO đã phẳng hóa thông tin món ăn.
    return OrderItemModel(
      id: json['id'] ?? 0, // Fallback nếu null
      menuItemName: json['menuItemName'] ?? json['menuItem']?['name'] ?? "Unknown Item",
      imageUrl: json['imageUrl'] ?? json['menuItem']?['imageUrl'],
      quantity: json['quantity'] ?? 1,
      price: (json['price'] as num).toDouble(),
      note: json['note'],
    );
  }
}