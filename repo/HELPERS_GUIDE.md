# 📚 REPOSITORY CODE HELPERS

Folder `repo/` chứa các file utilities, extensions, và helpers để hỗ trợ développement.
**NHẤT ĐỊNH: Những file này không ảnh hưởng đến code chính trong `lib/`**

---

## 📄 Danh Sách File Helpers

### 1. **api_response_handler.dart** ✅
**Mục đích:** Xử lý response từ API một cách unified

**Tính năng:**
- `ApiResponse<T>` - Generic wrapper cho API responses
- `.success()`, `.failure()`, `.error()` - Factory constructors
- `BaseService` - Abstract class cho các service khác extend

**Sử dụng:**
```dart
// Trong service
final response = await apiService.makeRequest<List<MenuItem>>(
  () => http.get(...),
);

if (response.success) {
  handleData(response.data);
} else {
  handleError(response.message);
}
```

---

### 2. **validation_helpers.dart** ✅
**Mục đích:** Validate input từ user

**Tính năng:**
- `validateEmail()` - Validate email format
- `validatePassword()` - Check password strength
- `validatePhoneNumber()` - Validate phone (Việt Nam)
- `validateFullName()`, `validateAmount()`, `validateRequired()`
- Helper methods: `isValidEmail()`, `isStrongPassword()`, etc.

**Sử dụng:**
```dart
final emailError = ValidationHelper.validateEmail(email);
if (emailError != null) {
  showError(emailError);
}

// Hoặc check boolean
if (ValidationHelper.isValidEmail(email)) {
  proceed();
}
```

---

### 3. **string_extensions.dart** ✅
**Mục đích:** Extend String class với các method tiện lợi

**Tính năng:**
- `.truncate()` - Cắt ngắn string
- `.capitalize()`, `.toTitleCase()` - Format text
- `.isEmail()`, `.isUrl()`, `.isNumeric()` - Check format
- `.removeExtraSpaces()`, `.toCamelCase()`, `.toSnakeCase()`
- `.getFileExtension()`, `.formatCurrency()`
- `.isValidPhoneNumber()`, `.isAlphabetic()`, etc.

**Sử dụng:**
```dart
String name = "hello world";
print(name.toTitleCase()); // "Hello World"

String email = "user@example.com";
if (email.isEmail()) { /* valid */ }

String price = "1000";
print(price.formatCurrency()); // "1.000 VNĐ"
```

---

### 4. **logger_utility.dart** ✅
**Mục đích:** Logging toàn cầu

**Tính năng:**
- `Logger.debug()`, `.info()`, `.warning()`, `.error()`, `.fatal()`
- `measure()` - Measure execution time của async function
- `measureSync()` - Measure execution time của sync function
- Customizable debug mode

**Sử dụng:**
```dart
Logger.info('App started', tag: 'Main');
Logger.error('Failed to load', error: exception);

// Measure performance
await Logger.measure('Load data', () => fetchData());
```

---

### 5. **date_extensions.dart** ✅
**Mục đích:** Extend DateTime class

**Tính năng:**
- `.format(pattern)` - Custom date format (dd/MM/yyyy HH:mm)
- `.isToday`, `.isYesterday`, `.isTomorrow` - Check date
- `.firstDayOfMonth`, `.lastDayOfMonth`, `.firstDayOfWeek`
- `.isPast`, `.isFuture`, `.daysFromNow`
- `.timeAgo` - Facebook-style relative time
- `.isSameDay()`, `.isSameWeek()`, `.isSameMonth()`

**Sử dụng:**
```dart
DateTime now = DateTime.now();
print(now.format('dd/MM/yyyy HH:mm')); // "13/03/2026 14:30"

if (date.isToday) { /* is today */ }

print(date.timeAgo); // "2h ago"
```

---

### 6. **num_extensions.dart** ✅
**Mục đích:** Extend num, int, double classes

**Tính năng cho `num`:**
- `.formatCurrency()` - Format VND: "1.000 VNĐ"
- `.formatPercent()` - Format percentage: "50%"
- `.formatFileSize()` - Format bytes: "1.5 MB"
- `.formatDuration()` - Format time: "1h 2m 3s"
- `.isNegative`, `.isPositive` - Check sign
- `.addPercent()`, `.subtractPercent()`, `.clamp()`
- `.inRange()`, `.lerp()`

**Tính năng cho `int`:**
- `.times()` - Loop n times
- `.to()` - Create range: `5.to(9)` => `[5,6,7,8]`
- `.factorial` - Calculate factorial
- `.isPrime` - Check if prime number

**Sử dụng:**
```dart
int price = 1000;
print(price.formatCurrency()); // "1.000 VNĐ"

double percent = 0.5;
print(percent.formatPercent()); // "50%"

int milliseconds = 3661000;
print(milliseconds.formatDuration()); // "1h 1m 1s"

// Repeat action
3.times((i) => print(i)); // Prints: 0, 1, 2

// Check if prime
if (7.isPrime) { /* 7 is prime */ }
```

---

### 7. **error_handler.dart** ✅
**Mục đích:** Xử lý lỗi toàn cầu

**Tính năng:**
- Custom exceptions: `AppException`, `NetworkException`, `ServerException`, `ValidationException`, `UnauthorizedException`
- `ErrorHandlerService` - Singleton service
  - `.getErrorMessage()` - Get user-friendly error message
  - `.logError()` - Log error
  - `.showErrorSnackBar()` - Show error in snackbar
  - `.showErrorDialog()` - Show error dialog
  - `.retryWithBackoff()` - Retry with exponential backoff

