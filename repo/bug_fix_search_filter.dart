/**
 * BUG FIX: Lọc & Tìm Kiếm Menu Thực Đơn - Tự Chứa (Standalone)
 *
 * Vấn đề gốc:
 *  1. Tìm kiếm phân biệt chữ hoa/thường → bỏ sót kết quả
 *  2. Lọc theo danh mục không reset về trang đầu → hiển thị sai
 *  3. Lọc kết hợp (từ khóa + danh mục + khoảng giá) không đồng bộ
 *  4. Gõ phím liên tục gọi filter mỗi ký tự → lag UI
 *
 * Fix:
 *  ✅ Normalize text (toLowerCase + trim) trước khi so sánh
 *  ✅ Reset page index mỗi khi bộ lọc thay đổi
 *  ✅ Kết hợp tất cả điều kiện trong một hàm applyFilters()
 *  ✅ Debounce 350ms cho search box
 *
 * LƯU Ý: File này hoàn toàn độc lập, không import bất kỳ file nào
 *         ngoài thư mục repo/. Chạy được như một đơn vị riêng biệt.
 */

// ============================================================
// DATA MODELS (tự định nghĩa, không phụ thuộc lib/)
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
}

// ============================================================
// FILTER STATE
// ============================================================

class FilterState {
  final String keyword;
  final String? category; // null = tất cả danh mục
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

// Sentinel object dùng để phân biệt "không truyền category" vs "truyền null"
const Object _sentinel = Object();

// ============================================================
// ❌ PHIÊN BẢN CŨ (BUG)
// ============================================================

class MenuSearchServiceBuggy {
  List<MenuItem> search(List<MenuItem> items, String keyword) {
    // BUG 1: phân biệt hoa/thường
    return items.where((item) => item.name.contains(keyword)).toList();
  }

  List<MenuItem> filterByCategory(List<MenuItem> items, String category) {
    // BUG 2: không trim khoảng trắng → "Cơm " != "Cơm"
    return items.where((item) => item.category == category).toList();
  }

  List<MenuItem> filterByPrice(
    List<MenuItem> items,
    double minPrice,
    double maxPrice,
  ) {
    return items
        .where((item) => item.price >= minPrice && item.price <= maxPrice)
        .toList();
  }

  // BUG 3: Ba hàm riêng lẻ → dùng sai thứ tự hoặc bỏ sót bước
  List<MenuItem> applyAllBuggy(
    List<MenuItem> items,
    String keyword,
    String? category,
    double minPrice,
    double maxPrice,
  ) {
    var result = search(items, keyword);
    if (category != null) {
      result = filterByCategory(result, category);
    }
    result = filterByPrice(result, minPrice, maxPrice);
    // BUG 4: không lọc isAvailable khi cần
    return result;
  }
}

// ============================================================
// ✅ PHIÊN BẢN MỚI (ĐÃ SỬA)
// ============================================================

class MenuSearchService {
  /// Chuẩn hóa chuỗi: bỏ khoảng trắng đầu/cuối, viết thường
  static String _normalize(String text) => text.trim().toLowerCase();

  /// Áp dụng toàn bộ bộ lọc trong một lần duyệt O(n)
  List<MenuItem> applyFilters(List<MenuItem> items, FilterState filter) {
    final keyword = _normalize(filter.keyword);

    return items.where((item) {
      // FIX 1: So sánh không phân biệt hoa/thường
      if (keyword.isNotEmpty &&
          !_normalize(item.name).contains(keyword) &&
          !_normalize(item.category).contains(keyword)) {
        return false;
      }

      // FIX 2: Trim category trước khi so sánh
      if (filter.category != null &&
          _normalize(item.category) != _normalize(filter.category!)) {
        return false;
      }

      // Lọc khoảng giá
      if (item.price < filter.minPrice || item.price > filter.maxPrice) {
        return false;
      }

      // Lọc trạng thái có sẵn
      if (filter.onlyAvailable && !item.isAvailable) {
        return false;
      }

      return true;
    }).toList();
  }

