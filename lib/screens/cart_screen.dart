import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'checkout_screen.dart';
import 'home_screen.dart';
import '../utils/image_helper.dart';
import '../utils/money.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  void _handleBack(BuildContext context) {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    const Color brandGreen = Color(0xFF00E676);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: const Text("Khay của bạn", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () => _handleBack(context),
          ),
        ),
      ),
      body: Column(
        children: [
          // 1. LIST ITEMS
          Expanded(
            child: cart.items.isEmpty
              ? const Center(child: Text("Khay của bạn đang trống!"))
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: cart.items.length + 1, // +1 cho nút "Add more items"
                    itemBuilder: (context, index) {
                      if (index == cart.items.length) {
                        // Nút Add more items ở cuối list
                        return Center(
                          child: TextButton.icon(
                            onPressed: () => _handleBack(context), // Quay về Home chọn tiếp
                            icon: const Icon(Icons.add_circle, color: brandGreen),
                            label: const Text("Thêm món khác", style: TextStyle(color: Colors.grey)),
                          ),
                        );
                      }

                      final item = cart.items[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 15),
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Ảnh
                            ClipRRect(
                              borderRadius: BorderRadius.circular(50), // Ảnh tròn
                              child: buildProductImage(
                                item.menuItem.imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 15),
                            // Thông tin
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(item.menuItem.name, 
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          maxLines: 1, overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      GestureDetector(
                                        onTap: () => cart.removeItem(item.id),
                                        child: const Icon(Icons.close, size: 18, color: Colors.grey),
                                      )
                                    ],
                                  ),
                                  // Hiển thị Options (Sốt, toppings)
                                  if (item.orderItemNote != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4, bottom: 4),
                                      child: Text(
                                        item.orderItemNote ?? "Mặc định",
                                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                                        maxLines: 2, overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(Money.vnd(item.totalPrice), 
                                        style: const TextStyle(color: brandGreen, fontWeight: FontWeight.bold, fontSize: 16)),
                                      // Nút tăng giảm số lượng nhỏ gọn
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(20)),
                                        child: Row(
                                          children: [
                                            InkWell(onTap: () => cart.updateQuantity(item.id, -1), child: const Icon(Icons.remove, size: 16)),
                                            const SizedBox(width: 10),
                                            Text("${item.quantity}", style: const TextStyle(fontWeight: FontWeight.bold)),
                                            const SizedBox(width: 10),
                                            InkWell(
                                              onTap: () => cart.updateQuantity(item.id, 1),
                                              child: Container(
                                                padding: const EdgeInsets.all(2),
                                                decoration: const BoxDecoration(color: brandGreen, shape: BoxShape.circle),
                                                child: const Icon(Icons.add, size: 14, color: Colors.white),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    ],
                                  )
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // 2. BILL SUMMARY & CHECKOUT BUTTON
          Container(
            padding: const EdgeInsets.all(25),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
            ),
            child: Column(
              children: [
                _buildSummaryRow("Tạm tính", Money.vnd(cart.subtotal)),
                const SizedBox(height: 10),
                _buildSummaryRow("Thuế (10%)", Money.vnd(cart.tax)),
                const Padding(padding: EdgeInsets.symmetric(vertical: 15), child: Divider()),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Tổng cộng", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    Text(Money.vnd(cart.totalAmount), 
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: brandGreen)),
                  ],
                ),
                const SizedBox(height: 15),
                const Row(
                  children: [
                    Icon(Icons.credit_card, size: 16, color: Colors.grey),
                    SizedBox(width: 8),
                    Text("Thanh toán bằng thẻ học sinh", style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: cart.items.isEmpty ? null : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const CheckoutScreen()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: brandGreen,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      elevation: 5,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Thanh toán", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white)
                      ],
                    ),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}