import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/promotion_model.dart';
import '../providers/cart_provider.dart';
import '../services/menu_service.dart';
import '../services/promotions_service.dart';
import '../utils/money.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final PromotionsService _service = PromotionsService();
  final MenuService _menuService = MenuService();

  late Future<List<PromotionModel>> _activeFuture;
  late Future<List<PromotionModel>> _savedFuture;

  @override
  void initState() {
    super.initState();
    _activeFuture = _service.getActivePromotions();
    _savedFuture = _service.getSavedPromotions();
  }

  void _refreshSaved() {
    setState(() {
      _savedFuture = _service.getSavedPromotions();
    });
  }

  Future<void> _saveCode(String code) async {
    final (ok, msg) = await _service.savePromotion(code);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    if (ok) _refreshSaved();
  }

  List<CartLineDto> _cartLinesFromProvider(CartProvider cart) {
    final Map<int, int> qtyById = {};
    for (final item in cart.items) {
      final id = item.menuItem.itemId;
      qtyById[id] = (qtyById[id] ?? 0) + item.quantity;
    }
    return qtyById.entries
        .where((e) => e.value > 0)
        .map((e) => CartLineDto(menuItemId: e.key, quantity: e.value))
        .toList();
  }

  Future<void> _applyCode(String code) async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    final (ok, result, msg) = await _service.applyPromotion(
      code: code,
      items: _cartLinesFromProvider(cart),
    );
    if (!mounted) return;

    if (!ok || result == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    if (!result.canApply && result.itemsToAdd.isNotEmpty) {
      final shouldBuyNow = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Voucher chua du dieu kien'),
            content: const Text('Them mon bat buoc vao gio va ap dung voucher?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Huy'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Mua ngay'),
              ),
            ],
          );
        },
      );

      if (shouldBuyNow != true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
        return;
      }

      final allMenu = await _menuService.getMenuItems();
      final menuById = {for (final m in allMenu) m.itemId: m};

      for (final add in result.itemsToAdd) {
        final menuItem = menuById[add.menuItemId];
        if (menuItem == null) continue;
        if (add.quantity <= 0) continue;
        cart.addItem(menuItem, add.quantity, const [], menuItem.price);
      }

      final (ok2, result2, msg2) = await _service.applyPromotion(
        code: code,
        items: _cartLinesFromProvider(cart),
      );
      if (!mounted) return;
      if (!ok2 || result2 == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg2)));
        return;
      }

      cart.setPromotion(code: code, discount: result2.discountAmount.toDouble());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Da ap dung voucher $code.')),
      );
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }

    if (!result.canApply) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }

    cart.setPromotion(code: code, discount: result.discountAmount.toDouble());
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Da ap dung voucher $code.')),
    );
    if (Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  Widget _promoCard(PromotionModel p, {required bool showSave}) {
    final fmt = DateFormat('dd/MM/yyyy HH:mm');

    String discountText() {
      final type = p.type;
      if (type == 'PercentBill') {
        return 'Giảm: ${p.discountPercentage}%';
      }
      if (type == 'AmountBill' && p.discountAmount != null) {
        return 'Giảm: ${Money.vnd(p.discountAmount!)}';
      }
      if (type == 'BuyXGetY') {
        return 'Loại: Mua X tang Y';
      }
      if (type == 'Combo') {
        return 'Loại: Combo';
      }
      return 'Loại: $type';
    }

    String conditionText() {
      final parts = <String>[];
      if (p.minOrderAmount != null && (p.minOrderAmount as num) > 0) {
        parts.add('Tối thiểu ${Money.vnd(p.minOrderAmount!)}');
      }
      if (p.maxDiscountAmount != null && (p.maxDiscountAmount as num) > 0) {
        parts.add('Giảm tối đa ${Money.vnd(p.maxDiscountAmount!)}');
      }
      if (p.type == 'BuyXGetY' && p.buyItemId != null && p.buyQuantity != null && p.getItemId != null && p.getQuantity != null) {
        parts.add('Mua ${p.buyQuantity} (ID ${p.buyItemId}) tang ${p.getQuantity} (ID ${p.getItemId})');
      }
      if (p.type == 'Combo' && p.comboRequirements.isNotEmpty) {
        final combo = p.comboRequirements.map((e) => '${e.qty}xID${e.itemId}').join(', ');
        parts.add('Combo: $combo');
      }
      if (parts.isEmpty) return 'Điều kiện: Không';
      return 'Điều kiện: ${parts.join(' • ')}';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
              Expanded(
                child: Text(
                  p.code,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              TextButton(
                onPressed: () => _applyCode(p.code),
                child: const Text('Dùng'),
              ),
              if (showSave)
                TextButton(
                  onPressed: () => _saveCode(p.code),
                  child: const Text('Lưu'),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(p.description, style: const TextStyle(color: Colors.black87)),
          const SizedBox(height: 8),
          Text(discountText(), style: const TextStyle(fontSize: 12, color: Colors.black87)),
          const SizedBox(height: 4),
          Text(conditionText(), style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 10),
          Text(
            'Hiệu lực: ${fmt.format(p.startDate.toLocal())} - ${fmt.format(p.endDate.toLocal())}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildList(Future<List<PromotionModel>> future, {required bool showSave}) {
    return FutureBuilder<List<PromotionModel>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snap.data ?? [];
        if (data.isEmpty) {
          return const Center(child: Text('Không có voucher nào.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: data.length,
          itemBuilder: (ctx, i) => _promoCard(data[i], showSave: showSave),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF9FAFB),
        appBar: AppBar(
          title: const Text(
            'Khuyến mãi',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          bottom: const TabBar(
            labelColor: Colors.black,
            tabs: [
              Tab(text: 'Đang có'),
              Tab(text: 'Đã lưu'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(_activeFuture, showSave: true),
            _buildList(_savedFuture, showSave: false),
          ],
        ),
      ),
    );
  }
}
