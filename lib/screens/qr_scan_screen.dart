import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';

import '../models/promotion_model.dart';
import '../providers/cart_provider.dart';
import '../services/menu_service.dart';
import '../services/promotions_service.dart';
import '../utils/money.dart';
import 'promotions_screen.dart';

class QrScanScreen extends StatefulWidget {
  const QrScanScreen({super.key});

  @override
  State<QrScanScreen> createState() => _QrScanScreenState();
}

class _QrScanScreenState extends State<QrScanScreen> {
  final MobileScannerController _controller = MobileScannerController();
  final PromotionsService _promotionsService = PromotionsService();
  final MenuService _menuService = MenuService();

  bool _handling = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRaw(String raw) async {
    if (_handling) return;
    _handling = true;

    Map<String, dynamic>? payload;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        payload = decoded;
      }
    } catch (_) {
      payload = null;
    }

    if (payload == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('QR khong hop le.')),
        );
      }
      _handling = false;
      return;
    }

    final kind = (payload['kind'] ?? '').toString();
    if (kind == 'checkin') {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PromotionsScreen()),
      );
      return;
    }

    if (kind == 'voucher') {
      final code = (payload['code'] ?? '').toString().trim();
      if (code.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('QR voucher thieu ma.')),
          );
        }
        _handling = false;
        return;
      }

      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Voucher'),
            content: Text('Ma: $code'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                },
                child: const Text('Huy'),
              ),
              TextButton(
                onPressed: () async {
                  final (ok, msg) = await _promotionsService.savePromotion(code);
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
                  }
                },
                child: const Text('Luu'),
              ),
              TextButton(
                onPressed: () async {
                  final (applied, message) = await _buyNowAndApply(code);
                  if (!ctx.mounted) return;
                  Navigator.of(ctx).pop();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message.isNotEmpty ? message : (applied ? 'Da ap dung voucher.' : 'Khong ap dung duoc voucher.'))),
                    );
                  }
                },
                child: const Text('Mua ngay'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loai QR chua ho tro.')),
      );
    }

    _handling = false;
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

  Future<(bool applied, String message)> _buyNowAndApply(String code) async {
    final cart = Provider.of<CartProvider>(context, listen: false);

    final (ok, result, msg) = await _promotionsService.applyPromotion(
      code: code,
      items: _cartLinesFromProvider(cart),
    );

    if (!ok || result == null) return (false, msg);

    if (result.canApply) {
      cart.setPromotion(code: code, discount: result.discountAmount.toDouble());
      return (true, result.message.isNotEmpty ? result.message : 'Da ap dung voucher.');
    }

    if (!result.canApply && result.itemsToAdd.isNotEmpty) {
      final allMenu = await _menuService.getMenuItems();
      final menuById = {for (final m in allMenu) m.itemId: m};

      for (final add in result.itemsToAdd) {
        final menuItem = menuById[add.menuItemId];
        if (menuItem == null) continue;
        if (add.quantity <= 0) continue;

        cart.addItem(menuItem, add.quantity, const [], menuItem.price);
      }

      final (ok2, result2, msg2) = await _promotionsService.applyPromotion(
        code: code,
        items: _cartLinesFromProvider(cart),
      );
      if (!ok2 || result2 == null) return (false, msg2);
      if (!result2.canApply) return (false, result2.message);

      cart.setPromotion(code: code, discount: result2.discountAmount.toDouble());
      return (true, result2.message.isNotEmpty ? result2.message : 'Da ap dung voucher.');
    }

    // Not applicable and no suggestions.
    return (false, result.message);
  }

  @override
  Widget build(BuildContext context) {
    const Color brandGreen = Color(0xFF00E676);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Quet QR'),
        backgroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _controller.toggleTorch(),
          ),
          IconButton(
            icon: const Icon(Icons.cameraswitch),
            onPressed: () => _controller.switchCamera(),
          ),
        ],
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              final barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;
              final raw = barcodes.first.rawValue;
              if (raw == null || raw.isEmpty) return;
              _handleRaw(raw);
            },
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black.withOpacity(0.6),
              child: Consumer<CartProvider>(
                builder: (context, cart, _) {
                  return Text(
                    'Gio hang: ${Money.vnd(cart.finalTotal)}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white),
                  );
                },
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 110,
            child: Center(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  border: Border.all(color: brandGreen, width: 3),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
