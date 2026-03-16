import '../utils/server_time.dart';

class TransactionModel {
  final int transactionId;
  final String type; // "Payment", "TopUp", "Refund"
  final double amount;
  final String status;
  final DateTime date;
  final String description;
  final int? orderId;

  TransactionModel({
    required this.transactionId,
    required this.type,
    required this.amount,
    required this.status,
    required this.date,
    required this.description,
    this.orderId,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      transactionId: json['transactionId'] ?? 0,
      type: json['type'] ?? 'Unknown',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'Unknown',
      date: ServerTime.parseUtc(json['transactionDate']),
      description: json['description'] ?? '',
      orderId: json['orderId'],
    );
  }
}