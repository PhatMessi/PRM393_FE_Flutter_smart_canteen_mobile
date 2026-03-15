/// Standalone bug fix example:
/// Prevents divide-by-zero and invalid percentage outputs.

double safePercentage(num part, num total, {int decimals = 2}) {
  if (total <= 0) {
    return 0.0;
  }

  final boundedPart = part < 0 ? 0 : (part > total ? total : part);
  final ratio = (boundedPart / total) * 100;
  final factor = _pow10(decimals);

  return (ratio * factor).round() / factor;
}

int _pow10(int exponent) {
  if (exponent <= 0) {
    return 1;
  }

  var result = 1;
  for (var i = 0; i < exponent; i++) {
    result *= 10;
  }
  return result;
}

void main() {
  // Quick self-checks for edge cases.
  print(safePercentage(25, 100)); // 25.0
  print(safePercentage(25, 0)); // 0.0
  print(safePercentage(-10, 100)); // 0.0
  print(safePercentage(150, 100)); // 100.0
}
