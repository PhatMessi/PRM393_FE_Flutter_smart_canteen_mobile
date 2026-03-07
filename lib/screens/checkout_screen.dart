import 'package:flutter/material.dart';
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

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final WalletService _walletService = WalletService();
  double _walletBalance = 0.0;
  bool _isLoading = true;

  String _selectedTime = "12:00 PM";
  final List<String> _pickupTimes = [
    "12:00 PM",
    "12:15 PM",
    "12:30 PM",
    "12:45 PM",
  ];

  DateTime _pickupTimeFromSelection() {
    final now = DateTime.now();
    final parts = _selectedTime.split(' ');
    final timePart = parts.isNotEmpty ? parts[0] : '12:00';
    final ampm = parts.length > 1 ? parts[1].toUpperCase() : 'PM';

    final hm = timePart.split(':');
    final hour12 = int.tryParse(hm.isNotEmpty ? hm[0] : '12') ?? 12;
    final minute = int.tryParse(hm.length > 1 ? hm[1] : '0') ?? 0;

    int hour24;
    if (ampm == 'AM') {
      hour24 = hour12 % 12;
    } else {
      hour24 = (hour12 % 12) + 12;
    }

    var pickup = DateTime(now.year, now.month, now.day, hour24, minute);
    // Ensure pickup time is in the future (backend enforces this).
    if (!pickup.isAfter(now)) {
      pickup = pickup.add(const Duration(days: 1));
    }
    return pickup;
  }

  String _extractErrorMessage(String body) {
    if (body.trim().isEmpty) return 'Unknown error';
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
          content: const Text("Insufficient funds! Please top up your wallet."),
          action: SnackBarAction(
            label: 'Top Up',
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
        ).showSnackBar(const SnackBar(content: Text("Please login first!")));
        return;
      }

      final orderData = {
        "items": cart.items
            .map(
              (item) => {
                "menuItemId": item.menuItem.itemId,
                "quantity": item.quantity,
              },
            )
            .toList(),
        // Use user selected pickup time
        "pickupTime": _pickupTimeFromSelection().toIso8601String(),
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
          "Failed to place order: ${_extractErrorMessage(response.body)}",
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
            "Your order has been placed and paid successfully.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } else {
      final msg = _extractErrorMessage(response.body);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Payment failed: $msg")));
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
          "Checkout",
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
                              "Wallet Balance",
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
                                  ? "SUFFICIENT FUNDS"
                                  : "INSUFFICIENT FUNDS",
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
                    "Your Order",
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
                            item.selectedOptions.join(", "),
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
                        "Pickup Time",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        "*Required",
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _pickupTimes.map((time) {
                        bool isSelected = time == _selectedTime;
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedTime = time),
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
                                time,
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  const SizedBox(height: 30),
                  // 4. SUMMARY
                  _buildSummaryRow("Subtotal", Money.vnd(cart.subtotal)),
                  const SizedBox(height: 10),
                  _buildSummaryRow("Tax (5%)", Money.vnd(cart.tax)),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total",
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
                            "Pay ${Money.vnd(cart.totalAmount)}",
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
