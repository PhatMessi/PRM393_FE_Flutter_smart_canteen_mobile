import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart';
import '../utils/image_helper.dart';
import '../utils/money.dart';
import '../utils/vn_time.dart';

class OrderDetailScreen extends StatelessWidget {
  final OrderModel order;

  const OrderDetailScreen({super.key, required this.order});

  static const double _vatRate = 0.05;

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd/MM/yyyy HH:mm').format(VnTime.toVn(order.orderDate));
    final total = order.totalPrice;
    final subtotal = total <= 0 ? 0.0 : (total / (1 + _vatRate)).roundToDouble();
    final tax = total <= 0 ? 0.0 : (total - subtotal);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text('Don hang #${order.orderId}'),
        centerTitle: true,
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow('Trang thai', _mapStatus(order.status)),
                const SizedBox(height: 8),
                _infoRow('Thoi gian dat', dateText),
                if (order.pickupTime != null) ...[
                  const SizedBox(height: 8),
                  _infoRow(
                    'Thoi gian nhan',
                    DateFormat('dd/MM/yyyy HH:mm').format(VnTime.toVn(order.pickupTime!)),
                  ),
                ],
                if (order.rejectionReason != null && order.rejectionReason!.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Ly do: ${order.rejectionReason}',
                      style: TextStyle(color: Colors.red.shade700),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chi tiet mon an',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...order.orderItems.map((item) {
                  final lineTotal = item.price * item.quantity;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: buildProductImage(
                            item.imageUrl,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.menuItemName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                              const SizedBox(height: 3),
                              Text('So luong: ${item.quantity}', style: const TextStyle(color: Colors.grey)),
                              if (item.note != null && item.note!.trim().isNotEmpty)
                                Text('Ghi chu: ${item.note}', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Money.vnd(lineTotal),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _SectionCard(
            child: Column(
              children: [
                _moneyRow('Tam tinh', Money.vnd(subtotal)),
                const SizedBox(height: 8),
                _moneyRow('Thue (5%)', Money.vnd(tax)),
                const Divider(height: 20),
                _moneyRow(
                  'Tong thanh toan',
                  Money.vnd(order.totalPrice),
                  isTotal: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _mapStatus(String status) {
    switch (status) {
      case 'Ready for Pickup':
        return 'San sang nhan mon';
      case 'Preparing':
        return 'Dang chuan bi';
      case 'Paid':
        return 'Da thanh toan';
      case 'Pending Payment':
        return 'Cho thanh toan';
      case 'Cancelled':
        return 'Da huy';
      case 'Completed':
        return 'Hoan tat';
      default:
        return status;
    }
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(label, style: const TextStyle(color: Colors.grey)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  Widget _moneyRow(String label, String value, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.black : Colors.grey[700],
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
            fontSize: isTotal ? 17 : 15,
          ),
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;

  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
