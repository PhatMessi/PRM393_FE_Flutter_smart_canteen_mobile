import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';
import 'transaction_history_screen.dart';
import 'wallet_topup_screen.dart';
import '../models/transaction_model.dart';
import '../services/wallet_service.dart';
import '../utils/money.dart';

class UserDashboardScreen extends StatefulWidget {
  const UserDashboardScreen({super.key});

  @override
  State<UserDashboardScreen> createState() => _UserDashboardScreenState();
}

class _UserDashboardScreenState extends State<UserDashboardScreen> {
  final WalletService _walletService = WalletService();

  bool _isLoading = true;
  double _balance = 0.0;
  double _weekDelta = 0.0;
  List<TransactionModel> _recent = [];

  @override
  void initState() {
    super.initState();
    _fetchWalletSnapshot();
  }

  Future<void> _fetchWalletSnapshot() async {
    final balance = await _walletService.getBalance();
    final history = await _walletService.getTransactionHistory();

    history.sort((a, b) => b.date.compareTo(a.date));
    final recent = history.take(3).toList();

    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    double delta = 0;
    for (final t in history.where((t) => t.date.isAfter(weekAgo))) {
      if (t.type == 'TopUp' || t.type == 'Refund') {
        delta += t.amount;
      } else if (t.type == 'Payment') {
        delta -= t.amount;
      }
    }

    if (!mounted) return;
    setState(() {
      _balance = balance;
      _weekDelta = delta;
      _recent = recent;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Lấy thông tin user từ Provider (nếu có)
    final user = Provider.of<AuthProvider>(context).user;

    // Màu sắc chủ đạo (Giống Home)
    const Color brandGreen = Color(0xFF2ED162);
    const Color cardDarkGreen = Color(0xFF0D2418); // Màu nền thẻ ATM tối
    const Color scaffoldBg = Color(0xFFF9FAFB);

    return Scaffold(
      backgroundColor: scaffoldBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. HEADER (Giống Home nhưng avatar khác)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(
                          "https://i.pravatar.cc/150?img=5",
                        ), // Ảnh đại diện giả lập
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Good Morning,",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          Text(
                            user?.fullName ?? "Alex!",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none, size: 24),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // 2. BALANCE CARD (Thẻ đen xanh)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 30,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: cardDarkGreen,
                  borderRadius: BorderRadius.circular(30),
                  // Hiệu ứng gradient nhẹ để giống hình
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D2418), Color(0xFF163E2B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    const Text(
                      "CURRENT BALANCE",
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      Money.vnd(_balance),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _weekDelta >= 0
                                ? Icons.trending_up
                                : Icons.trending_down,
                            color: _weekDelta >= 0
                                ? brandGreen
                                : Colors.redAccent,
                            size: 16,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            "${_weekDelta >= 0 ? '+' : '-'}${Money.vnd(_weekDelta.abs())} this week",
                            style: TextStyle(
                              color: _weekDelta >= 0
                                  ? brandGreen
                                  : Colors.redAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 3. ACTION BUTTONS (Top Up & My QR)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final didTopUp = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const WalletTopUpScreen(),
                          ),
                        );

                        if (didTopUp == true) {
                          if (!mounted) return;
                          setState(() => _isLoading = true);
                          await _fetchWalletSnapshot();
                        }
                      },
                      icon: const Icon(
                        Icons.account_balance_wallet,
                        color: Colors.black,
                      ),
                      label: const Text(
                        "Top Up",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('My QR: coming soon')),
                        );
                      },
                      icon: const Icon(Icons.qr_code, color: Colors.black),
                      label: const Text(
                        "My QR",
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // 4. TRANSFER FUNDS ITEM
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(
                    40,
                  ), // Bo tròn như hình viên thuốc
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_horiz, color: Colors.blue),
                  ),
                  title: const Text(
                    "Transfer Funds",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    "Send money to friends",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // 4.1 CHAT ITEM (Messaging)
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    );
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.purple[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.purple,
                    ),
                  ),
                  title: const Text(
                    "Messaging",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    "Chat with support",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 16,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // 5. RECENT ORDERS TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Transactions",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransactionHistoryScreen(),
                        ),
                      );
                    },
                    child: const Text(
                      "See All",
                      style: TextStyle(color: brandGreen),
                    ),
                  ),
                ],
              ),

              // 6. LIST GIAO DỊCH (Real data)
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: CircularProgressIndicator(color: brandGreen),
                  ),
                )
              else if (_recent.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ..._recent
                    .map((t) => _buildTransactionRow(t, brandGreen))
                    .toList(),

              const SizedBox(
                height: 80,
              ), // Padding bottom để không bị che bởi BottomBar
            ],
          ),
        ),
      ),

      // --- BOTTOM NAVIGATION BAR (Copy y chang từ HomeScreen) ---
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: brandGreen,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 3),
    );
  }

  Widget _buildTransactionRow(TransactionModel t, Color brandGreen) {
    final isNegative = t.type == 'Payment' || t.type == 'Withdrawal';
    final iconColor = t.type == 'TopUp'
        ? brandGreen
        : (t.type == 'Refund' ? Colors.purple : Colors.orange);
    final icon = t.type == 'TopUp'
        ? Icons.account_balance_wallet
        : (t.type == 'Refund' ? Icons.undo : Icons.fastfood);

    final timeText = DateFormat('dd/MM • HH:mm').format(t.date.toLocal());
    final title = t.description.isNotEmpty ? t.description : t.type;

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  timeText,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            "${isNegative ? '-' : '+'}${Money.vnd(t.amount)}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: isNegative ? Colors.black : const Color(0xFF2ED162),
            ),
          ),
        ],
      ),
    );
  }
}
