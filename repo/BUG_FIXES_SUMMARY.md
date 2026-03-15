# BUG FIXES SUMMARY - Smart Canteen Mobile App

## Tong quan
Tai lieu nay tong hop chuc nang cua tat ca file hien co trong thu muc `repo/`.
Muc tieu la giup review nhanh: file nao dang sua bug gi, co the tai su dung o dau, va muc do phu thuoc voi code chinh.

Cap nhat den: March 15, 2026.

---

## Danh sach file trong repo

### 1) bug_fix_cart_duplicate_items.dart
- Muc dich: fix loi trung lap san pham trong gio hang khi cung `menuItem` + cung options duoc them nhieu lan.
- Chuc nang chinh:
- So sanh options an toan bang `_optionsEqual()` (co sort de tranh sai do thu tu).
- Tim item da ton tai bang dieu kien `menuItem.id` + options.
- Neu trung thi cong don `quantity`, neu khong trung thi tao dong moi.
- Gia tri mang lai: gio hang gon hon, tong so luong/chiphi nhat quan hon.
- Phu thuoc: co su dung model va provider cua du an (`CartItem`, `MenuItem`, `ChangeNotifier`).

### 2) bug_fix_auth_token_expiry.dart
- Muc dich: xu ly token het han va tang do on dinh cho auth flow.
- Chuc nang chinh:
- Luu them thoi diem het han token (`_tokenExpireKey`) khi dang nhap.
- Kiem tra token hop le truoc khi tra ve (`isTokenValid`, `getToken`).
- Neu token het han/401 thi tu dong `clearToken()`.
- Bo sung timeout cho request, parse JSON an toan, xu ly loi login ro rang hon.
- Gia tri mang lai: giam tinh trang user bi "stuck" khi token het han, luong auth de debug hon.
- Phu thuoc: co su dung `ApiConfig`, `User`, `http`, `shared_preferences`.

### 3) bug_fix_order_service_retry.dart
- Muc dich: tang kha nang chiu loi mang khi lay danh sach don hang.
- Chuc nang chinh:
- Them timeout request (15s) va custom `TimeoutException`.
- Them retry tu dong toi da 3 lan (`fetchMyOrdersWithRetry`).
- Cache ket qua thanh cong vao local storage va fallback sang cache khi loi.
- Xu ly rieng cac truong hop: khong co token, 401, server error, timeout.
- Gia tri mang lai: app van hien thi du lieu khi mang kem/offline, trai nghiem on dinh hon.
- Phu thuoc: co su dung `ApiConfig`, `OrderModel`, `AuthService`, `http`, `shared_preferences`.

### 4) bug_fix_input_validation.dart
- Muc dich: bo sung validation dau vao truoc khi goi API auth.
- Chuc nang chinh:
- Validate email format, do dai/do manh password, confirm password.
- Quan ly loi tung field qua `_fieldErrors` + `setFieldError`.
- Chan submit neu du lieu khong hop le (`validateForm` truoc `login`).
- Ap dung check email cho flow forgot password.
- Gia tri mang lai: giam API call thua, feedback loi ro hon tren UI.
- Phu thuoc: co su dung `AuthService`, `User`, `ChangeNotifier`.

### 5) bug_fix_search_filter.dart
- Muc dich: cung cap bo loc/tim kiem menu on dinh va de test.
- Chuc nang chinh:
- Dinh nghia `MenuItem`, `FilterState`, `MenuSearchService`.
- Loc theo keyword, category, khoang gia, chi lay mon con hang.
- Chuan hoa chuoi (`trim + lowercase`) de tim kiem khong phan biet hoa thuong.
- Ho tro `applyFilters` va `applyFiltersLazy`.
- Co `Debouncer` de giam tan suat search khi user go lien tuc.
- Co bo test mini trong `main()` de verify nhanh cac case.
- Gia tri mang lai: logic search/filter ro rang, de tach rieng de test.
- Phu thuoc: file tu chua, doc lap de chay thu (khong import code du an).

### 6) bug_fix_percentage_calculation.dart
- Muc dich: fix tinh phan tram an toan cho edge cases.
- Chuc nang chinh:
- Ham `safePercentage(part, total)` tranh chia cho 0 (`total <= 0` => `0.0`).
- Clamp `part` vao mien hop le `[0, total]`.
- Lam tron theo so le tu chon (`decimals`).
- Co self-check trong `main()` cho cac case: total=0, am, vuot tong.
- Gia tri mang lai: tranh NaN/Infinity, ket qua phan tram on dinh.
- Phu thuoc: doc lap hoan toan, khong lien quan code ngoai `repo/`.

### 7) canteen_ui.dart
- Muc dich: helper hien thi anh mon an an toan cho nhieu nguon du lieu.
- Chuc nang chinh:
- Chuyen path backend thanh URL tuyet doi dua tren `ApiConfig.baseUrl`.
- Nhan dien path static (`/images`, `uploads`, `static`) va load qua `Image.network`.
- Mapping URL demo `example.com` sang asset local de tranh anh loi.
- Fallback icon khi anh null/loi/khong ton tai.
- Gia tri mang lai: giam anh hong tren app (dac biet Flutter Web/CORS).
- Phu thuoc: co su dung `flutter/material.dart` va `ApiConfig`.

---

## Phan loai nhanh theo muc do doc lap

### Doc lap hoan toan (co the chay rieng)
- `bug_fix_search_filter.dart`
- `bug_fix_percentage_calculation.dart`

### Co phu thuoc vao code du an
- `bug_fix_cart_duplicate_items.dart`
- `bug_fix_auth_token_expiry.dart`
- `bug_fix_order_service_retry.dart`
- `bug_fix_input_validation.dart`
- `canteen_ui.dart`

---

## Goi y su dung
1. Neu muon test nhanh logic thuan, uu tien chay 2 file doc lap de verify behavior.
2. Neu muon integrate vao app, merge tung fix vao file dich tuong ung trong `lib/` thay vi copy nguyen bo.
3. Truoc khi merge production, nen bo sung unit test cho cac case edge (token expiry, retry, filter, validation).

---

## Ghi chu
- File nay la ban tong hop theo trang thai hien tai cua thu muc `repo/`.
- Khi them file moi trong `repo/`, hay cap nhat lai muc "Danh sach file trong repo" de giu tai lieu dong bo.
