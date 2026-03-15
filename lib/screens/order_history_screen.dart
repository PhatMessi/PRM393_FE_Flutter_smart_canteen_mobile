import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Cần thêm package intl
import '../providers/order_provider.dart';
import '../models/order_model.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'map_screen.dart';
import 'order_detail_screen.dart';
import '../utils/image_helper.dart';
import '../utils/money.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  String _selectedTab = "Tat ca"; // Tab mặc định
  final List<String> _tabs = ["Tat ca", "Cho xu ly", "San sang", "Lich su"];

  @override
  void initState() {
    super.initState();
    // Load dữ liệu khi vào màn hình
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).loadMyOrders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final displayedOrders = orderProvider.getOrdersByStatus(_selectedTab);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "Lich su don hang",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        centerTitle: false,
        automaticallyImplyLeading: false, // Tắt nút back mặc định
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune, color: Colors.black),
          ), // Nút Filter
        ],
      ),
      body: Column(
        children: [
          // 1. TABS (Capsule shape)
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _tabs.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final tab = _tabs[index];
                final isSelected = _selectedTab == tab;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedTab = tab;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF2ED162)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(25),
                      border: isSelected
                          ? null
                          : Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        tab,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // 2. LIST ORDERS
          Expanded(
            child: orderProvider.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2ED162)),
                  )
                : (orderProvider.error != null)
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        orderProvider.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : displayedOrders.isEmpty
                ? const Center(child: Text("Khong co don hang nao"))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: displayedOrders.length,
                    itemBuilder: (context, index) {
                      return _buildOrderCard(displayedOrders[index]);
                    },
                  ),
          ),
        ],
      ),
      // Giữ BottomBar để đồng bộ trải nghiệm
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 2),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFF2ED162),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  void _openOrderDetail(OrderModel order) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
    );
  }

  // WIDGET CON: THẺ ĐƠN HÀNG
  Widget _buildOrderCard(OrderModel order) {
    Color statusColor;
    String statusText = order.status.toUpperCase();
    IconData? statusIcon;

    // Logic màu sắc trạng thái giống hình
    switch (order.status) {
      case "Ready for Pickup":
        statusColor = const Color(0xFF2ED162); // Xanh lá
        statusText = "SAN SANG NHAN MON";
        break;
      case "Preparing":
        statusColor = Colors.orange; // Vàng
        statusText = "DANG CHUAN BI";
        break;
      case "Paid":
        statusColor = Colors.orange;
        statusText = "DA THANH TOAN";
        break;
      case "Pending Payment":
        statusColor = Colors.orange;
        statusText = "CHO THANH TOAN";
        break;
      case "Cancelled":
        statusColor = Colors.red;
        statusIcon = Icons.error;
        statusText = "DA HUY";
        break;
      case "Completed":
        statusColor = Colors.grey;
        statusIcon = Icons.check_circle;
        statusText = "HOAN TAT";
        break;
      default:
        statusColor = Colors.blue;
    }

    final firstItem = order.orderItems.isNotEmpty ? order.orderItems[0] : null;
    final otherItemsCount = order.orderItems.length - 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: Status + Order ID + Time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (statusIcon != null)
                    Icon(statusIcon, size: 16, color: statusColor)
                  else
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Text(
                "#${order.orderId} • ${DateFormat('HH:mm').format(order.orderDate.toLocal())}",
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Rejected Reason Box (Chỉ hiện nếu Rejected)
          if (order.status == "Cancelled" && order.rejectionReason != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                "Ly do: ${order.rejectionReason}",
                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
              ),
            ),

          // Content: Image + Info
          Row(
            children: [
              // Ảnh món ăn (Giả lập nếu không có URL)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: firstItem?.imageUrl != null
                    ? buildProductImage(
                        firstItem!.imageUrl!,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.fastfood, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firstItem != null
                          ? (otherItemsCount > 0
                                ? "${firstItem.menuItemName} + $otherItemsCount mon khac"
                                : firstItem.menuItemName)
                          : "Khong ro mon",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      firstItem?.note ?? "Mac dinh",
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      Money.vnd(order.totalPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons
          if (order.status == "Ready for Pickup")
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const MapScreen()),
                      );
                    },
                    icon: const Icon(Icons.location_on, size: 18),
                    label: const Text("Theo doi don"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2ED162),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _openOrderDetail(order),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text("Xem chi tiet"),
                  ),
                ),
              ],
            )
          else if (order.status == "Pending Payment" || order.status == "Paid")
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _openOrderDetail(order),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey.shade100,
                  foregroundColor: Colors.black,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text("Xem chi tiet"),
              ),
            )
          else if (order.status == "Completed")
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text("Danh gia"),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text("Dat lai"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD4F8E2), // Màu xanh nhạt
                      foregroundColor: const Color(0xFF2ED162),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
