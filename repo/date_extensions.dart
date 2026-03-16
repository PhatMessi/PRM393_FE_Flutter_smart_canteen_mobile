/**
 * DateTime Extensions
 * 
 * Mở rộng DateTime class với các method hữu ích
 * Format, parse, compare dates
 */

extension DateTimeExtensions on DateTime {
  /// Format datetime theo pattern tùy chỉnh
  /// Example: now().format('dd/MM/yyyy HH:mm') => "13/03/2026 14:30"
  String format(String pattern) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    final days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    String result = pattern;

    // Day
    result = result.replaceAll('dd', day.toString().padLeft(2, '0'));
    result = result.replaceAll('d', day.toString());

    // Month
    result = result.replaceAll('MM', month.toString().padLeft(2, '0'));
    result = result.replaceAll('M', month.toString());
    result = result.replaceAll('MMMM', months[month - 1]);
    result = result.replaceAll('MMM', months[month - 1].substring(0, 3));

    // Year
    result = result.replaceAll('yyyy', year.toString());
    result = result.replaceAll('yy', year.toString().substring(2));

    // Hour
    result = result.replaceAll('HH', hour.toString().padLeft(2, '0'));
    result = result.replaceAll('H', hour.toString());

    // Minute
    result = result.replaceAll('mm', minute.toString().padLeft(2, '0'));
    result = result.replaceAll('m', minute.toString());

    // Second
    result = result.replaceAll('ss', second.toString().padLeft(2, '0'));
    result = result.replaceAll('s', second.toString());

    // Day name
    result = result.replaceAll('EEEE', days[weekday - 1]);
    result = result.replaceAll('EEE', days[weekday - 1].substring(0, 3));

    return result;
  }

  /// Kiểm tra xem ngày có phải hôm nay không
  bool get isToday {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Kiểm tra xem ngày có phải hôm qua không
  bool get isYesterday {
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Kiểm tra xem ngày có phải ngày mai không
  bool get isTomorrow {
    final tomorrow = DateTime.now().add(Duration(days: 1));
    return year == tomorrow.year &&
        month == tomorrow.month &&
        day == tomorrow.day;
  }

  /// Lấy ngày đầu tiên của tháng
  DateTime get firstDayOfMonth {
    return DateTime(year, month, 1);
  }

  /// Lấy ngày cuối cùng của tháng
  DateTime get lastDayOfMonth {
    return DateTime(year, month + 1, 0);
  }

  /// Lấy ngày đầu tiên của tuần (Thứ Hai)
  DateTime get firstDayOfWeek {
    final daysToSubtract = weekday == 7 ? 6 : weekday - 1;
    return subtract(Duration(days: daysToSubtract));
  }

  /// Lấy ngày cuối cùng của tuần (Chủ Nhật)
  DateTime get lastDayOfWeek {
    final daysToAdd = weekday == 7 ? 0 : 7 - weekday;
    return add(Duration(days: daysToAdd));
  }

  /// Kiểm tra xem là ngày trong quá khứ không
  bool get isPast {
    return isBefore(DateTime.now());
  }

  /// Kiểm tra xem là ngày trong tương lai không
  bool get isFuture {
    return isAfter(DateTime.now());
  }

  /// Lấy số ngày còn lại đến ngày này
  int get daysFromNow {
    final now = DateTime.now();
    final difference = difference(now);
    return difference.inDays;
  }

  /// Format giống Facebook (1 second ago, 2 minutes ago, etc)
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return format('dd/MM/yyyy');
    }
  }

  /// Kiểm tra xem datetime có trong cùng ngày không
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }

  /// Kiểm tra xem datetime có trong cùng tuần không
  bool isSameWeek(DateTime other) {
    return firstDayOfWeek.isSameDay(other.firstDayOfWeek);
  }

  /// Kiểm tra xem datetime có trong cùng tháng không
  bool isSameMonth(DateTime other) {
    return year == other.year && month == other.month;
  }

  /// Kiểm tra xem datetime có trong cùng năm không
  bool isSameYear(DateTime other) {
    return year == other.year;
  }

  /// Để có thể so sánh với các thời điểm khác
  /// Example: dateTime.isBetween(startDate, endDate)
  bool isBetween(DateTime start, DateTime end) {
    return isAfter(start) && isBefore(end);
  }
}
