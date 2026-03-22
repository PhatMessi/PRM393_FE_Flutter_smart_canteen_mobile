class MenuItemCustomization {
  final List<MenuItemOptionGroup> optionGroups;

  MenuItemCustomization({required this.optionGroups});

  factory MenuItemCustomization.fromJson(Map<String, dynamic> json) {
    final raw = json['optionGroups'] ?? json['OptionGroups'];
    final groups = <MenuItemOptionGroup>[];

    if (raw is List) {
      for (final g in raw) {
        if (g is Map<String, dynamic>) {
          groups.add(MenuItemOptionGroup.fromJson(g));
        } else if (g is Map) {
          groups.add(MenuItemOptionGroup.fromJson(Map<String, dynamic>.from(g)));
        }
      }
    }

    return MenuItemCustomization(optionGroups: groups);
  }
}

class MenuItemOptionGroup {
  final int optionGroupId;
  final String key;
  final String title;
  final bool isRequired;
  final bool isMultiple;
  final int? maxSelections;
  final int sortOrder;
  final List<MenuItemOption> options;

  MenuItemOptionGroup({
    required this.optionGroupId,
    required this.key,
    required this.title,
    required this.isRequired,
    required this.isMultiple,
    required this.maxSelections,
    required this.sortOrder,
    required this.options,
  });

  factory MenuItemOptionGroup.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] ?? json['Options'];
    final options = <MenuItemOption>[];
    if (rawOptions is List) {
      for (final o in rawOptions) {
        if (o is Map<String, dynamic>) {
          options.add(MenuItemOption.fromJson(o));
        } else if (o is Map) {
          options.add(MenuItemOption.fromJson(Map<String, dynamic>.from(o)));
        }
      }
    }

    return MenuItemOptionGroup(
      optionGroupId: (json['optionGroupId'] ?? json['OptionGroupId'] ?? 0) as int,
      key: (json['key'] ?? json['Key'] ?? '').toString(),
      title: (json['title'] ?? json['Title'] ?? '').toString(),
      isRequired: (json['isRequired'] ?? json['IsRequired'] ?? false) == true,
      isMultiple: (json['isMultiple'] ?? json['IsMultiple'] ?? false) == true,
      maxSelections: (json['maxSelections'] ?? json['MaxSelections']) as int?,
      sortOrder: (json['sortOrder'] ?? json['SortOrder'] ?? 0) as int,
      options: options,
    );
  }
}

class MenuItemOption {
  final int optionId;
  final String name;
  final double priceDelta;
  final bool isAvailable;
  final int sortOrder;

  MenuItemOption({
    required this.optionId,
    required this.name,
    required this.priceDelta,
    required this.isAvailable,
    required this.sortOrder,
  });

  factory MenuItemOption.fromJson(Map<String, dynamic> json) {
    final priceRaw = json['priceDelta'] ?? json['PriceDelta'] ?? 0;
    final price = (priceRaw is num)
        ? priceRaw.toDouble()
        : double.tryParse(priceRaw.toString()) ?? 0.0;

    return MenuItemOption(
      optionId: (json['optionId'] ?? json['OptionId'] ?? 0) as int,
      name: (json['name'] ?? json['Name'] ?? '').toString(),
      priceDelta: price,
      isAvailable: (json['isAvailable'] ?? json['IsAvailable'] ?? true) == true,
      sortOrder: (json['sortOrder'] ?? json['SortOrder'] ?? 0) as int,
    );
  }
}
