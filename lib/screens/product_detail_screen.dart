import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart'; 
import '../utils/image_helper.dart'; // [FIX] Import image helper
import '../utils/money.dart';

// Định nghĩa màu xanh giống trong hình thiết kế
const Color kPrimaryColor = Color(0xFF2ED162); // Màu xanh lá sáng
const Color kBackgroundColor = Color(0xFFF8F9FA); // Màu nền xám rất nhạt

class ProductDetailScreen extends StatefulWidget {
  final MenuItem menuItem;

  const ProductDetailScreen({Key? key, required this.menuItem}) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;
  
  // --- FAKE DATA ĐỂ GIỐNG UI DESIGN (Vì Backend chưa có) ---
  // Sau này có API thì thay thế list này bằng dữ liệu từ API
  final String _calories = "520 kcal";
  final double _rating = 4.8;
  final int _reviews = 120;
  
  // Quản lý trạng thái chọn Sauce (Radio Button)
  String _selectedSauce = "Spicy Mayo";
  final List<String> _sauces = ["Spicy Mayo", "BBQ Sauce", "Honey Mustard"];

  // Quản lý trạng thái chọn Extras (Checkbox)
  // Map lưu tên món thêm và giá tiền
  final Map<String, double> _extrasOptions = {
    "Extra Cheese": 5000,
    "Add Coke Zero": 10000,
  };
  // List lưu những món đã được check
  final List<String> _selectedExtras = [];

  // Hàm tính tổng tiền: (Giá gốc + Giá Extras) * Số lượng
  double get totalPrice {
    double extrasTotal = 0;
    for (var extra in _selectedExtras) {
      extrasTotal += _extrasOptions[extra] ?? 0;
    }
    return (widget.menuItem.price + extrasTotal) * quantity;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          // 1. Phần nội dung cuộn được
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100), // Chừa chỗ cho BottomBar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderImage(context),
                _buildContentBody(),
              ],
            ),
          ),

          // 2. Nút Back và Favorite nằm đè lên ảnh (Top)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircleIconButton(Icons.arrow_back, () => Navigator.pop(context)),
                _buildCircleIconButton(Icons.favorite_border, () {
                  // TODO: Xử lý logic yêu thích sau
                }),
              ],
            ),
          ),

          // 3. Bottom Bar (Sticky at bottom)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(),
          ),
        ],
      ),
    );
  }

  // Widget hiển thị ảnh Header
  Widget _buildHeaderImage(BuildContext context) {
    return SizedBox( // Dùng SizedBox thay Container
      height: 300,
      width: double.infinity,
      child: buildProductImage(
        widget.menuItem.imageUrl,
        width: double.infinity,
        height: 300,
        fit: BoxFit.cover,
      ),
    );
  }

  // Widget nội dung chính
  Widget _buildContentBody() {
    return Container(
      decoration: const BoxDecoration(
        color: kBackgroundColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      transform: Matrix4.translationValues(0.0, -30.0, 0.0), // Đẩy lên đè ảnh một chút
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tên món và Giá
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.menuItem.name,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                ),
              ),
              Text(
                Money.vnd(widget.menuItem.price),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text("Canteen A • Western Station", style: TextStyle(color: Colors.grey)),

          const SizedBox(height: 20),
          // Hàng thông tin metrics (Rating, Calories, Tag)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricChip(Icons.star, "$_rating ($_reviews)", Colors.amber),
              _buildMetricChip(Icons.local_fire_department, _calories, Colors.orange),
              _buildMetricChip(Icons.eco, "Healthy", Colors.green),
            ],
          ),

          const SizedBox(height: 24),
          // Description
          const Text("Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(
            widget.menuItem.description ?? "No description available.",
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),

          const SizedBox(height: 24),
          // Choice of Sauce (Radio)
          _buildSectionHeader("Choice of Sauce", "(Required)"),
          ..._sauces.map((sauce) => RadioListTile<String>(
            title: Text(sauce),
            value: sauce,
            groupValue: _selectedSauce,
            activeColor: kPrimaryColor,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              setState(() {
                _selectedSauce = value!;
              });
            },
          )),

          const SizedBox(height: 16),
          // Extras (Checkbox)
          _buildSectionHeader("Extras", ""),
          ..._extrasOptions.entries.map((entry) => CheckboxListTile(
            title: Text(entry.key),
            secondary: Text(
              "+${Money.vnd(entry.value)}",
                style: const TextStyle(color: kPrimaryColor, fontWeight: FontWeight.bold)),
            value: _selectedExtras.contains(entry.key),
            activeColor: kPrimaryColor,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading, // Checkbox bên trái
            onChanged: (bool? checked) {
              setState(() {
                if (checked == true) {
                  _selectedExtras.add(entry.key);
                } else {
                  _selectedExtras.remove(entry.key);
                }
              });
            },
          )),
        ],
      ),
    );
  }

  // Widget Bottom Bar (Chứa nút tăng giảm và nút Add)
  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -5)),
        ],
      ),
      child: Row(
        children: [
          // Nút tăng giảm số lượng
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(30),
            ),
            child: Row(
              children: [
                _buildQuantityBtn(Icons.remove, () {
                  if (quantity > 1) setState(() => quantity--);
                }),
                const SizedBox(width: 16),
                Text("$quantity", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                _buildQuantityBtn(Icons.add, () {
                  setState(() => quantity++);
                }),
              ],
            ),
          ),
          const SizedBox(width: 20),
          // Nút Add to Order
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                // Lấy danh sách options đã chọn
                List<String> options = [_selectedSauce, ..._selectedExtras];
                
                // Gọi Provider để thêm vào giỏ
                Provider.of<CartProvider>(context, listen: false).addItem(
                  widget.menuItem,
                  quantity,
                  options,
                  totalPrice / quantity, // Giá đơn vị đã cộng toppings
                );

                // Hiển thị thông báo hoặc chuyển sang giỏ hàng
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Added ${widget.menuItem.name} to tray!"),
                    backgroundColor: kPrimaryColor,
                    action: SnackBarAction(
                      label: "VIEW TRAY",
                      textColor: Colors.white,
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CartScreen()));
                      },
                    ),
                  )
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Add to Order", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                    child: Text(Money.vnd(totalPrice), style: const TextStyle(color: Colors.white)),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // Các Widget nhỏ hỗ trợ (Helper Widgets)
  Widget _buildCircleIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.5), shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: Colors.white), onPressed: onPressed),
    );
  }

  Widget _buildMetricChip(IconData icon, String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(subtitle, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        ]
      ],
    );
  }

  Widget _buildQuantityBtn(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Icon(icon, size: 20, color: Colors.black87),
    );
  }
}