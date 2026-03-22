import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import 'cart_screen.dart';
import 'home_screen.dart';
import '../providers/favorites_provider.dart';
import '../utils/image_helper.dart'; // [FIX] Import image helper
import '../utils/money.dart';
import '../models/menu_item_customization.dart';
import '../services/menu_item_customization_service.dart';

// Định nghĩa màu xanh giống trong hình thiết kế
const Color kPrimaryColor = Color(0xFF2ED162); // Màu xanh lá sáng
const Color kBackgroundColor = Color(0xFFF8F9FA); // Màu nền xám rất nhạt

class _OptionGroup {
  final String key;
  final String title;
  final bool required;
  final List<String> choices;

  const _OptionGroup({
    required this.key,
    required this.title,
    required this.required,
    required this.choices,
  });
}

class _CustomizationPreset {
  final List<_OptionGroup> optionGroups;
  final Map<String, double> extras;

  const _CustomizationPreset({
    required this.optionGroups,
    required this.extras,
  });
}

class ProductDetailScreen extends StatefulWidget {
  final MenuItem menuItem;

  const ProductDetailScreen({Key? key, required this.menuItem})
    : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int quantity = 1;

  final MenuItemCustomizationService _customizationService =
      MenuItemCustomizationService();

  // --- FAKE DATA ĐỂ GIỐNG UI DESIGN (Vì Backend chưa có) ---
  // Sau này có API thì thay thế list này bằng dữ liệu từ API
  final String _calories = "520 kcal";
  final double _rating = 4.8;
  final int _reviews = 120;

  _CustomizationPreset _preset = const _CustomizationPreset(
    optionGroups: [],
    extras: {},
  );
  final Map<String, String> _selectedByGroup = {};
  final Set<String> _selectedExtras = <String>{};
  final TextEditingController _otherController = TextEditingController();

  void _handleBack() {
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
    _initPreset();
  }

  Future<void> _initPreset() async {
    final customization = await _customizationService.getCustomizations(
      widget.menuItem.itemId,
    );
    if (!mounted) return;

    setState(() {
      _applyPreset(_presetFromCustomization(customization));
    });
  }

  _CustomizationPreset _presetFromCustomization(MenuItemCustomization? customization) {
    if (customization == null) {
      return const _CustomizationPreset(optionGroups: [], extras: {});
    }

    final groups = [...customization.optionGroups];
    groups.sort((a, b) {
      final byOrder = a.sortOrder.compareTo(b.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.optionGroupId.compareTo(b.optionGroupId);
    });

    final optionGroups = <_OptionGroup>[];
    final extras = <String, double>{};

    for (final g in groups) {
      final options = [...g.options.where((o) => o.isAvailable)];
      options.sort((a, b) {
        final byOrder = a.sortOrder.compareTo(b.sortOrder);
        if (byOrder != 0) return byOrder;
        return a.optionId.compareTo(b.optionId);
      });

      if (g.isMultiple) {
        for (final o in options) {
          extras[o.name] = o.priceDelta;
        }
        continue;
      }

      optionGroups.add(
        _OptionGroup(
          key: g.key,
          title: g.title,
          required: g.isRequired,
          choices: options.map((o) => o.name).toList(),
        ),
      );
    }

    return _CustomizationPreset(optionGroups: optionGroups, extras: extras);
  }

  void _applyPreset(_CustomizationPreset preset) {
    _preset = preset;
    _selectedByGroup.clear();
    _selectedExtras.clear();

    for (final group in _preset.optionGroups) {
      if (group.required && group.choices.isNotEmpty) {
        _selectedByGroup[group.key] = group.choices.first;
      }
    }
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  // Hàm tính tổng tiền: (Giá gốc + Giá Extras) * Số lượng
  double get totalPrice {
    double extrasTotal = 0;
    for (var extra in _selectedExtras) {
      extrasTotal += _preset.extras[extra] ?? 0;
    }
    return (widget.menuItem.price + extrasTotal) * quantity;
  }


  List<String> _buildSelectedOptions() {
    final options = <String>[];
    for (final group in _preset.optionGroups) {
      final selected = _selectedByGroup[group.key];
      if (selected != null && selected.isNotEmpty) {
        options.add('${group.title}: $selected');
      }
    }

    for (final extra in _selectedExtras) {
      options.add('Them: $extra');
    }

    return options;
  }

  bool _hasMissingRequiredSelection() {
    for (final group in _preset.optionGroups) {
      if (!group.required) continue;
      final selected = _selectedByGroup[group.key];
      if (selected == null || selected.isEmpty) {
        return true;
      }
    }
    return false;
  }

  Widget _buildOptionGroup(_OptionGroup group) {
    final selected = _selectedByGroup[group.key];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: _buildSectionHeader(
            group.title,
            group.required ? '(Bat buoc)' : '(Tuy chon)',
          ),
        ),
        if (!group.required && selected != null && selected.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () {
                setState(() {
                  _selectedByGroup.remove(group.key);
                });
              },
              child: const Text('Bo chon'),
            ),
          ),
        ...group.choices.map(
          (choice) => RadioListTile<String>(
            title: Text(choice),
            value: choice,
            groupValue: _selectedByGroup[group.key],
            activeColor: kPrimaryColor,
            contentPadding: EdgeInsets.zero,
            onChanged: (value) {
              setState(() {
                _selectedByGroup[group.key] = value ?? '';
              });
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = context.select<FavoritesProvider, bool>(
      (p) => p.isFavorite(widget.menuItem.itemId),
    );

    return Scaffold(
      backgroundColor: kBackgroundColor,
      body: Stack(
        children: [
          // 1. Phần nội dung cuộn được
          SingleChildScrollView(
            padding: const EdgeInsets.only(
              bottom: 100,
            ), // Chừa chỗ cho BottomBar
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [_buildHeaderImage(context), _buildContentBody()],
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
                _buildCircleIconButton(Icons.arrow_back, _handleBack),
                _buildCircleIconButton(
                  isFavorite ? Icons.favorite : Icons.favorite_border,
                  () async {
                    final favorites = context.read<FavoritesProvider>();
                    final wasFavorite = favorites.isFavorite(
                      widget.menuItem.itemId,
                    );

                    try {
                      await favorites.toggle(widget.menuItem);
                    } catch (_) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Khong the cap nhat yeu thich.'),
                        ),
                      );
                      return;
                    }

                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          wasFavorite
                              ? 'Da bo khoi yeu thich'
                              : 'Da them vao yeu thich',
                        ),
                        backgroundColor: kPrimaryColor,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // 3. Bottom Bar (Sticky at bottom)
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomBar()),
        ],
      ),
    );
  }

  // Widget hiển thị ảnh Header
  Widget _buildHeaderImage(BuildContext context) {
    return SizedBox(
      // Dùng SizedBox thay Container
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
      transform: Matrix4.translationValues(
        0.0,
        -30.0,
        0.0,
      ), // Đẩy lên đè ảnh một chút
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
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text(
                Money.vnd(widget.menuItem.price),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            "Cang tin A • Khu phia Tay",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 20),
          // Hàng thông tin metrics (Rating, Calories, Tag)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricChip(
                Icons.star,
                "$_rating ($_reviews)",
                Colors.amber,
              ),
              _buildMetricChip(
                Icons.local_fire_department,
                _calories,
                Colors.orange,
              ),
              _buildMetricChip(Icons.eco, "Tot cho suc khoe", Colors.green),
            ],
          ),

