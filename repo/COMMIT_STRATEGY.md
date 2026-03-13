# 📝 GIT COMMIT STRATEGY

Hướng dẫn chia file code thành các commits hợp lý

---

## 🎯 Commit Plan (Gợi ý)

### **Commit 1: Core Utilities & Extensions**
**Message:** `chore: add core string and number extensions`

```bash
git add repo/string_extensions.dart
git add repo/num_extensions.dart
git commit -m "chore: add core string and number extensions

- String utilities: truncate, capitalize, format, validation
- Number utilities: currency formatting, duration, percentage
- Reusable extensions for common operations"
```

---

### **Commit 2: Validation & Constants**
**Message:** `chore: add validation helpers and app constants`

```bash
git add repo/validation_helpers.dart
git add repo/app_constants.dart
git commit -m "chore: add validation helpers and app constants

- Email, password, phone, name validation
- Centralized app constants (API, UI, routes, etc.)
- Support Vietnamese phone validation"
```

---

### **Commit 3: Date & Time Utilities**
**Message:** `chore: add date and time extensions`

```bash
git add repo/date_extensions.dart
git commit -m "chore: add date and time extensions

- Custom date formatting with pattern support
- Utility methods: isToday, isYesterday, isFuture
- Relative time display (timeAgo)
- Date range comparisons"
```

---

### **Commit 4: Data & API Handling**
**Message:** `chore: add API response handler and error handling`

```bash
git add repo/api_response_handler.dart
git add repo/error_handler.dart
git commit -m "chore: add API response handler and error handling

- ApiResponse<T> generic wrapper for type-safe responses
- Custom exception classes (Network, Server, Validation, etc.)
- ErrorHandlerService with snackbar and dialog support
- Retry logic with exponential backoff"
```

---

### **Commit 5: Development Tools**
**Message:** `chore: add logging utility for development`

```bash
git add repo/logger_utility.dart
git commit -m "chore: add logging utility for development

- Multi-level logging (debug, info, warning, error, fatal)
- Performance measurement (async & sync)
- Customizable debug mode"
```

---

### **Commit 6: Documentation**
**Message:** `docs: add helpers guide and commit strategy`

```bash
git add repo/HELPERS_GUIDE.md
git add repo/COMMIT_STRATEGY.md
git commit -m "docs: add guides for code helpers and commit strategy

- Comprehensive helpers usage guide
- Code examples for each utility
- Best practices and recommendations"
```

---

## 🚀 Commit Một Lần (All-in-One)

Hoặc nếu bạn muốn commit tất cả cùng lúc:

```bash
git add repo/
git commit -m "chore: add utility helpers and constants to repo

- String and number extensions with formatting methods
- Validation helpers for email, password, phone
- DateTime extensions with custom formatting
- API response handler with error management
- Logging utility for development
- Centralized application constants
- Comprehensive guide for using utilities"
```

---

## 📋 Checklist Trước Commit

- [ ] Tất cả file syntax đúng (flutter analyze)
- [ ] Không import methods từ main app (lib/)
- [ ] Tất cả file helpers trong folder `repo/`
- [ ] Guided commit messages rõ ràng
- [ ] Files không conflict với code hiện tại

---

## 💡 Git Commands Cheatsheet

```bash
# Xem status
git status

# Add file cụ thể
git add repo/string_extensions.dart

# Add toàn bộ repo folder
git add repo/

# Commit với message
git commit -m "message"

# Commit với multiline message
git commit -m "title

body with details
- bullet point 1
- bullet point 2"

# Amend commit cuối
git commit --amend

# Xem git log
git log --oneline

# Interactive rebase (reorganize commits)
git rebase -i HEAD~5
```

---

## 🔍 Verifying Before Commit

```bash
# Check lint errors
flutter analyze

# Format code
dart format repo/

# Check if files compile
dart compile kernel repo/string_extensions.dart

# Preview changes
git diff repo/

# Dry run
git commit --dry-run -m "message"
```

---

## 📌 Branch Strategy (Optional)

```bash
# Create feature branch
git checkout -b feature/add-helpers

# Commit changes
git add repo/
git commit -m "..."

# Push branch
git push origin feature/add-helpers

# Create Pull Request on GitHub/GitLab
# After review and approval, merge to main
```

---

## ✅ Recommended Commit Order

Nếu bạn muốn commit theo thứ tự:

1. **Foundation** → Extensions (strings, numbers, dates)
2. **Core Utils** → Validation, constants, logger
3. **Business Logic** → API response, error handling
4. **Documentation** → Guides và markdown files

---

## 🎯 Commit Message Format

```
<type>: <subject>

<body>

<footer>
```

**Types:**
- `feat:` - New feature
- `fix:` - Bug fix
- `chore:` - Maintenance (dependencies, configs)
- `docs:` - Documentation changes
- `refactor:` - Code restructure
- `perf:` - Performance improvement
- `test:` - Test-related

**Example:**
```
chore: add string extensions utility

- Add truncate, capitalize, toTitleCase methods
- Add validation methods: isEmail, isUrl, isNumeric
- Add formatting: camelCase, snake_case conversion

Closes #123
```

---

**Created:** March 13, 2026
