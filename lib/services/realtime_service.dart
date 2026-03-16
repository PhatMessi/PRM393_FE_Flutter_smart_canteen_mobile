import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../config/api_config.dart';

class KitchenNewOrderEvent {
  final int orderId;
  final int userId;

  const KitchenNewOrderEvent({required this.orderId, required this.userId});

  factory KitchenNewOrderEvent.fromArgs(List<Object?>? args) {
    final first = (args != null && args.isNotEmpty) ? args.first : null;
    if (first is Map) {
      final orderIdRaw = first['orderId'] ?? first['OrderId'] ?? 0;
      final userIdRaw = first['userId'] ?? first['UserId'] ?? 0;
      return KitchenNewOrderEvent(
        orderId: orderIdRaw is int ? orderIdRaw : int.tryParse(orderIdRaw.toString()) ?? 0,
        userId: userIdRaw is int ? userIdRaw : int.tryParse(userIdRaw.toString()) ?? 0,
      );
    }

    return const KitchenNewOrderEvent(orderId: 0, userId: 0);
  }
}

class OrderReadyEvent {
  final int orderId;
  final String message;

  const OrderReadyEvent({required this.orderId, required this.message});

  factory OrderReadyEvent.fromArgs(List<Object?>? args) {
    final first = (args != null && args.isNotEmpty) ? args.first : null;
    if (first is Map) {
      final orderIdRaw = first['orderId'] ?? first['OrderId'] ?? 0;
      final messageRaw = first['message'] ?? first['Message'] ?? '';
      return OrderReadyEvent(
        orderId: orderIdRaw is int ? orderIdRaw : int.tryParse(orderIdRaw.toString()) ?? 0,
        message: messageRaw.toString(),
      );
    }

    return const OrderReadyEvent(orderId: 0, message: 'Đơn hàng đã sẵn sàng');
  }
}

class RealtimeService {
  RealtimeService._();

  static final RealtimeService instance = RealtimeService._();

  HubConnection? _connection;

  final _kitchenNewOrderController = StreamController<KitchenNewOrderEvent>.broadcast();
  final _orderReadyController = StreamController<OrderReadyEvent>.broadcast();

  Stream<KitchenNewOrderEvent> get kitchenNewOrders => _kitchenNewOrderController.stream;
  Stream<OrderReadyEvent> get orderReady => _orderReadyController.stream;

  bool get isConnected => _connection?.state == HubConnectionState.Connected;

  Future<void> start({required String token}) async {
    if (token.isEmpty) return;
    if (_connection != null && isConnected) return;

    final options = HttpConnectionOptions(
      accessTokenFactory: () async => token,
    );

    final connection = HubConnectionBuilder()
        .withUrl(ApiConfig.realtimeHubUrl, options: options)
        .withAutomaticReconnect()
        .build();

    connection.on('KitchenNewOrder', (args) {
      final event = KitchenNewOrderEvent.fromArgs(args);
      if (event.orderId != 0) {
        _kitchenNewOrderController.add(event);
      }
    });

    connection.on('OrderReady', (args) {
      final event = OrderReadyEvent.fromArgs(args);
      if (event.orderId != 0) {
        _orderReadyController.add(event);
      }
    });

    _connection = connection;
    await connection.start();
  }

  Future<void> stop() async {
    final conn = _connection;
    _connection = null;
    if (conn != null) {
      await conn.stop();
    }
  }
}
