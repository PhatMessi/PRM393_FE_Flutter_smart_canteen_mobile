import '../utils/server_time.dart';

class LinkedStudent {
  final int userId;
  final String fullName;
  final String email;

  LinkedStudent({
    required this.userId,
    required this.fullName,
    required this.email,
  });

  factory LinkedStudent.fromJson(Map<String, dynamic> json) {
    return LinkedStudent(
      userId: json['userId'] ?? json['UserId'] ?? 0,
      fullName: (json['fullName'] ?? json['FullName'] ?? '').toString(),
      email: (json['email'] ?? json['Email'] ?? '').toString(),
    );
  }
}

class ParentOrderSummary {
  final int orderId;
  final DateTime orderDate;
  final double totalPrice;
  final String status;

  ParentOrderSummary({
    required this.orderId,
    required this.orderDate,
    required this.totalPrice,
    required this.status,
  });

  factory ParentOrderSummary.fromJson(Map<String, dynamic> json) {
    return ParentOrderSummary(
      orderId: json['orderId'] ?? 0,
      orderDate: ServerTime.parseUtc(json['orderDate']),
      totalPrice: ((json['totalPrice'] ?? 0) as num).toDouble(),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class ParentTransaction {
  final int transactionId;
  final String type;
  final double amount;
  final String status;
  final DateTime transactionDate;
  final String description;

  ParentTransaction({
    required this.transactionId,
    required this.type,
    required this.amount,
    required this.status,
    required this.transactionDate,
    required this.description,
  });

  factory ParentTransaction.fromJson(Map<String, dynamic> json) {
    return ParentTransaction(
      transactionId: json['transactionId'] ?? 0,
      type: (json['type'] ?? '').toString(),
      amount: ((json['amount'] ?? 0) as num).toDouble(),
      status: (json['status'] ?? '').toString(),
      transactionDate: ServerTime.parseUtc(json['transactionDate']),
      description: (json['description'] ?? '').toString(),
    );
  }
}

class ParentWalletControlSnapshot {
  final int studentId;
  final String studentName;
  final double currentBalance;
  final double todaySpent;
  final bool isGuardianWalletEnabled;
  final double? dailySpendingLimit;
  final List<int> blockedItemIds;
  final List<ParentTransaction> recentTransactions;
  final List<ParentOrderSummary> recentOrders;

  ParentWalletControlSnapshot({
    required this.studentId,
    required this.studentName,
    required this.currentBalance,
    required this.todaySpent,
    required this.isGuardianWalletEnabled,
    required this.dailySpendingLimit,
    required this.blockedItemIds,
    required this.recentTransactions,
    required this.recentOrders,
  });

  factory ParentWalletControlSnapshot.fromJson(Map<String, dynamic> json) {
    final blocked = (json['blockedItemIds'] as List<dynamic>? ?? const [])
        .map((e) => (e as num).toInt())
        .toList();

    final txs = (json['recentTransactions'] as List<dynamic>? ?? const [])
        .map((e) => ParentTransaction.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    final orders = (json['recentOrders'] as List<dynamic>? ?? const [])
        .map((e) => ParentOrderSummary.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return ParentWalletControlSnapshot(
      studentId: json['studentId'] ?? 0,
      studentName: (json['studentName'] ?? '').toString(),
      currentBalance: ((json['currentBalance'] ?? 0) as num).toDouble(),
      todaySpent: ((json['todaySpent'] ?? 0) as num).toDouble(),
      isGuardianWalletEnabled: json['isGuardianWalletEnabled'] == true,
      dailySpendingLimit: json['dailySpendingLimit'] == null
          ? null
          : ((json['dailySpendingLimit'] as num).toDouble()),
      blockedItemIds: blocked,
      recentTransactions: txs,
      recentOrders: orders,
    );
  }
}
