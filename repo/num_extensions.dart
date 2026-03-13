/**
 * Number Extensions
 * 
 * Mở rộng int, double, num classes với các method hữu ích
 * Format tiền, giờ, file size, v.v.
 */

extension NumExtensions on num {
  /// Format currency VND
  /// Example: 1000.formatCurrency() => "1.000 VNĐ"
  String formatCurrency() {
    final formatter = RegExp(r'\B(?=(\d{3})+(?!\d))');
    return '${toString().replaceAllMapped(formatter, (match) => '.')} VNĐ';
  }

  /// Format percentage
  /// Example: 0.5.formatPercent() => "50%"
  String formatPercent({int decimals = 0}) {
    final value = (this * 100).toStringAsFixed(decimals);
    return '$value%';
  }

  /// Format file size (bytes to human readable)
  /// Example: 1024.formatFileSize() => "1.0 KB"
  String formatFileSize() {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var bytes = toDouble();
    var suffixIndex = 0;

    while (bytes >= 1024 && suffixIndex < suffixes.length - 1) {
      bytes /= 1024;
      suffixIndex++;
    }

    return '${bytes.toStringAsFixed(1)} ${suffixes[suffixIndex]}';
  }

  /// Format thời gian (milliseconds to human readable)
  /// Example: 3661000.formatDuration() => "1h 1m 1s"
  String formatDuration() {
    final duration = Duration(milliseconds: toInt());
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    final parts = <String>[];
    if (hours > 0) parts.add('${hours}h');
    if (minutes > 0) parts.add('${minutes}m');
    if (seconds > 0) parts.add('${seconds}s');

    return parts.isEmpty ? '0s' : parts.join(' ');
  }

  /// Kiểm tra xem số có phải là số âm không
  bool get isNegative => this < 0;

  /// Kiểm tra xem số có phải là số dương không
  bool get isPositive => this > 0;

  /// Kiểm tra xem số có phải là số chẵn không (chỉ cho int)
  bool get isEven => toInt() % 2 == 0;

  /// Kiểm tra xem số có phải là số lẻ không (chỉ cho int)
  bool get isOdd => toInt() % 2 != 0;

  /// Round đến bao nhiêu decimal places
  /// Example: 3.14159.roundToDecimal(2) => 3.14
  double roundToDecimal(int decimals) {
    final mod = pow(10.0, decimals).toInt();
    return (toDouble() * mod).round() / mod;
  }

  /// Cộng thêm percentage
  /// Example: 100.addPercent(10) => 110
  num addPercent(num percent) {
    return this + (this * percent / 100);
  }

  /// Trừ đi percentage
  /// Example: 100.subtractPercent(10) => 90
  num subtractPercent(num percent) {
    return this - (this * percent / 100);
  }

  /// Lấy absolute value (luôn dương)
  /// Example: -10.abs() => 10
  num abs() {
    return this < 0 ? -this : this;
  }

  /// Kiểm tra xem số có nằm trong range không
  /// Example: 5.inRange(1, 10) => true
  bool inRange(num min, num max) {
    return this >= min && this <= max;
  }

  /// Clamp number trong range
  /// Example: 15.clamp(1, 10) => 10
  num clamp(num min, num max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }

  /// Lerp (linear interpolation)
  /// Example: 0.lerp(10, 0.5) => 5
  num lerp(num to, double t) {
    return this + (to - this) * t;
  }
}

extension DoubleExtensions on double {
  /// Format với số lượng decimal places
  /// Example: 3.14159.toStringAsFixedLength(2) => "3.14"
  String toStringAsFixedLength(int digits) {
    return toStringAsFixed(digits);
  }

  /// Kiểm tra xem có phải là số nguyên không
  /// Example: 3.0.isWhole() => true, 3.5.isWhole() => false
  bool isWhole() {
    return this == toInt();
  }
}

extension IntExtensions on int {
  /// Repeat action n times
  /// Example: 3.times((i) => print(i)) => prints 0, 1, 2
  void times(Function(int) action) {
    for (int i = 0; i < this; i++) {
      action(i);
    }
  }

  /// Tạo range từ 0 đến n-1
  /// Example: 5.to(9) => [5, 6, 7, 8]
  List<int> to(int end) {
    final result = <int>[];
    for (int i = this; i <= end; i++) {
      result.add(i);
    }
    return result;
  }

  /// Tính giai thừa (factorial)
  /// Example: 5.factorial => 120
  int get factorial {
    if (this < 0) throw ArgumentError('Factorial not defined for negative numbers');
    if (this == 0 || this == 1) return 1;
    return this * (this - 1).factorial;
  }

  /// Kiểm tra xem có phải số nguyên tố không
  /// Example: 7.isPrime => true
  bool get isPrime {
    if (this < 2) return false;
    if (this == 2) return true;
    if (isEven) return false;

    for (int i = 3; i * i <= this; i += 2) {
      if (this % i == 0) return false;
    }
    return true;
  }
}
