class OrderModel {
  final int orderId;
  final DateTime orderDate;
  final DateTime? pickupTime; // Có thể null
  final double totalPrice;
  final String status; // Pending, Ready, Completed, Rejected
  final String? kitchenStatus; // Pending, Cooking, Complete (cho role bếp)
  final String? rejectionReason; // Lý do từ chối
  final List<OrderItemModel> orderItems;

  OrderModel({
    required this.orderId,
    required this.orderDate,
    this.pickupTime,
    required this.totalPrice,
    required this.status,
    this.kitchenStatus,
    this.rejectionReason,
    required this.orderItems,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final orderIdRaw = json['orderId'] ?? json['OrderId'] ?? 0;
    final orderDateRaw = json['orderDate'] ?? json['OrderDate'];
    final pickupTimeRaw = json['pickupTime'] ?? json['PickupTime'];
    final totalPriceRaw = json['totalPrice'] ?? json['TotalPrice'] ?? 0;
    final statusRaw = json['status'] ?? json['Status'] ?? '';
    final kitchenStatusRaw =
      json['kitchenStatus'] ?? json['KitchenStatus'];
    final rejectionReasonRaw = json['rejectionReason'] ?? json['RejectionReason'];
    final orderItemsRaw = json['orderItems'] ?? json['OrderItems'] ?? const [];

    return OrderModel(
      orderId: orderIdRaw is int ? orderIdRaw : int.tryParse(orderIdRaw.toString()) ?? 0,
      orderDate: DateTime.parse(orderDateRaw?.toString() ?? DateTime.now().toIso8601String()),
      pickupTime: pickupTimeRaw != null ? DateTime.tryParse(pickupTimeRaw.toString()) : null,
      totalPrice: (totalPriceRaw as num).toDouble(),
      status: statusRaw.toString(),
      kitchenStatus: kitchenStatusRaw?.toString(),
      rejectionReason: rejectionReasonRaw?.toString(),
      orderItems: (orderItemsRaw is List ? orderItemsRaw : const [])
          .map((item) => OrderItemModel.fromJson(item as Map<String, dynamic>))
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
    final idRaw = json['id'] ?? json['orderItemId'] ?? json['OrderItemId'] ?? 0;
    final quantityRaw = json['quantity'] ?? json['Quantity'] ?? 1;
    final priceRaw =
        json['price'] ?? json['Price'] ?? json['priceAtTimeOfOrder'] ?? json['PriceAtTimeOfOrder'] ?? 0;
    final menuItem = (json['menuItem'] ?? json['MenuItem']) as Map<String, dynamic>?;

    return OrderItemModel(
      id: idRaw is int ? idRaw : int.tryParse(idRaw.toString()) ?? 0,
      menuItemName: (json['menuItemName'] ?? json['MenuItemName'] ?? menuItem?['name'] ?? menuItem?['Name'] ?? 'Unknown Item')
          .toString(),
      imageUrl: (json['imageUrl'] ?? json['ImageUrl'] ?? menuItem?['imageUrl'] ?? menuItem?['ImageUrl'])?.toString(),
      quantity: quantityRaw is int ? quantityRaw : int.tryParse(quantityRaw.toString()) ?? 1,
      price: (priceRaw as num).toDouble(),
      note: (json['note'] ?? json['Note'])?.toString(),
    );
  }
}