/**
 * BUG FIX: Tránh crash khi parse dữ liệu API không ổn định
 *
 * Vấn đề:
 * - Backend có thể trả về number dưới dạng int, double, string hoặc null
 * - Một số field ngày giờ trả về sai format
 * - Parse trực tiếp bằng int.parse/double.parse dễ gây FormatException
 *
 * Fix:
 * - Tạo parser an toàn với fallback value
 * - Chuẩn hóa dữ liệu trước khi map sang model
 */

class ApiDataParserFixed {
  // FIX: Parse int an toàn
  static int parseInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) {
      final parsed = int.tryParse(value.trim());
      if (parsed != null) return parsed;

      final asDouble = double.tryParse(value.trim());
      if (asDouble != null) return asDouble.round();
    }
    return fallback;
  }

  // FIX: Parse double an toàn
  static double parseDouble(dynamic value, {double fallback = 0.0}) {
    if (value == null) return fallback;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final normalized = value.trim().replaceAll(',', '.');
      final parsed = double.tryParse(normalized);
      if (parsed != null) return parsed;
    }
    return fallback;
  }

  // FIX: Parse bool an toàn
  static bool parseBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is int) return value != 0;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1' || normalized == 'yes') {
        return true;
      }
      if (normalized == 'false' || normalized == '0' || normalized == 'no') {
        return false;
      }
    }
    return fallback;
  }

  // FIX: Parse string an toàn
  static String parseString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    if (value is String) return value.trim();
    return value.toString();
  }

  // FIX: Parse DateTime an toàn
  static DateTime? parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      final parsed = DateTime.tryParse(value.trim());
      return parsed;
    }
    return null;
  }

  // FIX: Parse list an toàn, bỏ qua phần tử lỗi
  static List<T> parseList<T>(
    dynamic value,
    T Function(dynamic raw) mapper,
  ) {
    if (value is! List) return [];

    final result = <T>[];
    for (final rawItem in value) {
      try {
        result.add(mapper(rawItem));
      } catch (_) {
        // Bỏ qua item lỗi để tránh crash toàn bộ danh sách
      }
    }
    return result;
  }
}

class TransactionPayloadFixed {
  final String id;
  final double amount;
  final String type;
  final DateTime createdAt;

  TransactionPayloadFixed({
    required this.id,
    required this.amount,
    required this.type,
    required this.createdAt,
  });

  // FIX: fromJson an toàn, không throw exception khi dữ liệu xấu
  factory TransactionPayloadFixed.fromJson(Map<String, dynamic> json) {
    return TransactionPayloadFixed(
      id: ApiDataParserFixed.parseString(json['id']),
      amount: ApiDataParserFixed.parseDouble(json['amount']),
      type: ApiDataParserFixed.parseString(
        json['type'],
        fallback: 'unknown',
      ),
      createdAt:
          ApiDataParserFixed.parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'type': type,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