**Sử dụng:**
```dart
try {
  await someAsyncFunction();
} on ServerException catch (e) {
  ErrorHandlerService().showErrorSnackBar(context, e);
} catch (e) {
  Logger.error('Unexpected error', error: e);
}

// Retry with backoff
await ErrorHandlerService().retryWithBackoff(
  () => fetchData(),
  maxRetries: 3,
);
```

---

### 8. **app_constants.dart** ✅
**Mục đích:** Centralize tất cả constants trong ứng dụng

**Bao gồm:**
- App info: appName, appVersion, appBuildNumber
- API config: baseUrl, apiVersion, timeouts
- Authentication: token keys, expiry buffer
- UI: padding, border radius, animations
- Validation: min/max lengths
- Transaction: currency, tax, fees
- Cache: keys, durations
- Storage keys
- Error codes
- Pagination, date formats, routes, etc.

**Sử dụng:**
```dart
import 'app_constants.dart';

// In API client
dio.options.baseUrl = AppConstants.baseUrl;
dio.options.connectTimeout = Duration(seconds: AppConstants.connectionTimeout);

// In form validation
if (password.length < AppConstants.minPasswordLength) {
  showError('Password too short');
}

// In UI
SizedBox(height: AppConstants.defaultPadding)

// Route names
Navigator.pushNamed(context, AppConstants.routeHome);
```

---

## 🎯 Hướng Dẫn Sử Dụng

### Import trong project:
```dart
// Sử dụng relative import từ bất kỳ file nào trong lib/
import 'package:smart_canteen/api_response_handler.dart';
import 'package:smart_canteen/validation_helpers.dart';
import 'package:smart_canteen/string_extensions.dart';
// ... etc
```

### Hoặc tạo file `lib/utils/imports.dart` cho centralized imports:
```dart
// All helpers in one place
export 'package:smart_canteen/repo/api_response_handler.dart';
export 'package:smart_canteen/repo/validation_helpers.dart';
export 'package:smart_canteen/repo/string_extensions.dart';
export 'package:smart_canteen/repo/logger_utility.dart';
export 'package:smart_canteen/repo/date_extensions.dart';
export 'package:smart_canteen/repo/num_extensions.dart';
export 'package:smart_canteen/repo/error_handler.dart';
export 'package:smart_canteen/repo/app_constants.dart';
```

---

## 📝 Cách Sử Dụng Cụ Thể

### Ví dụ 1: Login Form Validation
```dart
import 'package:smart_canteen/validation_helpers.dart';

// In form
String? emailError = ValidationHelper.validateEmail(email);
String? passwordError = ValidationHelper.validatePassword(password);

if (emailError == null && passwordError == null) {
  // Proceed with login
  performLogin(email, password);
}
```

### Ví dụ 2: API Call với Response Handler
```dart
import 'package:smart_canteen/api_response_handler.dart';
import 'package:smart_canteen/error_handler.dart';
import 'package:smart_canteen/logger_utility.dart';

Future<void> fetchMenu() async {
  try {
    final response = await ApiCall<List<MenuItem>>(
      () => menuService.getMenu(),
    );
    
    if (response.success) {
      Logger.info('Menu loaded: ${response.data?.length} items');
      setState(() => items = response.data ?? []);
    } else {
      ErrorHandlerService().showErrorSnackBar(context, response.message);
    }
  } catch (e) {
    ErrorHandlerService().showErrorDialog(context, e);
  }
}
```

### Ví dụ 3: Format Display Data
```dart
import 'package:smart_canteen/string_extensions.dart';
import 'package:smart_canteen/num_extensions.dart';
import 'package:smart_canteen/date_extensions.dart';

// Format price
Text(1500.formatCurrency()); // "1.500 VNĐ"

// Format name
Text(name.toTitleCase()); // "John Doe"

// Format date
Text(orderDate.format('dd/MM/yyyy HH:mm')); // "13/03/2026 14:30"

// Format relative time
Text(createdDate.timeAgo); // "2h ago"
```

### Ví dụ 4: Retry Failed Request
```dart
import 'package:smart_canteen/error_handler.dart';

// Auto-retry network calls with backoff
final data = await ErrorHandlerService().retryWithBackoff(
  () => http.get(url),
  maxRetries: 3,
  initialDelay: Duration(milliseconds: 100),
);
```

---

## ✨ Good Practices

✅ **DO:**
- Sử dụng các constants từ `app_constants.dart` thay vì hardcode
- Log chi tiết với `Logger` để dễ debug
- Validate tất cả user input với `ValidationHelper`
- Format data hiển thị với extensions (`.formatCurrency()`, `.toTitleCase()`)
- Sử dụng `retryWithBackoff()` cho network requests

❌ **DON'T:**
- Không import trực tiếp từ `repo/` vào `lib/` (ngoại trừ helpers)
- Không modify files trong `repo/` từ main app code
- Không hardcode values - sử dụng `AppConstants` thay vì

---

## 🔄 Updates & Maintenance

Để thêm helpers mới:
1. Tạo file mới trong `repo/`
2. Implement logic
3. Test carefully
4. Update `HELPERS_GUIDE.md` này
5. Không touch các file trong `lib/`

---

**Lần cập nhật cuối:** March 13, 2026
