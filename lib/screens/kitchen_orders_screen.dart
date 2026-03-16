import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/kitchen_order_service.dart';
import '../services/local_notification_service.dart';
import '../services/realtime_service.dart';
import '../utils/money.dart';
import '../utils/vn_time.dart';

class KitchenOrdersScreen extends StatefulWidget {
  const KitchenOrdersScreen({super.key});

  @override
  State<KitchenOrdersScreen> createState() => _KitchenOrdersScreenState();
}

class _KitchenOrdersScreenState extends State<KitchenOrdersScreen> {
  final KitchenOrderService _service = KitchenOrderService();
  final AuthService _authService = AuthService();

  Future<List<OrderModel>>? _unconfirmedFuture;
  Future<List<OrderModel>>? _cookingFuture;
  int _unconfirmedCount = 0;

  StreamSubscription<KitchenNewOrderEvent>? _newOrderSub;

  @override
  void initState() {
    super.initState();
    _refresh();
    _startRealtime();
  }

  Future<void> _startRealtime() async {
    final token = await _authService.getToken();
    if (!mounted || token == null || token.isEmpty) return;

    await RealtimeService.instance.start(token: token);

    _newOrderSub?.cancel();
    _newOrderSub = RealtimeService.instance.kitchenNewOrders.listen((event) {
      if (!mounted) return;
      SystemSound.play(SystemSoundType.alert);
      LocalNotificationService.instance.showKitchenNewOrder(orderId: event.orderId);
      _showNewOrderPopup(event.orderId);
      _refresh();
    });
  }

  void _refresh() {
    setState(() {
      _unconfirmedFuture = _service.fetchUnconfirmed().then((orders) {
        if (mounted) {
          setState(() {
            _unconfirmedCount = orders.length;
          });
        }
        return orders;
      });
      _cookingFuture = _service.fetchCooking();
    });
  }

  Future<void> _showNewOrderPopup(int orderId) async {
    if (!mounted) return;

    final shouldAccept = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Đơn mới'),
          content: Text('Có đơn mới #$orderId. Xác nhận để bắt đầu chế biến.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Đóng'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Xác nhận'),
            ),
          ],
        );
      },
    );

    if (shouldAccept == true) {
      try {
        await _service.accept(orderId);
        if (mounted) {
          _refresh();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _newOrderSub?.cancel();
    super.dispose();
  }

  Widget _tabLabel(String text, {required bool showBadge}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        if (showBadge) ...[
          const SizedBox(width: 6),
          Container(
            width: 10,
            height: 10,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
          ),
        ]
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 2,
      initialIndex: 0,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bếp'),
          bottom: TabBar(
            labelColor: theme.colorScheme.primary,
            tabs: [
              const Tab(text: 'Cooking'),
              Tab(child: _tabLabel('Chưa xác nhận', showBadge: _unconfirmedCount > 0)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _OrdersTab(
              title: 'Cooking',
              future: _cookingFuture,
              emptyText: 'Chưa có đơn đang chế biến.',
              primaryActionText: 'Hoàn thành',
              onPrimaryAction: (orderId) async {
                await _service.complete(orderId);
                _refresh();
              },
              onRefresh: _refresh,
            ),
            _OrdersTab(
              title: 'Chưa xác nhận',
              future: _unconfirmedFuture,
              emptyText: 'Không có đơn chờ xác nhận.',
              primaryActionText: 'Xác nhận',
              onPrimaryAction: (orderId) async {
                await _service.accept(orderId);
                _refresh();
              },
              onRefresh: _refresh,
            ),
          ],
        ),
      ),
    );
  }
}

class _OrdersTab extends StatelessWidget {
  final String title;
  final Future<List<OrderModel>>? future;
  final String emptyText;
  final String primaryActionText;
  final Future<void> Function(int orderId) onPrimaryAction;
  final VoidCallback? onRefresh;

  const _OrdersTab({
    required this.title,
    required this.future,
    required this.emptyText,
    required this.primaryActionText,
    required this.onPrimaryAction,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final f = future;
    if (f == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async => onRefresh?.call(),
      child: FutureBuilder<List<OrderModel>>(
        future: f,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView(
              children: [
                SizedBox(height: 300),
                Center(child: CircularProgressIndicator()),
              ],
            );
          }

          if (snapshot.hasError) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                Center(child: Text(snapshot.error.toString())),
              ],
            );
          }

          final orders = List<OrderModel>.from(snapshot.data ?? const []);
          orders.sort((a, b) {
            final aKey = a.pickupTime ?? a.orderDate;
            final bKey = b.pickupTime ?? b.orderDate;
            final byPickup = aKey.compareTo(bKey);
            if (byPickup != 0) return byPickup;
            return a.orderDate.compareTo(b.orderDate);
          });
          if (orders.isEmpty) {
            return ListView(
              children: [
                const SizedBox(height: 120),
                Center(child: Text(emptyText)),
              ],
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final o = orders[index];
              final fmt = DateFormat('HH:mm');
              final pickupVn = VnTime.toVn(o.pickupTime ?? o.orderDate);
              final createdVn = VnTime.toVn(o.orderDate);

                final rightTime = (o.pickupTime == null)
                  ? 'Đặt ${fmt.format(createdVn)}'
                  : 'Nhận ${fmt.format(pickupVn)} (đặt ${fmt.format(createdVn)})';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('#${o.orderId}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Text(rightTime),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text('Tổng: ${Money.vnd(o.totalPrice)}'),
                      const SizedBox(height: 6),
                      Text('Món: ${o.orderItems.length}'),
                      const SizedBox(height: 8),
                      ...o.orderItems.map((item) {
                        final note = (item.note ?? '').trim();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ${item.quantity}x ${item.menuItemName}',
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              if (note.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(left: 12, top: 2),
                                  child: Text(
                                    'Note: $note',
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            try {
                              await onPrimaryAction(o.orderId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('$primaryActionText thành công')),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
                                );
                              }
                            }
                          },
                          child: Text(primaryActionText),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
