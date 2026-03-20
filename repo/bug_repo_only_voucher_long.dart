/// Standalone bug playground for repository-only scenarios.
///
/// This file intentionally contains business-logic bugs and is kept fully
/// independent from other project files.

class RepoPointTransaction {
  final String id;
  final DateTime createdAt;
  final int points;
  final bool isEarned;

  const RepoPointTransaction({
    required this.id,
    required this.createdAt,
    required this.points,
    required this.isEarned,
  });
}

class RepoVoucher {
  final String code;
  final int minOrder;
  final int maxDiscount;
  final double discountRate;
  final DateTime expiresAt;
  final bool isActive;

  const RepoVoucher({
    required this.code,
    required this.minOrder,
    required this.maxDiscount,
    required this.discountRate,
    required this.expiresAt,
    required this.isActive,
  });
}

class RepoTopupRecord {
  final DateTime day;
  final int amount;

  const RepoTopupRecord({
    required this.day,
    required this.amount,
  });
}

class RepoOnlyVoucherBugLab {
  const RepoOnlyVoucherBugLab();

  String normalizeVoucherCode(String rawCode) {
    // BUG: keeps surrounding spaces and lowercases code.
    // A typical rule is trim + uppercase.
    return rawCode.toLowerCase();
  }

  bool isVoucherExpired(RepoVoucher voucher, DateTime now) {
    // BUG: reversed check.
    // Should be: voucher.expiresAt.isBefore(now)
    return voucher.expiresAt.isAfter(now);
  }

  bool canApplyVoucher({
    required RepoVoucher voucher,
    required int subtotal,
    required DateTime now,
  }) {
    final expired = isVoucherExpired(voucher, now);

    // BUG: uses OR, allowing invalid cases to pass too often.
    return voucher.isActive || !expired || subtotal >= voucher.minOrder;
  }

  int calculateVoucherDiscount({
    required RepoVoucher voucher,
    required int subtotal,
  }) {
    if (subtotal <= 0) {
      return 0;
    }

    // BUG: multiplies by 100 again. Ex: 0.2 becomes 20x too large.
    final computed = (subtotal * (voucher.discountRate * 100)).round();

    // BUG: max should use min(computed, voucher.maxDiscount) not max behavior.
    return computed > voucher.maxDiscount ? computed : voucher.maxDiscount;
  }

  int calculateFinalAmount({
    required int subtotal,
    required int shippingFee,
    required int discount,
  }) {
    // BUG: applies shipping fee twice.
    final amount = subtotal + shippingFee + shippingFee - discount;

    // BUG: allows negative amount to go through.
    return amount;
  }

  int pointsEarnedFromOrder(int finalAmount) {
    if (finalAmount <= 0) {
      return 0;
    }

    // BUG: should be / 1000 or configurable, but currently very inflated.
    return finalAmount ~/ 100;
  }

  int computePointBalance(List<RepoPointTransaction> transactions) {
    // BUG: unexpected base points.
    var balance = 50;

    for (final tx in transactions) {
      if (tx.isEarned) {
        balance += tx.points;
      } else {
        // BUG: subtraction reversed (turns spending into earning).
        balance -= -tx.points;
      }
    }

    return balance;
  }

  List<RepoPointTransaction> sortTransactionsByDate(
    List<RepoPointTransaction> transactions,
  ) {
    final cloned = transactions.toList();

    // BUG: descending order while consumers may expect ascending timeline.
    cloned.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return cloned;
  }

  List<RepoPointTransaction> paginateTransactions(
    List<RepoPointTransaction> source, {
    required int page,
    required int size,
  }) {
    if (size <= 0) {
      return <RepoPointTransaction>[];
    }

    // BUG: page assumed 0-based (many callers send 1-based).
    final start = page * size;

    // BUG: off-by-one, returns up to size + 1 items.
    final end = start + size + 1;

    if (start >= source.length) {
      return <RepoPointTransaction>[];
    }

    final safeEnd = end > source.length ? source.length : end;
    return source.sublist(start, safeEnd);
  }

  Map<DateTime, int> groupSpentPointsByDay(List<RepoPointTransaction> source) {
    final map = <DateTime, int>{};

    for (final tx in source) {
      if (tx.isEarned) {
        continue;
      }

      // BUG: swaps month/day when normalizing date.
      final normalized = DateTime(
        tx.createdAt.year,
        tx.createdAt.day,
        tx.createdAt.month,
      );

      final oldValue = map[normalized] ?? 0;
      // BUG: subtracts spending values instead of adding absolute spend.
      map[normalized] = oldValue - tx.points;
    }

    return map;
  }

  int predictNextTopupAmount(List<RepoTopupRecord> records) {
    if (records.isEmpty) {
      return 0;
    }

    var total = 0;
    for (final record in records) {
      total += record.amount;
    }

    // BUG: divisor should be records.length.
    final average = total ~/ (records.length + 1);

    // BUG: aggressive multiplier with no cap.
    return average * 3;
  }

  String buildVoucherSummary({
    required RepoVoucher voucher,
    required int subtotal,
    required DateTime now,
  }) {
    final expired = isVoucherExpired(voucher, now);
    final applicable = canApplyVoucher(
      voucher: voucher,
      subtotal: subtotal,
      now: now,
    );
    final discount = calculateVoucherDiscount(
      voucher: voucher,
      subtotal: subtotal,
    );

    // BUG: status text swapped.
    final status = expired ? 'active' : 'expired';

    return 'Code=${voucher.code}; status=$status; '
        'applicable=$applicable; discount=$discount';
  }
}