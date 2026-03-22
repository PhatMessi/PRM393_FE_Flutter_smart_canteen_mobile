import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/cart_provider.dart';
import '../services/menu_service.dart';
import '../models/menu_item.dart';
import 'product_detail_screen.dart'; // <--- 1. BỔ SUNG IMPORT NÀY
import 'notifications_screen.dart';
import 'cart_screen.dart';
import '../services/auth_service.dart';
import '../services/local_notification_service.dart';
import '../services/realtime_service.dart';
import '../widgets/custom_bottom_nav_bar.dart';
import '../utils/image_helper.dart'; // [FIX] Import Helper
import '../utils/money.dart';
import 'qr_scan_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MenuService _menuService = MenuService();
  final AuthService _authService = AuthService();
  StreamSubscription<OrderReadyEvent>? _orderReadySub;
  
  List<Category> _categories = [];
  List<MenuItem> _menuItems = [];
  bool _isLoading = true;
  int _selectedCategoryId = -1; // -1 là "Tat ca"

  @override
  void initState() {
    super.initState();
    _fetchData();
    _startRealtime();
  }

  Future<void> _startRealtime() async {
    final token = await _authService.getToken();
    if (!mounted || token == null || token.isEmpty) return;

    await RealtimeService.instance.start(token: token);

    _orderReadySub?.cancel();
    _orderReadySub = RealtimeService.instance.orderReady.listen((event) {
      if (!mounted) return;
      LocalNotificationService.instance.showStudentOrderReady(orderId: event.orderId, message: event.message);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(event.message.isNotEmpty ? event.message : 'Đơn #${event.orderId} đã sẵn sàng')),
      );
    });
  }

  @override
  void dispose() {
    _orderReadySub?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    
    // Load Categories và Menu song song
    final categories = await _menuService.getCategories();
    final menu = await _menuService.getMenuItems(
      categoryId: _selectedCategoryId == -1 ? null : _selectedCategoryId
    );

    if (mounted) {
      setState(() {
        _categories = [Category(categoryId: -1, name: "Tất cả"), ...categories];
        _menuItems = menu;
        _isLoading = false;
      });
    }
  }

  void _onCategorySelected(int id) async {
    setState(() {
      _selectedCategoryId = id;
      _isLoading = true;
    });
    final menu = await _menuService.getMenuItems(
      categoryId: id == -1 ? null : id
    );
    if (mounted) {
      setState(() {
        _menuItems = menu;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final cartCount = context.select<CartProvider, int>((cart) => cart.itemCount);
    const Color brandGreen = Color(0xFF2ED162); // Đã chỉnh lại màu cho giống ProductDetailScreen

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: brandGreen))
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. HEADER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 22,
                              backgroundImage: AssetImage('assets/images/Carteen.png'),
                              backgroundColor: Colors.white,
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("Chào buổi sáng,", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                Text(
                                  "Xin chào, ${user?.fullName ?? 'Học sinh'} 👋", 
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                ),
                              ],
                            )
                          ],
                        ),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const CartScreen()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: Stack(
                                  clipBehavior: Clip.none,
                                  children: [
                                    const Icon(Icons.shopping_cart_outlined, size: 24),
                                    if (cartCount > 0)
                                      Positioned(
                                        top: -6,
                                        right: -8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.all(Radius.circular(10)),
                                          ),
                                          constraints: const BoxConstraints(minWidth: 18, minHeight: 14),
                                          child: Text(
                                            cartCount > 99 ? '99+' : '$cartCount',
                                            textAlign: TextAlign.center,
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                                child: const Icon(Icons.notifications_outlined, size: 24),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // 2. SEARCH BAR
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const TextField(
                        decoration: InputDecoration(
                          hintText: "Tìm món ăn, đồ uống...",
                          hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                          border: InputBorder.none,
                          icon: Icon(Icons.search, color: Colors.grey),
                          suffixIcon: Icon(Icons.tune, color: brandGreen),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 3. BANNER
                    Container(
                      width: double.infinity,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: LinearGradient(colors: [Colors.grey.shade400, Colors.grey.shade300]),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.asset(
                                'assets/images/banner.png',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Center(
                                        child: Icon(Icons.image_not_supported,
                                            color: Colors.white, size: 50)),
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                              ),
                            ),
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(color: brandGreen, borderRadius: BorderRadius.circular(20)),
                                  child: const Text("GIẢM 50%", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                                ),
                                const SizedBox(height: 5),
                                const Text("Ưu đãi hôm nay", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                                const Text("Combo giá tốt mỗi ngày", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 4. CATEGORIES
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _categories.map((cat) {
                          bool isSelected = cat.categoryId == _selectedCategoryId;
                          return Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: GestureDetector(
                              onTap: () => _onCategorySelected(cat.categoryId),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? brandGreen : Colors.white,
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: isSelected ? [BoxShadow(color: brandGreen.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 4))] : [],
                                ),
                                child: Text(
                                  cat.name,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 5. POPULAR MENU TITLE
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("Món phổ biến", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        TextButton(onPressed: () {}, child: const Text("Xem tất cả", style: TextStyle(color: brandGreen)))
                      ],
                    ),

                    // 6. MENU LIST (ĐÃ FIX ĐIỀU HƯỚNG)
                    _menuItems.isEmpty 
                        ? const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("Không tìm thấy món nào")))
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _menuItems.length,
                            itemBuilder: (context, index) {
                              final item = _menuItems[index];
                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProductDetailScreen(menuItem: item),
                                    ),
                                  );
                                },
                                child: Container(
                                  margin: const EdgeInsets.only(bottom: 15),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 5))]
                                  ),
                                  child: Row(
                                    children: [
                                      // ẢNH MÓN (Có xử lý lỗi)
                                      Hero(
                                        tag: 'product_img_${item.itemId}',
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(15),
                                          // [FIX] Sử dụng helper để load ảnh local hoặc online
                                          child: buildProductImage(
                                            item.imageUrl,
                                            width: 80, 
                                            height: 80, 
                                            fit: BoxFit.cover
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 15),
                                      
                                      // THÔNG TIN MÓN (Fix Overflow)
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (index % 2 == 0) // Giả lập logic HOT
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                decoration: BoxDecoration(color: Colors.orange[50], borderRadius: BorderRadius.circular(10)),
                                                child: const Text("\uD83D\uDD25 BÁN CHẠY", style: TextStyle(color: Colors.orange, fontSize: 10, fontWeight: FontWeight.bold)),
                                              ),
                                            const SizedBox(height: 5),
                                            
                                            // --- ĐÃ FIX: TextOverflow ---
                                            Text(
                                              item.name, 
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                              maxLines: 1, 
                                              overflow: TextOverflow.ellipsis, // Cắt chữ ... khi quá dài
                                            ),
                                            // ----------------------------
                                            
                                            const SizedBox(height: 5),
                                            const Text("~ 10 phút • 450 kcal", style: TextStyle(color: Colors.grey, fontSize: 12)),
                                            const SizedBox(height: 8),
                                            Text(Money.vnd(item.price), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                          ],
                                        ),
                                      ),
                                      
                                      // NÚT CỘNG
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(color: brandGreen, shape: BoxShape.circle),
                                        child: const Icon(Icons.add, color: Colors.white),
                                      )
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(selectedIndex: 0),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const QrScanScreen()),
          );
        },
        backgroundColor: brandGreen,
        shape: const CircleBorder(),
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}