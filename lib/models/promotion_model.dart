class PromotionRequirement {
  final int itemId;
  final int qty;

  PromotionRequirement({required this.itemId, required this.qty});

  factory PromotionRequirement.fromJson(Map<String, dynamic> json) {
    return PromotionRequirement(
      itemId: (json['itemId'] ?? json['ItemId'] ?? 0) as int,
      qty: (json['qty'] ?? json['Qty'] ?? 0) as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'qty': qty,
      };
}

class PromotionModel {
  final int promotionId;
  final String code;
  final String description;
  final String type;
  final num discountPercentage;
  final num? discountAmount;
  final num? minOrderAmount;
  final num? maxDiscountAmount;
  final int? buyItemId;
  final int? buyQuantity;
  final int? getItemId;
  final int? getQuantity;
  final List<PromotionRequirement> comboRequirements;
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;

  PromotionModel({
    required this.promotionId,
    required this.code,
    required this.description,
    required this.type,
    required this.discountPercentage,
    required this.discountAmount,
    required this.minOrderAmount,
    required this.maxDiscountAmount,
    required this.buyItemId,
    required this.buyQuantity,
    required this.getItemId,
    required this.getQuantity,
    required this.comboRequirements,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  factory PromotionModel.fromJson(Map<String, dynamic> json) {
    final reqs = (json['comboRequirements'] ?? json['ComboRequirements']);
    final List<dynamic> rawReqs = reqs is List ? reqs : <dynamic>[];

    return PromotionModel(
      promotionId: (json['promotionId'] ?? json['PromotionId'] ?? 0) as int,
      code: (json['code'] ?? json['Code'] ?? '').toString(),
      description: (json['description'] ?? json['Description'] ?? '').toString(),
      type: (json['type'] ?? json['Type'] ?? '').toString(),
      discountPercentage: (json['discountPercentage'] ?? json['DiscountPercentage'] ?? 0) as num,
      discountAmount: json['discountAmount'] ?? json['DiscountAmount'],
      minOrderAmount: json['minOrderAmount'] ?? json['MinOrderAmount'],
      maxDiscountAmount: json['maxDiscountAmount'] ?? json['MaxDiscountAmount'],
      buyItemId: json['buyItemId'] ?? json['BuyItemId'],
      buyQuantity: json['buyQuantity'] ?? json['BuyQuantity'],
      getItemId: json['getItemId'] ?? json['GetItemId'],
      getQuantity: json['getQuantity'] ?? json['GetQuantity'],
      comboRequirements: rawReqs
          .whereType<Map<String, dynamic>>()
          .map(PromotionRequirement.fromJson)
          .toList(),
      startDate: DateTime.parse((json['startDate'] ?? json['StartDate']).toString()),
      endDate: DateTime.parse((json['endDate'] ?? json['EndDate']).toString()),
      isActive: (json['isActive'] ?? json['IsActive'] ?? false) as bool,
    );
  }
}

class CartLineDto {
  final int menuItemId;
  final int quantity;

  CartLineDto({required this.menuItemId, required this.quantity});

  Map<String, dynamic> toJson() => {
        'menuItemId': menuItemId,
        'quantity': quantity,
      };
}

class ApplyPromotionResult {
  final bool isValid;
  final bool canApply;
  final String message;
  final num originalTotal;
  final num discountAmount;
  final num finalTotal;
  final List<CartLineDto> itemsToAdd;
  final PromotionModel? promotion;

  ApplyPromotionResult({
    required this.isValid,
    required this.canApply,
    required this.message,
    required this.originalTotal,
    required this.discountAmount,
    required this.finalTotal,
    required this.itemsToAdd,
    required this.promotion,
  });

  factory ApplyPromotionResult.fromJson(Map<String, dynamic> json) {
    final rawItems = (json['itemsToAdd'] ?? json['ItemsToAdd']);
    final List<dynamic> items = rawItems is List ? rawItems : <dynamic>[];

    return ApplyPromotionResult(
      isValid: (json['isValid'] ?? json['IsValid'] ?? false) as bool,
      canApply: (json['canApply'] ?? json['CanApply'] ?? false) as bool,
      message: (json['message'] ?? json['Message'] ?? '').toString(),
      originalTotal: (json['originalTotal'] ?? json['OriginalTotal'] ?? 0) as num,
      discountAmount: (json['discountAmount'] ?? json['DiscountAmount'] ?? 0) as num,
      finalTotal: (json['finalTotal'] ?? json['FinalTotal'] ?? 0) as num,
      itemsToAdd: items
          .whereType<Map<String, dynamic>>()
          .map(
            (e) => CartLineDto(
              menuItemId: (e['menuItemId'] ?? e['MenuItemId'] ?? 0) as int,
              quantity: (e['quantity'] ?? e['Quantity'] ?? 0) as int,
            ),
          )
          .toList(),
      promotion: (json['promotion'] ?? json['Promotion']) is Map<String, dynamic>
          ? PromotionModel.fromJson((json['promotion'] ?? json['Promotion']) as Map<String, dynamic>)
          : null,
    );
  }
}
