import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/transaction_history_screen.dart';
import '../screens/order_history_screen.dart';
import '../screens/user_dashboard_screen.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int selectedIndex;

<<<<<<< HEAD
  const CustomBottomNavBar({super.key, required this.selectedIndex});

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex)
      return; // Nếu đang ở trang đó rồi thì không làm gì
=======
  const CustomBottomNavBar({
    super.key,
    required this.selectedIndex,
  });

  void _onItemTapped(BuildContext context, int index) {
    if (index == selectedIndex) return; // Nếu đang ở trang đó rồi thì không làm gì
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8

    // Sử dụng pushReplacement để không bị chồng chất màn hình (tràn ram)
    // PageRouteBuilder để tắt hiệu ứng chuyển cảnh, tạo cảm giác như chuyển Tab
    PageRouteBuilder pageRoute(Widget page) {
      return PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      );
    }

    Widget nextScreen;
    switch (index) {
      case 0:
        nextScreen = const HomeScreen();
        break;
      case 1:
        nextScreen = const TransactionHistoryScreen();
        break;
      case 2:
<<<<<<< HEAD
=======
        // YÊU CẦU CỦA BẠN: Nút Ví (Index 2) mở OrderHistoryScreen
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
        nextScreen = const OrderHistoryScreen();
        break;
      case 3:
        nextScreen = const UserDashboardScreen();
        break;
      default:
        nextScreen = const HomeScreen();
    }

    Navigator.of(context).pushReplacement(pageRoute(nextScreen));
  }

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF2ED162);
    const Color inactiveColor = Colors.grey;

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8.0,
      color: const Color(0xFF1A1F1D), // Màu nền đen
      child: SizedBox(
        height: 60,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            // Tab 0: Home
            IconButton(
<<<<<<< HEAD
              icon: Icon(
                Icons.home_filled,
                color: selectedIndex == 0 ? brandGreen : inactiveColor,
              ),
              onPressed: () => _onItemTapped(context, 0),
            ),

            // Tab 1: Receipt (Lịch sử giao dịch)
            IconButton(
              icon: Icon(
                Icons.receipt_long,
                color: selectedIndex == 1 ? brandGreen : inactiveColor,
              ),
=======
              icon: Icon(Icons.home_filled, 
                color: selectedIndex == 0 ? brandGreen : inactiveColor),
              onPressed: () => _onItemTapped(context, 0),
            ),
            
            // Tab 1: Receipt (Lịch sử giao dịch)
            IconButton(
              icon: Icon(Icons.receipt_long, 
                color: selectedIndex == 1 ? brandGreen : inactiveColor),
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
              onPressed: () => _onItemTapped(context, 1),
            ),

            const SizedBox(width: 40), // Khoảng trống cho nút QR ở giữa
<<<<<<< HEAD
            // Tab 2: Orders (Lịch sử đơn hàng)
            IconButton(
              icon: Icon(
                Icons.account_balance_wallet,
                color: selectedIndex == 2 ? brandGreen : inactiveColor,
              ),
=======

            // Tab 2: Wallet (Lịch sử đơn hàng - THEO YÊU CẦU CỦA BẠN)
            IconButton(
              icon: Icon(Icons.account_balance_wallet, 
                color: selectedIndex == 2 ? brandGreen : inactiveColor),
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
              onPressed: () => _onItemTapped(context, 2),
            ),

            // Tab 3: Profile (Dashboard)
            IconButton(
<<<<<<< HEAD
              icon: Icon(
                Icons.person,
                color: selectedIndex == 3 ? brandGreen : inactiveColor,
              ),
=======
              icon: Icon(Icons.person, 
                color: selectedIndex == 3 ? brandGreen : inactiveColor),
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
              onPressed: () => _onItemTapped(context, 3),
            ),
          ],
        ),
      ),
    );
  }
<<<<<<< HEAD
}
=======
}
>>>>>>> e4d461e2e105481c2ac08024809f60dafe47eaf8
