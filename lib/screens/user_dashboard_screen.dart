import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../widgets/custom_bottom_nav_bar.dart';

class UserDashboardScreen extends StatelessWidget {
  const UserDashboardScreen({super.key});

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
                        backgroundImage: NetworkImage("https://i.pravatar.cc/150?img=5"), // Ảnh đại diện giả lập
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Good Morning,", style: TextStyle(color: Colors.grey, fontSize: 13)),
                          Text(
                            user?.fullName ?? "Alex!", 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)
                          ),
                        ],
                      )
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: const Icon(Icons.notifications_none, size: 24),
                  )
                ],
              ),
              const SizedBox(height: 25),

              // 2. BALANCE CARD (Thẻ đen xanh)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
                decoration: BoxDecoration(
                  color: cardDarkGreen,
                  borderRadius: BorderRadius.circular(30),
                  // Hiệu ứng gradient nhẹ để giống hình
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0D2418), Color(0xFF163E2B)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                ),
                child: Column(
                  children: [
                    const Text("CURRENT BALANCE", style: TextStyle(color: Colors.white54, fontSize: 12, letterSpacing: 1)),
                    const SizedBox(height: 10),
                    const Text("\$24.50", style: TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up, color: brandGreen, size: 16),
                          SizedBox(width: 5),
                          Text("+\$50.00 this week", style: TextStyle(color: brandGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    )
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // 3. ACTION BUTTONS (Top Up & My QR)
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Chuyển sang màn hình nạp tiền
                      },
                      icon: const Icon(Icons.account_balance_wallet, color: Colors.black),
                      label: const Text("Top Up", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGreen,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // TODO: Hiện QR
                      },
                      icon: const Icon(Icons.qr_code, color: Colors.black),
                      label: const Text("My QR", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                          side: BorderSide(color: Colors.grey.shade200)
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
                  borderRadius: BorderRadius.circular(40), // Bo tròn như hình viên thuốc
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                    child: const Icon(Icons.swap_horiz, color: Colors.blue),
                  ),
                  title: const Text("Transfer Funds", style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text("Send money to friends", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  trailing: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                    child: const Icon(Icons.arrow_forward, size: 16, color: Colors.black),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // 5. RECENT ORDERS TITLE
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recent Orders", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  TextButton(onPressed: () {}, child: const Text("See All", style: TextStyle(color: brandGreen)))
                ],
              ),

              // 6. LIST GIAO DỊCH (Fake Data giống hình)
              _buildTransactionItem("Burger Combo", "Main Cafeteria • 12:30 PM", "-\$8.50", Colors.orange, Icons.lunch_dining, false),
              _buildTransactionItem("Iced Latte", "Coffee Corner • 9:00 AM", "-\$3.50", Colors.brown, Icons.coffee, false),
              _buildTransactionItem("Wallet Top Up", "Credit Card • Yesterday", "+\$20.00", brandGreen, Icons.account_balance_wallet, true),
              
              const SizedBox(height: 80), // Padding bottom để không bị che bởi BottomBar
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

  // Widget con để vẽ từng dòng lịch sử giao dịch
  Widget _buildTransactionItem(String title, String subtitle, String price, Color iconBgColor, IconData icon, bool isPositive) {
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
              color: iconBgColor.withOpacity(0.2), 
              shape: BoxShape.circle
            ),
            child: Icon(icon, color: iconBgColor),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Text(
            price, 
            style: TextStyle(
              fontWeight: FontWeight.bold, 
              fontSize: 16,
              color: isPositive ? const Color(0xFF2ED162) : Colors.black
            )
          ),
        ],
      ),
    );
  }
}