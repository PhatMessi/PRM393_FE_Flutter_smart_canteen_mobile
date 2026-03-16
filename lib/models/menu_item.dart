class MenuItem {
  final int itemId;
  final String name;
  final String? description;
  final double price;
  final String? imageUrl;
  final int categoryId;
<<<<<<< HEAD
  final String?
  categoryName; // Backend có thể trả về hoặc không, xử lý null an toàn
=======
  final String? categoryName; // Backend có thể trả về hoặc không, xử lý null an toàn
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8

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
<<<<<<< HEAD

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'categoryName': categoryName,
    };
  }
=======
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
}

class Category {
  final int categoryId;
  final String name;

  Category({required this.categoryId, required this.name});

  factory Category.fromJson(Map<String, dynamic> json) {
    // [FIX] Ưu tiên đọc 'CategoryName' vì đó là tên trường trong DB/API
    // Nếu không có mới thử đọc 'name' hoặc 'Name'
    return Category(
      categoryId: json['categoryId'] ?? json['CategoryId'] ?? 0,
<<<<<<< HEAD
      name:
          json['CategoryName'] ??
          json['categoryName'] ??
          json['name'] ??
          json['Name'] ??
          'Unknown',
    );
  }
}
=======
      name: json['CategoryName'] ?? json['categoryName'] ?? json['name'] ?? json['Name'] ?? 'Unknown',
    );
  }
}
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