          const SizedBox(height: 24),
          // Description
          const Text(
            "Mo ta",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            widget.menuItem.description ?? "Chua co mo ta.",
            style: const TextStyle(color: Colors.grey, height: 1.5),
          ),

          if (_preset.optionGroups.isNotEmpty) ...[
            const SizedBox(height: 24),
            ..._preset.optionGroups.map(_buildOptionGroup),
          ],

          if (_preset.extras.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildSectionHeader('Phan them', '(Tuy chon)'),
            ..._preset.extras.entries.map(
              (entry) => CheckboxListTile(
                title: Text(entry.key),
                secondary: Text(
                  '+${Money.vnd(entry.value)}',
                  style: const TextStyle(
                    color: kPrimaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                value: _selectedExtras.contains(entry.key),
                activeColor: kPrimaryColor,
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                onChanged: (bool? checked) {
                  setState(() {
                    if (checked == true) {
                      _selectedExtras.add(entry.key);
                    } else {
                      _selectedExtras.remove(entry.key);
                    }
                  });
                },
              ),
            ),
          ],

          const SizedBox(height: 16),
          _buildSectionHeader('Khac', '(Ghi chu tuy chon)'),
          const SizedBox(height: 8),
          TextField(
            controller: _otherController,
            maxLines: 3,
            maxLength: 200,
            decoration: InputDecoration(
              hintText: 'VD: Ít hành, không tiêu, đóng gói riêng...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                borderSide: BorderSide(color: kPrimaryColor),
              ),
            ),
          ),
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
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
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
                Text(
                  "$quantity",
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                if (_hasMissingRequiredSelection()) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng chọn đủ các mục bắt buộc.'),
                    ),
                  );
                  return;
                }

                final options = _buildSelectedOptions();
                final otherNote = _otherController.text.trim();

                // Gọi Provider để thêm vào giỏ
                Provider.of<CartProvider>(context, listen: false).addItem(
                  widget.menuItem,
                  quantity,
                  options,
                  totalPrice / quantity, // Giá đơn vị đã cộng toppings
                  otherNote: otherNote.isEmpty ? null : otherNote,
                );

                // Hiển thị thông báo hoặc chuyển sang giỏ hàng
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    behavior: SnackBarBehavior.floating,
                    margin: EdgeInsets.fromLTRB(
                      16,
                      0,
                      16,
                      96 + MediaQuery.of(context).padding.bottom,
                    ),
                    content: Text(
                      "Da them ${widget.menuItem.name} vao khay!",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    backgroundColor: kPrimaryColor,
                    action: SnackBarAction(
                      label: "XEM KHAY",
                      textColor: Colors.white,
                      onPressed: () {
                        if (!mounted) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartScreen()),
                        );
                      },
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Expanded(
                    child: Text(
                      "Them vao don",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 140),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Money.vnd(totalPrice),
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Các Widget nhỏ hỗ trợ (Helper Widgets)
  Widget _buildCircleIconButton(IconData icon, VoidCallback onPressed) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
      ),
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
          Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        if (subtitle.isNotEmpty) ...[
          const SizedBox(width: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
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