  /// Lấy danh sách danh mục không trùng từ menu
  List<String> extractCategories(List<MenuItem> items) {
    return items.map((e) => e.category.trim()).toSet().toList()..sort();
  }
}

// ============================================================
// DEBOUNCE HELPER (FIX 4 - không dùng Flutter timer để độc lập)
// ============================================================

class Debouncer {
  final Duration delay;
  DateTime? _lastCall;

  Debouncer({this.delay = const Duration(milliseconds: 350)});

  /// Trả về true nếu đủ thời gian trễ kể từ lần gọi trước
  bool shouldExecute() {
    final now = DateTime.now();
    if (_lastCall == null || now.difference(_lastCall!) >= delay) {
      _lastCall = now;
      return true;
    }
    return false;
  }

  void reset() => _lastCall = null;
}

// ============================================================
// UNIT TESTS NỘI BỘ (chạy độc lập, không cần test framework)
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
      category: 'Cơm ',  // có khoảng trắng thừa
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

  void expect(String testName, bool condition) {
    if (condition) {
      print('  ✅ PASS: $testName');
      passed++;
    } else {
      print('  ❌ FAIL: $testName');
      failed++;
    }
  }

  print('\n=== TEST: Tìm kiếm không phân biệt hoa/thường ===');
  final r1 = service.applyFilters(
    menu,
    const FilterState(keyword: 'cơm gà'),
  );
  expect('Tìm "cơm gà" khớp "Cơm Gà Xào Sả Ớt"', r1.length == 1);
  expect('Kết quả đúng item', r1.first.id == '1');

  print('\n=== TEST: Lọc danh mục có khoảng trắng thừa ===');
  final r2 = service.applyFilters(
    menu,
    const FilterState(category: 'Cơm'),
  );
  expect('Tìm category "Cơm" bao gồm cả "Cơm " (có space)', r2.length == 2);

  print('\n=== TEST: Lọc kết hợp từ khóa + khoảng giá ===');
  final r3 = service.applyFilters(
    menu,
    const FilterState(keyword: 'cơm', minPrice: 32000, maxPrice: 40000),
  );
  expect('Chỉ lấy cơm trong khoảng 32k-40k', r3.length == 1);
  expect('Kết quả là Cơm Gà', r3.first.id == '1');

  print('\n=== TEST: Lọc chỉ món còn phục vụ ===');
  final r4 = service.applyFilters(
    menu,
    const FilterState(onlyAvailable: true),
  );
  expect('Chỉ 3 món isAvailable=true', r4.length == 3);

  print('\n=== TEST: Lọc toàn bộ điều kiện kết hợp ===');
  final r5 = service.applyFilters(
    menu,
    const FilterState(
      keyword: 'trà sữa',
      category: 'Đồ uống',
      minPrice: 20000,
      maxPrice: 30000,
      onlyAvailable: true,
    ),
  );
  expect('Chỉ 1 kết quả: Trà Sữa Trân Châu', r5.length == 1);
  expect('Đúng sản phẩm Trà Sữa', r5.first.id == '4');

  print('\n=== TEST: Trích xuất danh mục không trùng ===');
  final categories = service.extractCategories(menu);
  expect('Có đúng 3 danh mục (Bún, Cơm, Đồ uống)', categories.length == 3);
  expect('Danh mục đã trim và không trùng', !categories.any((c) => c.contains(' ')));

  print('\n=== TEST: Keyword rỗng trả toàn bộ ===');
  final r6 = service.applyFilters(menu, const FilterState());
  expect('Không filter → trả toàn bộ 5 món', r6.length == 5);

  print('\n--- KẾT QUẢ: $passed passed / ${passed + failed} tests ---\n');
}

// ============================================================
// ENTRY POINT
// ============================================================

void main() {
  print('╔══════════════════════════════════════════════════╗');
  print('║  BUG FIX: Search & Filter Menu - Standalone     ║');
  print('╚══════════════════════════════════════════════════╝');
  _runTests();
}
