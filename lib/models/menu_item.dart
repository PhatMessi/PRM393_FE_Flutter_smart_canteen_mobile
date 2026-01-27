class MenuItem {
  final int itemId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final int categoryId;
  final String? categoryName; // Backend có thể trả về hoặc không, xử lý null an toàn

  MenuItem({
    required this.itemId,
    required this.name,
    this.description,
    required this.price,
    this.imageUrl,
    required this.categoryId,
    this.categoryName,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      itemId: json['itemId'] ?? json['ItemId'] ?? 0,
      name: json['name'] ?? json['Name'] ?? 'Unknown',
      description: json['description'] ?? json['Description'],
      // Xử lý chuyển đổi sang double an toàn
      price: (json['price'] ?? json['Price'] ?? 0).toDouble(),
      imageUrl: json['imageUrl'] ?? json['ImageUrl'],
      categoryId: json['categoryId'] ?? json['CategoryId'] ?? 0,
      categoryName: json['categoryName'] ?? json['CategoryName'],
    );
  }
}

class Category {
  final int categoryId;
  final String name;

  Category({required this.categoryId, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      categoryId: json['categoryId'] ?? json['CategoryId'] ?? 0,
      name: json['name'] ?? json['Name'] ?? 'All',
    );
  }
}