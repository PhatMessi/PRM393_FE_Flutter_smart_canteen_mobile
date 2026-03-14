import 'dart:async';

// ============================================================
// DATA MODELS
// ============================================================

class MenuItem {
  final String id;
  final String name;
  final String category;
  final double price;
  final bool isAvailable;

  const MenuItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.isAvailable,
  });

  @override
  String toString() =>
      'MenuItem(id: $id, name: $name, category: $category, price: $price)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuItem &&
          id == other.id &&
          name == other.name &&
          category == other.category &&
          price == other.price &&
          isAvailable == other.isAvailable;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ category.hashCode ^ price.hashCode ^ isAvailable.hashCode;
}

// ============================================================
// FILTER STATE
// ============================================================

class FilterState {
  final String keyword;
  final String? category;
  final double minPrice;
  final double maxPrice;
  final bool onlyAvailable;

  const FilterState({
    this.keyword = '',
    this.category,
    this.minPrice = 0,
    this.maxPrice = double.infinity,
    this.onlyAvailable = false,
  });

  FilterState copyWith({
    String? keyword,
    Object? category = _sentinel,
    double? minPrice,
    double? maxPrice,
    bool? onlyAvailable,
  }) {
    return FilterState(
      keyword: keyword ?? this.keyword,
      category: category == _sentinel ? this.category : category as String?,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
    );
  }
}

const Object _sentinel = Object();

// ============================================================
// SEARCH SERVICE
// ============================================================

class MenuSearchService {
  static String _normalize(String text) => text.trim().toLowerCase();

  /// Predicate kiểm tra item có hợp filter không
  bool _matches(MenuItem item, _PreparedFilter f) {
    if (f.keyword.isNotEmpty &&
        !item._normalizedName.contains(f.keyword) &&
        !item._normalizedCategory.contains(f.keyword)) {
      return false;
    }

    if (f.category != null &&
        item._normalizedCategory != f.category) {
      return false;
    }

    if (item.price < f.minPrice || item.price > f.maxPrice) {
      return false;
    }

    if (f.onlyAvailable && !item.isAvailable) {
      return false;
    }

    return true;
  }

  /// Apply filters O(n)
  List<MenuItem> applyFilters(List<MenuItem> items, FilterState filter) {
    final prepared = _PreparedFilter.from(filter);

    return items.where((item) {
      final normalizedItem = item._withNormalized();
      return _matches(normalizedItem, prepared);
    }).toList();
  }

  /// Trả Iterable để dùng lazy nếu muốn
  Iterable<MenuItem> applyFiltersLazy(List<MenuItem> items, FilterState filter) {
    final prepared = _PreparedFilter.from(filter);

    return items.where((item) {
      final normalizedItem = item._withNormalized();
      return _matches(normalizedItem, prepared);
    });
  }

  /// Extract unique categories
  List<String> extractCategories(List<MenuItem> items) {
    final set = <String>{};

    for (final item in items) {
      set.add(item.category.trim());
    }

    final list = set.toList()..sort();
    return list;
  }
}

// ============================================================
// PREPARED FILTER (performance optimization)
// ============================================================

class _PreparedFilter {
  final String keyword;
  final String? category;
  final double minPrice;
  final double maxPrice;
  final bool onlyAvailable;

  _PreparedFilter({
    required this.keyword,
    required this.category,
    required this.minPrice,
    required this.maxPrice,
    required this.onlyAvailable,
  });

  factory _PreparedFilter.from(FilterState f) {
    return _PreparedFilter(
      keyword: f.keyword.trim().toLowerCase(),
      category: f.category?.trim().toLowerCase(),
      minPrice: f.minPrice,
      maxPrice: f.maxPrice,
      onlyAvailable: f.onlyAvailable,
    );
  }
}

// ============================================================
// NORMALIZED EXTENSION
// ============================================================

extension _NormalizedMenuItem on MenuItem {
  String get _normalizedName => name.trim().toLowerCase();
  String get _normalizedCategory => category.trim().toLowerCase();

  MenuItem _withNormalized() => this;
}

// ============================================================
// DEBOUNCER (production version)
// ============================================================

class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({this.delay = const Duration(milliseconds: 350)});

  void call(void Function() action) {
    _timer?.cancel();
    _timer = Timer(delay, action);
  }

  void dispose() {
    _timer?.cancel();
  }
}

// ============================================================
// TESTS
// ============================================================

void _runTests() {
  final service = MenuSearchService();

  final menu = [
    const MenuItem(
      id: '1',
      name: 'Cơm Gà Xào Sả Ớt',
      category: 'Cơm',
      price: 35000,
      isAvailable: true,
    ),
    const MenuItem(
      id: '2',
      name: 'cơm sườn bí đao',
      category: 'Cơm ',
      price: 30000,
      isAvailable: false,
    ),
    const MenuItem(
      id: '3',
      name: 'Bún Bò Huế',
      category: 'Bún',
      price: 45000,
      isAvailable: true,
    ),
    const MenuItem(
      id: '4',
      name: 'Trà Sữa Trân Châu',
      category: 'Đồ uống',
      price: 25000,
      isAvailable: true,
    ),
    const MenuItem(
      id: '5',
      name: 'Nước Cam Ép',
      category: 'Đồ uống',
      price: 20000,
      isAvailable: false,
    ),
  ];

  int passed = 0;
  int failed = 0;

  void expect(String name, bool cond) {
    if (cond) {
      print("✅ $name");
      passed++;
    } else {
      print("❌ $name");
      failed++;
    }
  }

  final r1 = service.applyFilters(menu, const FilterState(keyword: 'cơm gà'));
  expect("Search case-insensitive", r1.length == 1);

  final r2 = service.applyFilters(menu, const FilterState(category: 'Cơm'));
  expect("Category trim", r2.length == 2);

  final r3 = service.applyFilters(
      menu, const FilterState(keyword: 'cơm', minPrice: 32000, maxPrice: 40000));
  expect("Price filter", r3.length == 1);

  final r4 =
      service.applyFilters(menu, const FilterState(onlyAvailable: true));
  expect("Available filter", r4.length == 3);

  final r5 = service.applyFilters(
      menu,
      const FilterState(
        keyword: 'trà sữa',
        category: 'Đồ uống',
        minPrice: 20000,
        maxPrice: 30000,
        onlyAvailable: true,
      ));

  expect("Combined filters", r5.length == 1);

  print("\nRESULT: $passed passed / ${passed + failed}");
}

// ============================================================
// ENTRY
// ============================================================

void main() {
  print("Menu Search Service Test");
  _runTests();
}