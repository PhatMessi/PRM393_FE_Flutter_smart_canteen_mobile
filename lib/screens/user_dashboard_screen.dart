import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'qr_scan_screen.dart';
import 'chat_screen.dart';
import 'notifications_screen.dart';
import 'login_screen.dart';
import 'transaction_history_screen.dart';
import 'wallet_topup_screen.dart';
import '../models/transaction_model.dart';
import '../services/wallet_service.dart';
import '../utils/money.dart';
import '../utils/vn_time.dart';
import 'promotions_screen.dart';

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

  Future<void> _openTransferHub() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Chuyen tien nhanh',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Chon tac vu phu hop de thao tac nhanh hon',
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE8F9EF),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: Color(0xFF2ED162),
                    ),
                  ),
                  title: const Text('Nap tien vao vi'),
                  subtitle: const Text('Bo sung so du de thanh toan don hang'),
                  onTap: () => Navigator.pop(ctx, 'topup'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue.shade50,
                    child: const Icon(Icons.history, color: Colors.blue),
                  ),
                  title: const Text('Xem lich su giao dich'),
                  subtitle: const Text('Theo doi nap tien va thanh toan'),
                  onTap: () => Navigator.pop(ctx, 'history'),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: Colors.purple.shade50,
                    child: const Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.purple,
                    ),
                  ),
                  title: const Text('Nhan tin ho tro'),
                  subtitle: const Text('Can tro giup khi can giao dich'),
                  onTap: () => Navigator.pop(ctx, 'chat'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    if (action == 'topup') {
      final didTopUp = await Navigator.push<bool>(
        context,
        MaterialPageRoute(builder: (_) => const WalletTopUpScreen()),
      );
      if (didTopUp == true) {
        if (!mounted) return;
        setState(() => _isLoading = true);
        await _fetchWalletSnapshot();
      }
      return;
    }

    if (action == 'history') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
      );
      return;
    }

    if (action == 'chat') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ChatScreen()),
      );
    }
  }

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
      if (t.type == 'TopUp' || t.type == 'Refund' || t.type == 'Nap tien') {
        delta += t.amount;
      } else if (t.type == 'Payment' || t.type == 'Thanh toan') {
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
                            "Chao buoi sang,",
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          Text(
                            user?.fullName ?? "Ban!",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: [
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
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () async {
                          await Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).logout();
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const LoginScreen()),
                            (_) => false,
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.logout, size: 22),
                        ),
                      ),
                    ],
                  )
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
                      "SO DU HIEN TAI",
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
                            "${_weekDelta >= 0 ? '+' : '-'}${Money.vnd(_weekDelta.abs())} trong tuan nay",
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
                        "Nap tien",
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
                          const SnackBar(
                            content: Text('Ma QR cua toi: sap co'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.qr_code, color: Colors.black),
                      label: const Text(
                        "Ma QR cua toi",
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
                  onTap: _openTransferHub,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_horiz, color: Colors.blue),
                  ),
                  title: const Text(
                    "Chuyen tien",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  // subtitle: const Text(
                  //   "Gui tien cho ban be",
                  //   style: TextStyle(fontSize: 12, color: Colors.grey),
                  // ),
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

              // 4.0 FAVORITES ITEM
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.pushNamed(context, '/favorites');
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite, color: Colors.red),
                  ),
                  title: const Text(
                    'Yeu thich',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
              // 4.05 VOUCHER ITEM
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
                      MaterialPageRoute(builder: (_) => const PromotionsScreen()),
                    );
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.local_offer, color: Color(0xFF2ED162)),
                  ),
                  title: const Text(
                    'Voucher',
                    style: TextStyle(fontWeight: FontWeight.bold),
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
                    "Nhan tin",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    "Tro chuyen voi ho tro",
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
                    "Giao dich gan day",
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
                      "Xem tat ca",
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
                      'Chua co giao dich nao',
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
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QrScanScreen()),
          );
        },
        backgroundColor: brandGreen,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 3),
    );
  }

  Widget _buildTransactionRow(TransactionModel t, Color brandGreen) {
    final isNegative =
        t.type == 'Payment' || t.type == 'Withdrawal' || t.type == 'Thanh toan';
    final iconColor = t.type == 'TopUp' || t.type == 'Nap tien'
        ? brandGreen
        : (t.type == 'Refund' ? Colors.purple : Colors.orange);
    final icon = t.type == 'TopUp' || t.type == 'Nap tien'
        ? Icons.account_balance_wallet
        : (t.type == 'Refund' ? Icons.undo : Icons.fastfood);

    final timeText = DateFormat('dd/MM • HH:mm').format(VnTime.toVn(t.date));
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
