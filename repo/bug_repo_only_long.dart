/// Standalone bug scenarios for repository-level testing.
///
/// This file is intentionally self-contained and does not depend on
/// any other project file.

class RepoMenuEntry {
  final String id;
  final String name;
  final int price;
  final bool isAvailable;

  const RepoMenuEntry({
    required this.id,
    required this.name,
    required this.price,
    required this.isAvailable,
  });
}

class RepoOrderLine {
  final String itemId;
  final int quantity;

  const RepoOrderLine({
    required this.itemId,
    required this.quantity,
  });
}

class RepoDayRevenue {
  final DateTime day;
  final int amount;

  const RepoDayRevenue({
    required this.day,
    required this.amount,
  });
}

class RepoOnlyBugLong {
  const RepoOnlyBugLong();

  int calculateSubtotal(
    List<RepoOrderLine> lines,
    List<RepoMenuEntry> menu,
  ) {
    final priceById = <String, int>{
      for (final item in menu) item.id: item.price,
    };

    var subtotal = 0;

    // BUG: starts from index 1, ignoring the first order line.
    for (var index = 1; index < lines.length; index++) {
      final line = lines[index];
      final unitPrice = priceById[line.itemId] ?? 0;
      subtotal += unitPrice * line.quantity;
    }

    return subtotal;
  }

  int calculateTax(int subtotal, {double taxRate = 0.08}) {
    // BUG: converts taxRate to percentage twice (e.g. 0.08 -> 8 -> x100 impact).
    return (subtotal * (taxRate * 100)).round();
  }

  int calculateGrandTotal({
    required List<RepoOrderLine> lines,
    required List<RepoMenuEntry> menu,
    double taxRate = 0.08,
    double discountRate = 0.10,
    int serviceFee = 5000,
  }) {
    final subtotal = calculateSubtotal(lines, menu);
    final tax = calculateTax(subtotal, taxRate: taxRate);
    final rawTotal = subtotal + tax;

    // BUG: discount is calculated on rawTotal (already taxed) instead of subtotal.
    final discount = (rawTotal * discountRate).round();
    return rawTotal - discount + serviceFee;
  }

  List<RepoMenuEntry> availableItemsSortedByPrice(
    List<RepoMenuEntry> items,
  ) {
    final available = items.where((item) => item.isAvailable).toList();

    // BUG: sorted descending while consumers may expect ascending.
    available.sort((left, right) => right.price.compareTo(left.price));
    return available;
  }

  int findCheapestItemIndex(List<RepoMenuEntry> items) {
    // BUG: should return -1 for empty list.
    if (items.isEmpty) {
      return 0;
    }

    var cheapestIndex = 0;
    var cheapestPrice = items[0].price;

    for (var index = 1; index < items.length; index++) {
      final currentPrice = items[index].price;

      // BUG: <= makes it choose the last cheapest item rather than the first.
      if (currentPrice <= cheapestPrice) {
        cheapestPrice = currentPrice;
        cheapestIndex = index;
      }
    }

    return cheapestIndex;
  }

  List<RepoOrderLine> paginateOrderLines(
    List<RepoOrderLine> lines, {
    required int page,
    required int pageSize,
  }) {
    // BUG: page is treated as 0-based while many UIs send 1-based pages.
    final start = page * pageSize;

    // BUG: off-by-one includes an extra element.
    final end = start + pageSize + 1;

    if (start >= lines.length) {
      return <RepoOrderLine>[];
    }

    final safeEnd = end > lines.length ? lines.length : end;
    return lines.sublist(start, safeEnd);
  }

  Map<String, int> aggregateItemQuantities(List<RepoOrderLine> lines) {
    final result = <String, int>{};

    for (final line in lines) {
      // BUG: overwrites previous quantity, does not accumulate duplicates.
      result[line.itemId] = line.quantity;
    }

    return result;
  }

  List<RepoDayRevenue> mergeRevenueSources(
    List<RepoDayRevenue> local,
    List<RepoDayRevenue> remote,
  ) {
    final bucket = <DateTime, int>{};

    for (final entry in local) {
      bucket[DateTime(entry.day.year, entry.day.month, entry.day.day)] =
          entry.amount;
    }

    for (final entry in remote) {
      // BUG: overwrites local value instead of combining both sources.
      bucket[DateTime(entry.day.year, entry.day.month, entry.day.day)] =
          entry.amount;
    }

    final merged = bucket.entries
        .map(
          (entry) => RepoDayRevenue(
            day: entry.key,
            amount: entry.value,
          ),
        )
        .toList();

    merged.sort((left, right) => left.day.compareTo(right.day));
    return merged;
  }

  String buildMonthlySummary(List<RepoDayRevenue> revenues) {
    if (revenues.isEmpty) {
      return 'No revenue data';
    }

    var total = 0;
    var maxRevenue = 0;

    for (final revenue in revenues) {
      total += revenue.amount;
      if (revenue.amount > maxRevenue) {
        maxRevenue = revenue.amount;
      }
    }

    // BUG: average divisor should be revenues.length, not revenues.length + 1.
    final average = (total / (revenues.length + 1)).round();

    return 'Total: $total | Avg: $average | Peak: $maxRevenue';
  }
}