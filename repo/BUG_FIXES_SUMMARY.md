# BUG FIXES SUMMARY - Smart Canteen Mobile App

## Tổng quan

Tài liệu này tổng hợp chức năng của tất cả file hiện có trong thư mục `repo/`.
Mục tiêu giúp review nhanh:

* File nào đang sửa bug gì
* Có thể tái sử dụng ở đâu
* Mức độ phụ thuộc với code chính

**Last Updated:** March 16, 2026
**Project:** PRM393 - Smart Canteen Mobile App (Flutter)

---

# 📂 Danh sách File Fix Bug

## 1️⃣ Cart Duplicate Items

**File:** `bug_fix_cart_duplicate_items.dart`

### Vấn đề

Khi thêm cùng một món ăn với cùng options nhiều lần, giỏ hàng tạo **nhiều dòng item trùng nhau**.

### Giải pháp

* So sánh options bằng `_optionsEqual()`
* Sort options để tránh sai do thứ tự
* Nếu item đã tồn tại → tăng `quantity`
* Nếu chưa → tạo item mới

### Lợi ích

* Giỏ hàng gọn gàng
* Tổng giá chính xác
* UX tốt hơn

### Phụ thuộc

* `CartItem`
* `MenuItem`
* `ChangeNotifier`

---

## 2️⃣ Auth Token Expiry Handling

**File:** `bug_fix_auth_token_expiry.dart`

### Vấn đề

Token hết hạn nhưng app vẫn dùng → user bị **stuck login**.

### Giải pháp

* Lưu thời điểm hết hạn `_tokenExpireKey`
* Kiểm tra `isTokenValid()` trước khi trả token
* Khi gặp `401` → `clearToken()`
* Thêm timeout request
* Parse JSON an toàn

### Lợi ích

* Tránh lỗi đăng nhập treo
* Auth flow ổn định
* Debug dễ hơn

### Phụ thuộc

* `ApiConfig`
* `User`
* `http`
* `shared_preferences`

---

## 3️⃣ Order Service Retry

**File:** `bug_fix_order_service_retry.dart`

### Vấn đề

Request lấy danh sách order dễ fail khi mạng yếu.

### Giải pháp

* Timeout request: **15s**
* Retry tối đa **3 lần**
* Cache kết quả thành công
* Fallback sang cache khi offline

### Lợi ích

* App vẫn hiển thị dữ liệu khi mạng yếu
* UX ổn định hơn

### Phụ thuộc

* `ApiConfig`
* `OrderModel`
* `AuthService`
* `http`
* `shared_preferences`

---

## 4️⃣ Input Validation

**File:** `bug_fix_input_validation.dart`

### Vấn đề

Form đăng nhập không validate input.

### Root Cause

```dart
Future<bool> login(String email, String password) async {
  final result = await _authService.login(email, password);
}
```

### Giải pháp

#### Validate email

```dart
String? validateEmail(String email) {
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  if (!emailRegex.hasMatch(email)) {
    return 'Email không hợp lệ';
  }
  return null;
}
```

#### Validate password

```dart
String? validatePassword(String password, {bool isLogin = true}) {
  if (password.length < 6) return 'Phải ít nhất 6 ký tự';
  if (!isLogin) {
    if (!password.contains(RegExp(r'[A-Z]')))
      return 'Phải chứa chữ hoa';
  }
  return null;
}
```

#### Store lỗi từng field

```dart
Map<String, String?> _fieldErrors = {};

void setFieldError(String fieldName, String? error) {
  _fieldErrors[fieldName] = error;
  notifyListeners();
}
```

### Lợi ích

* Validation trước khi call API
* Hiển thị lỗi rõ ràng
* UX tốt hơn

---

## 5️⃣ Search & Filter Service

**File:** `bug_fix_search_filter.dart`

### Chức năng

* Tìm kiếm menu theo keyword
* Filter theo category
* Filter theo khoảng giá
* Chỉ lấy món còn hàng

### Tính năng

* Chuẩn hóa text (`trim + lowercase`)
* `Debouncer` để giảm spam search
* `applyFiltersLazy()` cho performance
* Mini test trong `main()`

### Phụ thuộc

File **độc lập hoàn toàn**

---

## 6️⃣ Safe Percentage Calculation

**File:** `bug_fix_percentage_calculation.dart`

### Vấn đề

Tính phần trăm có thể gây:

* `NaN`
* `Infinity`
* chia cho 0

### Giải pháp

```dart
double safePercentage(double part, double total) {
  if (total <= 0) return 0.0;
}
```

### Tính năng

* Clamp `part` trong `[0, total]`
* Làm tròn số thập phân
* Self-test trong `main()`

### Phụ thuộc

Không phụ thuộc project.

---

## 7️⃣ UI Image Helper

**File:** `canteen_ui.dart`

### Chức năng

Helper hiển thị hình ảnh món ăn an toàn.

### Tính năng

* Convert path backend → URL
* Detect static images (`uploads`, `images`)
* Map demo URL → local assets
* Fallback icon khi lỗi ảnh

### Phụ thuộc

* `flutter/material.dart`
* `ApiConfig`

---

# 🖥 UI Overflow Fix

**File:** `bug_fix_ui_overflow.dart`

### Vấn đề

Flutter layout lỗi:

```
RenderFlex overflowed by XX pixels
```

### Nguyên nhân

Text hoặc widget vượt quá container.

### Giải pháp

Cung cấp **8 utility widgets**

1️⃣ AdaptiveText
2️⃣ ScrollableRow
3️⃣ FlexibleColumn
4️⃣ ConstrainedText
5️⃣ OverflowContainer
6️⃣ ResponsiveRow
7️⃣ OverflowUtils
8️⃣ ExpandableContainer

### Ví dụ

```dart
AdaptiveText(
  'Long text...',
  maxLines: 3,
  overflow: TextOverflow.ellipsis,
)
```

### Lợi ích

* Tránh crash UI
* Responsive mọi màn hình
* Tái sử dụng widget

---

# 📊 Phân Loại Theo Mức Độ Độc Lập

## Độc lập hoàn toàn

* `bug_fix_search_filter.dart`
* `bug_fix_percentage_calculation.dart`

## Phụ thuộc code dự án

* `bug_fix_cart_duplicate_items.dart`
* `bug_fix_auth_token_expiry.dart`
* `bug_fix_order_service_retry.dart`
* `bug_fix_input_validation.dart`
* `canteen_ui.dart`
* `bug_fix_ui_overflow.dart`

---

# 🧪 Ví dụ Unit Test

```dart
test('AdaptiveText should truncate long text', () {
  final widget = AdaptiveText(
    'Very long text...',
    maxLines: 2,
  );
  expect(find.byType(AdaptiveText), findsOneWidget);
});
```

---

# 📊 Performance Impact

| Fix              | Component     | Impact        | Priority |
| ---------------- | ------------- | ------------- | -------- |
| Cart Duplicate   | CartProvider  | Better UX     | High     |
| Token Expiry     | Auth Service  | Security      | Critical |
| Order Retry      | Order Service | Reliability   | High     |
| Input Validation | Auth Provider | Performance   | Medium   |
| UI Overflow      | Layout        | Responsive UI | High     |

---

# 🚀 Next Steps

1️⃣ Review code
2️⃣ Test locally
3️⃣ Integrate vào project
4️⃣ Deploy
5️⃣ Monitor logs

---

# 📌 Ghi chú

* Tài liệu phản ánh trạng thái hiện tại của thư mục `repo/`
* Khi thêm file fix mới cần cập nhật lại tài liệu này
