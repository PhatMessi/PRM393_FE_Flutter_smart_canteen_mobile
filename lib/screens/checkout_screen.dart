import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/wallet_service.dart';
import '../services/auth_service.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'wallet_topup_screen.dart';
import '../utils/image_helper.dart';
import '../utils/money.dart';
import '../utils/vn_time.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final WalletService _walletService = WalletService();
  double _walletBalance = 0.0;
  bool _isLoading = true;

  late List<DateTime> _pickupSlotsUtc;
  late DateTime _selectedPickupUtc;

  bool _sameMinuteUtc(DateTime a, DateTime b) {
    final au = a.toUtc();
    final bu = b.toUtc();
    return au.year == bu.year &&
        au.month == bu.month &&
        au.day == bu.day &&
        au.hour == bu.hour &&
        au.minute == bu.minute;
  }

  Future<void> _pickCustomPickupTime() async {
    final nowVn = VnTime.now();
    final maxVn = nowVn.add(const Duration(hours: 3));

    final initialVn = VnTime.toVn(_selectedPickupUtc);
    final initial = TimeOfDay(hour: initialVn.hour, minute: initialVn.minute);

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );

    if (!mounted || picked == null) return;

    // Build VN DateTime for today. If it's already passed, treat as next day.
    var candidateVn = DateTime(
      nowVn.year,
      nowVn.month,
      nowVn.day,
      picked.hour,
      picked.minute,
    );

    if (candidateVn.isBefore(nowVn)) {
      candidateVn = candidateVn.add(const Duration(days: 1));
    }

    if (candidateVn.isAfter(maxVn) || candidateVn.isBefore(nowVn)) {
      final fmt = DateFormat('HH:mm');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Giờ nhận chỉ được trong 3 giờ tới (tối đa ${fmt.format(maxVn)}).',
            ),
          ),
        );
      }
      return;
    }

    final utc = VnTime.utcFromVnWall(
      candidateVn.year,
      candidateVn.month,
      candidateVn.day,
      candidateVn.hour,
      candidateVn.minute,
    );

    setState(() {
      _selectedPickupUtc = utc;
    });
  }

  List<DateTime> _buildPickupSlotsUtc() {
    final nowUtc = DateTime.now().toUtc();
    final nowVn = nowUtc.add(VnTime.offset);

    // Round up to next 15-minute mark in Vietnam time.
    final minute = nowVn.minute;
    final remainder = minute % 15;
    final addMinutes = remainder == 0 ? 15 : (15 - remainder);
    final baseVn = DateTime(
      nowVn.year,
      nowVn.month,
      nowVn.day,
      nowVn.hour,
      nowVn.minute,
    ).add(Duration(minutes: addMinutes));

    final slots = <DateTime>[];
    for (var i = 0; i < 4; i++) {
      final vnSlot = baseVn.add(Duration(minutes: i * 15));
      final utcSlot = VnTime.utcFromVnWall(
        vnSlot.year,
        vnSlot.month,
        vnSlot.day,
        vnSlot.hour,
        vnSlot.minute,
      );
      slots.add(utcSlot);
    }

    // Ensure all slots are in the future (UTC).
    return slots.where((s) => s.isAfter(nowUtc)).toList();
  }

  String _extractErrorMessage(String body) {
    if (body.trim().isEmpty) return 'Loi khong xac dinh';
    try {
      final data = jsonDecode(body);
      if (data is Map<String, dynamic>) {
        final msg =
            data['message'] ??
            data['Message'] ??
            data['error'] ??
            data['Error'];
        if (msg != null) return msg.toString();
      }
    } catch (_) {
      // Ignore JSON parse errors
    }
    return body;
  }

  @override
  void initState() {
    super.initState();
    _pickupSlotsUtc = _buildPickupSlotsUtc();
    _selectedPickupUtc = _pickupSlotsUtc.isNotEmpty
        ? _pickupSlotsUtc.first
        : DateTime.now().toUtc().add(const Duration(minutes: 30));
    _fetchWalletBalance();
  }

  Future<void> _fetchWalletBalance() async {
    final balance = await _walletService.getBalance();
    if (mounted) {
      setState(() {
        _walletBalance = balance;
        _isLoading = false;
      });
    }
  }

  Future<void> _processPayment(BuildContext context) async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    if (_walletBalance < cart.totalAmount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("So du khong du! Vui long nap them vao vi."),
          action: SnackBarAction(
            label: 'Nap tien',
            onPressed: () async {
              final didTopUp = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => const WalletTopUpScreen()),
              );

              if (didTopUp == true) {
                await _fetchWalletBalance();
              }
            },
          ),
        ),
      );
      return;
    }

    try {
      // Lấy token từ AuthService (đã fix)
      final token = await AuthService().getToken();
      if (token == null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Vui long dang nhap truoc!")));
        return;
      }

      final orderData = {
        "items": cart.items
            .map(
              (item) => {
                "menuItemId": item.menuItem.itemId,
                "quantity": item.quantity,
                "note": item.orderItemNote,
              },
            )
            .toList(),
        // Use user selected pickup time
        // Always send UTC (with 'Z') so backend doesn't misinterpret timezone.
        "pickupTime": _selectedPickupUtc.toIso8601String(),
      };

      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/orders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(orderData),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        final orderId = responseData['orderId'];

        await _confirmPayment(orderId);
      } else {
        throw Exception(
          "Dat don that bai: ${_extractErrorMessage(response.body)}",
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Loi: $e")));
    }
  }

  Future<void> _confirmPayment(int orderId) async {
    final token = await AuthService().getToken();
    if (token == null) return;

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/orders/$orderId/confirm-payment'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      if (!mounted) return;
      Provider.of<CartProvider>(context, listen: false).clearCart();

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text("Success!"),
          content: const Text(
            "Don hang da duoc dat va thanh toan thanh cong.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text("Dong"),
            ),
          ],
        ),
      );
    } else {
      final msg = _extractErrorMessage(response.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Thanh toan that bai: $msg")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    const Color brandGreen = Color(0xFF00E676);
    bool isSufficient = _walletBalance >= cart.totalAmount;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text(
          "Thanh toan",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. WALLET CARD
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: brandGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet,
                                color: brandGreen,
                              ),
                            ),
                            const SizedBox(width: 10),
                            const Text(
                              "So du vi",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          Money.vnd(_walletBalance),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Icon(
                              isSufficient ? Icons.check_circle : Icons.error,
                              color: isSufficient ? brandGreen : Colors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isSufficient
                                  ? "DU SO DU"
                                    : "KHONG DU SO DU",
                              style: TextStyle(
                                color: isSufficient ? brandGreen : Colors.red,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),
                  const Text(
                    "Don hang cua ban",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 15),

                  // 2. ORDER ITEMS
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (ctx, i) {
                        final item = cart.items[i];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: buildProductImage(
                              item.menuItem.imageUrl,
                              width: 50,
                              height: 50,
                              fit: BoxFit.cover,
                            ),
                          ),
                          title: Text(
                            item.menuItem.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            item.orderItemNote ?? "Mac dinh",
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Text(
                            Money.vnd(item.totalPrice),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 25),
                  // 3. PICKUP TIME
                  Row(
                    children: [
                      const Text(
                        "Gio nhan mon",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "*Bat buoc",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _pickupSlotsUtc.map((slotUtc) {
                              final label = DateFormat('HH:mm').format(VnTime.toVn(slotUtc));
                              final isSelected = _sameMinuteUtc(slotUtc, _selectedPickupUtc);
                              return Padding(
                                padding: const EdgeInsets.only(right: 10),
                                child: GestureDetector(
                                  onTap: () => setState(() => _selectedPickupUtc = slotUtc),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSelected ? brandGreen : Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: isSelected
                                            ? Colors.transparent
                                            : Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        color: isSelected ? Colors.white : Colors.black87,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _pickCustomPickupTime,
                        child: const Text('Chọn giờ khác'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  // 4. SUMMARY
                  _buildSummaryRow("Tam tinh", Money.vnd(cart.subtotal)),
                  const SizedBox(height: 10),
                  _buildSummaryRow("Thue (5%)", Money.vnd(cart.tax)),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Tong cong",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        Money.vnd(cart.totalAmount),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),
                  // 5. PAY BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSufficient
                          ? () => _processPayment(context)
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGreen,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_forward, color: Colors.white),
                          const SizedBox(width: 10),
                          Text(
                            "Thanh toan ${Money.vnd(cart.totalAmount)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        Text(value, style: const TextStyle(color: Colors.grey, fontSize: 16)),
      ],
    );
  }
}
