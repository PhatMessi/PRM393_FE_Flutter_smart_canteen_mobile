/**
 * String Extensions
 * 
 * Mở rộng String class với các method hữu ích
 * Giúp format dữ liệu, validate, v.v.
 */

extension StringExtensions on String {
  /// Cắt ngắn string nếu vượt quá maxLength
  /// Example: "Hello World".truncate(5) => "Hello..."
  String truncate(int maxLength, {String ellipsis = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - ellipsis.length)}$ellipsis';
  }

  /// Viết hoa chữ cái đầu tiên
  /// Example: "hello world".capitalize() => "Hello world"
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }

  /// Viết hoa chữ cái đầu mỗi từ (Title Case)
  /// Example: "hello world".toTitleCase() => "Hello World"
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ')
        .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  /// Kiểm tra xem string có phải là email không
  bool isEmail() {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(this);
  }

  /// Kiểm tra xem string có phải là URL không
  bool isUrl() {
    try {
      Uri.parse(this);
      return this.startsWith('http://') || this.startsWith('https://');
    } catch (_) {
      return false;
    }
  }

  /// Kiểm tra xem string chỉ chứa chữ số không
  bool isNumeric() {
    return RegExp(r'^[0-9]+$').hasMatch(this);
  }

  /// Loại bỏ khoảng trắng dư thừa
  /// Example: "hello  world".removeExtraSpaces() => "hello world"
  String removeExtraSpaces() {
    return replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  /// Chuyển thành camelCase
  /// Example: "hello world".toCamelCase() => "helloWorld"
  String toCamelCase() {
    List<String> words = split(RegExp(r'[\s_-]+'));
    String result = words[0].toLowerCase();
    for (int i = 1; i < words.length; i++) {
      result += words[i][0].toUpperCase() + words[i].substring(1).toLowerCase();
    }
    return result;
  }

  /// Chuyển thành snake_case
  /// Example: "HelloWorld".toSnakeCase() => "hello_world"
  String toSnakeCase() {
    return replaceAllMapped(
      RegExp(r'(?<=[a-z])[A-Z]'),
      (match) => '_${match.group(0)}',
    ).toLowerCase();
  }

  /// Lấy phần mở rộng của file name
  /// Example: "image.jpg".getFileExtension() => "jpg"
  String getFileExtension() {
    if (!contains('.')) return '';
    return split('.').last.toLowerCase();
  }

  /// Kiểm tra xem string có phải là số điện thoại hợp lệ không (Việt Nam)
  bool isValidPhoneNumber() {
    return RegExp(r'^0\d{9}$').hasMatch(this);
  }

  /// Kiểm tra xem string có chứa chỉ các ký tự chữ cái không
  bool isAlphabetic() {
    return RegExp(r'^[a-zA-Z]+$').hasMatch(this);
  }

  /// Kiểm tra xem string có chứa chỉ các ký tự alphanumeric không
  bool isAlphanumeric() {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(this);
  }

  /// Format currency - VND
  /// Example: "1000".formatCurrency() => "1.000 VNĐ"
  String formatCurrency() {
    if (!isNumeric()) return this;
    
    final number = int.parse(this);
    final formatter = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${number.toString().replaceAllMapped(formatter, (match) => '.')}'
        ' VNĐ';
  }

  /// Check if string is null or empty
  bool get isNullOrEmpty => isEmpty;

  /// Check if string is not null and not empty
  bool get isNotNullOrEmpty => isNotEmpty;

  /// Reverse string
  /// Example: "hello".reverse() => "olleh"
  String reverse() {
    return split('').reversed.join('');
  }

  /// Replace first occurrence
  String replaceFirst(String from, String to) {
    return replaceFirst(RegExp(RegExp.escape(from)), to);
  }
}
