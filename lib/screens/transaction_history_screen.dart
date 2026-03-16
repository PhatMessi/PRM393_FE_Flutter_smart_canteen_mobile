import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Cần thêm package intl vào pubspec.yaml nếu chưa có
import '../models/transaction_model.dart';
import '../services/wallet_service.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import 'qr_scan_screen.dart';
import '../utils/money.dart';
import 'home_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  final String initialFilter;

  const TransactionHistoryScreen({super.key, this.initialFilter = 'Tat ca'});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final WalletService _walletService = WalletService();

  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  double _balance = 0.0;
  bool _isLoading = true;
  String _selectedFilter = "Tat ca"; // Tat ca, Thanh toan, Nap tien

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.initialFilter;
    _fetchData();
  }

  Future<void> _fetchData() async {
    final balance = await _walletService.getBalance();
    final history = await _walletService.getTransactionHistory();

    if (mounted) {
      setState(() {
        _balance = balance;
        _allTransactions = history;
        _filteredTransactions = history;
        _isLoading = false;
      });

      if (_selectedFilter != 'Tat ca') {
        _filterTransactions(_selectedFilter);
      }
    }
  }

  void _filterTransactions(String filterType) {
    setState(() {
      _selectedFilter = filterType;
      if (filterType == "Tat ca") {
        _filteredTransactions = _allTransactions;
      } else {
        String backendType = filterType;
        if (filterType == 'Thanh toan') backendType = 'Payment';
        if (filterType == 'Nap tien') backendType = 'TopUp';

        _filteredTransactions = _allTransactions
            .where((t) => t.type == backendType || t.type == filterType)
            .toList();
      }
    });
  }

  // Hàm nhóm giao dịch theo ngày
  Map<String, List<TransactionModel>> _groupTransactionsByDate(
    List<TransactionModel> transactions,
  ) {
    Map<String, List<TransactionModel>> grouped = {};
    for (var transaction in transactions) {
      String dateKey = _getDateLabel(transaction.date);
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      grouped[dateKey]!.add(transaction);
    }
    return grouped;
  }

  String _getDateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck == today) return "Hom nay";
    if (dateToCheck == yesterday) return "Hom qua";
    return DateFormat('MMM dd').format(date);
  }

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF2ED162);
    const Color scaffoldBg = Color(0xFFF9FAFB);

    // Tính tổng chi tiêu trong tháng (các giao dịch Payment)
    double totalSpent = _allTransactions
        .where((t) => t.type == 'Payment')
        .fold(0, (sum, t) => sum + t.amount);

    return Scaffold(
      backgroundColor: scaffoldBg,
      appBar: AppBar(
        backgroundColor: scaffoldBg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => _handleBack(context),
        ),
        title: const Text(
          "Lich su giao dich",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: brandGreen))
          : Column(
              children: [
                // 1. TOTAL SPENT CARD
                Container(
                  margin: const EdgeInsets.all(20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Tong chi tieu",
                            style: TextStyle(color: Colors.grey),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            Money.vnd(totalSpent),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Icons.circle,
                                size: 10,
                                color: brandGreen,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                "So du: ${Money.vnd(_balance)}",
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      // Hình minh họa đồng tiền vàng (dùng Icon thay thế)
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Color(0xFF1A1F1D),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.attach_money,
                          color: brandGreen,
                          size: 36,
                        ),
                      ),
                    ],
                  ),
                ),

                // 2. SEARCH & FILTER
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: "Tim theo mon hoac ngay",
                              border: InputBorder.none,
                              icon: Icon(Icons.search, color: Colors.grey),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 15),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      _buildFilterChip("Tat ca", _selectedFilter == "Tat ca"),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                        "Thanh toan",
                        _selectedFilter == "Thanh toan",
                        icon: Icons.fastfood,
                      ),
                      const SizedBox(width: 10),
                      _buildFilterChip(
                        "Nap tien",
                        _selectedFilter == "Nap tien",
                        icon: Icons.account_balance_wallet,
                      ),
                    ],
                  ),
                ),

                // 3. TRANSACTION LIST
                Expanded(
                  child: _filteredTransactions.isEmpty
                      ? const Center(child: Text("Khong tim thay giao dich"))
                      : ListView(
                          padding: const EdgeInsets.all(20),
                          children:
                              _groupTransactionsByDate(
                                _filteredTransactions,
                              ).entries.map((entry) {
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.key,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    ...entry.value
                                        .map((t) => _buildTransactionItem(t))
                                        .toList(),
                                    const SizedBox(height: 15),
                                  ],
                                );
                              }).toList(),
                        ),
                ),
              ],
            ),

      // --- BOTTOM NAVIGATION BAR (Giống Home, Active tại icon Receipt) ---
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
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 1),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, {IconData? icon}) {
    return GestureDetector(
      onTap: () => _filterTransactions(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1F1D) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 5),
            ],
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel t) {
    bool isNegative =
        t.type == "Payment" || t.type == "Withdrawal" || t.type == "Thanh toan";
    Color iconColor = t.type == "TopUp" || t.type == "Nap tien"
        ? const Color(0xFF2ED162)
        : (t.type == "Refund" ? Colors.purple : Colors.orange);
    IconData icon = t.type == "TopUp" || t.type == "Nap tien"
        ? Icons.account_balance_wallet
        : (t.type == "Refund" ? Icons.undo : Icons.fastfood);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 5),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.description.isNotEmpty ? t.description : t.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('hh:mm a').format(t.date),
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
              color: isNegative ? Colors.red : const Color(0xFF2ED162),
            ),
          ),
        ],
      ),
    );
  }
}
